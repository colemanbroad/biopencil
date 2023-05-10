pub const cl = @cImport({
    // @cDefine("CL_TARGET_OPENCL_VERSION", "220");
    @cDefine("CL_USE_DEPRECATED_OPENCL_1_2_APIS", "");
    @cInclude("OpenCL/cl.h");
});

const std = @import("std");

const im = @import("image_base.zig");
const print = std.debug.print;
const assert = std.debug.assert;
const expect = std.testing.expect;
const eql = std.mem.eql;
const min = std.math.min;
const max = std.math.max;
const View = @import("biopencil.zig").View;

const ViewOpenCL = struct {
    // view_matrix: [9]f32, // orthonormal
    front_scale: [3]f32,
    back_scale: [3]f32,
    anisotropy: [3]f32,
    screen_size: [2]u32,
    theta: f32,
    phi: f32,
};

const ViewOpenCLTest = extern struct {
    view_matrix: [9]f32, // orthonormal
    // front_scale: [3]f32,
    // back_scale: [3]f32,
    // anisotropy: [3]f32,
    // screen_size: [2]u32,
    theta: f32,
    phi: f32,
};

const milliTimestamp = std.time.milliTimestamp;

const Img2D = im.Img2D;
const Img3D = im.Img3D;

pub fn err(val: cl.cl_int) CLERROR!void {
    const maybeErr = switch (val) {
        0 => cl.CL_SUCCESS,
        -1 => CLERROR.CL_DEVICE_NOT_FOUND,
        -2 => CLERROR.CL_DEVICE_NOT_AVAILABLE,
        -3 => CLERROR.CL_COMPILER_NOT_AVAILABLE,
        -4 => CLERROR.CL_MEM_OBJECT_ALLOCATION_FAILURE,
        -5 => CLERROR.CL_OUT_OF_RESOURCES,
        -6 => CLERROR.CL_OUT_OF_HOST_MEMORY,
        -7 => CLERROR.CL_PROFILING_INFO_NOT_AVAILABLE,
        -8 => CLERROR.CL_MEM_COPY_OVERLAP,
        -9 => CLERROR.CL_IMAGE_FORMAT_MISMATCH,
        -10 => CLERROR.CL_IMAGE_FORMAT_NOT_SUPPORTED,
        -11 => CLERROR.CL_BUILD_PROGRAM_FAILURE,
        -12 => CLERROR.CL_MAP_FAILURE,
        -13 => CLERROR.CL_MISALIGNED_SUB_BUFFER_OFFSET,
        -14 => CLERROR.CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST,
        -15 => CLERROR.CL_COMPILE_PROGRAM_FAILURE,
        -16 => CLERROR.CL_LINKER_NOT_AVAILABLE,
        -17 => CLERROR.CL_LINK_PROGRAM_FAILURE,
        -18 => CLERROR.CL_DEVICE_PARTITION_FAILED,
        -19 => CLERROR.CL_KERNEL_ARG_INFO_NOT_AVAILABLE,
        -30 => CLERROR.CL_INVALID_VALUE,
        -31 => CLERROR.CL_INVALID_DEVICE_TYPE,
        -32 => CLERROR.CL_INVALID_PLATFORM,
        -33 => CLERROR.CL_INVALID_DEVICE,
        -34 => CLERROR.CL_INVALID_CONTEXT,
        -35 => CLERROR.CL_INVALID_QUEUE_PROPERTIES,
        -36 => CLERROR.CL_INVALID_COMMAND_QUEUE,
        -37 => CLERROR.CL_INVALID_HOST_PTR,
        -38 => CLERROR.CL_INVALID_MEM_OBJECT,
        -39 => CLERROR.CL_INVALID_IMAGE_FORMAT_DESCRIPTOR,
        -40 => CLERROR.CL_INVALID_IMAGE_SIZE,
        -41 => CLERROR.CL_INVALID_SAMPLER,
        -42 => CLERROR.CL_INVALID_BINARY,
        -43 => CLERROR.CL_INVALID_BUILD_OPTIONS,
        -44 => CLERROR.CL_INVALID_PROGRAM,
        -45 => CLERROR.CL_INVALID_PROGRAM_EXECUTABLE,
        -46 => CLERROR.CL_INVALID_KERNEL_NAME,
        -47 => CLERROR.CL_INVALID_KERNEL_DEFINITION,
        -48 => CLERROR.CL_INVALID_KERNEL,
        -49 => CLERROR.CL_INVALID_ARG_INDEX,
        -50 => CLERROR.CL_INVALID_ARG_VALUE,
        -51 => CLERROR.CL_INVALID_ARG_SIZE,
        -52 => CLERROR.CL_INVALID_KERNEL_ARGS,
        -53 => CLERROR.CL_INVALID_WORK_DIMENSION,
        -54 => CLERROR.CL_INVALID_WORK_GROUP_SIZE,
        -55 => CLERROR.CL_INVALID_WORK_ITEM_SIZE,
        -56 => CLERROR.CL_INVALID_GLOBAL_OFFSET,
        -57 => CLERROR.CL_INVALID_EVENT_WAIT_LIST,
        -58 => CLERROR.CL_INVALID_EVENT,
        -59 => CLERROR.CL_INVALID_OPERATION,
        -60 => CLERROR.CL_INVALID_GL_OBJECT,
        -61 => CLERROR.CL_INVALID_BUFFER_SIZE,
        -62 => CLERROR.CL_INVALID_MIP_LEVEL,
        -63 => CLERROR.CL_INVALID_GLOBAL_WORK_SIZE,
        -64 => CLERROR.CL_INVALID_PROPERTY,
        -65 => CLERROR.CL_INVALID_IMAGE_DESCRIPTOR,
        -66 => CLERROR.CL_INVALID_COMPILER_OPTIONS,
        -67 => CLERROR.CL_INVALID_LINKER_OPTIONS,
        -68 => CLERROR.CL_INVALID_DEVICE_PARTITION_COUNT,
        -69 => CLERROR.CL_INVALID_PIPE_SIZE,
        -70 => CLERROR.CL_INVALID_DEVICE_QUEUE,
        -71 => CLERROR.CL_INVALID_SPEC_ID,
        -72 => CLERROR.CL_MAX_SIZE_RESTRICTION_EXCEEDED,
        else => unreachable,
    };

    if (maybeErr) |_| {
        // no error, return void
        return;
    } else |e| {
        // yes error
        print("OpenCL ERROR: {d} {!} \n", .{ val, e });
        @breakpoint();
        return e;
    }
}

