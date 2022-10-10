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

///
///  BEGIN OpenCL Helpers
///
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
            var len: usize = 90_000;
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

pub fn Kernel(
    comptime _kernName: []const u8,
    comptime _argtype: []const u8,
) type {
    return struct {
        const Self = @This();

        const kernName: []const u8 = _kernName;
        const argtype: []const u8 = _argtype;

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
            };

            return res;

            // for (nproc) |n, i| res.nproc_fixed[i] = n;
        }

        /// DEPRECATED
        pub fn reEnqueue(
            self: Self,
            dcqp: DevCtxQueProg,
            args: anytype,
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
            for (self.buffers) |b, i| {
                if (argtype[i] == 'x') continue;
                _ = cl.clReleaseMemObject(b); // TODO: what happens to defer inside of inline for ?
            }
            _ = cl.clReleaseKernel(self.kernel);
        }
    };
}

test "init.DevCtxQueProg" {
    const al = std.testing.allocator;
    const files = &[_][]const u8{
        "volumecaster3.cl",
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

pub fn boxImage() !Img3D(f32) {
    const nx = 708;
    const ny = 512;
    const nz = 34;
    var img = try Img3D(f32).init(nx, ny, nz);

    for (img.img) |*v, i| {
        const iz = (i / (nx * ny)) % nz; // should never exceed 34
        const iy = (i / nx) % ny;
        const ix = i % nx;
        var sum: u8 = 0;
        if (iz == 0 or iz == nz - 1) sum += 1;
        if (iy == 0 or iy == ny - 1) sum += 1;
        if (ix == 0 or ix == nx - 1) sum += 1;
        if (sum >= 2) {
            v.* = 1;
            print("{} {} {} \n", .{
                iz,
                iy,
                ix,
            });
        }
    }

    return img;
}

///
///  BEGIN SDL2 Helpers
///
const SDL_WINDOWPOS_UNDEFINED = @bitCast(c_int, cc.SDL_WINDOWPOS_UNDEFINED_MASK);

// For some reason, this isn't parsed automatically. According to SDL docs, the
// surface pointer returned is optional!
extern fn SDL_GetWindowSurface(window: *cc.SDL_Window) ?*cc.SDL_Surface;

/// deprecated
fn setPixel(surf: *cc.SDL_Surface, x: c_int, y: c_int, pixel: [4]u8) void {
    const target_pixel = @ptrToInt(surf.pixels) +
        @intCast(usize, y) * @intCast(usize, surf.pitch) +
        @intCast(usize, x) * 4;
    // @breakpoint();
    @intToPtr(*u32, target_pixel).* = @bitCast(u32, pixel);
}

fn setPixels(surf: *cc.SDL_Surface, buffer: [][4]u8) void {
    _ = cc.SDL_LockSurface(surf);
    var pix = @ptrCast([*c][4]u8, surf.pixels.?);
    for (buffer) |v, i| {
        pix[i] = v;
    }
    cc.SDL_UnlockSurface(surf);
}

///
///  BEGIN TIFFIO Helpers
///
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

///
///  MAIN() program. Load and Render TIFF with OpenCL and SDL.
///
pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // temporary stack allocator
    // var page = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const temp = arena.allocator();

    // const testtifname = "/Users/broaddus/Desktop/mpi-remote/project-broaddus/rawdata/celegans_isbi/Fluo-N3DH-CE/01/t100.tif";

    // var alo = std.testing.allocator;
    const t1 = std.time.milliTimestamp();

    // define allocator and .CL files
    const files = &[_][]const u8{
        "volumecaster3.cl",
    };
    const t2 = std.time.milliTimestamp();

    // setup OpenCL Contex Queue
    var dcqp = try DevCtxQueProg.init(temp, files);
    defer dcqp.deinit();

    const t3 = std.time.milliTimestamp();

    const t4 = std.time.milliTimestamp();

    // Load TIFF image
    const testtifname = "/Users/broaddus/Desktop/mpi-remote/project-broaddus/rawdata/celegans_isbi/Fluo-N3DH-CE/01/t100.tif";
    var arg_it = try std.process.argsWithAllocator(temp);
    _ = arg_it.skip(); // skip exe name
    const filename = arg_it.next() orelse testtifname;
    // _ = filename;

    const grey = blk: {
        const img = try readTIFF3D(temp, filename);
        const _gray = try Img3D(f32).init(img.nx, img.ny, img.nz);
        for (_gray.img) |*v, i| {
            v.* = @intToFloat(f32, img.img[i][0]) / 255;
        }
        break :blk _gray;
    };
    // const grey = try boxImage();

    const t5 = std.time.milliTimestamp();

    var img_cl = try img2CLImg(grey, dcqp);
    var nx: u32 = @floatToInt(u32, @intToFloat(f32, grey.nx) * 1.5);
    var ny: u32 = @floatToInt(u32, @intToFloat(f32, grey.ny) * 1.5);
    var d_output = try Img2D([4]u8).init(nx, ny);
    // var d_output = try temp.alloc([4]u8, nx * ny);
    // var colormap = try temp.alloc([4]u8, 256);
    const colormap = @import("cmap.zig").colormap_cool[0..];

    var view = View{
        .view_matrix = .{ 1, 0, 0, 0, 1, 0, 0, 0, 1 },
        .front_scale = .{ 1.2, 1.2, 1 },
        .back_scale = .{ 1.8, 1.8, 1 },
        .anisotropy = .{ 1, 1, 4 },
        .screen_size = .{ nx, ny },
    };

    const mima = im.minmax(f32, grey.img);

    // for (colormap) |*v, i| v.* = .{
    //     @intCast(u8, i), // Blue
    //     @intCast(u8, 255 - i), // Green
    //     @intCast(u8, 255 - i), // Red
    //     255,
    // };

    var args = .{
        img_cl,
        d_output.img,
        colormap,
        nx,
        ny,
        mima,
        view,
    };

    var kernel = try Kernel("max_project_float", "xrwxxxx").init(dcqp, args);
    defer kernel.deinit();

    const t6 = std.time.milliTimestamp();

    // perform the render
    try kernel.executeKernel(dcqp, args, &.{ nx, ny });

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

    const window = cc.SDL_CreateWindow(
        "weekend raytracer",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        @intCast(c_int, nx),
        @intCast(c_int, ny),
        cc.SDL_WINDOW_OPENGL,
    ) orelse {
        cc.SDL_Log("Unable to create window: %s", cc.SDL_GetError());
        return error.SDLInitializationFailed;
    };

    const surface = SDL_GetWindowSurface(window) orelse {
        cc.SDL_Log("Unable to get window surface: %s", cc.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    // @compileLog("Type of surface is ", @TypeOf(surface));

    // Update window
    addBBox(d_output, view);
    setPixels(surface, d_output.img);

    if (cc.SDL_UpdateWindowSurface(window) != 0) {
        cc.SDL_Log("Error updating window surface: %s", cc.SDL_GetError());
        return error.SDLUpdateWindowFailed;
    }

    var update = false;
    var running = true;
    var update_count: u64 = 0;

    // var boxpts:[8]Vec2 = undefined;
    // var imgnamebuffer:[100]u8 = undefined;

    while (running) {

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
                        view.view_matrix = matMulNNRowFirst(3, f32, view.view_matrix, delta.right);
                        update = true;
                    }
                    if (event.key.keysym.sym == cc.SDLK_LEFT) {
                        view.view_matrix = matMulNNRowFirst(3, f32, view.view_matrix, delta.left);
                        update = true;
                        // print("view_angle {}\n", .{view_angle});
                    }
                    if (event.key.keysym.sym == cc.SDLK_UP) {
                        view.view_matrix = matMulNNRowFirst(3, f32, view.view_matrix, delta.up);
                        update = true;
                        // print("view_angle {}\n", .{view_angle});
                    }
                    if (event.key.keysym.sym == cc.SDLK_DOWN) {
                        view.view_matrix = matMulNNRowFirst(3, f32, view.view_matrix, delta.down);
                        update = true;
                        // print("view_angle {}\n", .{view_angle});
                    }
                },
                else => {},
            }
        }

        if (update == false) {
            cc.SDL_Delay(16);
            continue;
        }

        update_count += 1;

        // perform the render and update the window
        args = .{ img_cl, d_output.img, colormap, nx, ny, mima, view };
        try kernel.executeKernel(dcqp, args, &.{ nx, ny });
        // _ = cl.clFinish(dcqp.command_queue);

        addBBox(d_output, view);
        setPixels(surface, d_output.img);

        if (cc.SDL_UpdateWindowSurface(window) != 0) {
            cc.SDL_Log("Error updating window surface: %s", cc.SDL_GetError());
            return error.SDLUpdateWindowFailed;
        }

        update = false;

        // Save max projection result
        // const filename = try std.fmt.bufPrint(&imgnamebuffer, "output/t100_rendered_{d:0>3}.tga", .{update_count});
        // try im.saveF32AsTGAGreyNormed(d_output, @intCast(u16, ny), @intCast(u16, nx), filename);
    }

    return 0;
}

