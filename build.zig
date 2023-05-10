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
        // exe.addIncludePath("libs/include/"); // CL/opencl.h
        // exe.addSystemIncludePath("/Library/Developer/CommandLineTools/SDKs/MacOSX13.1.sdk/System/Library/Frameworks/OpenCL.framework/");
        exe.linkFramework("OpenCL");
        exe.linkSystemLibrary("tiff");
        exe.linkSystemLibrary("SDL2");
        b.installArtifact(exe);
    }

    {

        // const exe = b.addTest("biopencil-test", "src/biopencil.zig");
        const exe = b.addTest(.{ .root_source_file = .{ .path = "src/opencl-maxproj.zig" }, .filter = "buffer" });

        // exe.addLibraryPath("/usr/local/lib"); (automatically linked ???)
        // exe.addIncludePath("/usr/local/include/"); // tiff.h (required)
        // exe.addIncludePath("libs/include/"); // CL/opencl.h
        exe.linkFramework("OpenCL");
        // exe.linkSystemLibrary("tiff");
        // exe.linkSystemLibrary("SDL2");
        // exe.setFilter("test DevCtxQueProg");
        // exe.setFilter("test dcqp basic kernel");
        // exe.setFilter("test read write loops");
        // exe.setFilter("test TIFF vs raw speed");
        // exe.setFilter("buffer");
        // exe.setFilter("writefloatbuffer");
        // exe.setFilter("mandelbrot");
        b.installArtifact(exe);
    }
}
