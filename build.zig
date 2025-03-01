const std = @import("std");

const GPU_ARCH = "sm_50";
const KERNELS_PATH = "src/kernels";

fn compileCuda(
    b: *std.Build,
    nvcc_path: []const u8,
    source_filepath: std.Build.LazyPath,
    target_filename: []const u8,
    exe_compile_step: *std.Build.Step.Compile,
) void {
    const nvcc_args = &.{
        "-O3",
        b.fmt("--gpu-architecture={s}", .{GPU_ARCH}),
        "--compiler-options",
        "-fPIC",
    };

    const nvcc_compile_step = b.addSystemCommand(&.{nvcc_path});
    nvcc_compile_step.addArg("-c");
    nvcc_compile_step.addFileArg(source_filepath);
    nvcc_compile_step.addArg("-o");
    const target_filepath = nvcc_compile_step.addOutputFileArg(target_filename);
    nvcc_compile_step.addArgs(nvcc_args);

    exe_compile_step.addObjectFile(target_filepath);
    exe_compile_step.step.dependOn(&nvcc_compile_step.step);
}

fn use_nvcc(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    cuda_path: []const u8,
) *std.Build.Step.Compile {
    const nvcc_path = b.pathJoin(&.{ cuda_path, "bin", "nvcc" });

    const exe = b.addExecutable(.{
        .name = "nvcc_example",
        .root_source_file = .{ .cwd_relative = "src/nvcc_example.zig" },
        .target = target,
        .optimize = optimize,
    });

    const source_path = b.pathJoin(&.{ "src", "kernels", "offset.cu" });
    const target_filename = b.fmt("{s}.{s}", .{ std.fs.path.stem(source_path), "o" });
    compileCuda(b, nvcc_path, b.path(source_path), target_filename, exe);

    exe.addIncludePath(.{ .cwd_relative = b.fmt("{s}/include", .{cuda_path}) });
    exe.addIncludePath(b.path(KERNELS_PATH));

    exe.addLibraryPath(.{ .cwd_relative = b.fmt("{s}/lib64", .{cuda_path}) });
    exe.linkLibC();
    exe.linkSystemLibrary("cuda");
    exe.linkSystemLibrary("cudart");

    return exe;
}

fn use_nvrtc(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    cuda_path: []const u8,
) *std.Build.Step.Compile {
    const cudaz_build_utils = @import("cudaz");

    // exe points to main.zig that uses cudaz
    const exe = b.addExecutable(.{
        .name = "nvrtc_example",
        .root_source_file = b.path("src/nvrtc_example.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Point to cudaz dependency
    const cudaz_dep = b.dependency("cudaz", .{ .CUDA_PATH = cuda_path });

    // Fetch and add the module from cudaz dependency
    const cudaz_module = cudaz_dep.module("cudaz");
    exe.root_module.addImport("cudaz", cudaz_module);
    const cudaz_includes = cudaz_build_utils.generateCudazIncludes(exe, b.path(KERNELS_PATH)) catch @panic("failed to write files");
    exe.root_module.addAnonymousImport("cudaz_includes", .{ .root_source_file = cudaz_includes });

    // Dynamically link to libc, cuda, nvrtc
    exe.linkLibC();
    exe.linkSystemLibrary("cuda");
    exe.linkSystemLibrary("nvrtc");

    return exe;
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const cuda_path = std.process.getEnvVarOwned(b.allocator, "CUDA_PATH") catch "/usr/local/cuda";

    const nvcc_example = use_nvcc(b, target, optimize, cuda_path);
    const nvrtc_example = use_nvrtc(b, target, optimize, cuda_path);

    b.installArtifact(nvcc_example);
    b.installArtifact(nvrtc_example);

    // Run binary
    const run = b.step("run", "Run the nvrtc example");
    const run_step = b.addRunArtifact(nvrtc_example);
    run.dependOn(&run_step.step);

    const run_static = b.step("run_static", "Run the nvrtc example");
    const run_static_step = b.addRunArtifact(nvcc_example);
    run_static.dependOn(&run_static_step.step);
}
