const std = @import("std");
const im = @import("image_base.zig");
const print = std.debug.print;
const assert = std.debug.assert;
const expect = std.testing.expect;
const eql = std.mem.eql;

const milliTimestamp = std.time.milliTimestamp;

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
        // no error, return void
        return;
    } else |err| {
        // yes error
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

test "Handle a custom CLERROR" {
    print("\n", .{});
    try testForCLError(0); // code zero => CL_SUCCESS
    print("{any}\n", .{@typeInfo(cl.cl_int)});
    testForCLError(-4) catch |err| switch (err) {
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
        defer al.free(prog_source);
        inline for (files) |name, i| prog_source[i] = try cwd.readFileAllocOptions(al, name, 20_000, null, @alignOf(u8), 0);
        defer inline for (files) |_, i| al.free(prog_source[i]);
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

fn containsOnly(sequence: []const u8, charset: []const u8) bool {
    blk: for (sequence) |s| {
        for (charset) |c| {
            if (s == c) break :blk;
        }
        return false;
    }
    return true;
}

test "test containsonly" {
    const a = "aabbccdefgaabbcc";
    const b = "bcadgfe";
    try expect(containsOnly(a, b));
}

const ArgTypes = enum {
    buffer_write_once,
    buffer_write_everytime,
    buffer_read_everytime,
    nonbuf_write_once,
    nonbuf_write_everytime,
    nonbuf_read_everytime,
};

pub fn Kernel(
    comptime _kern_name: []const u8,
    comptime _argtype: []const ArgTypes,
) type {
    // assert(containsOnly(_argtype, "rwxi"));

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
        ) !Self {

            // reuse errCode variable for each OpenCL call
            var errCode: cl.cl_int = undefined;

            // Create a Kernel
            var kernel = cl.clCreateKernel(dcqp.program, &kern_name[0], &errCode);
            try testForCLError(errCode);

            // TODO: Do we need to create buffers for all arguments or only for arrays?
            // Buffers are just pointers?! Easy to make a simple array.
            var buffers: [argtype.len]cl.cl_mem = undefined;

            // Loop over the arguments we want to pass to the kernel. Set read/write flags
            // as appropriate. Create buffers, add data to buffers, pass buffers as kernel args.
            inline for (argtype) |argT, i| {
                const arg = args[i];
                const T = @TypeOf(arg);
                const size = switch (@typeInfo(T)) {
                    .Pointer => @sizeOf(std.meta.Elem(T)) * arg.len, // assume slice or array
                    else => @sizeOf(T),
                };

                switch (argT) {
                    .buffer_write_once, .buffer_write_everytime => {
                        buffers[i] = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_WRITE_ONLY, size, null, &errCode);
                        try testForCLError(errCode);
                        errCode = cl.clEnqueueWriteBuffer(dcqp.command_queue, buffers[i], cl.CL_TRUE, 0, size, &arg[0], 0, null, null);
                        try testForCLError(errCode);
                        errCode = cl.clSetKernelArg(kernel, i, @sizeOf(cl.cl_mem), &buffers[i]);
                        try testForCLError(errCode);
                    },
                    .buffer_read_everytime => {
                        buffers[i] = cl.clCreateBuffer(dcqp.ctx, cl.CL_MEM_READ_ONLY, size, null, &errCode);
                        try testForCLError(errCode);
                        errCode = cl.clSetKernelArg(kernel, i, @sizeOf(cl.cl_mem), &buffers[i]);
                        try testForCLError(errCode);
                    },
                    else => {
                        errCode = cl.clSetKernelArg(kernel, i, size, &arg);
                        try testForCLError(errCode);
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

            var errCode: cl.cl_int = undefined;

            // Loop over the arguments we want to pass to the kernel. Set read/write flags
            // as appropriate. Create buffers, add data to buffers, pass buffers as kernel args.
            inline for (argtype) |argT, i| {
                const arg = args[i];
                const T = @TypeOf(arg);
                const size = switch (@typeInfo(T)) {
                    .Pointer => @sizeOf(std.meta.Elem(T)) * arg.len, // assume slice or array
                    else => @sizeOf(T),
                };

                switch (argT) {
                    .buffer_write_everytime => {
                        errCode = cl.clEnqueueWriteBuffer(dcqp.command_queue, self.buffers[i], cl.CL_TRUE, 0, size, &arg[0], 0, null, null);
                        try testForCLError(errCode);
                        errCode = cl.clSetKernelArg(self.kernel, i, @sizeOf(cl.cl_mem), &self.buffers[i]);
                        try testForCLError(errCode);
                    },
                    .nonbuf_write_everytime => {
                        // errCode = cl.clSetKernelArg(self.kernel, i, @sizeOf(cl.cl_mem), &self.buffers[i]);
                        // try testForCLError(errCode);
                        errCode = cl.clSetKernelArg(self.kernel, i, size, &arg);
                        try testForCLError(errCode);
                    },
                    else => {},
                }
            }

            errCode = cl.clEnqueueNDRangeKernel(dcqp.command_queue, self.kernel, @intCast(u32, nproc.len), null, &nproc[0], null, 0, null, null);
            try testForCLError(errCode);

            inline for (argtype) |argT, i| {
                switch (argT) {
                    .buffer_read_everytime => {
                        const arg = args[i];
                        const T = @TypeOf(arg);
                        const size = switch (@typeInfo(T)) {
                            .Pointer => @sizeOf(std.meta.Elem(T)) * arg.len, // assume slice or array
                            else => @sizeOf(T),
                        };

                        errCode = cl.clEnqueueReadBuffer(dcqp.command_queue, self.buffers[i], cl.CL_TRUE, 0, size, &arg[0], 0, null, null);
                        try testForCLError(errCode);
                    },
                    else => {},
                }
            }
        }

        pub fn deinit(self: Self) void {
            for (self.buffers) |b, i| {
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

test "test DevCtxQueProg" {
    const al = std.testing.allocator;
    const files = &[_][]const u8{
        "volumecaster.cl",
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

test "test tiff open float image" {
    const al = std.testing.allocator;
    const img = try readTIFF3D(al, "/Users/broaddus/Desktop/mpi-remote/project-broaddus/fisheye/training/ce_024/train_cp/pimgs/train1/pimg_211.tif");
    defer img.deinit();
}

///  BEGIN TIFFIO Helpers
/// loads ISBI CTC images
pub fn readTIFF3D(al: std.mem.Allocator, name: []const u8) !Img3D(f32) {
    _ = cc.tiffio.TIFFSetWarningHandler(null);

    const tif = cc.tiffio.TIFFOpen(&name[0], "r");
    defer cc.tiffio.TIFFClose(tif);

    const Meta = struct {
        datatype: u32 = undefined,
        bitspersample: u32 = undefined,
        samplesperpixel: u32 = undefined,
        imagewidth: u32 = undefined,
        rowsperstrip: u32 = undefined,
        imagelength: u32 = undefined,
        n_strips: u32 = undefined,
        n_directories: u32 = undefined,
        scanline_size: u64 = undefined,
    };

    // var meta = std.mem.zeroInit(Meta, .{});
    var meta = Meta{};

    _ = cc.tiffio.TIFFGetField(tif, cc.tiffio.TIFFTAG_DATATYPE, &meta.datatype);
    _ = cc.tiffio.TIFFGetField(tif, cc.tiffio.TIFFTAG_BITSPERSAMPLE, &meta.bitspersample);
    _ = cc.tiffio.TIFFGetField(tif, cc.tiffio.TIFFTAG_SAMPLESPERPIXEL, &meta.samplesperpixel);
    _ = cc.tiffio.TIFFGetField(tif, cc.tiffio.TIFFTAG_IMAGEWIDTH, &meta.imagewidth);

    _ = cc.tiffio.TIFFGetField(tif, cc.tiffio.TIFFTAG_ROWSPERSTRIP, &meta.rowsperstrip);
    _ = cc.tiffio.TIFFGetField(tif, cc.tiffio.TIFFTAG_IMAGELENGTH, &meta.imagelength);

    meta.scanline_size = cc.tiffio.TIFFRasterScanlineSize64(tif); // size in Bytes !
    meta.n_strips = cc.tiffio.TIFFNumberOfStrips(tif);
    meta.n_directories = blk: {
        var depth_: u32 = 0;
        while (cc.tiffio.TIFFReadDirectory(tif) == 1) {
            depth_ += 1;
        }
        break :blk depth_;
    };

    print("meta = {}\n", .{meta});

    // const buf = try al.alloc(u8, meta.imagewidth * meta.imagelength * meta.n_directories * @divExact(meta.bitspersample, 8));
    const buf = try al.alloc(u8, meta.scanline_size * meta.imagelength * meta.n_directories);
    defer al.free(buf);

    // TODO: This interface provides the simplest, highest level access to the data, but we could gain speed if we use TIFFReadEncodedStrip or TIFFReadEncodedTile inferfaces below.
    // var slice: u16 = 0;

    var pos: usize = 0; //slice * w * h + line * line_size;
    var i_dir: u16 = 0;
    while (i_dir < meta.n_directories) : (i_dir += 1) {
        const err = cc.tiffio.TIFFSetDirectory(tif, i_dir);
        if (err == 0) print("ERROR: error reading TIFF i_dir {d}\n", .{i_dir});

        // print("read: i_dir {} at row {}\n", .{ i_dir, row });
        // print("read: i_dir {} \n", .{i_dir});
        var row: u32 = 0;
        while (row < meta.imagelength) : (row += 1) {
            _ = cc.tiffio.TIFFReadScanline(tif, &buf[pos], row, 0); // assume one sample per pixel
            pos += meta.scanline_size;
        }
    }

    // typedef enum {
    // 	TIFF_NOTYPE = 0,      /* placeholder */
    // 	TIFF_BYTE = 1,        /* 8-bit unsigned integer */
    // 	TIFF_ASCII = 2,       /* 8-bit bytes w/ last byte null */
    // 	TIFF_SHORT = 3,       /* 16-bit unsigned integer */
    // 	TIFF_LONG = 4,        /* 32-bit unsigned integer */
    // 	TIFF_RATIONAL = 5,    /* 64-bit unsigned fraction */
    // 	TIFF_SBYTE = 6,       /* !8-bit signed integer */
    // 	TIFF_UNDEFINED = 7,   /* !8-bit untyped data */
    // 	TIFF_SSHORT = 8,      /* !16-bit signed integer */
    // 	TIFF_SLONG = 9,       /* !32-bit signed integer */
    // 	TIFF_SRATIONAL = 10,  /* !64-bit signed fraction */
    // 	TIFF_FLOAT = 11,      /* !32-bit IEEE floating point */
    // 	TIFF_DOUBLE = 12,     /* !64-bit IEEE floating point */
    // 	TIFF_IFD = 13,        /* %32-bit unsigned integer (offset) */
    // 	TIFF_LONG8 = 16,      /* BigTIFF 64-bit unsigned integer */
    // 	TIFF_SLONG8 = 17,     /* BigTIFF 64-bit signed integer */
    // 	TIFF_IFD8 = 18        /* BigTIFF 64-bit unsigned integer (offset) */
    // } TIFFDataType;
    const pic = try Img3D(f32).init(meta.imagewidth, meta.imagelength, meta.n_directories);
    const n = @divExact(meta.bitspersample, 8);
    for (pic.img) |*v, i| {
        const bufbytes = buf[(n * i)..(n * (i + 1))];

        v.* = switch (meta.datatype) {
            1, 2 => @intToFloat(f32, bufbytes[0]),
            3 => @intToFloat(f32, std.mem.bytesAsSlice(u16, bufbytes)[0]),
            else => unreachable,
        };
    }

    return pic;
}

/// IDEA: acts like an Allocator ? What happens when we want to remove or add vertices to a loop?
const ScreenLoop = [][2]u32;
const VolumeLoop = [][3]f32;

fn drawScreenLoop(sl: ScreenLoop, d_output: Img2D([4]u8)) void {
    // var pix = @ptrCast([*c][4]u8, surface.pixels.?);
    if (sl.len == 0) return;

    for (sl) |pt, i| {
        if (i == 0) continue;
        im.drawLineInBounds(
            [4]u8,
            d_output,
            @intCast(u31, sl[i - 1][0]),
            @intCast(u31, sl[i - 1][1]),
            @intCast(u31, pt[0]),
            @intCast(u31, pt[1]),
            colors.white,
        );
    }

    // DONT ACTUALLY COMPLETE THE LOOP.

    // im.drawLine(
    //     [4]u8,
    //     d_output,
    //     @intCast(u31, sl[0][0]),
    //     @intCast(u31, sl[0][1]),
    //     @intCast(u31, sl[sl.len - 1][0]),
    //     @intCast(u31, sl[sl.len - 1][1]),
    //     colors.white,
    // );
}

/// Returns slice (ptr type) to existing memory in `loops.screen_loop`
fn volumeLoop2ScreenLoop(view: View, vl: VolumeLoop) ScreenLoop {
    // loops.screen_loop.clearRetainingCapacity();
    for (vl) |pt3, i| {
        loops.temp_screen_loop[i] = v22U2(pointToPixel(view, pt3));
        // loops.screen_loop.appendAssumeCapacity(v22U2(pointToPixel(view, pt3)));
    }
    const n = vl.len;
    loops.temp_screen_loop_len = n;
    return loops.temp_screen_loop[0..n];
}

// fn screenLoop2VolumeLoop(sl: ScreenLoop, view: View, zbuf: Img2D(f32)) VolumeLoop {}

// fn zmean(filtered_positions: [][3]f32) f32 {
//     var total: f32 = 0;
//     for (filtered_positions) |v| total += v[2];
//     return total / @intToFloat(f32, filtered_positions.len);
// }

/// embed ScreenLoop inside volume with normalized coords [-1,1]^3
///  since our data is noisy, we can't always expect that the maxval of the intensity is from
///  the object we intend. we could deal with this by _denoising_ the loop depth, the image depth buffer,
///
fn embedLoops(al: std.mem.Allocator, loop: ScreenLoop, view: View, depth_buffer: Img2D(f32)) !void {

    // NOTE: we're looping over pixel knots in our Loop, but this does not include pixels drawn interpolated between knot points.
    var depth_mean = @as(f32, 0);
    for (loop) |v| {
        var depth = depth_buffer.get(v[0], v[1]).*; // in [0,1] coords
        depth_mean += depth;
    }
    depth_mean /= @intToFloat(f32, loop.len);

    var filtered_positions = try al.alloc([3]f32, 900);
    defer al.free(filtered_positions);
    var vertex_count: u16 = 0;

    for (loop) |v| {
        const ray = pixelToRay(view, v);
        const position = ray.orig + @splat(3, depth_mean) * ray.direc;
        if (@reduce(.Or, position < V3{ -1, -1, -1 })) continue;
        if (@reduce(.Or, position > V3{ 1, 1, 1 })) continue;
        filtered_positions[vertex_count] = position;
        vertex_count += 1;
    }

    // const the_zmean = zmean(filtered_positions) ;
    // for (filtered_positions) |*v| v.*[2] = the_zmean;

    var floatPosActual = loops.getNewSlice(@intCast(u16, vertex_count));
    for (floatPosActual) |*v, i| v.* = filtered_positions[i];
}

const colors = struct {
    const white = [4]u8{ 255, 255, 255, 255 };
    const red = [4]u8{ 255, 0, 0, 255 };
};

fn drawLoops(d_output: Img2D([4]u8), view: View) void {

    // for each loop in loop_collection we know the internal coordinates (in [-1,1]) and
    // can compute the coordinates in the pixel space of the surface using pointToPixel()
    // then we can draw them connected with lines.
    var i: u16 = 0;
    while (i < loops.volume_loop_max_index) : (i += 1) {
        const vl = loops.getVolumeLoop(i);
        const sl = volumeLoop2ScreenLoop(view, vl);
        drawScreenLoop(sl, d_output);
    }
}

// var mybuf = [_]u8{0} ** 10_000;
// const fba = std.heap.FixedBufferAllocator(mybuf);

const loops = struct {

    // This buffer stores pixel locations as a loop is being drawn before it's embeded and saved.
    // It also stores pixel locations as a loop is converted from []V3 -> []U2 before it's drawn to screen.
    var temp_screen_loop: [10_000][2]u32 = undefined; // will crash if a screen loop exceeds 10_000 points (at 16ms frame rate that's 160s of drawing)
    var temp_screen_loop_len: usize = 0;

    // Buffer that stores 3D coordinates of knots that form Loops.
    // Works like a simple memory allocator for []V3 slices.
    var volume_loop_mem: [1000 * 100][3]f32 = undefined; // 1000 loops * 100 avg-loop-length
    var volume_loop_indices = [_]usize{0} ** 1000; // up to 100 indices into loop memory
    var volume_loop_max_index: usize = 0; // number of indices currently in use

    pub fn getVolumeLoop(n: u16) VolumeLoop {
        return volume_loop_mem[volume_loop_indices[n]..volume_loop_indices[n + 1]];
    }

    pub fn getNewSlice(nitems: u16) [][3]f32 {
        const idx0 = volume_loop_indices[volume_loop_max_index];
        const idx1 = idx0 + nitems;
        volume_loop_indices[volume_loop_max_index + 1] = idx1;
        volume_loop_max_index += 1;
        return volume_loop_mem[idx0..idx1];
    }

    // pub fn handleMouseDown() {}
    // pub fn handleMouseUp() {}
    // pub fn handleMouseMove() {}

};

const rects = struct {
    // var temp_screen_rect: [2]U2 = undefined;
    var all_volume_pixel_aligned_bboxes: [100][3]U2 = undefined;
    var all_volume_pixel_aligned_bbox_count: usize = 0;
};

// const anno = struct {
//     // ArrayList ? can add and set
//     const loops = ...
//     const rects = ...
//     pub fn drawLoops()
//     pub fn drawRects()
// }

// const Screen = struct {
//     surface: *cc.SDL_Surface,
//     needs_update: bool,
//     update_count: u64,
// };

// var mouse_mode =
// TODO: Use mouse modes to dispatch early to loop, rect, view mouse functions.
// Let the mode determine how to handle key and mouse input.
const Mouse = struct {
    mousedown: bool,
    mouse_location: ?[2]u31,
    loop_draw_mode: enum { view, loop, rect },
};

// for timings
// var t1: i64 = 0;
// var t2: i64 = 0;

test "test window creation" {
    const win = try Window.init(1000, 800);
    try win.update();
}

const SDL_WINDOWPOS_UNDEFINED = @bitCast(c_int, cc.SDL_WINDOWPOS_UNDEFINED_MASK);

// For some reason, this isn't parsed automatically. According to SDL docs, the
// surface pointer returned is optional!
extern fn SDL_GetWindowSurface(window: *cc.SDL_Window) ?*cc.SDL_Surface;

const Window = struct {
    sdl_window: *cc.SDL_Window,
    surface: *cc.SDL_Surface,
    pix: [*c][4]u8,

    needs_update: bool,
    update_count: u64,

    const This = @This();

    /// WARNING: c managed heap memory mixed with our custom allocator
    pub fn init(nx: u32, ny: u32) !This {
        var t1: i64 = undefined;
        var t2: i64 = undefined;

        t1 = milliTimestamp();
        const window = cc.SDL_CreateWindow(
            "Main Volume",
            SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED,
            @intCast(c_int, nx),
            @intCast(c_int, ny),
            cc.SDL_WINDOW_OPENGL,
        ) orelse {
            cc.SDL_Log("Unable to create window: %s", cc.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        t2 = milliTimestamp();
        print("CreateWindow [{}ms]\n", .{t2 - t1});

        t1 = milliTimestamp();
        const surface = SDL_GetWindowSurface(window) orelse {
            cc.SDL_Log("Unable to get window surface: %s", cc.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        t2 = milliTimestamp();
        print("SDL_GetWindowSurface [{}ms]\n", .{t2 - t1});

        // @breakpoint();

        const res = .{
            .sdl_window = window,
            .surface = surface,
            .pix = @ptrCast([*c][4]u8, surface.pixels.?),
            .needs_update = false,
            .update_count = 0,
        };

        res.pix[50] = .{ 255, 255, 255, 255 };
        res.pix[51] = .{ 255, 255, 255, 255 };
        res.pix[52] = .{ 255, 255, 255, 255 };
        res.pix[53] = .{ 255, 255, 255, 255 };

        return res;
    }

    fn update(this: This) !void {
        const err = cc.SDL_UpdateWindowSurface(this.sdl_window);
        if (err != 0) {
            cc.SDL_Log("Error updating window surface: %s", cc.SDL_GetError());
            return error.SDLUpdateWindowFailed;
        }
    }

    fn setPixel(this: *This, x: c_int, y: c_int, pixel: [4]u8) void {
        const target_pixel = @ptrToInt(this.surface.pixels) +
            @intCast(usize, y) * @intCast(usize, this.surface.pitch) +
            @intCast(usize, x) * 4;
        @intToPtr(*u32, target_pixel).* = @bitCast(u32, pixel);
    }

    fn setPixels(this: *This, buffer: [][4]u8) void {
        _ = cc.SDL_LockSurface(this.surface);
        for (buffer) |v, i| {
            this.pix[i] = v;
        }
        cc.SDL_UnlockSurface(this.surface);
    }
};

// const App = struct {
//     al: std.mem.Allocator,
//     window1: Window,
//     window2: Window,
//     dcqp : DevCtxQueProg,
//     grey : Img3D(f32),
//     annotations : Anno,
//     loops : Loops,

//     const This = @This();

// };

// const myCL = struct {
// }

///
///  Load and Render TIFF with OpenCL and SDL.
///
pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    // temporary stack allocator
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const temp = arena.allocator();

    const files = &[_][]const u8{
        "volumecaster.cl",
    };

    var t1: i64 = undefined;
    var t2: i64 = undefined;

    const filename = blk: {
        const testtifname = "/Users/broaddus/Desktop/mpi-remote/project-broaddus/rawdata/celegans_isbi/Fluo-N3DH-CE/01/t100.tif";
        var arg_it = try std.process.argsWithAllocator(temp);
        _ = arg_it.skip(); // skip exe name
        break :blk arg_it.next() orelse testtifname; // zig10.x version
        // break :blk try (arg_it.next(temp) orelse testtifname); // zig0.9.x version
    };

    // Load TIFF image
    // t1 = milliTimestamp();
    const grey = try readTIFF3D(temp, filename);

    // t2 = milliTimestamp();
    print("load TIFF and convert to f32 [{}ms]\n", .{t2 - t1});

    // Setup SDL & open window
    // t1 = milliTimestamp();
    if (cc.SDL_Init(cc.SDL_INIT_VIDEO) != 0) {
        cc.SDL_Log("Unable to initialize SDL: %s", cc.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer cc.SDL_Quit();
    // t2 = milliTimestamp();
    print("SDL_Init [{}ms]\n", .{t2 - t1});

    // t1 = milliTimestamp();
    // this assumes x will be the bounding length, but it could be either!
    var nx: u31 = undefined;
    var ny: u31 = undefined;
    {
        const gx = @intToFloat(f32, grey.nx);
        const gy = @intToFloat(f32, grey.ny);
        const scale = std.math.min3(1600 / gx, 1200 / gy, 1.3);
        nx = @floatToInt(u31, gx * scale);
        ny = @floatToInt(u31, gy * scale);
    }

    var d_output = try Img2D([4]u8).init(nx, ny);
    var d_zbuffer = try Img2D(f32).init(nx, ny);
    // t2 = milliTimestamp();
    print("initialize buffers [{}ms]\n", .{t2 - t1});

    var windy = try Window.init(nx, ny);
    // TODO: window deinit()

    // t1 = milliTimestamp();
    const mima = im.minmax(f32, grey.img);
    print("mima = {d}\n", .{mima});
    // t2 = milliTimestamp();
    print("find min/max of f32 img [{}ms]\n", .{t2 - t1});

    // setup OpenCL Contex Queue
    // t1 = milliTimestamp();
    var dcqp = try DevCtxQueProg.init(temp, files);
    defer dcqp.deinit();
    // t2 = milliTimestamp();
    print("DevCtxQueProg.init [{}ms]\n", .{t2 - t1});

    // setup arguments for max-project Kernel
    // t1 = milliTimestamp();
    const colormap = cmapCool();
    var img_cl = try img2CLImg(grey, dcqp);
    var view = View{
        .view_matrix = .{ 1, 0, 0, 0, 1, 0, 0, 0, 1 },
        .front_scale = .{ 1.1, 1.1, 1 },
        .back_scale = .{ 2.3, 2.3, 1 },
        .anisotropy = .{ 1, 1, 4 },
        .screen_size = .{ nx, ny },
    };
    const volume_dims = [3]u16{ @intCast(u16, grey.nx), @intCast(u16, grey.ny), @intCast(u16, grey.nz) };
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

    const argtypes = &[_]ArgTypes{
        .nonbuf_write_once,
        .buffer_read_everytime,
        .buffer_read_everytime,
        .buffer_write_once,
        .nonbuf_write_once,
        .nonbuf_write_once,
        .nonbuf_write_once,
        .nonbuf_write_everytime,
        .nonbuf_write_once,
    };

    var kernel = try Kernel("max_project_float", argtypes).init(dcqp, args);
    defer kernel.deinit();
    // t2 = milliTimestamp();
    print("define kernel and args [{}ms]\n", .{t2 - t1});

    // t1 = milliTimestamp();
    try kernel.executeKernel(dcqp, args, &.{ nx, ny });
    // t2 = milliTimestamp();
    print("exec kernel [{}ms]\n", .{t2 - t1});

    const mima2 = blk: {
        var mn = [4]u8{ 0, 0, 0, 0 };
        var mx = [4]u8{ 0, 0, 0, 0 };
        for (d_output.img) |v| {
            for (v) |vi, i| {
                mn[i] = std.math.min(mn[i], vi);
                mx[i] = std.math.max(mx[i], vi);
            }
        }
        break :blk .{ .mn = mn, .mx = mx };
    };
    print("mima of d_output.img {any}\n", .{mima2});

    // Update window
    addBBox(d_output, view);

    windy.setPixels(d_output.img);
    try windy.update();

    // done with startup . time to run the app

    var running = true;

    var mouse = Mouse{
        .mousedown = false,
        // .mousePixbuffer = try temp.alloc([2]c_int, 10),
        .mouse_location = null,
        .loop_draw_mode = .view,
    };

    // var boxpts:[8]Vec2 = undefined;
    // var imgnamebuffer:[100]u8 = undefined;

    while (running) {
        var event: cc.SDL_Event = undefined;
        while (cc.SDL_PollEvent(&event) != 0) {
            switch (event.@"type") {
                cc.SDL_QUIT => {
                    running = false;
                },
                cc.SDL_KEYDOWN => {
                    switch (event.key.keysym.sym) {
                        cc.SDLK_q => {
                            running = false;
                        },
                        cc.SDLK_d => {
                            mouse.loop_draw_mode = .loop;
                        },
                        cc.SDLK_v => {
                            mouse.loop_draw_mode = .view;
                        },
                        cc.SDLK_r => {
                            mouse.loop_draw_mode = .rect;
                        },
                        cc.SDLK_x => {
                            // mouse.loop_draw_mode = .rect;
                            if (mouse.mousedown){
                                const x = mouse.mouse_location.?[0];
                                const y = mouse.mouse_location.?[1];
                                print("loc: {d}, {d} \t d_output.img: {d} \n",.{x,y,d_output.get(x,y).*});
                            }
                        },
                        cc.SDLK_RIGHT => {
                            view.view_matrix = matMulNNRowFirst(3, f32, view.view_matrix, delta.right);
                            windy.needs_update = true;
                        },
                        cc.SDLK_LEFT => {
                            view.view_matrix = matMulNNRowFirst(3, f32, view.view_matrix, delta.left);
                            windy.needs_update = true;
                            // print("view_angle {}\n", .{view_angle});
                        },
                        cc.SDLK_UP => {
                            view.view_matrix = matMulNNRowFirst(3, f32, view.view_matrix, delta.up);
                            windy.needs_update = true;
                            // print("view_angle {}\n", .{view_angle});
                        },
                        cc.SDLK_DOWN => {
                            view.view_matrix = matMulNNRowFirst(3, f32, view.view_matrix, delta.down);
                            windy.needs_update = true;
                            // print("view_angle {}\n", .{view_angle});
                        },
                        else => {},
                    }
                },
                cc.SDL_MOUSEBUTTONDOWN => {
                    mouse.mousedown = true;
                    // TODO: reset .loopInProgress
                    const px = @intCast(u31, event.button.x);
                    const py = @intCast(u31, event.button.y);
                    mouse.mouse_location = .{ px, py };

                    loops.temp_screen_loop_len = 0;
                    // loops.screen_loop.clearRetainingCapacity();
                },
                cc.SDL_MOUSEBUTTONUP => blk: {
                    mouse.mousedown = false;
                    mouse.mouse_location = null;

                    if (mouse.loop_draw_mode == .view) break :blk;

                    if (loops.temp_screen_loop_len < 3) break :blk;

                    try embedLoops(gpa.allocator(), loops.temp_screen_loop[0..loops.temp_screen_loop_len], view, d_zbuffer);
                    print("The number of total objects is {} \n", .{loops.volume_loop_max_index});
                },
                cc.SDL_MOUSEMOTION => blk: {
                    if (mouse.mousedown == false) break :blk;

                    const px = @intCast(u31, event.motion.x);
                    const py = @intCast(u31, event.motion.y);

                    // should never be null, we've already asserted `mousedown`
                    // if (mouse.mouse_location == null) {
                    //     mouse.mouse_location = .{ px, py };
                    //     break :blk;
                    // }

                    const x_old = mouse.mouse_location.?[0];
                    const y_old = mouse.mouse_location.?[1];
                    mouse.mouse_location.?[0] = px;
                    mouse.mouse_location.?[1] = py;

                    switch (mouse.loop_draw_mode) {
                        .loop => {
                            im.drawLine2(windy.pix, nx, x_old, y_old, px, py, colors.white);
                            try windy.update();
                            // loops.screen_loop.appendAssumeCapacity(.{ px, py });
                            loops.temp_screen_loop[loops.temp_screen_loop_len] = .{ px, py };
                            loops.temp_screen_loop_len += 1;
                        },
                        .view => {
                            mouseMoveCamera(px, py, x_old, y_old, &view);
                            windy.needs_update = true;
                        },
                        else => {},
                    }
                },
                else => {},
            }
        }

        if (windy.needs_update == false) {
            cc.SDL_Delay(16);
            continue;
        }

        windy.update_count += 1;

        // perform the render and update the window
        args = .{ img_cl, d_output.img, d_zbuffer.img, colormap, nx, ny, mima, view, volume_dims };
        try kernel.executeKernel(dcqp, args, &.{ nx, ny });
        // try blurfilter(gpa.allocator(), d_zbuffer);

        addBBox(d_output, view);
        drawLoops(d_output, view);

        windy.setPixels(d_output.img);
        try windy.update();
        windy.needs_update = false;

        // Save max projection result
        // const filename = try std.fmt.bufPrint(&imgnamebuffer, "output/t100_rendered_{d:0>3}.tga", .{update_count});
        // try im.saveF32AsTGAGreyNormed(d_output, @intCast(u16, ny), @intCast(u16, nx), filename);
    }

    return 0;
}

/// generate "cool" colormap
fn cmapCool() [256][4]u8 {
    var cmap: [256][4]u8 = undefined;
    const reds = piecewiseLinearInterpolation(256, &[_][3]f32{ .{ 0, 0, 0 }, .{ 1, 1, 1 } });
    const greens = piecewiseLinearInterpolation(256, &[_][3]f32{ .{ 0, 1, 1 }, .{ 1, 0, 0 } });
    const blues = piecewiseLinearInterpolation(256, &[_][3]f32{ .{ 0, 1, 1 }, .{ 1, 1, 1 } });
    for (cmap) |*r, i| {
        r.* = .{
            @floatToInt(u8, reds[i] * 255),
            @floatToInt(u8, greens[i] * 255),
            @floatToInt(u8, blues[i] * 255),
            255,
        };
    }
    return cmap;
}

/// Max of ten segments per color
// const LSCmap = struct {
//     red: [10]?[3]f32,
//     green: [10]?[3]f32,
//     blue: [10]?[3]f32,
// };

/// Follows matplotlib colormap convention for piecewise linear colormaps
fn piecewiseLinearInterpolation(comptime n: u16, pieces: []const [3]f32) [n]f32 {
    var res = [_]f32{0} ** n;
    var k: usize = 0;
    for (res) |*r, i| {
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

const V3 = @Vector(3, f32);
const V2 = @Vector(2, f32);
const U2 = @Vector(2, u32);

const View = struct {
    view_matrix: [9]f32, // orthonormal
    front_scale: V3,
    back_scale: V3,
    anisotropy: V3,
    screen_size: U2,
    theta: f32 = 0,
    phi: f32 = 0,
};

const Ray = struct { orig: V3, direc: V3 };

fn u22V2(x: U2) V2 {
    return V2{ @intToFloat(f32, x[0]), @intToFloat(f32, x[1]) };
}

/// define small rotations: right,left,up,down
const delta = struct {
    const c = @cos(@as(f32, 2.0) * std.math.pi / 32.0);
    const s = @sin(@as(f32, 2.0) * std.math.pi / 32.0);

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

/// maps a pixel on the camera to a ray that points into the image volume.
fn pixelToRay(view: View, pix: U2) Ray {
    const xy = u22V2(pix * U2{ 2, 2 }) / u22V2(view.screen_size + U2{ 1, 1 }) - V2{ 1, 1 }; // norm to [-1,1]
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

/// Maps a point inside the image volume in normalized [-1,1] coordinates
/// to a pixel on the camera.
fn pointToPixel(view: View, _pt: V3) V2 {

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

test "test pointToPixel" {
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
        const r = pixelToRay(view, px0);
        const y = r.orig + V3{ 4, 4, 4 } * r.direc;
        const pix = pointToPixel(view, y);
        const px1 = U2{ @floatToInt(u32, @floor(pix[0])), @floatToInt(u32, @floor(pix[1])) };
        try expect(@reduce(.And, px0 == px1));
    }

    {
        const px0 = U2{ 100, 200 };
        const r = pixelToRay(view, px0);
        const y = r.orig + V3{ 4, 4, 4 } * r.direc;
        const pix = pointToPixel(view, y);
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
        const r = pixelToRay(view, px0);
        const y = r.orig + V3{ 4, 4, 4 } * r.direc;
        const pix = pointToPixel(view, y);
        const px1 = U2{ @floatToInt(u32, @floor(pix[0])), @floatToInt(u32, @floor(pix[1])) };
        expect(@reduce(.And, px0 == px1)) catch {
            print("pix {} fail\n", .{px0});
        };
    }
}

fn v22U2(x: V2) U2 {
    return U2{ @floatToInt(u32, std.math.clamp(x[0], 0, 1e6)), @floatToInt(u32, std.math.clamp(x[1], 0, 1e6)) };
}

fn addBBox(img: Img2D([4]u8), view: View) void {
    const lines = [_][2]V3{
        // draw along x
        .{ .{ -1, -1, -1 }, .{ 1, -1, -1 } },
        .{ .{ -1, 1, -1 }, .{ 1, 1, -1 } },
        .{ .{ -1, 1, 1 }, .{ 1, 1, 1 } },
        .{ .{ -1, -1, 1 }, .{ 1, -1, 1 } },

        // draw along y
        .{ .{ -1, -1, -1 }, .{ -1, 1, -1 } },
        .{ .{ -1, -1, 1 }, .{ -1, 1, 1 } },
        .{ .{ 1, -1, -1 }, .{ 1, 1, -1 } },
        .{ .{ 1, -1, 1 }, .{ 1, 1, 1 } },

        // draw along z
        .{ .{ -1, -1, -1 }, .{ -1, -1, 1 } },
        .{ .{ -1, 1, -1 }, .{ -1, 1, 1 } },
        .{ .{ 1, -1, -1 }, .{ 1, -1, 1 } },
        .{ .{ 1, 1, -1 }, .{ 1, 1, 1 } },
    };

    inline for (lines) |x0x1| {
        const x0 = pointToPixel(view, x0x1[0]);
        const x1 = pointToPixel(view, x0x1[1]);
        im.drawLineInBounds(
            [4]u8,
            img,
            @floatToInt(i32, x0[0]),
            @floatToInt(i32, x0[1]),
            @floatToInt(i32, x1[0]),
            @floatToInt(i32, x1[1]),
            colors.white,
        );
    }
}

/// create white bounding box around image volume
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

    print("\n{}\n", .{pixelToRay(view, .{ 120, 120 })});
}

fn normV3(x: V3) V3 {
    const s = @sqrt(@reduce(.Add, x * x));
    return x / V3{ s, s, s };
}

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

test "test TIFF vs raw speed" {
    // pub fn main() !void {
    print("\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var al = gpa.allocator();
    const testtifname = "/Users/broaddus/Desktop/mpi-remote/project-broaddus/rawdata/celegans_isbi/Fluo-N3DH-CE/01/t100.tif";

    var t1: i64 = undefined;
    var t2: i64 = undefined;

    t1 = milliTimestamp();
    const img = try readTIFF3D(al, testtifname);
    t2 = milliTimestamp();
    print("readTIFF3D {d} ms \n", .{t2 - t1});

    t1 = milliTimestamp();
    try img.save("raw.img");
    t2 = milliTimestamp();
    print("save img {d} ms \n", .{t2 - t1});

    t1 = milliTimestamp();
    const img2 = try Img3D(f32).load("raw.img");
    t2 = milliTimestamp();
    print("load raw {d} ms \n", .{t2 - t1});

    try expect(eql(f32, img.img, img2.img));

    // does it help to use f16 ?

    const img3 = try Img3D(f16).init(img.nx, img.ny, img.nz);
    for (img3.img) |*v, i| v.* = @floatCast(f16, img.img[i]);

    t1 = milliTimestamp();
    try img3.save("raw.img");
    t2 = milliTimestamp();
    print("save img f16 {d} ms \n", .{t2 - t1});

    t1 = milliTimestamp();
    _ = try Img3D(f16).load("raw.img");
    t2 = milliTimestamp();
    print("load raw f16 {d} ms \n", .{t2 - t1});
}

// IMAGE FILTERS  IMAGE FILTERS  IMAGE FILTERS  IMAGE FILTERS  IMAGE FILTERS  IMAGE FILTERS
// IMAGE FILTERS  IMAGE FILTERS  IMAGE FILTERS  IMAGE FILTERS  IMAGE FILTERS  IMAGE FILTERS
// IMAGE FILTERS  IMAGE FILTERS  IMAGE FILTERS  IMAGE FILTERS  IMAGE FILTERS  IMAGE FILTERS

// XY format . TODO: ensure inline ?
pub inline fn inbounds(img: anytype, px: anytype) bool {
    if (0 <= px[0] and px[0] < img.nx and 0 <= px[1] and px[1] < img.ny) return true else return false;
}

// Run a simple min-kernel over the image to remove noise.
fn minfilter(al: std.mem.Allocator, img: Img2D(f32)) !void {
    const nx = img.nx;
    // const ny = img.ny;
    const s = img.img; // source
    const t = try al.alloc(f32, s.len); // target
    defer al.free(t);
    const deltas = [_]@Vector(2, i32){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 0 } };

    for (s) |_, i| {
        // const i = @intCast(u32,_i);
        var mn = s[i];
        const px = @Vector(2, i32){ @intCast(i32, i % nx), @intCast(i32, i / nx) };
        for (deltas) |dpx| {
            const p = px + dpx;
            const v = if (inbounds(img, p)) s[@intCast(u32, p[0]) + nx * @intCast(u32, p[1])] else 0;
            mn = std.math.min(mn, v);
        }
        t[i] = mn;
    }

    // for (s) |_,i| {
    // }
    for (img.img) |*v, i| {
        v.* = t[i];
    }
}

// Run a simple min-kernel over the image to remove noise.
fn blurfilter(al: std.mem.Allocator, img: Img2D(f32)) !void {
    const nx = img.nx;
    // const ny = img.ny;
    const s = img.img; // source
    const t = try al.alloc(f32, s.len); // target
    defer al.free(t);
    const deltas = [_]@Vector(2, i32){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 0 } };

    for (s) |_, i| {
        // const i = @intCast(u32,_i);
        var x = @as(f32, 0); //s[i];
        const px = @Vector(2, i32){ @intCast(i32, i % nx), @intCast(i32, i / nx) };
        for (deltas) |dpx| {
            const p = px + dpx;
            const v = if (inbounds(img, p)) s[@intCast(u32, p[0]) + nx * @intCast(u32, p[1])] else 0;
            x += v;
        }
        t[i] = x / 5;
    }

    // for (s) |_,i| {
    // }
    for (img.img) |*v, i| {
        v.* = t[i];
    }
}

/// update camera position in (theta, phi) coordinates from mouse movement.
/// determine transformation matrix from camera location.
fn mouseMoveCamera(x: i32, y: i32, x_old: i32, y_old: i32, view: *View) void {
    if (x == x_old and y == y_old) return;

    const mouseDiffX = @intToFloat(f32, x - x_old);
    const mouseDiffY = @intToFloat(f32, y - y_old);

    view.theta += mouseDiffX / 200.0;
    view.phi += mouseDiffY / 200.0;
    view.phi = std.math.clamp(view.phi, -3.1415 / 2.0, 3.1415 / 2.0);

    // view.view_matrix = lookAtOrigin(cam, .ZYX);
    view.view_matrix = viewmatrix_from_theta_phi(view.theta, view.phi);
}

fn sliceL2Norm(arr: anytype) f32 {
    var sum: f32 = 0;
    for (arr) |v| sum += v * v;
    return @sqrt(sum);
}

// find determinant of 3x3 matrix?
pub fn det(mat: Mat3x3) f32 {
    const a = V3{ mat[0], mat[1], mat[2] };
    const b = V3{ mat[3], mat[4], mat[5] };
    const c = V3{ mat[6], mat[7], mat[8] };
    return dot(a, cross(b, c)); // determinant of 3x3 matrix is equal to scalar triple product
}

// const AxisOrder = enum { XYZ, ZYX };
const Mat3x3 = [9]f32;

/// direct computation of view matrix (rotation matrix) from theta,phi position on unit sphere
/// in spherical coordinates in Left Handed coordinate system with r(theta=0,phi=0) = -z !
/// x' =  norm (dr/d_theta)
/// y' =  dr/d_phi
/// z' = -r(theta,phi)'
fn viewmatrix_from_theta_phi(theta: f32, phi: f32) [9]f32 {
    const x = normV3(V3{ @cos(theta) * @cos(phi), 0, @sin(theta) * @cos(phi) }); // x
    const y = V3{ -@sin(theta) * @sin(phi), @cos(phi), @cos(theta) * @sin(phi) }; // y
    const z = V3{ -@sin(theta) * @cos(phi), -@sin(phi), @cos(theta) * @cos(phi) }; // z
    const m = matFromVecs(x, y, z);
    return m;
}

pub fn matFromVecs(v0: [3]f32, v1: [3]f32, v2: [3]f32) Mat3x3 {
    return Mat3x3{ v0[0], v0[1], v0[2], v1[0], v1[1], v1[2], v2[0], v2[1], v2[2] };
}

// pass in pointer-to-array or slice
// fn reverse_inplace(array_ptr: anytype) void {
//     var array = array_ptr.*;
//     var temp = array[0];
//     const n = array.len;
//     var i: usize = 0;

//     while (i < @divFloor(n, 2)) : (i += 1) {
//         temp = array[i];
//         array[i] = array[n - i - 1];
//         array[n - i - 1] = temp;
//     }
// }

