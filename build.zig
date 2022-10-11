
const std = @import("std");
const Builder = std.build.Builder;
const print = std.debug.print;

pub fn build(b: *Builder) void {


    const installstep = b.step("buildy","build de' prog");
    {
        const exe = b.addExecutable("clbridge", "src/clbridge.zig");
        exe.addIncludeDir("libs");  // CL/opencl.h
        exe.linkFramework("OpenCL");
        exe.addIncludeDir("/usr/local/include/");  // tiff.h
        exe.linkSystemLibrary("tiff");
        // linkOpenCL(b,exe);
        // exe.addIncludeDir("./src/");
        exe.install();

        exe.addFrameworkDir("/System/Library/Frameworks");
        exe.linkFramework("Cocoa");
        exe.linkFramework("OpenGL"); // not sure if necessary?
        exe.linkFramework("IOKit");
        // Homebrew style linking (instead of Frameworks)
        exe.addIncludeDir("/usr/local/include/SDL2/");
        exe.addLibPath("/usr/local/lib");
        exe.linkSystemLibrary("SDL2");
        installstep.dependOn(&exe.step);
    }
    b.default_step.dependOn(installstep);

}
