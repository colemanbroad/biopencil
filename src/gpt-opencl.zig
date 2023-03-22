const std = @import("std");
const ocl = @import("std").opencl;
// const ocl = @cImport("OpenCL/cl.h");

pub fn main() !void {
    const num_elements: usize = 1000;
    var arr: [num_elements]u32 = undefined;
    std.debug.print("hello world\n\n", .{});

    // Initialize array with random data
    for (&arr) |*element| {
        element.* = @as(u32, std.rand.uniform(0, 100));
    }

    // Initialize OpenCL context and command queue
    const platform = try ocl.getPlatform(ocl.PlatformFilter.Any);
    const device = try ocl.getDevice(platform, ocl.DeviceFilter.Any);
    const context = try ocl.createContext(&device);
    defer ocl.destroyContext(&context);
    const queue = try ocl.createCommandQueue(&context, &device, {});

    // Create OpenCL memory buffer and copy array to it
    const buffer_size = num_elements * @sizeOf(u32);
    const buffer = try ocl.createBuffer(&context, ocl.MemFlags.WriteOnly, buffer_size, null);
    defer ocl.releaseMemObject(&buffer);
    try ocl.enqueueWriteBuffer(&queue, &buffer, true, 0, buffer_size, arr);

    // Create OpenCL program that sums the elements of the array
    const program_source =
        \\ __kernel void sum(__global uint* arr, __global uint* result) {
        \\     const size_t gid = get_global_id(0);
        \\     result[0] = atomic_add(result, arr[gid]);
        \\ }
    ;

    const program = try ocl.createProgramWithSource(&context, program_source);
    defer ocl.releaseProgram(&program);
    try ocl.buildProgram(&program, &device);

    // Create kernel from program and set arguments
    const kernel = try ocl.createKernel(&program, "sum");
    defer ocl.releaseKernel(&kernel);
    try ocl.setKernelArg(&kernel, 0, buffer);
    const result_size = @sizeOf(u32);
    const result_buffer = try ocl.createBuffer(&context, ocl.MemFlags.ReadWrite, result_size, null);
    try ocl.setKernelArg(&kernel, 1, result_buffer);

    // Execute kernel and retrieve result
    try ocl.enqueueNDRangeKernel(&queue, &kernel, 1, 0, num_elements, null);
    var result: u32 = undefined;
    try ocl.enqueueReadBuffer(&queue, &result_buffer, true, 0, result_size, &result);

    // Print result
    std.debug.print("{d}\n", .{result});
}