const V3 = @Vector(3, f32);
const V2 = @Vector(2, f32);
const U2 = @Vector(2, u32);

const View = struct {
    view_matrix: [9]f32, // orthonormal
    front_scale: V3,
    back_scale: V3,
    anisotropy: V3,
    screen_size: U2,
};
const Ray = struct { orig: V3, direc: V3 };

fn U22V2(x: U2) V2 {
    return V2{ @intToFloat(f32, x[0]), @intToFloat(f32, x[1]) };
}

fn pix2RayView(view: View, pix: U2) Ray {
    const xy = U22V2(pix * U2{ 2, 2 }) / U22V2(view.screen_size + U2{ 1, 1 }) - V2{ 1, 1 }; // norm to [-1,1]
    // (xy + 1) * (sz + 1) / 2 = pix;
    // const xy = .{pix[0]*2 / }
    // print("xy = {}\n",.{xy});
    var front = V3{ xy[0], xy[1], -1 };
    var back = V3{ xy[0], xy[1], 1 };
    // print("1. front = {}\n",.{front});
    front *= view.front_scale;
    back *= view.back_scale;
    // print("2. front = {}\n",.{front});
    front = matVecMul33(view.view_matrix, front);
    back = matVecMul33(view.view_matrix, back);
    // print("3. front = {}\n",.{front});
    front *= view.anisotropy;
    back *= view.anisotropy;
    // print("4. front = {}\n",.{front});

    const direc = normV3(back - front);
    return .{ .orig = front, .direc = direc };
}