pub const CLERROR = error{
    CL_DEVICE_NOT_FOUND,
    CL_DEVICE_NOT_AVAILABLE,
    CL_COMPILER_NOT_AVAILABLE,
    CL_MEM_OBJECT_ALLOCATION_FAILURE,
    CL_OUT_OF_RESOURCES,
    CL_OUT_OF_HOST_MEMORY,
    CL_PROFILING_INFO_NOT_AVAILABLE,
    CL_MEM_COPY_OVERLAP,
    CL_IMAGE_FORMAT_MISMATCH,
    CL_IMAGE_FORMAT_NOT_SUPPORTED,
    CL_BUILD_PROGRAM_FAILURE,
    CL_MAP_FAILURE,
    CL_MISALIGNED_SUB_BUFFER_OFFSET,
    CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST,
    CL_COMPILE_PROGRAM_FAILURE,
    CL_LINKER_NOT_AVAILABLE,
    CL_LINK_PROGRAM_FAILURE,
    CL_DEVICE_PARTITION_FAILED,
    CL_KERNEL_ARG_INFO_NOT_AVAILABLE,
    CL_INVALID_VALUE,
    CL_INVALID_DEVICE_TYPE,
    CL_INVALID_PLATFORM,
    CL_INVALID_DEVICE,
    CL_INVALID_CONTEXT,
    CL_INVALID_QUEUE_PROPERTIES,
    CL_INVALID_COMMAND_QUEUE,
    CL_INVALID_HOST_PTR,
    CL_INVALID_MEM_OBJECT,
    CL_INVALID_IMAGE_FORMAT_DESCRIPTOR,
    CL_INVALID_IMAGE_SIZE,
    CL_INVALID_SAMPLER,
    CL_INVALID_BINARY,
    CL_INVALID_BUILD_OPTIONS,
    CL_INVALID_PROGRAM,
    CL_INVALID_PROGRAM_EXECUTABLE,
    CL_INVALID_KERNEL_NAME,
    CL_INVALID_KERNEL_DEFINITION,
    CL_INVALID_KERNEL,
    CL_INVALID_ARG_INDEX,
    CL_INVALID_ARG_VALUE,
    CL_INVALID_ARG_SIZE,
    CL_INVALID_KERNEL_ARGS,
    CL_INVALID_WORK_DIMENSION,
    CL_INVALID_WORK_GROUP_SIZE,
    CL_INVALID_WORK_ITEM_SIZE,
    CL_INVALID_GLOBAL_OFFSET,
    CL_INVALID_EVENT_WAIT_LIST,
    CL_INVALID_EVENT,
    CL_INVALID_OPERATION,
    CL_INVALID_GL_OBJECT,
    CL_INVALID_BUFFER_SIZE,
    CL_INVALID_MIP_LEVEL,
    CL_INVALID_GLOBAL_WORK_SIZE,
    CL_INVALID_PROPERTY,
    CL_INVALID_IMAGE_DESCRIPTOR,
    CL_INVALID_COMPILER_OPTIONS,
    CL_INVALID_LINKER_OPTIONS,
    CL_INVALID_DEVICE_PARTITION_COUNT,
    CL_INVALID_PIPE_SIZE,
    CL_INVALID_DEVICE_QUEUE,
    CL_INVALID_SPEC_ID,
    CL_MAX_SIZE_RESTRICTION_EXCEEDED,
};

test "Handle a custom CLERROR" {
    print("\n", .{});
    try err(0); // code zero => CL_SUCCESS
    print("{any}\n", .{@typeInfo(cl.cl_int)});
    err(-4) catch |e| switch (e) {
        CLERROR.CL_MEM_OBJECT_ALLOCATION_FAILURE => {
            // print("\nERROR: We ran out of mem, but handle it gracefully\n", .{});
        },
        else => unreachable,
    };
    print("\n", .{});
}

pub const MyCLError = error{
    GetPlatformsFailed,
    GetPlatformInfoFailed,
    NoPlatformsFound,
    GetDevicesFailed,
    GetDeviceInfoFailed,
    NoDevicesFound,
    CreateContextFailed,
    CreateCommandQueueFailed,
    CreateProgramFailed,
    BuildProgramFailed,
    CreateKernelFailed,
    SetKernelArgFailed,
    EnqueueNDRangeKernel,
    CreateBufferFailed,
    EnqueueWriteBufferFailed,
    EnqueueReadBufferFailed,
};

pub fn getClDevice() MyCLError!cl.cl_device_id {
    var platform_ids: [16]cl.cl_platform_id = undefined;
    var platform_count: cl.cl_uint = undefined;
    if (cl.clGetPlatformIDs(platform_ids.len, &platform_ids, &platform_count) != cl.CL_SUCCESS) {
        return MyCLError.GetPlatformsFailed;
    }
    // print("{} cl platform(s) found:\n", .{@intCast(u32, platform_count)});

    for (platform_ids[0..platform_count], 0..) |id, i| {
        var name: [1024]u8 = undefined;
        var name_len: usize = undefined;
        if (cl.clGetPlatformInfo(id, cl.CL_PLATFORM_NAME, name.len, &name, &name_len) != cl.CL_SUCCESS) {
            return MyCLError.GetPlatformInfoFailed;
        }
        _ = i;
        // print("platform {}: {s}\n", .{ i, name[0..name_len] });
    }

    if (platform_count == 0) {
        return MyCLError.NoPlatformsFound;
    }

    // print("choosing platform 0...\n", .{});

    var device_ids: [16]cl.cl_device_id = undefined;
    var device_count: cl.cl_uint = undefined;
    if (cl.clGetDeviceIDs(platform_ids[0], cl.CL_DEVICE_TYPE_ALL, device_ids.len, &device_ids, &device_count) != cl.CL_SUCCESS) {
        return MyCLError.GetDevicesFailed;
    }
    // print("{} cl device(s) found on platform 0:\n", .{@intCast(u32, device_count)});

    for (device_ids[0..device_count], 0..) |id, i| {
        var name: [1024]u8 = undefined;
        var name_len: usize = undefined;
        if (cl.clGetDeviceInfo(id, cl.CL_DEVICE_NAME, name.len, &name, &name_len) != cl.CL_SUCCESS) {
            return MyCLError.GetDeviceInfoFailed;
        }
        _ = i;
        // print("  device {}: {s}\n", .{ i, name[0..name_len] });
    }

    if (device_count == 0) {
        return MyCLError.NoDevicesFound;
    }

    // print("choosing device 0...\n", .{});

    return device_ids[0];
}

