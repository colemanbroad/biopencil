const std = @import("std");
const Builder = std.build.Builder;
const print = std.debug.print;

pub fn build(b: *Builder) void {
    // const mode = b.standardReleaseOptions();
    // const target = b.standardTargetOptions(.{});

    {
        const exe = b.addExecutable(.{
            .name = "biopencil",
            .root_source_file = .{ .path = "src/biopencil.zig" },
            .target = .{},
            .optimize = .Debug,
        });

        // const exe = b.addExecutable("biopencil", "src/biopencil.zig");
        // exe.setBuildMode(mode);

        exe.addIncludePath("/usr/local/include/"); // tiff.h
        exe.addIncludePath("libs/include/"); // CL/opencl.h
        exe.linkFramework("OpenCL");
        exe.linkSystemLibrary("tiff");
        exe.linkSystemLibrary("SDL2");
        exe.install();
    }

    {

        // const exe = b.addTest("biopencil-test", "src/biopencil.zig");
        const exe = b.addTest(.{ .kind = .test_exe, .root_source_file = .{ .path = "src/biopencil.zig" } });
        // exe.addLibraryPath("/usr/local/lib"); (automatically linked ???)
        exe.addIncludePath("/usr/local/include/"); // tiff.h (required)
        exe.addIncludePath("libs/include/"); // CL/opencl.h
        exe.linkFramework("OpenCL");
        exe.linkSystemLibrary("tiff");
        exe.linkSystemLibrary("SDL2");
        // exe.setFilter("test read write loops");
        // exe.setFilter("test TIFF vs raw speed");
        exe.install();
    }
}
