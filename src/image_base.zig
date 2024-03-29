const std = @import("std");
// const warn = std.debug.warn;
const print = std.debug.print;
const expect = std.testing.expect;
const assert = std.debug.assert;

const Allocator = std.mem.Allocator;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var al = gpa.allocator();
const eql = std.mem.eql;

test {
    std.testing.refAllDecls(@This());
    al = std.testing.allocator;
}

pub fn Img2D(comptime T: type) type {
    return struct {
        const pixtype = T;
        const This = @This();

        img: []T,
        nx: u32,
        ny: u32,

        pub fn init(nx: u32, ny: u32) !This {
            return This{
                .img = try al.alloc(T, nx * ny),
                .nx = nx,
                .ny = ny,
            };
        }

        pub inline fn get(this: This, x: usize, y: usize) *T {
            return &this.img[this.nx * y + x];
        }

        pub fn deinit(this: This) void {
            al.free(this.img);
        }
    };
}

test "test imageBase. new img2d" {
    const mimg = Img2D(f32){
        .img = try al.alloc(f32, 100 * 100),
        .nx = 100,
        .ny = 100,
    };
    defer mimg.deinit();
    // print("mimg {d}", .{mimg.nx});

    const bimg = try Img2D(f32).init(100, 100);
    defer bimg.deinit();
}

pub fn Img3D(comptime T: type) type {
    return struct {
        const pixtype = T;
        const This = @This();
        img: []T,
        nz: u32,
        ny: u32,
        nx: u32,

        pub fn init(nx: u32, ny: u32, nz: u32) !This {
            return This{
                .img = try al.alloc(T, nx * ny * nz),
                .nx = nx,
                .ny = ny,
                .nz = nz,
            };
        }

        pub fn deinit(this: This) void {
            al.free(this.img);
        }

        pub inline fn get(this: This, x: usize, y: usize, z: usize) *T {
            return &this.img[this.nx * this.ny * z + this.nx * y + x];
        }

        pub fn save(this: This, name: []const u8) !void {
            const file = try std.fs.cwd().createFile(name, .{});
            defer file.close();

            var writer = file.writer();

            // try writer.writeAll(&[_]u8{
            //     0, // ID length
            //     0, // No color map
            //     2, // Unmapped RGB
            // });

            try writer.writeIntLittle(u32, this.nx); //u16, @truncate(u16, self.width));
            try writer.writeIntLittle(u32, this.ny); //u16, @truncate(u16, self.height));
            try writer.writeIntLittle(u32, this.nz); //u16, @truncate(u16, self.height));
            try writer.writeAll(std.mem.sliceAsBytes(this.img));
        }

        pub fn load(name: []const u8) !This {
            const file = try std.fs.cwd().openFile(name, .{});
            defer file.close();
            var reader = file.reader();

            const nx = try reader.readIntLittle(u32); //u16, @truncate(u16, self.width));
            const ny = try reader.readIntLittle(u32); //u16, @truncate(u16, self.height));
            const nz = try reader.readIntLittle(u32); //u16, @truncate(u16, self.height));
            const buf = try reader.readAllAlloc(al, nx * ny * nz * @sizeOf(This.pixtype));
            return This{
                .nx = nx,
                .ny = ny,
                .nz = nz,
                .img = std.mem.bytesAsSlice(This.pixtype, @alignCast(@sizeOf(This.pixtype), buf)),
            };
        }
    };
}

test "test img3d save()" {
    {
        const img = try Img3D(f32).init(10, 11, 12);
        defer img.deinit();
        for (img.img, 0..) |*v, i| v.* = @cos(@intToFloat(f32, i));
        try img.save("cosine.img");
        // const img2 = try Img3D(f32).load("cosine.img");
        // try expect(eql(f32, img.img, img2.img));
    }

    {
        const img = try Img3D([4]u8).init(10, 11, 12);
        defer img.deinit();
        for (img.img, 0..) |*v, i| v.* = [4]u8{
            @intCast(u8, i % 255),
            @intCast(u8, (2 * i) % 255),
            @intCast(u8, (3 * i) % 255),
            @intCast(u8, i % 255),
        };
        try img.save("cosine.img");
    }
}

test "test img3d load()" {
    {
        const img = try Img3D(f32).init(10, 11, 12);
        defer img.deinit();
        for (img.img, 0..) |*v, i| v.* = @cos(@intToFloat(f32, i));
        try img.save("cosine.img");
        const img2 = try Img3D(f32).load("cosine.img");
        defer img2.deinit();
        try expect(eql(f32, img.img, img2.img));
    }

    {
        const img = try Img3D([4]u8).init(10, 11, 12);
        defer img.deinit();
        for (img.img, 0..) |*v, i| v.* = [4]u8{
            @intCast(u8, i % 255),
            @intCast(u8, (2 * i) % 255),
            @intCast(u8, (3 * i) % 255),
            @intCast(u8, i % 255),
        };
        try img.save("cosine.img");
        const img2 = try Img3D([4]u8).load("cosine.img");
        defer img2.deinit();
        for (img.img, 0..) |_, i| {
            try expect(eql(u8, &img.img[i], &img2.img[i]));
        }
    }
}