pub fn get_device_info_string(al: std.mem.Allocator, device: cl.cl_device_id, param_name: cl.cl_device_info) []u8 {
    var value_sz: usize = undefined;
    try err(cl.clGetDeviceInfo(device, param_name, 0, null, &value_sz));
    // char * value = new char[value_sz];
    var value = try al.alloc(u8, value_sz);
    try err(cl.clGetDeviceInfo(device, param_name, value_sz, value, null));
    return value;
}

pub const DevCtxQueProg = struct {
    const Self = @This();

    device: cl.cl_device_id,
    ctx: cl.cl_context,
    command_queue: cl.cl_command_queue,
    program: cl.cl_program,

    // TODO: How do I keep all these objects alive? Are they on the stack?
    // Have they already been malloc'd onto the heap? And that's why we have to call the various de-init funcs?
    pub fn init(
        al: std.mem.Allocator,
        comptime files: []const []const u8,
    ) !DevCtxQueProg {
        var ecode: cl.cl_int = undefined;

        // Get a device. Build a context and command queue.
        var device = try getClDevice();
        var ctx = cl.clCreateContext(null, 1, &device, null, null, &ecode);
        try err(ecode);
        var command_queue = cl.clCreateCommandQueue(ctx, device, 0, &ecode);
        try err(ecode);

        // Load Source from .cl files and coerce into null terminated c-style pointers.
        var cwd = try std.fs.cwd().openDir("src", .{});
        defer cwd.close();

        var prog_source = try al.alloc([:0]u8, files.len);
        defer al.free(prog_source);
        inline for (files, 0..) |name, i| {
            prog_source[i] = try cwd.readFileAllocOptions(al, name, 20_000, null, @alignOf(u8), 0);
            // defer al.free(prog_source[i]);
        }
        defer inline for (files, 0..) |_, i| al.free(prog_source[i]);
        var program = cl.clCreateProgramWithSource(ctx, @intCast(cl.cl_uint, files.len), @ptrCast([*c][*c]const u8, prog_source), null, &ecode);
        try err(ecode);

        ecode = cl.clBuildProgram(program, 1, &device, null, null, null); // (prog, n_devices, *device, ...)

        // Spit out CL compiler errors if the build fails
        if (ecode != cl.CL_SUCCESS) {
            var len: usize = 90_000;
            var lenOut: usize = undefined;
            var buffer = try al.alloc(u8, len);
            _ = cl.clGetProgramBuildInfo(program, device, cl.CL_PROGRAM_BUILD_LOG, len, &buffer[0], &lenOut);
            print("==CL_PROGRAM_BUILD_LOG== \n\n {s}\n\n", .{buffer[0..lenOut]});
        }
        try err(ecode);

        // print("devic

        // print("Found Device {s} \n", .{get_device_info_string(al,device,cl.CL_DEVICE_NAME)})
        // e\n {any}\n\n", .{device});
        // print("ctx\n {any}\n\n", .{ctx});

        var dcqp = DevCtxQueProg{
            .device = device,
            .ctx = ctx,
            .command_queue = command_queue,
            .program = program,
        };

        // print("dcqp =\n\n {any} \n\n", .{dcqp});
        return dcqp;
    }

    pub fn deinit(self: Self) void {
        _ = cl.clFlush(self.command_queue);
        _ = cl.clFinish(self.command_queue);
        _ = cl.clReleaseCommandQueue(self.command_queue);
        _ = cl.clReleaseProgram(self.program);
        _ = cl.clReleaseContext(self.ctx);
    }
};

const ArgTypes = enum {
    buffer_write_once,
    buffer_write_everytime,
    buffer_read_everytime,
    nonbuf_write_once,
    nonbuf_write_everytime,
    nonbuf_read_everytime,
};

pub fn testOclWrite(flags: cl.cl_mem_flags, q_write: bool) !void {
    print("\n", .{});
    const al = std.testing.allocator;
    const files = &[_][]const u8{
        "testkernels.cl",
    };
    var dcqp = try DevCtxQueProg.init(al, files);
    defer dcqp.deinit();

    const nelems = 10;
    var data = try al.alloc(f32, nelems);
    defer al.free(data);
    for (data, 0..) |*d, i| d.* = @intToFloat(f32, i + 5);
    print("data = {d} \n", .{data});

    var e: cl.cl_int = undefined;
    var kernel = cl.clCreateKernel(dcqp.program, "readfloatbuffer", &e);
    try err(e);

    const data_size_in_bytes = nelems * 4;

    var buff: cl.cl_mem = cl.clCreateBuffer(dcqp.ctx, flags, data_size_in_bytes, &data[0], &e);
    try err(e);

    if (q_write) {
        e = cl.clEnqueueWriteBuffer(dcqp.command_queue, buff, cl.CL_TRUE, 0, data_size_in_bytes, &data[0], 0, null, null);
        try err(e);
    }

    e = cl.clSetKernelArg(kernel, 0, @sizeOf(cl.cl_mem), @ptrCast(?*anyopaque, &buff));
    try err(e);

    const ndims = 1;
    const global_work_size = [1]usize{nelems};
    // Global vs Local ? TODO
    e = cl.clEnqueueNDRangeKernel(dcqp.command_queue, kernel, ndims, null, &global_work_size[0], null, 0, null, null);
}

test "test to-gpu float buffer usehostptr true" {
    try testOclWrite(cl.CL_MEM_USE_HOST_PTR, true);
}
test "test to-gpu float buffer copyhostptr true" {
    try testOclWrite(cl.CL_MEM_COPY_HOST_PTR, true);
}
test "test to-gpu float buffer usehostptr false" {
    try testOclWrite(cl.CL_MEM_USE_HOST_PTR, false);
}
test "test to-gpu float buffer copyhostptr false" {
    try testOclWrite(cl.CL_MEM_COPY_HOST_PTR, false);
}

