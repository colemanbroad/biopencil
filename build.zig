const std = @import("std");
const Builder = std.build.Builder;
const print = std.debug.print;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    // const target = b.standardTargetOptions(.{});
    // const clbridge_step = b.step("clbridge", "build de' prog");

    {
        const exe = b.addExecutable("clbridge", "src/clbridge.zig");
        exe.setBuildMode(mode);
        exe.addIncludePath("/usr/local/include/"); // tiff.h
        exe.addIncludePath("libs/include/"); // CL/opencl.h
        // exe.addLibraryPath("/usr/local/lib");

        // exe.addIncludePath("libs"); // CL/opencl.h

        // OpenCL
        exe.linkFramework("OpenCL");

        // Tiff
        exe.linkSystemLibrary("tiff");

        // SDL2
        // exe.addIncludePath("libs/SDL2-2.0.20/include/");
        // exe.addLibraryPath("libs/SDL2-2.0.20/lib/");
        exe.linkSystemLibrary("SDL2");
        // exe.addIncludePath("/usr/local/include/SDL2/");
        // exe.linkSystemLibrary("SDL2");

        exe.install();
    }

    // const test_step = b.step("test", "build de' tests");
    {
        // const exe = b.addTest("src/clbridge.zig");
        const exe = b.addTestExe("clbridge-test", "src/clbridge.zig");

        // exe.addLibraryPath("/usr/local/lib"); (automatically linked in ???)
        exe.addIncludePath("/usr/local/include/"); // tiff.h (required)
        exe.addIncludePath("libs/include/"); // CL/opencl.h

        // exe.setFilter("test tiff open float image");
        // exe.setFilter("test TIFF vs raw speed");

        // OpenCL
        // exe.addIncludePath("libs"); // CL/opencl.h
        exe.linkFramework("OpenCL");

        // Tiff
        exe.linkSystemLibrary("tiff");

        // SDL2
        // exe.addIncludePath("libs/SDL2-2.0.20/include/");
        // exe.addLibraryPath("libs/SDL2-2.0.20/lib/");
        exe.linkSystemLibrary("SDL2");
        // exe.addIncludePath("/usr/local/include/SDL2/");
        // exe.linkSystemLibrary("SDL2");

        exe.install();
        // test_step.dependOn(&exe.step); // why doesn't this lead to a dangling reference when exe is free'd at end of scope ?
    }

    // b.default_step.dependOn(install_step);
    // b.default_step.dependOn(test_step);
}
