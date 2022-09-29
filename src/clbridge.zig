const std = @import("std");
const im = @import("image_base.zig");
const print = std.debug.print;
const assert = std.debug.assert;
const Img2D = im.Img2D;
const Img3D = im.Img3D;

const cc = struct {
    pub const cl = @cImport({
        @cDefine("CL_TARGET_OPENCL_VERSION", "220");
        @cInclude("CL/cl.h");
    });

    pub const tiffio = @cImport({
        @cInclude("tiffio.h");
    });

    pub usingnamespace @cImport({
        @cInclude("SDL.h");
    });
};

const cl = cc.cl;

pub fn testForCLError(val: cl.cl_int) CLERROR!void {
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
        return;
    } else |err| {
        @breakpoint();
        return err;
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

// Actually failing to catch an error causes the test to FAIL and emit an error trace.
// I don't know why this trace doesn't look like a compile error. In fact it shares
// the same problem as a PANIC in that on macos the trace doesn't point to the correct
// locations in the source files.
test "Handle a custom CLERROR" {
    print("\n", .{});
    try testForCLError(0); // code zero => CL_SUCCESS
    print("{any}\n", .{@typeInfo(cl.cl_int)});
    testForCLError(-4) catch |err| switch (err) {
        CLERROR.CL_MEM_OBJECT_ALLOCATION_FAILURE => {
            print("\nERROR: We ran out of mem, but handle it gracefully\n", .{});
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

    for (platform_ids[0..platform_count]) |id| {
        var name: [1024]u8 = undefined;
        var name_len: usize = undefined;
        if (cl.clGetPlatformInfo(id, cl.CL_PLATFORM_NAME, name.len, &name, &name_len) != cl.CL_SUCCESS) {
            return MyCLError.GetPlatformInfoFailed;
        }
        // print("  platform {}: {s}\n", .{ i, name[0..name_len] });
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

    for (device_ids[0..device_count]) |id| {
        var name: [1024]u8 = undefined;
        var name_len: usize = undefined;
        if (cl.clGetDeviceInfo(id, cl.CL_DEVICE_NAME, name.len, &name, &name_len) != cl.CL_SUCCESS) {
            return MyCLError.GetDeviceInfoFailed;
        }
        // print("  device {}: {s}\n", .{ i, name[0..name_len] });
    }

    if (device_count == 0) {
        return MyCLError.NoDevicesFound;
    }

    // print("choosing device 0...\n", .{});

    return device_ids[0];
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
        var errCode: cl.cl_int = undefined;

        // Get a device. Build a context and command queue.
        var device = try getClDevice();
        var ctx = cl.clCreateContext(null, 1, &device, null, null, &errCode);
        try testForCLError(errCode);
        var command_queue = cl.clCreateCommandQueue(ctx, device, 0, &errCode);
        try testForCLError(errCode);

        // Load Source from .cl files and coerce into null terminated c-style pointers.
        const cwd = try std.fs.cwd().openDir("src", .{});
        var prog_source = try al.alloc([:0]u8, files.len);
        inline for (files) |name, i| {
            const file = try cwd.readFileAllocOptions(al, name, 20_000, null, @alignOf(u8), 0);
            prog_source[i] = file;
        }
        var program = cl.clCreateProgramWithSource(ctx, @intCast(cl.cl_uint, files.len), @ptrCast([*c][*c]const u8, prog_source), null, &errCode);
        try testForCLError(errCode);

        errCode = cl.clBuildProgram(program, 1, &device, null, null, null); // (prog, n_devices, *device, ...)

        // Spit out CL compiler errors if the build fails
        if (errCode != cl.CL_SUCCESS) {
            var len: usize = 10_000;
            var lenOut: usize = undefined;
            var buffer = try al.alloc(u8, len);
            _ = cl.clGetProgramBuildInfo(program, device, cl.CL_PROGRAM_BUILD_LOG, len, &buffer[0], &lenOut);
            print("==CL_PROGRAM_BUILD_LOG== \n\n {s}\n\n", .{buffer[0..lenOut]});
        }
        try testForCLError(errCode);

        var dcqp = DevCtxQueProg{
            .device = device,
            .ctx = ctx,
            .command_queue = command_queue,
            .program = program,
        };
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

pub fn Kernel(comptime n: u8) type {
    return struct {
        const nargs = n;
        const Self = @This();

        kernel: cl.cl_kernel,
        buffers: [n]cl.cl_mem,

        // nproc_fixed: [3]?usize = .{ null, null, null },
        // proc_count: u2,

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
            comptime kernName: []const u8,
            args: anytype,
            comptime argtype: []const u8,
        ) !Self {

            // reuse errCode variable for each OpenCL call
            var errCode: cl.cl_int = undefined;

            // Create a Kernel
            var kernel = cl.clCreateKernel(dcqp.program, &kernName[0], &errCode);
            try testForCLError(errCode);

            // TODO: Do we need to create buffers for all arguments or only for arrays?
            // Buffers are cheap! Easy to make a simple array.
            var buffers: [argtype.len]cl.cl_mem = undefined;

            // Loop over the arguments we want to pass to the kernel. Set read/write flags
            // as appropriate. Create buffers, add data to buffers, pass buffers as kernel args.
            inline for (argtype) |argT, i| {
                const arg = args[i];
                // const size = @sizeOf(std.meta.Elem(@TypeOf(arg))) * arg.len; // @sizeOf(@typeInfo(@TypeOf(arg)).Pointer.child);
                const T = @TypeOf(arg);
                const size = switch (@typeInfo(T)) {
                    .Pointer => @sizeOf(std.meta.Elem(T)) * arg.len, // assume slice or array
                    else => @sizeOf(T),
                };

                if (argT == 'w') {
                    // const child = @typeInfo(@TypeOf(arg)).Pointer.child;
                    // @compileLog(child, @sizeOf(child), arg.len * @sizeOf(child), @sizeOf(@TypeOf(arg)));
                    // const size = arg.len * @sizeOf(@typeInfo(@TypeOf(arg)).child);
                    buffers[i] = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_WRITE_ONLY, size, null, &errCode);
                    try testForCLError(errCode);
                    errCode = cl.clEnqueueWriteBuffer(dcqp.command_queue, buffers[i], cl.CL_TRUE, 0, size, &arg[0], 0, null, null);
                    try testForCLError(errCode);
                    errCode = cl.clSetKernelArg(kernel, i, @sizeOf(cl.cl_mem), &buffers[i]);
                    try testForCLError(errCode);
                } else if (argT == 'r') {
                    buffers[i] = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_READ_ONLY, size, null, &errCode);
                    try testForCLError(errCode);
                    errCode = cl.clSetKernelArg(kernel, i, @sizeOf(cl.cl_mem), &buffers[i]);
                    try testForCLError(errCode);
                } else if (argT == 'i') {
                    buffers[i] = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_READ_ONLY, size, null, &errCode);
                    try testForCLError(errCode);
                    errCode = cl.clSetKernelArg(kernel, i, @sizeOf(cl.cl_mem), &buffers[i]);
                    try testForCLError(errCode);
                } else {
                    errCode = cl.clSetKernelArg(kernel, i, size, &arg);
                    try testForCLError(errCode);
                }
            }

            var res = .{
                .kernel = kernel,
                .buffers = buffers,
                // .proc_count = nproc.len,
            };

            return res;

            // for (nproc) |n, i| res.nproc_fixed[i] = n;
        }

        /// DEPRECATED
        pub fn reEnqueue(
            self: Self,
            dcqp: DevCtxQueProg,
            args: anytype,
            comptime argtype: []const u8,
        ) !void {
            var errCode: cl.cl_int = undefined;

            // Loop over the arguments we want to pass to the kernel. Set read/write flags
            // as appropriate. Create buffers, add data to buffers, pass buffers as kernel args.
            inline for (argtype) |argT, i| {
                const arg = args[i];
                // const size = @sizeOf(std.meta.Elem(@TypeOf(arg))) * arg.len; // @sizeOf(@typeInfo(@TypeOf(arg)).Pointer.child);
                const T = @TypeOf(arg);
                const size = switch (@typeInfo(T)) {
                    .Pointer => @sizeOf(std.meta.Elem(T)) * arg.len, // assume slice or array
                    else => @sizeOf(T),
                };

                if (argT == 'w') {
                    errCode = cl.clEnqueueWriteBuffer(dcqp.command_queue, self.buffers[i], cl.CL_TRUE, 0, size, &arg[0], 0, null, null);
                    try testForCLError(errCode);
                    // errCode = cl.clSetKernelArg(kernel, i, @sizeOf(cl.cl_mem), &self.buffers[i]);
                    // try testForCLError(errCode);
                } else if (argT == 'r') {
                    // self.buffers[i] = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_READ_ONLY, size, null, &errCode);
                    // try testForCLError(errCode);
                    // errCode = cl.clSetKernelArg(kernel, i, @sizeOf(cl.cl_mem), &self.buffers[i]);
                    // try testForCLError(errCode);
                } else if (argT == 'i') {
                    // self.buffers[i] = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_READ_ONLY, size, null, &errCode);
                    // try testForCLError(errCode);
                    // errCode = cl.clSetKernelArg(kernel, i, @sizeOf(cl.cl_mem), &self.buffers[i]);
                    // try testForCLError(errCode);
                } else {
                    // errCode = cl.clSetKernelArg(kernel, i, size, &arg);
                    // try testForCLError(errCode);
                }
            }
        }

        /// Execute kernel
        pub fn executeKernel(
            self: Self,
            dcqp: DevCtxQueProg,
            args: anytype,
            comptime argtype: []const u8,
            nproc: []const usize,
        ) !void {
            // var local_item_size: usize = 64;
            // TODO: Allow customization of work_dim (currently 1)
            // TODO: learn how to use local_item_size (currently null)

            var errCode: cl.cl_int = undefined;

            // Loop over the arguments we want to pass to the kernel. Set read/write flags
            // as appropriate. Create buffers, add data to buffers, pass buffers as kernel args.
            inline for (argtype) |argT, i| {
                const arg = args[i];
                // const size = @sizeOf(std.meta.Elem(@TypeOf(arg))) * arg.len; // @sizeOf(@typeInfo(@TypeOf(arg)).Pointer.child);
                const T = @TypeOf(arg);
                const size = switch (@typeInfo(T)) {
                    .Pointer => @sizeOf(std.meta.Elem(T)) * arg.len, // assume slice or array
                    else => @sizeOf(T),
                };

                if (argT == 'w') {
                    errCode = cl.clEnqueueWriteBuffer(dcqp.command_queue, self.buffers[i], cl.CL_TRUE, 0, size, &arg[0], 0, null, null);
                    try testForCLError(errCode);
                    errCode = cl.clSetKernelArg(self.kernel, i, @sizeOf(cl.cl_mem), &self.buffers[i]);
                    try testForCLError(errCode);
                } else if (argT == 'r') {
                    // self.buffers[i] = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_READ_ONLY, size, null, &errCode);
                    // try testForCLError(errCode);
                    errCode = cl.clSetKernelArg(self.kernel, i, @sizeOf(cl.cl_mem), &self.buffers[i]);
                    try testForCLError(errCode);
                } else if (argT == 'i') {
                    // self.buffers[i] = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_READ_ONLY, size, null, &errCode);
                    // try testForCLError(errCode);
                    errCode = cl.clSetKernelArg(self.kernel, i, @sizeOf(cl.cl_mem), &self.buffers[i]);
                    try testForCLError(errCode);
                } else {
                    errCode = cl.clSetKernelArg(self.kernel, i, size, &arg);
                    try testForCLError(errCode);
                }
            }

            errCode = cl.clEnqueueNDRangeKernel(dcqp.command_queue, self.kernel, @intCast(u32, nproc.len), null, &nproc[0], null, 0, null, null);
            try testForCLError(errCode);
            // print("Ran the Kernel\n", .{});
            // print("Reading results...\n", .{});

            inline for (argtype) |argT, i| {
                if (argT == 'r') {
                    const arg = args[i];
                    const T = @TypeOf(arg);
                    const size = switch (@typeInfo(T)) {
                        .Pointer => @sizeOf(std.meta.Elem(T)) * arg.len, // assume slice or array
                        else => @sizeOf(T),
                    };

                    errCode = cl.clEnqueueReadBuffer(dcqp.command_queue, self.buffers[i], cl.CL_TRUE, 0, size, &arg[0], 0, null, null);
                    try testForCLError(errCode);
                }
            }
        }

        pub fn deinit(self: Self) void {
            for (self.buffers) |b| {
                _ = cl.clReleaseMemObject(b); // TODO: what happens to defer inside of inline for ?
            }
            _ = cl.clReleaseKernel(self.kernel);
        }
    };
}

test "init.DevCtxQueProg" {
    const al = std.testing.allocator;
    const files = &[_][]const u8{
        "volumecaster2.cl",
    };
    var dcqp = try DevCtxQueProg.init(al, files);
    defer dcqp.deinit();
    print("\n", .{});
    print("DevCtxQueProg:\n{any}\n", .{dcqp});
    print("\n", .{});
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

    // const data_type = switch (T) {
    //     f32 => cl.CL_FLOAT,
    //     else => unreachable,
    // };
    const data_type = cl.CL_FLOAT;

    // TODO: do img_format and description need to live beyond function scope?
    const img_format = cl.cl_image_format{
        .image_channel_order = cl.CL_INTENSITY, // :cl.cl_channel_order
        .image_channel_data_type = data_type, // 32-bit
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

    var errcode: i32 = 0;
    var climg = cl.clCreateImage(
        dcqp.ctx,
        cl.CL_MEM_USE_HOST_PTR | cl.CL_MEM_READ_ONLY,
        &img_format,
        &img_description,
        &img.img[0],
        &errcode,
    );

    try testForCLError(errcode);

    return climg;
}

/// Deprecated
pub fn renderImg(al: std.mem.Allocator, testtifname: []const u8) !Img2D(f32) {

    // temporary stack allocator
    // var page = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(al);
    defer arena.deinit();
    const temp = arena.allocator();

    // var alo = std.testing.allocator;
    const t1 = std.time.milliTimestamp();

    // define allocator and .CL files
    const files = &[_][]const u8{
        "volumecaster2.cl",
    };
    const t2 = std.time.milliTimestamp();

    // setup OpenCL Contex Queue
    var dcqp = try DevCtxQueProg.init(temp, files);
    defer dcqp.deinit();
    const t3 = std.time.milliTimestamp();

    // Load TIFF image
    // const testtifname = "/Users/broaddus/Desktop/mpi-remote/project-broaddus/rawdata/celegans_isbi/Fluo-N3DH-CE/01/t100.tif";
    const img = try readTIFF3D(temp, testtifname);
    const t4 = std.time.milliTimestamp();

    // Move TIFF image into standard buffer
    const grey = try Img3D(f32).init(img.nx, img.ny, img.nz);
    for (grey.img) |*v, i| {
        v.* = @intToFloat(f32, img.img[i][0]) / 255;
    }
    const t5 = std.time.milliTimestamp();

    // Run max projection kernel
    var img_cl = try img2CLImg(grey, dcqp);
    var nx: u32 = grey.nx * 1;
    var ny: u32 = grey.ny * 1;
    var d_output = try al.alloc(f32, nx * ny);
    var d_alpha_output = try temp.alloc(f32, nx * ny);
    var d_depth_output = try temp.alloc(f32, nx * ny);
    var view_angle: f32 = 0;
    const args = .{
        img_cl,
        d_output,
        d_alpha_output,
        d_depth_output,
        nx,
        ny,
        view_angle,
    };
    try dcqp.callKernel(
        "max_project_float",
        args,
        "xrrrxxx",
        &.{ nx, ny },
    );
    const t6 = std.time.milliTimestamp();

    // Save max projection result
    try im.saveF32AsTGAGreyNormed(d_output, @intCast(u16, ny), @intCast(u16, nx), "output/t100_rendered.tga");
    const t7 = std.time.milliTimestamp();

    print(
        \\Timings : 
        \\ t2-t1 = {} 
        \\ t3-t2 = {} 
        \\ t4-t3 = {} 
        \\ t5-t4 = {} 
        \\ t6-t5 = {} 
        \\ t7-t6 = {} 
        \\
    , .{
        t2 - t1,
        t3 - t2,
        t4 - t3,
        t5 - t4,
        t6 - t5,
        t7 - t6,
    });

    return Img2D(f32){
        .img = d_output,
        .nx = nx,
        .ny = ny,
    };
}

const SDL_WINDOWPOS_UNDEFINED = @bitCast(c_int, cc.SDL_WINDOWPOS_UNDEFINED_MASK);

// For some reason, this isn't parsed automatically. According to SDL docs, the
// surface pointer returned is optional!
extern fn SDL_GetWindowSurface(window: *cc.SDL_Window) ?*cc.SDL_Surface;

fn setPixel(surf: *cc.SDL_Surface, x: c_int, y: c_int, pixel: u32) void {
    const target_pixel = @ptrToInt(surf.pixels) +
        @intCast(usize, y) * @intCast(usize, surf.pitch) +
        @intCast(usize, x) * 4;
    // @breakpoint();
    const val = @bitCast(u32, [4]u8{
        @intCast(u8, pixel % 255),
        @intCast(u8, pixel % 255),
        @intCast(u8, pixel % 255),
        255,
    });
    @intToPtr(*u32, target_pixel).* = val;
}

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // temporary stack allocator
    // var page = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const temp = arena.allocator();

    const testtifname = "/Users/broaddus/Desktop/mpi-remote/project-broaddus/rawdata/celegans_isbi/Fluo-N3DH-CE/01/t100.tif";

    // var alo = std.testing.allocator;
    const t1 = std.time.milliTimestamp();

    // define allocator and .CL files
    const files = &[_][]const u8{
        "volumecaster2.cl",
    };
    const t2 = std.time.milliTimestamp();

    // setup OpenCL Contex Queue
    var dcqp = try DevCtxQueProg.init(temp, files);
    const t3 = std.time.milliTimestamp();

    // Load TIFF image
    // const testtifname = "/Users/broaddus/Desktop/mpi-remote/project-broaddus/rawdata/celegans_isbi/Fluo-N3DH-CE/01/t100.tif";
    const img = try readTIFF3D(temp, testtifname);
    const t4 = std.time.milliTimestamp();

    // Move TIFF image into standard buffer
    const grey = try Img3D(f32).init(img.nx, img.ny, img.nz);
    for (grey.img) |*v, i| {
        v.* = @intToFloat(f32, img.img[i][0]) / 255;
    }
    const t5 = std.time.milliTimestamp();

    var view_angle: f32 = 0;

    // Run max projection kernel
    var img_cl = try img2CLImg(grey, dcqp);
    var nx: u32 = grey.nx * 1;
    var ny: u32 = grey.ny * 1;
    var d_output = try temp.alloc(f32, nx * ny);
    var d_alpha_output = try temp.alloc(f32, nx * ny);
    var d_depth_output = try temp.alloc(f32, nx * ny);
    var args = .{
        img_cl,
        d_output,
        d_alpha_output,
        d_depth_output,
        nx,
        ny,
        view_angle,
    };
    const argtype = "xrrrxxx";

    var kernel = try Kernel(argtype.len).init(
        dcqp,
        "max_project_float",
        args,
        argtype,
    );

    try kernel.executeKernel(
        dcqp,
        args,
        argtype,
        &.{ nx, ny },
    );

    // try dcqp.callKernel(
    //     "max_project_float",
    //     args,
    //     argtype,
    //     &.{ nx, ny },
    // );
    const t6 = std.time.milliTimestamp();

    // Save max projection result
    // try im.saveF32AsTGAGreyNormed(d_output, @intCast(u16, ny), @intCast(u16, nx), "output/t100_rendered.tga");
    const t7 = std.time.milliTimestamp();

    print(
        \\Timings : 
        \\ t2-t1 = {} 
        \\ t3-t2 = {} 
        \\ t4-t3 = {} 
        \\ t5-t4 = {} 
        \\ t6-t5 = {} 
        \\ t7-t6 = {} 
        \\
    , .{
        t2 - t1,
        t3 - t2,
        t4 - t3,
        t5 - t4,
        t6 - t5,
        t7 - t6,
    });

    // Setup SDL stuff
    if (cc.SDL_Init(cc.SDL_INIT_VIDEO) != 0) {
        cc.SDL_Log("Unable to initialize SDL: %s", cc.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer cc.SDL_Quit();
    // Make window and surface
    const window_width: c_int = @intCast(c_int, nx);
    const window_height: c_int = @intCast(c_int, ny);
    print("nx:{} , ny:{}\n", .{ nx, ny });
    const window = cc.SDL_CreateWindow("weekend raytracer", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, window_width + 10, window_height + 10, cc.SDL_WINDOW_OPENGL) orelse {
        cc.SDL_Log("Unable to create window: %s", cc.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    const surface = SDL_GetWindowSurface(window) orelse {
        cc.SDL_Log("Unable to get window surface: %s", cc.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    var running = true;
    while (running) {

        // setup arena
        // var arena2 = std.heap.ArenaAllocator.init(gpa.allocator());
        // defer arena2.deinit();
        // const al = arena2.allocator();

        // perform the render
        args = .{
            img_cl,
            d_output,
            d_alpha_output,
            d_depth_output,
            nx,
            ny,
            view_angle,
        };
        try kernel.executeKernel(
            dcqp,
            args,
            argtype,
            &.{ nx, ny },
        );

        // Update window
        _ = cc.SDL_LockSurface(surface);
        for (d_output) |v, i| setPixel(
            surface,
            @intCast(c_int, i % nx),
            @intCast(c_int, i / nx),
            @floatToInt(u32, v * 255),
        );
        cc.SDL_UnlockSurface(surface);
        if (cc.SDL_UpdateWindowSurface(window) != 0) {
            cc.SDL_Log("Error updating window surface: %s", cc.SDL_GetError());
            return error.SDLUpdateWindowFailed;
        }

        // Event Handling
        var event: cc.SDL_Event = undefined;
        while (cc.SDL_PollEvent(&event) != 0) {
            switch (event.@"type") {
                cc.SDL_QUIT => {
                    running = false;
                },
                cc.SDL_KEYDOWN => {
                    if (event.key.keysym.sym == cc.SDLK_q) {
                        running = false;
                    }
                    if (event.key.keysym.sym == cc.SDLK_RIGHT) {
                        view_angle += 0.1;
                        print("view_angle {}\n", .{view_angle});
                    }
                    if (event.key.keysym.sym == cc.SDLK_LEFT) {
                        view_angle -= 0.1;
                        print("view_angle {}\n", .{view_angle});
                    }
                },
                else => {},
            }
        }

        cc.SDL_Delay(16);
    }

    return 0;
}

/// tested on ISBI CTC images
pub fn readTIFF3D(al: std.mem.Allocator, name: []const u8) !Img3D([4]u8) {
    _ = cc.tiffio.TIFFSetWarningHandler(null);

    const tif = cc.tiffio.TIFFOpen(&name[0], "r");
    defer cc.tiffio.TIFFClose(tif);

    var w: u32 = undefined;
    var h: u32 = undefined;
    _ = cc.tiffio.TIFFGetField(tif, cc.tiffio.TIFFTAG_IMAGEWIDTH, &w);
    _ = cc.tiffio.TIFFGetField(tif, cc.tiffio.TIFFTAG_IMAGELENGTH, &h);

    const n_strips = cc.tiffio.TIFFNumberOfStrips(tif);

    var depth: u32 = 0;
    while (cc.tiffio.TIFFReadDirectory(tif) == 1) {
        depth += 1;
    }

    const data = .{ .w = w, .h = h, .depth = depth, .n_strips = n_strips };
    print("{}\n", .{data});

    const buf = try al.alloc(u32, w * h * depth);

    // TODO: This interface provides the simplest, highest level access to the data, but we could gain speed if we use TIFFReadEncodedStrip or TIFFReadEncodedTile inferfaces below.
    var slice: u16 = 0;
    while (slice < depth) : (slice += 1) {
        const err = cc.tiffio.TIFFSetDirectory(tif, slice);
        if (err == 0) print("ERROR: error reading TIFF slice {d}\n", .{slice});
        var pos: usize = slice * w * h;
        _ = cc.tiffio.TIFFReadRGBAImage(tif, w, h, &buf[pos], 0);
    }

    // var i:u32 = 0;
    // while (i<n_strips) : (i+=1) {
    //     const len = @intCast(usize, cc.tiffio.TIFFReadEncodedStrip(tif, i, &buf[pos], -1) );
    //     pos += len;
    //     print("pos={d}\n", .{pos});
    // }

    // var tile:u32 = 0;
    // while (tile<cc.tiffio.TIFFNumberOfTiles(tif)) : (tile+=1){
    //     const len = cc.tiffio.TIFFReadEncodedTile(tif, tile, &buf[pos], -1);
    //     print("pos={d}\n", .{pos});
    //     pos += len;
    // }

    const pic = Img3D([4]u8){
        .img = std.mem.bytesAsSlice([4]u8, std.mem.sliceAsBytes(buf)),
        .nx = w,
        .ny = h,
        .nz = depth,
    };
    return pic;
}