test "test write float buffer" {
    print("\n", .{});

    const al = std.testing.allocator;
    const files = &[_][]const u8{
        "testkernels.cl",
    };
    var dcqp = try DevCtxQueProg.init(al, files);
    defer dcqp.deinit();

    const nelems = 10;
    var data = try al.alloc(f32, nelems);
    defer al.free(data);
    // for (data, 0..) |*d, i| d.* = @intToFloat(f32, i);

    var e: cl.cl_int = undefined;
    const kernel = cl.clCreateKernel(dcqp.program, "writefloatbuffer", &e);
    try err(e);

    const data_size_in_bytes = nelems * 4;
    var buff: cl.cl_mem = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_USE_HOST_PTR, data_size_in_bytes, &data[0], &e);
    try err(e);

    // try err(cl.clEnqueueWriteBuffer(dcqp.command_queue, buff, cl.CL_TRUE, 0, data_size_in_bytes, &data[0], 0, null, null));
    // print("kernel is : {any} \n", .{kernel.?.*});
    // print("buffer is : {any} \n", .{buff.?.*});

    try err(cl.clSetKernelArg(kernel, 0, @sizeOf(cl.cl_mem), @ptrCast(?*anyopaque, &buff)));

    const ndims = 1;
    const global_work_size = [1]usize{nelems};
    // Global vs Local ? TODO
    try err(cl.clEnqueueNDRangeKernel(dcqp.command_queue, kernel, ndims, null, &global_work_size[0], null, 0, null, null));
    try err(cl.clEnqueueReadBuffer(dcqp.command_queue, buff, cl.CL_TRUE, 0, data_size_in_bytes, &data[0], 0, null, null));
    print("val is {d}\n", .{data});
}

test "mandelbrot" {
    print("\n", .{});

    const al = std.testing.allocator;
    const files = &[_][]const u8{
        "mandelbrot.cl",
    };
    var dcqp = try DevCtxQueProg.init(al, files);
    // defer dcqp.deinit();

    const img_width: usize = 1200;
    const img_height: usize = 800;

    // Create kernel
    var e: cl.cl_int = undefined;
    const kernel = cl.clCreateKernel(dcqp.program, "mandelbrot", &e);
    try err(e);

    var format: cl.cl_image_format = undefined;
    format.image_channel_order = cl.CL_RGBA;
    format.image_channel_data_type = cl.CL_UNSIGNED_INT8;

    // cl_image_desc desc;
    var desc: cl.cl_image_desc = undefined;
    desc.image_type = cl.CL_MEM_OBJECT_IMAGE2D;
    desc.image_width = img_width;
    desc.image_height = img_height;
    desc.image_depth = 0;
    desc.image_array_size = 0;
    desc.image_row_pitch = 0;
    desc.image_slice_pitch = 0;
    desc.num_mip_levels = 0;
    desc.num_samples = 0;
    desc.buffer = null;

    var cl_img = cl.clCreateImage(dcqp.ctx, cl.CL_MEM_WRITE_ONLY, &format, &desc, null, &e);
    try err(e);

    // var clmeminfo: cl.cl_mem_info = undefined;
    // const info = cl.clGetMemObjectInfo(cl_img, clmeminfo)

    // print("Size of cl_img is {d} \n", .{@sizeOf(@TypeOf(cl_img))});
    const sizeof_climg = 8;
    try err(cl.clSetKernelArg(kernel, 0, sizeof_climg, @ptrCast(?*anyopaque, &cl_img)));

    // Queue kernel
    // size_t global[2] = {img_width, img_height};
    const global = [2]usize{ img_width, img_height };
    // size_t local[2] = {16, 16};
    const local = [2]usize{ 16, 16 };
    // cl(clEnqueueNDRangeKernel(q, kernel, 2, NULL, global, local, 0, NULL, NULL));
    try err(cl.clEnqueueNDRangeKernel(dcqp.command_queue, kernel, 2, null, &global, &local, 0, null, null));

    // Read output
    // uint8_t * img = new uint8_t[img_width * img_height * 4];
    // var img = @alignCast(8, try al.alloc(u8, img_width * img_height * 4));
    var img = try al.alloc(u8, img_width * img_height * 4);
    defer al.free(img);

    // size_t origin[3] = {0, 0, 0};
    const origin = [3]usize{ 0, 0, 0 };
    // size_t depth[3] = {img_width, img_height, 1};
    const depth = [3]usize{ img_width, img_height, 1 };
    // cl(clEnqueueReadImage(dcqp.command_queue, cl_img, CL_TRUE, origin, depth, 0, 0, img, 0, NULL, NULL));
    try err(cl.clEnqueueReadImage(dcqp.command_queue, cl_img, cl.CL_TRUE, &origin, &depth, 0, 0, &img[0], 0, null, null));

    // Wait for opencl to finish
    try err(cl.clFlush(dcqp.command_queue));
    try err(cl.clFinish(dcqp.command_queue));

    // Write image
    // FILE* fp = fopen("mandelbrot.png", "wb");
    // svpng(fp, img_width, img_height, img, 1);
    // fclose(fp);

    // Cleanup
    // delete[] img;
    try err(cl.clReleaseKernel(kernel));
    try err(cl.clReleaseProgram(dcqp.program));
    try err(cl.clReleaseMemObject(cl_img));
    try err(cl.clReleaseCommandQueue(dcqp.command_queue));
    try err(cl.clReleaseContext(dcqp.ctx));
}

