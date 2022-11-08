const std = @import("std");
const Builder = std.build.Builder;
const print = std.debug.print;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    // const target = b.standardTargetOptions(.{});

    {
        const exe = b.addExecutable("biopencil", "src/biopencil.zig");
        exe.setBuildMode(mode);

        exe.addIncludeDir("/usr/local/include/"); // tiff.h
        exe.addIncludeDir("libs/include/"); // CL/opencl.h
        exe.linkFramework("OpenCL");
        // exe.linkSystemLibrary("tiff");
        // exe.linkSystemLibrary("SDL2");

        exe.addIncludeDir("/usr/local/include/SDL2/");
        exe.addObjectFile("/usr/local/lib/libSDL2.a");
        exe.addObjectFile("/usr/local/lib/libtiff.a");


        // TIFF transitive
        exe.addObjectFile("/usr/local/lib/libjpeg.a");

        // SDL transitive
        exe.linkSystemLibrary("iconv");
        exe.linkFramework("AppKit");
        exe.linkFramework("AudioToolbox");
        exe.linkFramework("Carbon");
        exe.linkFramework("Cocoa");
        exe.linkFramework("CoreAudio");
        exe.linkFramework("CoreFoundation");
        exe.linkFramework("CoreGraphics");
        exe.linkFramework("CoreHaptics");
        exe.linkFramework("CoreVideo");
        exe.linkFramework("ForceFeedback");
        exe.linkFramework("GameController");
        exe.linkFramework("IOKit");
        exe.linkFramework("Metal");





        exe.install();
    }

    {
        const exe = b.addTestExe("biopencil-test", "src/biopencil.zig");
        // exe.addLibraryPath("/usr/local/lib"); (automatically linked ???)
        exe.addIncludeDir("/usr/local/include/"); // tiff.h (required)
        exe.addIncludeDir("libs/include/"); // CL/opencl.h
        exe.linkFramework("OpenCL");
        exe.linkSystemLibrary("tiff");
        exe.linkSystemLibrary("SDL2");
        // exe.setFilter("test tiff open float image");
        // exe.setFilter("test TIFF vs raw speed");
        exe.install();
    }
}
