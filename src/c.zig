
// pub const bres = @cImport({
//     @cInclude("./bresenham_all.c");
// });

// pub const hm = @cImport({
//     @cDefine("HANDMADE_MATH_IMPLEMENTATION","");
//     @cInclude("HandmadeMath.h");
// });

pub const cl = @cImport({
    @cDefine("CL_TARGET_OPENCL_VERSION", "220");
    @cInclude("CL/cl.h");
});

pub const tiffio = @cImport({
  // @cInclude("tinytiffreader.h");
  @cInclude("tiffio.h");
});

pub usingnamespace @cImport({
  @cInclude("SDL.h");
});