pub fn Kernel(
    comptime _kern_name: []const u8,
    comptime _argtype: []const ArgTypes,
) type {
    return struct {
        const Self = @This();

        const kern_name: []const u8 = _kern_name;
        const argtype: []const ArgTypes = _argtype;

        kernel: cl.cl_kernel,
        buffers: [argtype.len]cl.cl_mem,

        /// Create a kernel, then comptime loop over each argument and do:
        /// - create a cl_mem buffer . add it to ArrayList container
        /// - IF arg is input, write it to buffer
        /// - Add the buffer as a kernel argument
        /// RUN the kernel
        /// do for each arg:
        /// - IF arg is output, read data from buffer
        /// - clean up buffer memory
        pub fn init(
            dcqp: DevCtxQueProg,
            args: anytype,
            // sizes: anytype,
        ) !Self {

            // reuse ecode variable for each OpenCL call
            var e: cl.cl_int = undefined;

            // Create a Kernel
            var kernel = cl.clCreateKernel(dcqp.program, @ptrCast([*c]const u8, kern_name), &e);
            print("ecode = {d}\n", .{e});
            try err(e);

            // TODO: Do we need to create buffers for all arguments or only for arrays?
            // Buffers are just pointers?! Easy to make a simple array.
            var buffers: [argtype.len]cl.cl_mem = undefined;

            // Loop over the arguments we want to pass to the kernel. Set read/write flags
            // as appropriate. Create buffers, add data to buffers, pass buffers as kernel args.
            inline for (argtype, 0..) |argT, i| {
                const arg = args[i];
                // const size = sizes[i];

                switch (argT) {
                    .buffer_write_once, .buffer_write_everytime => {
                        // const offset = 0;
                        const size_in_bytes = @sizeOf(std.meta.Elem(@TypeOf(arg))) * arg.len;
                        buffers[i] = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_WRITE_ONLY, size_in_bytes, null, &e);
                        try err(e);
                        e = cl.clEnqueueWriteBuffer(dcqp.command_queue, buffers[i], cl.CL_TRUE, 0, size_in_bytes, &arg[0], 0, null, null);
                        try err(e);
                        e = cl.clSetKernelArg(kernel, i, @sizeOf(cl.cl_mem), @ptrCast(?*anyopaque, &buffers[i]));
                        try err(e);
                    },
                    .buffer_read_everytime => {
                        const size_in_bytes = @sizeOf(std.meta.Elem(@TypeOf(arg))) * arg.len;
                        buffers[i] = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_READ_ONLY, size_in_bytes, null, &e);
                        try err(e);
                        e = cl.clSetKernelArg(kernel, i, @sizeOf(cl.cl_mem), @ptrCast(?*anyopaque, &buffers[i]));
                        try err(e);
                    },
                    else => {

                        // const size =
                        //     if (info == .Pointer and info.Pointer.size == .Many)
                        //     @sizeOf(std.meta.Elem(T)) * arg.len
                        // else
                        //     @sizeOf(T);
                        // _ = size;

                        const size = @sizeOf(@TypeOf(arg));
                        switch (@TypeOf(arg)) {
                            *cl.cl_mem => {
                                e = cl.clSetKernelArg(kernel, i, size, @ptrCast(?*const anyopaque, arg));
                            },
                            cl.cl_mem => {
                                e = cl.clSetKernelArg(kernel, i, size, @ptrCast(?*const anyopaque, &arg));
                            },
                            else => {
                                // const info = @typeInfo(@TypeOf(arg));
                                // if (info == .Pointer and info.Pointer.size == .Many) {
                                // @sizeOf(std.meta.Elem(T)) * arg.len;
                                e = cl.clSetKernelArg(kernel, i, size, &arg);
                                // } else {
                                // e = cl.clSetKernelArg(kernel, i, size, arg);
                                // }
                            },
                        }

                        try err(e);
                    },
                }
            }

            return Self{
                .kernel = kernel,
                .buffers = buffers,
            };
        }

        /// Execute kernel
        pub fn executeKernel(
            self: Self,
            dcqp: DevCtxQueProg,
            args: anytype,
            nproc: []const usize,
        ) !void {

            // var local_item_size: usize = 64;
            // TODO: Allow customization of work_dim (currently 1)
            // TODO: learn how to use local_item_size (currently null)

            var e: cl.cl_int = undefined;

            // Loop over the arguments we want to pass to the kernel. Set read/write flags
            // as appropriate. Create buffers, add data to buffers, pass buffers as kernel args.
            inline for (argtype, 0..) |argT, i| {
                const arg = args[i];
                const T = @TypeOf(arg);
                const info = @typeInfo(T);

                const size =
                    if (info == .Pointer and info.Pointer.size == .Many)
                    @sizeOf(std.meta.Elem(T)) * arg.len
                else
                    @sizeOf(T);
                _ = size;

                // const size = switch (@typeInfo(T)) {
                //     .Pointer => @sizeOf(std.meta.Elem(T)) * arg.len, // assume slice or array
                //     else => @sizeOf(T),
                // };

                switch (argT) {
                    .buffer_write_everytime => {
                        const offset = 0;
                        const size_in_bytes = @sizeOf(std.meta.Elem(@TypeOf(arg))) * arg.len;
                        e = cl.clEnqueueWriteBuffer(dcqp.command_queue, self.buffers[i], cl.CL_TRUE, offset, size_in_bytes, &arg[0], 0, null, null);
                        try err(e);
                        e = cl.clSetKernelArg(self.kernel, i, @sizeOf(cl.cl_mem), @ptrCast(?*anyopaque, &self.buffers[i]));
                        try err(e);
                    },
                    .nonbuf_write_everytime => {
                        // ecode = cl.clSetKernelArg(self.kernel, i, @sizeOf(cl.cl_mem), &self.buffers[i]);
                        // try testForCLError(ecode);
                        // e = cl.clSetKernelArg(self.kernel, i, size, arg);
                        switch (@TypeOf(arg)) {
                            *cl.cl_mem => {
                                e = cl.clSetKernelArg(self.kernel, i, @sizeOf(cl.cl_mem), @ptrCast(?*const anyopaque, arg));
                            },
                            cl.cl_mem => {
                                e = cl.clSetKernelArg(self.kernel, i, @sizeOf(cl.cl_mem), @ptrCast(?*const anyopaque, &arg));
                            },
                            else => {
                                e = cl.clSetKernelArg(self.kernel, i, @sizeOf(T), &arg);
                            },
                        }
                        try err(e);
                    },
                    else => {},
                }
            }

            e = cl.clEnqueueNDRangeKernel(dcqp.command_queue, self.kernel, @intCast(u32, nproc.len), null, &nproc[0], null, 0, null, null);
            // ecode = cl.clEnqueueNDRangeKernel(dcqp.command_queue, self.kernel, @intCast(u32, nproc.len), null, global,   local, 0, null, null);

            try err(e);

            inline for (argtype, 0..) |argT, i| {
                switch (argT) {
                    .buffer_read_everytime => {
                        const arg = args[i];
                        // const T = @TypeOf(arg);
                        // const size_in_bytes = switch (@typeInfo(T)) {
                        //     .Pointer => @sizeOf(std.meta.Elem(T)) * arg.len, // assume slice or array
                        //     else => @sizeOf(T),
                        // };
                        const size_in_bytes = @sizeOf(std.meta.Elem(@TypeOf(arg))) * arg.len;
                        const offset = 0;
                        e = cl.clEnqueueReadBuffer(dcqp.command_queue, self.buffers[i], cl.CL_TRUE, offset, size_in_bytes, &arg[0], 0, null, null);
                        try err(e);
                    },
                    else => {},
                }
            }
        }

        pub fn deinit(self: Self) void {
            for (self.buffers, 0..) |b, i| {
                // if (argtype[i] == 'x') continue;
                switch (argtype[i]) {
                    .buffer_read_everytime, .buffer_write_everytime, .buffer_write_once => {
                        _ = cl.clReleaseMemObject(b); // TODO: what happens to defer inside of inline for ?
                    },
                    else => {},
                }
            }
            _ = cl.clReleaseKernel(self.kernel);
        }
    };
}

