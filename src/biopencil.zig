const std = @import("std");

const mp = @import("opencl-maxproj.zig");
const im = @import("image_base.zig");
const print = std.debug.print;
const assert = std.debug.assert;
const expect = std.testing.expect;
const eql = std.mem.eql;
const min = std.math.min;
const max = std.math.max;

const milliTimestamp = std.time.milliTimestamp;

const Img2D = im.Img2D;
const Img3D = im.Img3D;

const cc = struct {
    pub const tiffio = @cImport({
        @cInclude("tiffio.h");
    });

    pub usingnamespace @cImport({
        @cInclude("SDL.h");
    });
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
        datatype: u32,
        bitspersample: u32,
        samplesperpixel: u32,
        imagewidth: u32,
        rowsperstrip: u32,
        imagelength: u32,
        n_strips: u32,
        n_directories: u32,
        scanline_size: u64,
    };

    var meta = std.mem.zeroInit(Meta, .{});
    // var meta: Meta = undefined;

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
    for (pic.img, 0..) |*v, i| {
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

    for (sl, 0..) |pt, i| {
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
    for (vl, 0..) |pt3, i| {
        loops.temp_screen_loop[i] = v22U2(pointToPixel(view, pt3));
        // loops.screen_loop.appendAssumeCapacity(v22U2(pointToPixel(view, pt3)));
    }
    const n = vl.len;
    loops.temp_screen_loop_len = n;
    return loops.temp_screen_loop[0..n];
}

/// embed ScreenLoop inside volume with normalized coords [-1,1]^3
///  since our data is noisy, we can't always expect that the maxval of the intensity is from
///  the object we intend. we could deal with this by _denoising_ the loop depth or the image depth buffer.
fn embedLoopAndSave(loop: ScreenLoop, view: View, depth_buffer: Img2D(f32)) !void {

    // NOTE: we're looping over pixel knots in our Loop, but this does not include pixels drawn interpolated between knot points.
    var depth_mean = @as(f32, 0);
    for (loop) |v| {
        var depth = depth_buffer.get(v[0], v[1]).*; // in [0,1] coords
        depth_mean += depth;
    }
    depth_mean /= @intToFloat(f32, loop.len);

    // var filtered_positions = try al.alloc([3]f32, 900);
    var filtered_positions: [900][3]f32 = undefined;
    // defer al.free(filtered_positions);
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

    var floatPosActual = loops.addNewSlice(@intCast(u16, vertex_count));
    for (floatPosActual, 0..) |*v, i| v.* = filtered_positions[i];
}

const colors = struct {
    const white = [4]u8{ 255, 255, 255, 255 };
    const red = [4]u8{ 0, 0, 255, 255 };
    const yellow = [4]u8{ 0, 255, 0, 255 };
    const blue = [4]u8{ 255, 0, 0, 255 };
};

fn drawLoops(d_output: Img2D([4]u8), view: View) void {

    // for each loop in loop_collection we know the internal coordinates (in [-1,1]) and
    // can compute the coordinates in the pixel space of the surface using pointToPixel()
    // then we can draw them connected with lines.
    var i: u16 = 0;
    while (i < loops.volume_loop_max_index) : (i += 1) {
        const vl = loops.getVolumeLoopAtIndex(i);
        const sl = volumeLoop2ScreenLoop(view, vl);
        drawScreenLoop(sl, d_output);
    }
}

const loops = struct {

    // This buffer stores pixel locations as a loop is being drawn before it's embeded and saved.
    // It also stores pixel locations as a loop is converted from []V3 -> []U2 before it's drawn to screen.
    var temp_screen_loop: [10_000][2]u32 = undefined; // will crash if a screen loop exceeds 10_000 points (at 16ms frame rate that's 160s of drawing)
    var temp_screen_loop_len: usize = 0;

    // Buffer that stores 3D coordinates of knots that form Loops.
    // Works like a simple memory allocator for []V3 slices.
    var volume_loop_mem: [1000 * 100][3]f32 = undefined; // 1000 loops * 100 avg-loop-length
    var volume_loop_indices = [_]usize{0} ** 1000; // up to 1000 indices into loop memory
    var volume_loop_max_index: usize = 0; // number of indices currently in use

    pub fn getVolumeLoopAtIndex(n: u16) VolumeLoop {
        return volume_loop_mem[volume_loop_indices[n]..volume_loop_indices[n + 1]];
    }

    pub fn addNewSlice(nitems: u16) [][3]f32 {
        const idx0 = volume_loop_indices[volume_loop_max_index];
        const idx1 = idx0 + nitems;
        volume_loop_indices[volume_loop_max_index + 1] = idx1;
        volume_loop_max_index += 1;
        return volume_loop_mem[idx0..idx1];
    }

    pub fn save(name: []const u8) !void {
        const file = try std.fs.cwd().createFile(name, .{});
        defer file.close();
        const writer = file.writer();

        try writer.writeIntLittle(usize, volume_loop_max_index);
        try writer.writeAll(std.mem.sliceAsBytes(&volume_loop_indices));
        try writer.writeAll(std.mem.sliceAsBytes(&volume_loop_mem));
    }

    /// returns false if file doesn't exist
    pub fn load(name: []const u8) !void {
        const file = try std.fs.cwd().openFile(name, .{});
        defer file.close();
        const reader = file.reader();

        volume_loop_max_index = try reader.readIntLittle(usize);
        for (&volume_loop_indices) |*v| v.* = try reader.readIntLittle(usize);
        _ = try reader.readAll(std.mem.sliceAsBytes(&volume_loop_mem));

        // return error.Success;
        // return true;
        // try writer.writeIntLittle(usize,temp_screen_loop_len);
        // try writer.writeAll(std.mem.sliceAsBytes(&volume_loop_indices));
        // try writer.writeAll(std.mem.sliceAsBytes(&volume_loop_mem));
    }

    // pub fn handleMouseDown() {}
    // pub fn handleMouseUp() {}
    // pub fn handleMouseMove() {}
};

test "test read write loops" {
    const s1 = loops.addNewSlice(100);
    for (s1) |*v| v.* = .{ 0.9, 0.8, 0.7 };
    // const name = "testfile.loops";
    try loops.save("testfile.loops");
    _ = try loops.load("testfile.loops");
    try loops.save("testfile2.loops");
}

const rects = struct {
    // var temp_screen_rect: [2]U2 = undefined;
    // var rect_being_drawn_vertex0: [2]u31 = .{0,0};
    var volume_pixel_aligned_bboxes: [100][3]U2 = undefined;
    var volume_pixel_aligned_bbox_count: usize = 0;

    fn onMouseDown() void {}
    fn onMouseUp() void {}
    fn onMouseMove() void {}
};

const app = struct {
    var running = true;
    const ViewMode = enum { view, loop, rect };
    var loop_draw_mode: ViewMode = .view;
    var rectmode: enum { blue, resize } = .blue;
};

test "test window creation" {
    const win = try Window.init(1000, 800);
    try win.update();
}

const SDL_WINDOWPOS_UNDEFINED = @bitCast(c_int, cc.SDL_WINDOWPOS_UNDEFINED_MASK);

/// For some reason, this isn't parsed automatically. According to SDL docs, the
/// surface pointer returned is optional!
extern fn SDL_GetWindowSurface(window: *cc.SDL_Window) ?*cc.SDL_Surface;

const Window = struct {
    sdl_window: *cc.SDL_Window,
    surface: *cc.SDL_Surface,
    // pix: [*c][4]u8,
    // pix: [][4]u8,
    pix: Img2D([4]u8),

    needs_update: bool,
    update_count: u64,
    windowID: u32,
    nx: u32,
    ny: u32,

    const This = @This();

    /// WARNING: c managed heap memory mixed with our custom allocator
    fn init(nx: u32, ny: u32) !This {
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
        var pix: [][4]u8 = undefined;
        pix.ptr = @ptrCast([*][4]u8, surface.pixels.?);
        pix.len = nx * ny;

        var img = Img2D([4]u8){
            .img = pix,
            .nx = nx,
            .ny = ny,
        };

        const res = .{
            .sdl_window = window,
            .surface = surface,
            // .pix = @ptrCast([*c][4]u8, surface.pixels.?),
            // .pix = pix,
            .pix = img,
            .needs_update = false,
            .update_count = 0,
            .windowID = cc.SDL_GetWindowID(window),
            .nx = nx,
            .ny = ny,
        };

        res.pix.img[50] = .{ 255, 255, 255, 255 };
        res.pix.img[51] = .{ 255, 255, 255, 255 };
        res.pix.img[52] = .{ 255, 255, 255, 255 };
        res.pix.img[53] = .{ 255, 255, 255, 255 };

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
        for (buffer, 0..) |v, i| {
            this.pix.img[i] = v;
        }
        cc.SDL_UnlockSurface(this.surface);
    }

    fn setPixelsFromRectangle(this: *This, img: Img2D([4]u8), r: Rect) void {
        _ = cc.SDL_LockSurface(this.surface);

        const x_zoom = @intToFloat(f32, this.nx) / @intToFloat(f32, r.xmax - r.xmin);
        const y_zoom = @intToFloat(f32, this.ny) / @intToFloat(f32, r.ymax - r.ymin);

        for (this.pix.img, 0..) |*w, i| {
            const x_idx = r.xmin + divFloorIntByFloat(i % this.nx, x_zoom);
            const y_idx = r.ymin + divFloorIntByFloat(@divFloor(i, this.nx), y_zoom);
            const v = img.get(x_idx, y_idx).*;
            w.* = v;
        }
        cc.SDL_UnlockSurface(this.surface);
    }
};

fn divFloorIntByFloat(numerator: anytype, denom: anytype) @TypeOf(numerator) {
    const T1 = @TypeOf(numerator);
    const T2 = @TypeOf(denom);
    return @floatToInt(T1, @intToFloat(T2, numerator) / denom);
}

const I2 = @Vector(2, i32);
const Rect2 = struct { r0: I2, dr: I2 };

fn rect2ToRect(r: Rect2) Rect {
    return sortRect(Rect{ .xmin = @intCast(u32, r.r0[0]), .xmax = @intCast(u32, r.r0[0] + r.dr[0]), .ymin = @intCast(u32, r.r0[1]), .ymax = @intCast(u32, r.r0[1] + r.dr[1]) });
}

fn rectToRect2(r: Rect) Rect2 {
    return Rect2{ .r0 = .{ r.xmin, r.ymin }, .dr = .{ r.xmax - r.xmin, r.ymax - r.ymin } };
}

// NOTE: we add the `sorted` flag to help avoid manual creation of Rect{...} without first sorting.
const Rect = struct { xmin: u32, xmax: u32, ymin: u32, ymax: u32, sorted: bool = false };

fn sortRect(r0: Rect) Rect {
    return .{ .xmin = min(r0.xmin, r0.xmax), .xmax = max(r0.xmin, r0.xmax), .ymin = min(r0.ymin, r0.ymax), .ymax = max(r0.ymin, r0.ymax), .sorted = true };
}

fn abs(num: anytype) @TypeOf(num) {
    // const T = @TypeOf(num);
    // comptime assert(im.isin())
    if (num < 0) return -num;
    return num;
}

///
///  Load and Render TIFF with OpenCL and SDL.
///
pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const temp_allo = gpa.allocator();

    // temporary stack allocator
    // TODO: why use an arena? do we have to allocate in-the-loop? no.
    // And even if we did we wouldn't we want
    // var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    // defer arena.deinit();
    // const temp_allo = arena.allocator();

    var t1: i64 = undefined;
    var t2: i64 = undefined;

    const filename = blk: {
        const testtifname = "/Users/broaddus/Desktop/mpi-remote/project-broaddus/rawdata/celegans_isbi/Fluo-N3DH-CE/01/t100.tif";
        var arg_it = try std.process.argsWithAllocator(temp_allo);
        _ = arg_it.skip(); // skip exe name
        break :blk arg_it.next() orelse testtifname; // zig10.x version
        // break :blk try (arg_it.next(temp) orelse testtifname); // zig0.9.x version
    };

    // Load TIFF image
    t1 = milliTimestamp();
    const grey = try readTIFF3D(temp_allo, filename);
    t2 = milliTimestamp();
    print("load TIFF and convert to f32 [{}ms]\n", .{t2 - t1});

    // Setup SDL & open window
    t1 = milliTimestamp();
    if (cc.SDL_Init(cc.SDL_INIT_VIDEO) != 0) {
        cc.SDL_Log("Unable to initialize SDL: %s", cc.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer cc.SDL_Quit();
    t2 = milliTimestamp();
    print("SDL_Init [{}ms]\n", .{t2 - t1});

    t1 = milliTimestamp();

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
    t2 = milliTimestamp();
    print("initialize buffers [{}ms]\n", .{t2 - t1});

    // orthogonal window
    var windy_ortho = try Window.init(grey.nx, grey.ny);
    const windy_ortho_projection = try maxProjectionOrtho(grey);
    const windy_ortho_projection_rgba = try intensityToRGBA(windy_ortho_projection);
    windy_ortho.setPixels(windy_ortho_projection_rgba.img);
    try windy_ortho.update();

    // small window
    var windy_ortho_small = try Window.init(256, 256);
    // var blue_rectangle = Rect{ .xmin = 0, .ymin = 0, .xmax = 256, .ymax = 256, .sorted = true };
    var blue_rectangle = Rect2{ .r0 = .{ 0, 0 }, .dr = .{ 128, 128 } };

    // 3D window
    var windy = try Window.init(nx, ny);

    cc.SDL_SetWindowPosition(windy.sdl_window, 0, 0);
    cc.SDL_SetWindowPosition(windy_ortho.sdl_window, nx, 0);
    cc.SDL_SetWindowPosition(windy_ortho_small.sdl_window, nx, ny);

    // done with window creation

    var view = View{
        .view_matrix = .{ 1, 0, 0, 0, 1, 0, 0, 0, 1 },
        .front_scale = .{ 1.1, 1.1, 1 },
        .back_scale = .{ 2.3, 2.3, 1 },
        .anisotropy = .{ 1, 1, 4 },
        .screen_size = .{ nx, ny },
    };

    // var renderer = try mp.buildKernelMaxProj(temp_allo, grey, d_output, d_zbuffer, view);

    // const files = &[_][]const u8{"volumecaster.cl"};
    // var dcqp = try mp.DevCtxQueProg.init(temp_allo, files);
    // _ = dcqp;

    // Do first rendering
    try mp.reexecuteKernel(temp_allo, null, grey, d_output, d_zbuffer, view);

    // Update window
    const err = loops.load("loopfile.loops");
    if (err) |_| {
        print("File Found . Loading Loops . \n", .{});
        drawLoops(d_output, view);
    } else |e| {
        print("File Not Found? {!} \n", .{e});
    }

    addBBox(d_output, view);
    windy.setPixels(d_output.img);
    try windy.update();

    // done with startup . time to run the app

    // WARNING: can't move this to global scope or zig10_4060 breaks!
    const Mouse = struct {
        mousedown: bool,
        mouse_location: ?[2]u31,
    };

    var app_mouse = Mouse{
        .mousedown = false,
        .mouse_location = null,
    };

    var rect_being_drawn_vertex0: [2]u31 = undefined; // this is

    // var boxpts:[8]Vec2 = undefined;
    // var imgnamebuffer:[100]u8 = undefined;

    while (app.running) {

        // Poll Events and allow the user to interact with windows.
        var event: cc.SDL_Event = undefined;
        while (cc.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                cc.SDL_QUIT => {
                    app.running = false;
                },
                cc.SDL_KEYDOWN => {
                    switch (event.key.keysym.sym) {
                        cc.SDLK_q => {
                            print("Saving... volume_loop_max_index is : {d} \n", .{loops.volume_loop_max_index});
                            try loops.save("loopfile.loops");
                            app.running = false;
                        },
                        cc.SDLK_s => {
                            print("Saving... volume_loop_max_index is : {d} \n", .{loops.volume_loop_max_index});
                            try loops.save("loopfile.loops");
                        },
                        cc.SDLK_d => {
                            app.loop_draw_mode = .loop;
                        },
                        cc.SDLK_v => {
                            app.loop_draw_mode = .view;
                        },
                        cc.SDLK_r => {
                            app.loop_draw_mode = .rect;
                            app.rectmode = switch (app.rectmode) {
                                .blue => .resize,
                                .resize => .blue,
                            };
                        },
                        cc.SDLK_x => blk: {
                            // app.loop_draw_mode = .rect;
                            if (event.key.windowID != windy.windowID) break :blk;
                            if (app_mouse.mousedown) {
                                const x = app_mouse.mouse_location.?[0];
                                const y = app_mouse.mouse_location.?[1];
                                print("loc: {d}, {d} \t d_output.img: {d} \n", .{ x, y, d_output.get(x, y).* });
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
                    app_mouse.mousedown = true;
                    // TODO: reset .loopInProgress
                    const px = @intCast(u31, event.button.x);
                    const py = @intCast(u31, event.button.y);
                    app_mouse.mouse_location = .{ px, py };

                    rect_being_drawn_vertex0 = [2]u31{ px, py };

                    loops.temp_screen_loop_len = 0;
                },
                cc.SDL_MOUSEBUTTONUP => blk: {
                    app_mouse.mousedown = false;
                    app_mouse.mouse_location = null;

                    if (app.loop_draw_mode == .view) break :blk;
                    if (loops.temp_screen_loop_len < 3) break :blk;

                    try embedLoopAndSave(loops.temp_screen_loop[0..loops.temp_screen_loop_len], view, d_zbuffer);
                    print("The number of total objects is {} \n", .{loops.volume_loop_max_index});
                },
                cc.SDL_MOUSEMOTION => blk: {
                    if (app_mouse.mousedown == false) break :blk;

                    const px = @intCast(u31, clip(event.motion.x, 0, nx));
                    const py = @intCast(u31, clip(event.motion.y, 0, ny));

                    // should never be null, we've already asserted `mousedown`
                    assert(app_mouse.mouse_location != null);

                    const x_old = app_mouse.mouse_location.?[0];
                    const y_old = app_mouse.mouse_location.?[1];

                    // if (euclideanSquared(px, py, x_old, y_old) < 5) break :blk;

                    app_mouse.mouse_location.?[0] = px;
                    app_mouse.mouse_location.?[1] = py;

                    switch (app.loop_draw_mode) {
                        .loop => blk2: {
                            if (event.motion.windowID != windy.windowID) break :blk2;
                            // im.drawLine2(windy.pix, nx, x_old, y_old, px, py, colors.white);
                            im.drawLineInBounds([4]u8, windy.pix, x_old, y_old, px, py, colors.white);
                            try windy.update();
                            loops.temp_screen_loop[loops.temp_screen_loop_len] = .{ px, py };
                            loops.temp_screen_loop_len += 1;
                        },
                        .rect => blk2: {
                            if (event.motion.windowID != windy_ortho.windowID) break :blk2;

                            // windy.setPixels(d_output.img); // bounding box already written to d_output.img!
                            windy_ortho.setPixels(windy_ortho_projection_rgba.img);
                            switch (app.rectmode) {
                                .blue => {
                                    blue_rectangle.r0 = .{ px, py };
                                    const x_width = abs(blue_rectangle.dr[0]);
                                    const y_width = abs(blue_rectangle.dr[1]);
                                    const x_halfwidth = @divFloor(x_width, 2);
                                    const y_halfwidth = @divFloor(y_width, 2);
                                    blue_rectangle.r0 -= I2{ x_halfwidth, y_halfwidth };
                                    blue_rectangle.r0[0] = std.math.clamp(blue_rectangle.r0[0], 0, @intCast(i32, windy_ortho.nx) - x_width - 1);
                                    blue_rectangle.r0[1] = std.math.clamp(blue_rectangle.r0[1], 0, @intCast(i32, windy_ortho.ny) - y_width - 1);
                                    drawRectangle2(windy_ortho, blue_rectangle, colors.blue);
                                    windy_ortho_small.setPixelsFromRectangle(windy_ortho_projection_rgba, rect2ToRect(blue_rectangle));
                                    try windy_ortho_small.update();
                                },
                                .resize => {
                                    blue_rectangle.dr = I2{ px, py } - blue_rectangle.r0;
                                    drawRectangle2(windy_ortho, blue_rectangle, colors.blue);
                                    windy_ortho_small.setPixelsFromRectangle(windy_ortho_projection_rgba, rect2ToRect(blue_rectangle));
                                    try windy_ortho_small.update();
                                },
                            }
                            try windy_ortho.update();
                        },
                        .view => blk2: {
                            if (event.motion.windowID != windy.windowID) break :blk2;
                            mouseMoveCamera(px, py, x_old, y_old, &view);
                            windy.needs_update = true;
                        },
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
        try mp.reexecuteKernel(temp_allo, null, grey, d_output, d_zbuffer, view);
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

fn drawRectangle2(window: Window, r: Rect2, color: [4]u8) void {
    const x0 = @intCast(u31, r.r0[0]);
    const x1 = @intCast(u31, r.r0[0] + r.dr[0]);
    const y0 = @intCast(u31, r.r0[1]);
    const y1 = @intCast(u31, r.r0[1] + r.dr[1]);
    im.drawLineInBounds([4]u8, window.pix, x0, y0, x1, y0, color);
    im.drawLineInBounds([4]u8, window.pix, x0, y0, x0, y1, color);
    im.drawLineInBounds([4]u8, window.pix, x1, y1, x1, y0, color);
    im.drawLineInBounds([4]u8, window.pix, x1, y1, x0, y1, color);
}

fn drawRectangle(window: Window, r: Rect, color: [4]u8) void {
    // const _nx = @intCast(u31, window.nx);
    const x0 = @intCast(u31, r.xmin);
    const x1 = @intCast(u31, r.xmax);
    const y0 = @intCast(u31, r.ymin);
    const y1 = @intCast(u31, r.ymax);
    im.drawLineInBounds([4]u8, window.pix, x0, y0, x1, y0, color);
    im.drawLineInBounds([4]u8, window.pix, x0, y0, x0, y1, color);
    im.drawLineInBounds([4]u8, window.pix, x1, y1, x1, y0, color);
    im.drawLineInBounds([4]u8, window.pix, x1, y1, x0, y1, color);
}

fn intensityToRGBA(img: Img2D(f32)) !Img2D([4]u8) {
    const mima = im.minmax(f32, img.img);
    const res = try Img2D([4]u8).init(img.nx, img.ny);
    for (img.img, 0..) |v, i| {
        const v_rescaled = @floatToInt(u8, (v - mima[0]) / (mima[1] - mima[0]) * 255);
        res.img[i] = [4]u8{ v_rescaled, v_rescaled, v_rescaled, 255 };
    }
    return res;
}

fn maxProjectionOrtho(img: Img3D(f32)) !Img2D(f32) {
    const res = try Img2D(f32).init(img.nx, img.ny);
    for (img.img, 0..) |v, i| {
        const x = i % img.nx;
        const y = @divFloor(i, img.nx) % img.ny; //
        // const z = @divFloor(i, img.nx * img.ny) & img.nz; // mod nz shouldn't be necessary
        const w_ptr = res.get(x, y);
        // const val0
        if (w_ptr.* < v) w_ptr.* = v;
    }
    return res;
}

fn euclideanSquared(x0: i32, y0: i32, x1: i32, y1: i32) f32 {
    const x = @intToFloat(f32, x0 - x1);
    const y = @intToFloat(f32, y0 - y1);
    return x * x + y * y;
}

const V3 = @Vector(3, f32);
const V2 = @Vector(2, f32);
const U2 = @Vector(2, u32);

// WARNING: OpenCL Requires `extern` and crashes without it.
pub const View = extern struct {
    view_matrix: [9]f32, // orthonormal
    front_scale: V3,
    back_scale: V3,
    anisotropy: V3,
    screen_size: U2,
    theta: f32 = 0,
    phi: f32 = 0,
};

// typedef struct {
//   float view_matrix[9] ;
//   float3 front_scale ;
//   float3 back_scale ;
//   float3 anisotropy ;
//   uint2 screen_size ;
//   float theta;
//   float phi;
// }  View ;

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

    for (img.img, 0..) |*v, i| {
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

fn clip(val: anytype, lo: @TypeOf(val), hi: @TypeOf(val)) @TypeOf(val) {
    if (val < lo) return lo;
    if (val > hi) return hi;
    return val;
}

/// Requires XYZ order (or some rotation thereof)
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
    // comptime {}

    inline for (&result, 0..) |*c, k| {
        comptime var i = (k / n) * n;
        comptime var j = k % n;
        comptime var m = 0;
        inline while (m < n) : (m += 1) {
            c.* += left[i + m] * right[j + m * n];
            // @compileLog(i + m, j + m * n);
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
    for (img3.img, 0..) |*v, i| v.* = @floatCast(f16, img.img[i]);

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
    view.view_matrix = viewMatrixFromThetaPhi(view.theta, view.phi);
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
fn viewMatrixFromThetaPhi(theta: f32, phi: f32) [9]f32 {
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