fn vol2PixView(view: View, _pt: V3) V2 {

    // @breakpoint();
    var pt = _pt;
    // print("1. pt= {}\n", .{pt});
    pt /= view.anisotropy;
    // print("2. pt= {}\n", .{pt});
    const inv = invert3x3(view.view_matrix);
    // print("mat= {d}\n",.{view.view_matrix});
    // print("inv= {d}\n",.{inv});
    pt = matVecMul33(inv, pt);
    // print("3. pt= {}\n", .{pt});
    // to get scale correct do a lerp between front_scale and back_scale, independently for each dimension.
    const scaleX = lerp(-1 * view.front_scale[2], pt[2], 1 * view.back_scale[2], view.front_scale[0], view.back_scale[0]);
    const scaleY = lerp(-1 * view.front_scale[2], pt[2], 1 * view.back_scale[2], view.front_scale[1], view.back_scale[1]);
    const x = (pt[0] / scaleX + 1) / 2 * @intToFloat(f32, view.screen_size[0] + 1);
    const y = (pt[1] / scaleY + 1) / 2 * @intToFloat(f32, view.screen_size[1] + 1);
    // print("4. xy= {}\n", .{.{x,y}});

    return .{ x, y };
}

test "test vol2PixView" {
    // pub fn main() !void {
    print("\n", .{});

    const c = @cos(2 * 3.14159 / 6.0);
    const s = @sin(2 * 3.14159 / 6.0);
    var view = View{
        .view_matrix = .{ c, s, 0, -s, c, 0, 0, 0, 1 },
        .front_scale = .{ 1.2, 1.2, 1 },
        .back_scale = .{ 1.8, 1.8, 1 },
        .anisotropy = .{ 1, 1, 4 },
        .screen_size = .{ 340, 240 },
    };

    {
        const px0 = U2{ 0, 240 };
        const r = pix2RayView(view, px0);
        const y = r.orig + V3{ 4, 4, 4 } * r.direc;
        const pix = vol2PixView(view, y);
        const px1 = U2{ @floatToInt(u32, @floor(pix[0])), @floatToInt(u32, @floor(pix[1])) };
        try expect(@reduce(.And, px0 == px1));
    }

    {
        const px0 = U2{ 100, 200 };
        const r = pix2RayView(view, px0);
        const y = r.orig + V3{ 4, 4, 4 } * r.direc;
        const pix = vol2PixView(view, y);
        const px1 = U2{ @floatToInt(u32, @floor(pix[0])), @floatToInt(u32, @floor(pix[1])) };
        try expect(@reduce(.And, px0 == px1));
    }

    // FAIL
    const pixlist = [_]U2{
        U2{ 0, 240 },
        U2{ 0, 360 },
        U2{ 1, 240 },
        U2{ 10, 180 },
        U2{ 30, 100 },
        U2{ 31, 101 },
        U2{ 7, 233 },
        U2{ 7, 353 },
        U2{ 8, 233 },
        U2{ 17, 173 },
        U2{ 37, 93 },
        U2{ 38, 94 },
    };

    for (pixlist) |px0| {
        // const px0 = U2{10,240};
        const r = pix2RayView(view, px0);
        const y = r.orig + V3{ 4, 4, 4 } * r.direc;
        const pix = vol2PixView(view, y);
        const px1 = U2{ @floatToInt(u32, @floor(pix[0])), @floatToInt(u32, @floor(pix[1])) };
        expect(@reduce(.And, px0 == px1)) catch {
            print("pix {} fail\n", .{px0});
        };
    }
}