test "test dcqp basic kernel" {
    const al = std.testing.allocator;
    const files = &[_][]const u8{
        "volumecaster.cl",
    };
    var dcqp = try DevCtxQueProg.init(al, files);
    defer dcqp.deinit();

    const kern = try Kernel("testkernel", &.{}).init(
        dcqp,
        &.{},
    );
    // const kern = try Kernel("mandelbrot", &argtypes).init(dcqp, args);
    defer kern.deinit();

    try kern.executeKernel(dcqp, &.{}, &.{ 50, 50 });

    // print("\n", .{});
    // print("DevCtxQueProg:\n{any}\n", .{dcqp});
    // print("Result:\n{any}\n", .{result});
    print("\n", .{});
}

test "test DevCtxQueProg" {
    const al = std.testing.allocator;
    const files = &[_][]const u8{
        "volumecaster.cl",
    };
    var dcqp = try DevCtxQueProg.init(al, files);
    defer dcqp.deinit();

    const img2d = try Img2D(f32).init(100, 101);
    defer img2d.deinit();

    for (img2d.img) |*v| v.* = 0.753;

    const img2dptr = try img2CLImg(img2d, dcqp);
    var args = .{ &20, &20, img2dptr };
    // const sizes = [3]usize{ 4, 4, 100 * 101 };
    const argtypes = [3]ArgTypes{ .nonbuf_write_once, .nonbuf_write_once, .nonbuf_write_once };

    const kern = try Kernel("imgtest", &argtypes).init(dcqp, args);
    // const kern = try Kernel("mandelbrot", &argtypes).init(dcqp, args);
    defer kern.deinit();

    const result = kern.executeKernel(dcqp, args, &.{ 50, 50 });

    print("\n", .{});
    print("DevCtxQueProg:\n{any}\n", .{dcqp});
    print("Result:\n{any}\n", .{result});
    print("\n", .{});
}

test "test zzz" {
    const al = std.testing.allocator;
    const files = &[_][]const u8{
        // "volumecaster.cl",
        "mandelbrot.cl",
    };
    var dcqp = try DevCtxQueProg.init(al, files);
    defer dcqp.deinit();

    const img2d = try Img2D([4]u8).init(100, 100);
    defer img2d.deinit();

    for (img2d.img) |*v| v.* = .{ 0, 0, 0, 255 };

    const img2dptr = try img2CLImgU4(img2d, dcqp);
    // var args = .{ &20, &20, img2dptr };
    var args = .{img2dptr};
    const sizes = [1]usize{100 * 100};
    _ = sizes;
    const argtypes = [1]ArgTypes{.nonbuf_write_everytime};

    const kern = try Kernel("mandelbrot", &argtypes).init(dcqp, args);
    defer kern.deinit();

    const result = kern.executeKernel(dcqp, .{ &20, &20, img2dptr }, &.{ 50, 50 });

    print("\n", .{});
    print("DevCtxQueProg:\n{any}\n", .{dcqp});
    print("Result:\n{any}\n", .{result});
    print("\n", .{});
}

pub fn img2CLImgU4(img: Img2D([4]u8), dcqp: DevCtxQueProg) !cl.cl_mem {
    const img_format = cl.cl_image_format{
        .image_channel_order = cl.CL_RGBA,
        .image_channel_data_type = cl.CL_UNSIGNED_INT8,
    };
    var img_description = std.mem.zeroes(cl.cl_image_desc);
    img_description.image_width = @intCast(usize, img.nx);
    img_description.image_height = @intCast(usize, img.ny);
    img_description.image_type = cl.CL_MEM_OBJECT_IMAGE2D;

    var ecode: i32 = 0;
    var climg = cl.clCreateImage(
        dcqp.ctx,
        cl.CL_MEM_WRITE_ONLY,
        // cl.CL_MEM_USE_HOST_PTR, // | cl.CL_MEM_READ_ONLY,
        &img_format,
        &img_description,
        &img.img[0],
        &ecode,
    );
    try err(ecode);

    return climg;
}