test "test toBytes()" {
    const S = struct { a: u4, b: u4, c: [2]u2 };
    const s = S{ .a = 0, .b = 15, .c = .{ 3, 2 } };

    const file = try std.fs.cwd().createFile("myfile.out", .{});
    try file.writeAll(std.mem.asBytes(&s));
    file.close();

    const pix = try Img2D([4]u8).init(10, 11);
    defer pix.deinit();
    for (pix.img) |*v| v.* = [4]u8{ 1, 2, 4, 8 };
    try std.fs.cwd().writeFile("pix.out", std.mem.asBytes(&pix));

    const pix2 = std.mem.bytesAsSlice(u8, try std.fs.cwd().readFileAlloc(al, "pix.out", 1600)); // SEGFAULT
    defer al.free(pix2);

    var array_of_bytes: [@sizeOf(S)]u8 = undefined;
    _ = try std.fs.cwd().readFile("myfile.out", array_of_bytes[0..]);
    // WARNING: passing slice to `std.mem.bytesAsValue` SEGFAULTs
    const casted = std.mem.bytesAsValue(S, &array_of_bytes);
    try expect(std.meta.eql(s, casted.*));
    print("\nwe did it?\n{any}\n\n", .{casted.*});

    // var byteslice:[10]u8 = undefined;
    // const byteslice = try allo.alloc(u8,4);
    // _ = byteslice;
    // const newbytes = "\x08\xFA";

    // TODO: Both of these casts FAIL! Segfault!
    // const fromb = std.mem.asBytes(&s);
    // for (fromb) |v,i| array_of_bytes[i] = v;
    // var casted = std.mem.bytesToValue(S,std.mem.toBytes(s));
    // _ = casted;
    // print("\nwe did it?\n{any}\n\n",.{newbytes});

    const S2 = packed struct { a: u8, b: u8, c: u8, d: u8 };
    const inst = S2{ .a = 0xBE, .b = 0xEF, .c = 0xDE, .d = 0xA1 };
    const inst_bytes = "\xBE\xEF\xDE\xA1";
    const inst2 = std.mem.bytesAsValue(S2, inst_bytes);

    try expect(std.meta.eql(inst, inst2.*));
}

test "test imageBase. Img3D Generic" {
    var img = try al.alloc(f32, 50 * 100 * 200);
    defer al.free(img);
    const a1 = Img3D(f32){ .img = img, .nz = 50, .ny = 100, .nx = 200 };
    _ = a1;
    // defer a1.deinit();
    const a2 = try Img3D(f32).init(50, 100, 200); // comptime
    defer a2.deinit();
    // print("{}{}", .{ a1.nx, a2.nx });
}

pub inline fn inbounds(img: anytype, px: anytype) bool {
    if (0 <= px[0] and px[0] < img.nx and 0 <= px[1] and px[1] < img.ny) return true else return false;
}

pub fn minmax(
    comptime T: type,
    arr: []T,
) [2]T {
    var mn: T = arr[0];
    var mx: T = arr[0];
    for (arr) |val| {
        if (val < mn) mn = val;
        if (val > mx) mx = val;
    }
    return [2]T{ mn, mx };
}

// const DivByZeroNormalizationError = error {}

pub fn isin(x: anytype, container: anytype) bool {
    inline for (container) |c| {
        if (x == c) return true;
    }
    return false;
}

test "test isin" {
    try expect(isin(3, .{ 1, 2, 3, 4, 5 }));
    try expect(isin('a', .{ 1, 'a', 3, 4, 5 }));
    try expect(!isin(3.9, .{ 1, 2, 3, 4, 5.0 }));
}

pub fn norm01(comptime T: type, img: []T) void {
    // const T = @TypeOf(img).pixtype;
    comptime assert(isin(T, .{ f16, f32, f64, i8, u8, i16, u16, i32, u32, i64, u64 }));
    // var min:T = 0;
    // var max:T = 0;
    const mima = minmax(T, img);
    for (img) |*v| v.* = (v.* - mima[0]) / (mima[1] - mima[0]);
}

test "test norm()" {
    var pic = try Img2D(f32).init(100, 101);
    defer pic.deinit();
    for (pic.img, 0..) |*v, i| v.* = @intToFloat(f32, i % 255);
    norm01(f32, pic.img);
    try expect(eql(f32, &minmax(f32, pic.img), &.{ 0.0, 1.0 }));
}