fn V22U2(x: V2) U2 {
    return U2{ @floatToInt(u32, x[0]), @floatToInt(u32, x[1]) };
}

fn addBBox(img: Img2D([4]u8), view: View) void {

    const lines = [_][2]V3{
        // draw along x
        .{.{ -1, -1, -1 } , .{ 1, -1, -1 }},
        .{.{ -1,  1, -1 } , .{ 1,  1, -1 }},
        .{.{ -1,  1,  1 } , .{ 1,  1,  1 }},
        .{.{ -1, -1,  1 } , .{ 1, -1,  1 }},

        // draw along y
        .{.{ -1, -1, -1  } , .{-1,  1, -1 }},
        .{.{ -1, -1,  1  } , .{-1,  1,  1 }},
        .{.{  1, -1,  -1 } , .{ 1,  1, -1 }},
        .{.{  1, -1,   1 } , .{ 1,  1,  1 }},

        // draw along z
        .{.{ -1, -1, -1 } , .{-1, -1,  1 }},
        .{.{ -1,  1, -1 } , .{-1,  1,  1 }},
        .{.{  1, -1, -1 } , .{ 1, -1,  1 }},
        .{.{  1,  1, -1 } , .{ 1,  1,  1 }},
    };

    inline for (lines) |x0x1|
    {
    const x0 = vol2PixView(view, x0x1[0]);
    const x1 = vol2PixView(view, x0x1[1]);
    im.drawLineInBounds(
        [4]u8,
        img,
        @floatToInt(i32, x0[0]),
        @floatToInt(i32, x0[1]),
        @floatToInt(i32, x1[0]),
        @floatToInt(i32, x1[1]),
        .{ 255, 255, 255, 255 },
    );
    }
}

//
// Basic Math
//

test "test lerp" {
    print("\n", .{});
    print("lerp = {} \n", .{lerp(0, 0.5, 1, 1, 2)});
    print("lerp = {} \n", .{lerp(-1, 1, 1, 1, 2)});
    print("lerp = {} \n", .{lerp(-1, 1, 1, 1, 2)});
}

fn lerp(lo: f32, mid: f32, hi: f32, valLo: f32, valHi: f32) f32 {
    return valLo * (hi - mid) / (hi - lo) + valHi * (mid - lo) / (hi - lo);
}

// Requires XYZ order (or some rotation thereof)
pub fn cross(a: V3, b: V3) V3 {
    return V3{
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    };
}

pub fn dot(a: V3, b: V3) f32 {
    // return a[0] * b[0] + a[1] * b[1] + a[2] * b[2] ;
    return @reduce(.Add, a * b);
}