/// Convert an Img[23]D(f32) into an OpenCL image[23]d_t object
pub fn img2CLImg(
    img: anytype,
    dcqp: DevCtxQueProg,
) !cl.cl_mem {
    const ndim = switch (@TypeOf(img)) {
        Img2D(f32) => 2,
        Img3D(f32) => 3,
        else => {
            @compileError("`img` must have type Img2D(f32) or Img3D(f32).\n");
        },
    };

    // const data_type = cl.CL_FLOAT;

    // TODO: do img_format and description need to live beyond function scope?
    const img_format = cl.cl_image_format{
        .image_channel_order = cl.CL_INTENSITY, // :cl.cl_channel_order
        .image_channel_data_type = cl.CL_FLOAT, // 32-bit
    };

    var img_description = std.mem.zeroes(cl.cl_image_desc);
    img_description.image_width = @intCast(usize, img.nx);
    img_description.image_height = @intCast(usize, img.ny);
    if (ndim == 2) {
        img_description.image_type = cl.CL_MEM_OBJECT_IMAGE2D;
    } else {
        img_description.image_type = cl.CL_MEM_OBJECT_IMAGE3D;
        img_description.image_depth = @intCast(usize, img.nz);
    }

    // print("img_description = {any} \n", .{img_description});

    var ecode: i32 = 0;
    var climg = cl.clCreateImage(
        dcqp.ctx,
        cl.CL_MEM_USE_HOST_PTR | cl.CL_MEM_READ_ONLY,
        // cl.CL_MEM_READ_ONLY,
        &img_format,
        &img_description,
        &img.img[0],
        &ecode,
    );
    try err(ecode);

    return climg;
}

/// Follows matplotlib colormap convention for piecewise linear colormaps
fn piecewiseLinearInterpolation(comptime n: u16, pieces: []const [3]f32) [n]f32 {
    var res = [_]f32{0} ** n;
    var k: usize = 0;
    for (&res, 0..) |*r, i| {
        const x = @intToFloat(f32, i) / 255; // in [0,1] inclusive
        if (x > pieces[k + 1][0]) k += 1;
        const x0 = pieces[k][0];
        // print("\n{d}\n",.{pieces[k+1]});
        const x1 = pieces[k + 1][0];
        const y0 = pieces[k][2];
        const y1 = pieces[k + 1][1];
        const y = lerp(x0, x, x1, y0, y1);
        // if (k == 1) @breakpoint();
        // print("")
        r.* = y;
    }
    return res;
}

fn lerp(lo: f32, mid: f32, hi: f32, valLo: f32, valHi: f32) f32 {
    return valLo * (hi - mid) / (hi - lo) + valHi * (mid - lo) / (hi - lo);
}

test "test piecewiseLinearInterp" {
    var pieces = [_][3]f32{
        .{ 0, 0, 1.0 },
        .{ 0.25, 0, 1 },
        .{ 0.75, 0.0, 1 },
        .{ 1.0, 0.0, 1 },
    };
    const res = piecewiseLinearInterpolation(256, pieces[0..]);
    print("\nres = {d}\n", .{res});
}

/// generate "cool" colormap
pub fn cmapCool() [256][4]u8 {
    var cmap: [256][4]u8 = undefined;
    const reds = piecewiseLinearInterpolation(256, &[_][3]f32{ .{ 0, 0, 0 }, .{ 1, 1, 1 } });
    const greens = piecewiseLinearInterpolation(256, &[_][3]f32{ .{ 0, 1, 1 }, .{ 1, 0, 0 } });
    const blues = piecewiseLinearInterpolation(256, &[_][3]f32{ .{ 0, 1, 1 }, .{ 1, 1, 1 } });
    for (&cmap, 0..) |*r, i| {
        r.* = .{
            @floatToInt(u8, reds[i] * 255),
            @floatToInt(u8, greens[i] * 255),
            @floatToInt(u8, blues[i] * 255),
            255,
        };
    }
    return cmap;
}

// test "build a kernel and call it" {
//     kernargs = .{
//         .file = "volumecaster.cl",
//         .kern = "max_project_float",
//         .args = .{
//             .img = .{ imgval, .buffer, .write_every, 0 }, // value, buffer?, write_every time?, arg_position
//             .nx = .{ nxlocal, .nobuffer, .write_once, 1 },
//         },
//     };

//     const kern = build_kernel_maxproj(.{
//         .volume = img3df32,
//         .Nx = 1024,
//         .Ny = 888,
//         .d_output = img2d4u8,
//         .view = view,
//     });
//     kern.execute();
// }

const mp_argtypes = &[_]ArgTypes{
    .nonbuf_write_everytime,
    .buffer_read_everytime,
    .buffer_read_everytime,
    .buffer_write_once,
    .nonbuf_write_once,
    .nonbuf_write_once,
    .nonbuf_write_once,
    .nonbuf_write_everytime,
    .nonbuf_write_once,
};

const ArgTypeMP = struct {
    cl.cl_mem, // img_cl.?,
    [][4]u8, // d_output.img,
    []f32, // d_zbuffer.img,
    [256][4]u8, // colormap,
    u32, // &nx,
    u32, // &ny,
    [2]f32, // &mima,
    View, // &view,
    [3]u16, // &volume_dims,
};

pub const KernelMP = Kernel("max_project_float", mp_argtypes);

pub const KernelStateMaxProject = struct {
    dcqp: DevCtxQueProg,
    kern: KernelMP,
    args: ArgTypeMP, // must be values or long lived pointers
};

/// Caller must run dcqp.deinit() and kern.deinit()
pub fn buildKernelMaxProj(
    al: std.mem.Allocator,
    grey: im.Img3D(f32),
    d_output: im.Img2D([4]u8),
    d_zbuffer: im.Img2D(f32),
    view: View,
) !KernelStateMaxProject {

    // setup OpenCL Contex Queue

    const files = &[_][]const u8{"volumecaster.cl"};
    var dcqp = try DevCtxQueProg.init(al, files);

    var img_cl = try img2CLImg(grey, dcqp);
    const volume_dims = [3]u16{ @intCast(u16, grey.nx), @intCast(u16, grey.ny), @intCast(u16, grey.nz) };
    const volume_total: u64 = grey.nx * grey.ny * grey.nz;
    _ = volume_total;
    const colormap = cmapCool();
    const nx = d_output.nx;
    const ny = d_output.ny;
    const mima = im.minmax(f32, grey.img);
    print("mima = {d}\n", .{mima});

    var args = .{
        img_cl,
        d_output.img,
        d_zbuffer.img,
        colormap,
        nx,
        ny,
        mima,
        view,
        volume_dims,
    };

    var kernel = try KernelMP.init(dcqp, args);
    return .{ .dcqp = dcqp, .kern = kernel, .args = args };
}

