const std = @import("std");
const Builder = std.build.Builder;
const print = std.debug.print;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    // const target = b.standardTargetOptions(.{});

    {
        const exe = b.addExecutable("clbridge-static", "src/clbridge.zig");
        exe.setBuildMode(mode);
        exe.addIncludeDir("/usr/local/include/"); // tiff.h
        exe.addIncludeDir("libs/include/"); // CL/opencl.h
        exe.addIncludeDir("/usr/local/include/SDL2/");
        exe.linkFramework("OpenCL");
        exe.addObjectFile("/usr/local/lib/libSDL2.a");
        exe.addObjectFile("/usr/local/lib/libtiff.a");

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


        // exe.linkSystemLibrary("tiff");
        // exe.linkSystemLibrary("SDL2");
        exe.install();
    }

    {
        const exe = b.addTestExe("clbridge-test-static", "src/clbridge.zig");
        // exe.addLibraryPath("/usr/local/lib"); (automatically linked ???)
        exe.addIncludeDir("/usr/local/include/"); // tiff.h (required)
        exe.addIncludeDir("libs/include/"); // CL/opencl.h
        exe.addIncludeDir("/usr/local/include/SDL2/");
        exe.linkFramework("OpenCL");
        exe.addObjectFile("/usr/local/lib/libSDL2.a");
        exe.addObjectFile("/usr/local/lib/libtiff.a");

        // exe.linkFramework("Foundation");
        // exe.linkFramework("IOKit");
        // exe.linkFramework("Cocoa"); // wrapper for AppKit Foundation and CoreData
        // exe.linkFramework("CoreAudio");
        // exe.linkFramework("CoreHaptics");
        // exe.linkFramework("Metal");


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

        // exe.linkSystemLibrary("tiff");
        // exe.linkSystemLibrary("SDL2");
        // exe.setFilter("test tiff open float image");
        // exe.setFilter("test TIFF vs raw speed");
        exe.install();
    }
}