pub fn invert3x3(mat: [9]f32) [9]f32 {
    const v1 = mat[0..3].*;
    const v2 = mat[3..6].*;
    const v3 = mat[6..9].*;
    const v1v2 = cross(v1, v2);
    const v2v3 = cross(v2, v3);
    const v3v1 = cross(v3, v1);
    const d = dot(v1, v2v3);
    return [9]f32{
        v2v3[0] / d,
        v3v1[0] / d,
        v1v2[0] / d,
        v2v3[1] / d,
        v3v1[1] / d,
        v1v2[1] / d,
        v2v3[2] / d,
        v3v1[2] / d,
        v1v2[2] / d,
    };
}

test "test invert3x3" {
    const a = [9]f32{ 0.58166294, 0.33293927, 0.81886478, 0.63398062, 0.85116383, 0.8195473, 0.83363027, 0.52720334, 0.17217296 };
    const b = [9]f32{ 0.05057727, 0.00987139, 0.74565127, 0.42741473, 0.34184494, 0.37298805, 0.3842003, 0.48188364, 0.16291618 };
    // const c = [9]f32{ 0.48633017, 0.51415297, 0.6913064, 0.71073529, 0.69215076, 0.9237199, 0.33364612, 0.27141822, 0.84628778 };
    const d = matMulNNRowFirst(3, f32, a, b);
    const e = matMulNNRowFirst(3, f32, invert3x3(a), d);
    print("\nb = {d}\ne = {d}\n", .{ b, e });
}

test "test pix2RayView" {
    var view = View{
        .view_matrix = .{ 1, 0, 0, 0, 1, 0, 0, 0, 1 },
        .front_scale = .{ 1.2, 1.2, 1 },
        .back_scale = .{ 1.8, 1.8, 1 },
        .anisotropy = .{ 1, 1, 4 },
        .screen_size = .{ 340, 240 },
    };

    print("\n{}\n", .{pix2RayView(view, .{ 120, 120 })});
}

fn normV3(x: V3) V3 {
    const s = @sqrt(@reduce(.Add, x * x));
    return x / V3{ s, s, s };
}

fn pix2Ray(view_matrix: [9]f32) struct { front: [9]f32, back: [9]f32 } {
    const Nx = 500;
    const Ny = 500;

    const front = blk: {
        const FB = 1;
        //  row first    { 1        , 2 , 3             , 4 , 5        , 6             , 7 , 8 , 9   }
        const a = [9]f32{ 2 / (Nx - 1), 0, -2 / (Nx - 1) - 1, 0, 2 / (Ny - 1), -2 / (Ny - 1) - 1, 0, 0, FB }; // affine translate x , y to [-1 , 1]
        const b = [9]f32{ 1.2, 0, 0, 0, 1.2, 0, 0, 0, 1.0 }; // scale front (back) plane to determine perspective
        const c = view_matrix; // rotate
        const d = [9]f32{ 1.0, 0, 0, 0, 1.0, 0, 0, 0, 4.0 }; // anisotropy
        var res = matMulNNRowFirst(3, f32, b, a);
        res = matMulNNRowFirst(3, f32, c, res);
        res = matMulNNRowFirst(3, f32, d, res);
        break :blk res;
    };

    const back = blk: {
        const FB = -1;
        //  row first    { 1        , 2 , 3             , 4 , 5        , 6             , 7 , 8 , 9   }
        const a = [9]f32{ 2 / (Nx - 1), 0, -2 / (Nx - 1) - 1, 0, 2 / (Ny - 1), -2 / (Ny - 1) - 1, 0, 0, FB }; // affine translate x , y to [-1 , 1]
        const b = [9]f32{ 1.8, 0, 0, 0, 1.8, 0, 0, 0, 1.0 }; // scale front (back) plane to determine perspective
        const c = view_matrix; // rotate
        const d = [9]f32{ 1.0, 0, 0, 0, 1.0, 0, 0, 0, 4.0 }; // anisotropy
        var res = matMulNNRowFirst(3, f32, b, a);
        res = matMulNNRowFirst(3, f32, c, res);
        res = matMulNNRowFirst(3, f32, d, res);
        break :blk res;
    };

    return .{ .front = front, .back = back };
}