pub fn reexecuteKernel(
    al: std.mem.Allocator,
    _dcqp: ?DevCtxQueProg,
    grey: im.Img3D(f32),
    d_output: im.Img2D([4]u8),
    d_zbuffer: im.Img2D(f32),
    view: View,
) !void {
    // _ = al;
    // const files = &[_][]const u8{"volumecaster.cl"};
    // var dcqp = try DevCtxQueProg.init(al, files);

    var dcqp: DevCtxQueProg = undefined;
    if (_dcqp) |val| {
        dcqp = val;
    } else {
        const files = &[_][]const u8{"volumecaster.cl"};
        // const files = &{"volumecaster.cl"};
        dcqp = try DevCtxQueProg.init(al, files);
    }

    defer if (_dcqp == null) dcqp.deinit();

    var img_cl = try img2CLImg(grey, dcqp);
    const volume_dims = [3]u16{ @intCast(u16, grey.nx), @intCast(u16, grey.ny), @intCast(u16, grey.nz) };
    // const volume_total: u64 = grey.nx * grey.ny * grey.nz;
    // _ = volume_total;
    const colormap = cmapCool();
    const nx: cl.cl_uint = d_output.nx;
    const ny: cl.cl_uint = d_output.ny;
    const mima = im.minmax(f32, grey.img);

    // const viewopencl = ViewOpenCLTest{
    //     .view_matrix = view.view_matrix,
    //     // .front_scale = view.front_scale,
    //     // .back_scale = view.back_scale,
    //     // .anisotropy = view.anisotropy,
    //     // .screen_size = view.screen_size,
    //     .theta = view.theta,
    //     .phi = view.phi,
    // };

    var e: cl.cl_int = undefined;
    const offset = 0;
    var i_argnum: u32 = 0;

    var kernel = cl.clCreateKernel(dcqp.program, @ptrCast([*c]const u8, "max_project_float"), &e);
    try err(e);

    var size_in_bytes: usize = undefined;

    // volume
    // var buffers_0 = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_WRITE_ONLY, size_in_bytes, null, &e);
    // try err(e);
    // e = cl.clEnqueueWriteBuffer(dcqp.command_queue, buffers_0, cl.CL_TRUE, offset, size_in_bytes, arg[0], 0, null, null);
    // try err(e);
    // e = cl.clSetKernelArg(kernel, 0, @sizeOf(cl.cl_mem), @ptrCast(?*anyopaque, &buffers_0));
    size_in_bytes = @intCast(usize, volume_dims[0]) * @intCast(usize, volume_dims[1]) * @intCast(usize, volume_dims[2]) * 4; // f32 has 4 bytes * size of image.
    e = cl.clSetKernelArg(kernel, i_argnum, @sizeOf(cl.cl_mem), @ptrCast(?*anyopaque, &img_cl));
    i_argnum += 1;
    try err(e);

    // d_output.img
    size_in_bytes = @sizeOf(std.meta.Elem(@TypeOf(d_output.img))) * d_output.img.len;
    var buffers_1 = cl.clCreateBuffer(dcqp.ctx, 0, size_in_bytes, null, &e);
    try err(e);
    e = cl.clSetKernelArg(kernel, i_argnum, @sizeOf(cl.cl_mem), @ptrCast(?*anyopaque, &buffers_1));
    i_argnum += 1;
    try err(e);

    // d_output.img
    size_in_bytes = @sizeOf(std.meta.Elem(@TypeOf(d_zbuffer.img))) * d_zbuffer.img.len;
    var buffers_2 = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_WRITE_ONLY, size_in_bytes, null, &e);
    try err(e);
    e = cl.clSetKernelArg(kernel, i_argnum, @sizeOf(cl.cl_mem), @ptrCast(?*anyopaque, &buffers_2));
    i_argnum += 1;
    try err(e);

    // colormap
    size_in_bytes = @sizeOf(std.meta.Elem(@TypeOf(colormap))) * colormap.len;
    var buffers_3 = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_WRITE_ONLY, size_in_bytes, null, &e);
    try err(e);
    e = cl.clEnqueueWriteBuffer(dcqp.command_queue, buffers_3, cl.CL_TRUE, offset, size_in_bytes, &colormap[0], 0, null, null);
    try err(e);
    e = cl.clSetKernelArg(kernel, i_argnum, @sizeOf(cl.cl_mem), @ptrCast(?*anyopaque, &buffers_3));
    i_argnum += 1;
    try err(e);

    // uint Nx,
    e = cl.clSetKernelArg(kernel, i_argnum, @sizeOf(@TypeOf(nx)), @ptrCast(?*const anyopaque, &nx));
    i_argnum += 1;
    try err(e);

    // uint Ny,
    e = cl.clSetKernelArg(kernel, i_argnum, @sizeOf(@TypeOf(ny)), &ny);
    i_argnum += 1;
    try err(e);

    // float2 global_minmax,
    e = cl.clSetKernelArg(kernel, i_argnum, @sizeOf(@TypeOf(mima)), &mima);
    i_argnum += 1;
    try err(e);

    // View ,
    e = cl.clSetKernelArg(kernel, i_argnum, @sizeOf(@TypeOf(view)), &view);
    i_argnum += 1;
    try err(e);

    // ushort3 volume_dims
    e = cl.clSetKernelArg(kernel, i_argnum, @sizeOf(@TypeOf(volume_dims)), &volume_dims);
    i_argnum += 1;
    try err(e);

    const global_workers = [2]usize{ nx, ny };
    const ndims = 2;
    e = cl.clEnqueueNDRangeKernel(dcqp.command_queue, kernel, ndims, null, &global_workers[0], null, 0, null, null);

    size_in_bytes = @sizeOf(std.meta.Elem(@TypeOf(d_output.img))) * d_output.img.len;
    e = cl.clEnqueueReadBuffer(dcqp.command_queue, buffers_1, cl.CL_TRUE, offset, size_in_bytes, &d_output.img[0], 0, null, null);
    try err(e);

    // print("buffer color is {d} \n", .{d_output.img[0]});

    size_in_bytes = @sizeOf(std.meta.Elem(@TypeOf(d_zbuffer.img))) * d_zbuffer.img.len;
    e = cl.clEnqueueReadBuffer(dcqp.command_queue, buffers_2, cl.CL_TRUE, offset, size_in_bytes, &d_zbuffer.img[0], 0, null, null);
    try err(e);
}
