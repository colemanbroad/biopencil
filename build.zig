const std = @import("std");
const Builder = std.build.Builder;
const print = std.debug.print;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    // const target = b.standardTargetOptions(.{});

    {
        const exe = b.addExecutable("clbridge", "src/clbridge.zig");
        exe.setBuildMode(mode);
        exe.addIncludePath("/usr/local/include/"); // tiff.h
        exe.addIncludePath("libs/include/"); // CL/opencl.h

        exe.linkFramework("OpenCL");
        exe.linkSystemLibrary("tiff");
        exe.linkSystemLibrary("SDL2");
        exe.install();
    }

    {
        const exe = b.addTestExe("clbridge-test", "src/clbridge.zig");

        // exe.addLibraryPath("/usr/local/lib"); (automatically linked in ???)
        exe.addIncludePath("/usr/local/include/"); // tiff.h (required)
        exe.addIncludePath("libs/include/"); // CL/opencl.h

        exe.linkFramework("OpenCL");
        exe.linkSystemLibrary("tiff");
        exe.linkSystemLibrary("SDL2");

        // exe.setFilter("test tiff open float image");
        // exe.setFilter("test TIFF vs raw speed");

        exe.install();
    }

}
