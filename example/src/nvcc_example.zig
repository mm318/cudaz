const std = @import("std");

const c = @cImport({
    // workaround compilation error based on https://github.com/Narsil/zig_cuda_bug/blob/main/src/main.zig#L3
    @cDefine("struct___device_builtin__", "__device_builtin__");
    @cInclude("cuda_runtime.h");
    @cInclude("tuple.h");
});

extern "C" fn launchOffset(block_dim: c.dim3, grid_dim: c.dim3, in: [*c]c.tuple, out: [*c]f32) void;

fn cudaMalloc(dataType: type, num: usize) ![]dataType {
    var devPtr: ?*anyopaque = undefined;
    const result = c.cudaMalloc(&devPtr, num * @sizeOf(dataType));
    if (result != c.cudaSuccess) {
        return error.CudaError;
    }
    if (devPtr) |ptr| {
        var slice: []dataType = undefined;
        slice.ptr = @alignCast(@ptrCast(ptr));
        slice.len = num;
        return slice;
    } else {
        return error.NullPointer;
    }
}

fn cudaMemcpy(dataType: type, dst_slice: *[]dataType, src_slice: []const dataType, num: usize, kind: c.cudaMemcpyKind) !void {
    const result = c.cudaMemcpy(dst_slice.ptr, src_slice.ptr, num * @sizeOf(dataType), kind);
    if (result != c.cudaSuccess) {
        return error.CudaError;
    }
    dst_slice.len = num;
}

fn cudaFree(dataType: type, slice: *[]dataType) !void {
    const result = c.cudaFree(@constCast(@ptrCast(slice.ptr)));
    if (result != c.cudaSuccess) {
        return error.CudaError;
    }
    slice.len = 0;
}

pub fn main() !void {
    // Initialize allocator
    var GP = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = GP.deinit();
    const allocator = GP.allocator();
    std.debug.print("Initialized allocator\n", .{});

    // Initialize host data with a custom data type
    var src_array = try std.ArrayList(c.tuple).initCapacity(allocator, 10);
    defer src_array.deinit();
    for (0..10) |index| {
        try src_array.append(.{ .x = @floatFromInt(index), .y = @as(f32, @floatFromInt(index)) + std.math.pi });
    }

    // Allocate 10 tuple in GPU memory
    var src_cu_slice = try cudaMalloc(c.tuple, src_array.items.len);
    defer cudaFree(c.tuple, &src_cu_slice) catch @panic("unable to clean up memory");

    // Copy data from host to GPU
    try cudaMemcpy(c.tuple, &src_cu_slice, src_array.items, src_array.items.len, c.cudaMemcpyHostToDevice);
    std.debug.print("Copied tuple array {any} from system to GPU\n", .{src_array.items});

    // Allocate 10 f32 in GPU memory
    const dest_cu_slice = try cudaMalloc(f32, src_array.items.len);

    // Run the kernel on the data
    const block_dim = c.dim3{ .x = 10, .y = 1, .z = 1 };
    const grid_dim = c.dim3{ .x = 1, .y = 1, .z = 1 };
    launchOffset(block_dim, grid_dim, src_cu_slice.ptr, dest_cu_slice.ptr);

    // Retrieve incremented data back to the system
    var incremented_arr = try std.ArrayList(f32).initCapacity(allocator, src_array.items.len);
    defer incremented_arr.deinit();
    try cudaMemcpy(f32, &incremented_arr.items, dest_cu_slice, dest_cu_slice.len, c.cudaMemcpyDeviceToHost);
    incremented_arr.items.len = dest_cu_slice.len;
    std.debug.print("Retrieved offset data {d:.3} from GPU to system\n", .{incremented_arr.items});
}