const delta = struct {
    const c = @cos(2 * std.math.pi / 32.0);
    const s = @sin(2 * std.math.pi / 32.0);

    // rotate z to right, x into screen.
    pub const right: [9]f32 = .{
        c,  0, s,
        0,  1, 0,
        -s, 0, c,
    };
    pub const left: [9]f32 = .{
        c, 0, -s,
        0, 1, 0,
        s, 0, c,
    };
    pub const up: [9]f32 = .{
        1, 0, 0,
        0, c, -s,
        0, s, c,
    };
    pub const down: [9]f32 = .{
        1, 0,  0,
        0, c,  s,
        0, -s, c,
    };
};

fn rotmatFromAngles(invM: *[16]f32, view_angle: [2]f32) void {
    const c0 = @cos(view_angle[0]);
    const s0 = @sin(view_angle[0]);
    const r0 = [16]f32{
        c0, 0, -s0, 0,
        0,  1, 0,   0,
        s0, 0, c0,  0,
        0,  0, 0,   1,
    };

    const c1 = @cos(view_angle[1]);
    const s1 = @sin(view_angle[1]);
    const r1 = [16]f32{
        1, 0,  0,   0,
        0, c1, -s1, 0,
        0, s1, c1,  0,
        0, 0,  0,   1,
    };

    invM.* = matMulNNRowFirst(4, f32, r1, r0);

    // for (int i=0; i<16; i++){invM[i] = _invM[i];}
}

pub fn matVecMul33(left: [9]f32, right: V3) V3 {
    var res = V3{ 0, 0, 0 };
    res[0] = @reduce(.Add, @as(V3, left[0..3].*) * right);
    res[1] = @reduce(.Add, @as(V3, left[3..6].*) * right);
    res[2] = @reduce(.Add, @as(V3, left[6..9].*) * right);

    return res;
}

test "test matVecMul33" {
    const a = V3{ 1, 0, 0 };
    const b = [9]f32{ 1, 0, 0, 0, 2, 0, 0, 0, 3 };
    print("a*b = {d}\n", .{matVecMul33(b, a)});
}

pub fn matMulNNRowFirst(comptime n: u8, comptime T: type, left: [n * n]T, right: [n * n]T) [n * n]T {
    var result: [n * n]T = .{0} ** (n * n);
    assert(n < 128);
    comptime {
        for (result) |*c, k| {
            var i = (k / n) * n;
            var j = k % n;
            var m = 0;
            while (m < n) : (m += 1) {
                c.* += left[i + m] * right[j + m * n];
                // @compileLog(i+m, j+m*n);
            }
        }
    }
    return result;
}

const expect = std.testing.expect;
const eql = std.mem.eql;

test "test matMulRowFirst" {
    {
        const a = [9]f32{ 0.58166294, 0.33293927, 0.81886478, 0.63398062, 0.85116383, 0.8195473, 0.83363027, 0.52720334, 0.17217296 };
        const b = [9]f32{ 0.05057727, 0.00987139, 0.74565127, 0.42741473, 0.34184494, 0.37298805, 0.3842003, 0.48188364, 0.16291618 };
        const c = [9]f32{ 0.48633017, 0.51415297, 0.6913064, 0.71073529, 0.69215076, 0.9237199, 0.33364612, 0.27141822, 0.84628778 };
        const d = matMulNNRowFirst(3, f32, a, b);
        const V = @Vector(9, f32);
        const delt = @reduce(.Add, @as(V, c) - @as(V, d));
        try expect(delt < 1e-5);
    }

    {
        const a = [9]u32{ 1, 1, 1, 0, 0, 0, 0, 0, 0 };
        const b = [9]u32{ 1, 1, 1, 0, 0, 0, 0, 0, 0 };
        const c = [9]u32{ 1, 1, 1, 0, 0, 0, 0, 0, 0 };
        const d = matMulNNRowFirst(3, u32, a, b);
        try expect(eql(u32, &c, &d));
    }

    {
        const a = [4]u5{ 1, 2, 3, 4 };
        const b = [4]u5{ 1, 2, 3, 4 };
        const c = [4]u5{ 7, 10, 15, 22 };
        const d = matMulNNRowFirst(2, u5, a, b);
        try expect(eql(u5, &c, &d));
    }

    // const a = [4]u32{1,1,0,0};
    // const b = [4]u32{1,1,0,0};
    // const c = matMulNNRowFirst(2,u32,a,b);

    // print("\n\na*b {d} \n\n, c {d} \n\n", .{matMulNNRowFirst(3,u32,a,b), c});
}
