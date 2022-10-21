const std = @import("std");
const Builder = std.build.Builder;
const print = std.debug.print;

pub fn build(b: *Builder) void {
    const install_step = b.step("clbridge", "build de' prog");
    {
        const exe = b.addExecutable("clbridge", "src/clbridge.zig");

        // OpenCL
        exe.addIncludePath("libs"); // CL/opencl.h
        exe.linkFramework("OpenCL");

        // Tiff
        exe.addIncludePath("/usr/local/include/"); // tiff.h
        exe.linkSystemLibrary("tiff");

        // SDL2
        exe.addIncludePath("/usr/local/include/SDL2/");
        exe.addLibraryPath("/usr/local/lib");
        exe.linkSystemLibrary("SDL2");

        exe.install();
        install_step.dependOn(&exe.step);
    }

    const test_step = b.step("test", "build de' tests");
    {

        // const exe = b.addTest("src/clbridge.zig");
        const exe = b.addTestExe("clbridge-test", "src/clbridge.zig");

        // exe.setFilter("test tiff open float image");
        // exe.setFilter("test TIFF vs raw speed");

        // OpenCL
        exe.addIncludePath("libs"); // CL/opencl.h
        exe.linkFramework("OpenCL");

        // Tiff
        exe.addIncludePath("/usr/local/include/"); // tiff.h
        exe.linkSystemLibrary("tiff");

        // SDL2
        exe.addIncludePath("/usr/local/include/SDL2/");
        exe.addLibraryPath("/usr/local/lib");
        exe.linkSystemLibrary("SDL2");

        exe.install();
        test_step.dependOn(&exe.step); // why doesn't this lead to a dangling reference when exe is free'd at end of scope ?
    }

    b.default_step.dependOn(install_step);
    b.default_step.dependOn(test_step);
}
