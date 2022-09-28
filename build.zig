
const std = @import("std");
const Builder = std.build.Builder;
const print = std.debug.print;

pub fn build(b: *Builder) void {

    {
        const exe = b.addExecutable("main", "src/clbridge.zig");
        exe.addIncludeDir("libs");  // CL/opencl.h
        exe.linkFramework("OpenCL");
        exe.addIncludeDir("/usr/local/include/");  // tiff.h
        exe.linkSystemLibrary("tiff");
        // linkOpenCL(b,exe);
        // exe.addIncludeDir("./src/");
        exe.install();
        b.default_step.dependOn(&exe.step);

        exe.addFrameworkDir("/System/Library/Frameworks");
        exe.linkFramework("Cocoa");
        exe.linkFramework("OpenGL"); // not sure if necessary?
        exe.linkFramework("IOKit");
        // Homebrew style linking (instead of Frameworks)
        exe.addIncludeDir("/usr/local/include/SDL2/");
        exe.addLibPath("/usr/local/lib");
        exe.linkSystemLibrary("SDL2");

    }
}