/// Checks for mx > mn
pub fn normAffine(data: []f32, mn: f32, mx: f32) !void {
    expect(mx > mn) catch {
        return error.DivByZeroNormalizationError;
    };
    for (data) |*v| v.* = (v.* - mn) / (mx - mn);
}

/// Caller guarantees mx > mn
pub fn normAffineNoErr(data: []f32, mn: f32, mx: f32) void {
    // assert(mx>mn);
    if (mn == mx) {
        print("\nWARNING (normAffineNoErr): NO Contrast. min==max.\n", .{});
        for (data) |*v| v.* = 0;
    } else {
        for (data) |*v| v.* = (v.* - mn) / (mx - mn);
    }
}

pub fn saveU8AsTGA(data: []u8, h: u16, w: u16, name: []const u8) !void {

    // determine if absolute path or relative path. ensure there is a filename with ".tga"
    // remove file if already exists
    // make path if it doesn't exist

    // const cwd = std.fs.cwd();
    // const resolved = try std.fs.path.resolve(al, &.{name});
    // defer al.free(resolved);
    // const dirname = std.fs.path.dirname(resolved);

    // const basename = std.fs.path.basename(resolved);
    // print("resolved : {s} \n" , .{resolved});
    // print("dirname : {s} \n" , .{dirname});
    // print("basename : {s} \n" , .{basename});

    // cwd.makePath(dirname.?) catch {};
    // cwd.createFile(sub_path: []const u8, flags: File.CreateFlags)

    // try std.fs.makeDirAbsolute(dirname.?);
    // const dirnameDir = try std.fs.openDirAbsolute(dirname.?, .{});
    // try dirnameDir.makePath("");

    // WARNING fails when `resolved` is an existing directory...
    // std.fs.deleteDirAbsolute(resolved) catch {};
    // std.fs.deleteFileAbsolute(resolved) catch {};
    // var out = std.fs.createFileAbsolute(resolved, .{ .exclusive = true }) catch unreachable;
    // defer out.close();
    // errdefer cwd.deleteFile(name) catch {};

    var outfile = try std.fs.cwd().createFile(name, .{});
    defer outfile.close();

    var writer = outfile.writer();

    try writer.writeAll(&[_]u8{
        0, // ID length
        0, // No color map
        2, // Unmapped RGB
        0,
        0,
        0,
        0,
        0, // No color map
        0,
        0, // X origin
        0,
        0, // Y origin
    });

    try writer.writeIntLittle(u16, w); //u16, @truncate(u16, self.width));
    try writer.writeIntLittle(u16, h); //u16, @truncate(u16, self.height));
    try writer.writeAll(&[_]u8{
        32, // Bit depth
        0, // Image descriptor
    });

    try writer.writeAll(data);
}

pub fn saveRGBA(pic: Img2D([4]u8), name: []const u8) !void {
    const data = std.mem.sliceAsBytes(pic.img);
    const h = @intCast(u16, pic.ny);
    const w = @intCast(u16, pic.nx);
    try saveU8AsTGA(data, h, w, name);
}

// Drawing on Img2D 👇 Drawing on Img2D 👇 Drawing on Img2D 👇 Drawing on Img2D 👇 Drawing on Img2D
// Drawing on Img2D 👇 Drawing on Img2D 👇 Drawing on Img2D 👇 Drawing on Img2D 👇 Drawing on Img2D
// Drawing on Img2D 👇 Drawing on Img2D 👇 Drawing on Img2D 👇 Drawing on Img2D 👇 Drawing on Img2D

pub fn myabs(a: anytype) @TypeOf(a) {
    if (a < 0) return -a else return a;
}

pub fn drawLine(comptime T: type, img: Img2D(T), _x0: u31, _y0: u31, x1: u31, y1: u31, val: T) void {
    var x0: i32 = _x0;
    var y0: i32 = _y0;
    const dx = myabs(x1 - x0);
    const sx: i8 = if (x0 < x1) 1 else -1;
    const dy = -myabs(y1 - y0);
    const sy: i8 = if (y0 < y1) 1 else -1;
    var err: i32 = dx + dy; //
    var e2: i32 = 0;

    while (true) {
        const idx = @intCast(u32, x0) + img.nx * @intCast(u32, y0);
        img.img[idx] = val;
        e2 = 2 * err;
        if (e2 >= dy) {
            if (x0 == x1) break;
            err += dy;
            x0 += sx;
        }
        if (e2 <= dx) {
            if (y0 == y1) break;
            err += dx;
            y0 += sy;
        }
    }
}

