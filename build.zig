const std = @import("std");

pub fn build(b: *std.Build) !void {
    // Point to cudaz dependency
    const cudaz_dep = b.dependency(
        "cudaz",
        .{ .CUDA_PATH = @as([]const u8, "/usr/local/cuda-12.6") },
    );

    // exe points to main.zig that uses cudaz
    const exe = b.addExecutable(.{
        .name = "main",
        .root_source_file = b.path("src/main.zig"),
        .target = b.host,
    });

    // Fetch and add the module from cudaz dependency
    const cudaz_module = cudaz_dep.module("cudaz");
    exe.root_module.addImport("cudaz", cudaz_module);
    const cudaz_includes = try @import("cudaz").generateCudazIncludes(exe, b.path("src/kernels/"));
    exe.root_module.addAnonymousImport("cudaz_includes", .{ .root_source_file = cudaz_includes });

    // Dynamically link to libc, cuda, nvrtc
    exe.linkLibC();
    exe.linkSystemLibrary("cuda");
    exe.linkSystemLibrary("nvrtc");

    // Run binary
    const run = b.step("run", "Run the binary");
    const run_step = b.addRunArtifact(exe);
    run.dependOn(&run_step.step);
}