pub fn drawLineInBounds(comptime T: type, img: Img2D(T), _x0: i32, _y0: i32, x1: i32, y1: i32, val: T) void {
    var x0 = _x0;
    var y0 = _y0;
    const dx = myabs(x1 - x0);
    const sx: i8 = if (x0 < x1) 1 else -1;
    const dy = -myabs(y1 - y0);
    const sy: i8 = if (y0 < y1) 1 else -1;
    var err: i32 = dx + dy; //
    var e2: i32 = 0;

    while (true) {
        if (inbounds(img, .{ x0, y0 })) {
            const idx = @intCast(u32, x0) + img.nx * @intCast(u32, y0);
            img.img[idx] = val;
        }
        e2 = 2 * err;
        if (e2 >= dy) {
            if (x0 == x1) break;
            err += dy;
            x0 += sx;
        }
        if (e2 <= dx) {
            if (y0 == y1) break;
            err += dx;
            y0 += sy;
        }
    }
}

test "test imageBase. draw a simple yellow line" {
    const pic = try Img2D([4]u8).init(600, 400);
    defer pic.deinit();
    drawLine([4]u8, pic, 10, 0, 500, 100, .{ 0, 255, 255, 255 });
    try saveRGBA(pic, "../test-artifacts/testeroo.tga");
}

pub fn drawCircle(comptime T: type, pic: Img2D(T), x0: i32, y0: i32, r: i32, val: T) void {
    var idx: i32 = 0;
    while (idx < 4 * r * r) : (idx += 1) {
        const dx = @mod(idx, 2 * r) - r;
        const dy = @divFloor(idx, 2 * r) - r;
        const x = x0 + dx;
        const y = y0 + dy;
        if (inbounds(pic, .{ x, y }) and dx * dx + dy * dy <= r * r) {
            const imgigx = @intCast(u31, x) + pic.nx * @intCast(u31, y);
            pic.img[imgigx] = val;
        }
    }
}

/// just a 1px circle outline. tested with delaunay circumcircles.
pub fn drawCircleOutline(pic: Img2D([4]u8), xm: i32, ym: i32, _r: i32, val: [4]u8) void {
    var r = _r;
    var x = -r;
    var y: i32 = 0;
    var err: i32 = 2 - 2 * r; // /* bottom left to top right */
    var x0: i32 = undefined;
    var y0: i32 = undefined;
    const nx = @intCast(i32, pic.nx);
    var idx: usize = undefined;

    while (x < 0) {
        x0 = xm - x;
        y0 = ym + y;
        if (inbounds(pic, .{ x0, y0 })) {
            idx = @intCast(usize, x0 + nx * y0);
            pic.img[idx] = val;
        }
        x0 = xm + x;
        y0 = ym + y;
        if (inbounds(pic, .{ x0, y0 })) {
            idx = @intCast(usize, x0 + nx * y0);
            pic.img[idx] = val;
        }
        x0 = xm - x;
        y0 = ym - y;
        if (inbounds(pic, .{ x0, y0 })) {
            idx = @intCast(usize, x0 + nx * y0);
            pic.img[idx] = val;
        }
        x0 = xm + x;
        y0 = ym - y;
        if (inbounds(pic, .{ x0, y0 })) {
            idx = @intCast(usize, x0 + nx * y0);
            pic.img[idx] = val;
        }

        // setPixel(xm-x, ym+y); //                           /*   I. Quadrant +x +y */
        // setPixel(xm-y, ym-x); //                           /*  II. Quadrant -x +y */
        // setPixel(xm+x, ym-y); //                           /* III. Quadrant -x -y */
        // setPixel(xm+y, ym+x); //                           /*  IV. Quadrant +x -y */
        r = err;
        if (r <= y) {
            y += 1;
            err += y * 2 + 1;
        } //  /* e_xy+e_y < 0 */
        if (r > x or err > y) {
            x += 1;
            err += x * 2 + 1; //  /* -> x-step now */
        } //  /* e_xy+e_x > 0 or no 2nd y-step */
    }
}

/// Run a simple min-kernel over the image to remove noise.
fn minfilter(alo: std.mem.Allocator, img: Img2D(f32)) !void {
    const nx = img.nx;
    // const ny = img.ny;
    const s = img.img; // source
    const t = try alo.alloc(f32, s.len); // target
    defer alo.free(t);
    const deltas = [_]@Vector(2, i32){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 0 } };

    for (s, 0..) |_, i| {
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
    for (img.img, 0..) |*v, i| {
        v.* = t[i];
    }
}

/// Run a simple min-kernel over the image to remove noise.
fn blurfilter(alo: std.mem.Allocator, img: Img2D(f32)) !void {
    const nx = img.nx;
    // const ny = img.ny;
    const s = img.img; // source
    const t = try alo.alloc(f32, s.len); // target
    defer alo.free(t);
    const deltas = [_]@Vector(2, i32){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 0 } };

    for (s, 0..) |_, i| {
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
    for (img.img, 0..) |*v, i| {
        v.* = t[i];
    }
}
