const std = @import("std");
// const warn = std.debug.warn;

const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const clamp = std.math.clamp;

const cc = @import("./c.zig");
const clbridge = @import("clbridge.zig");
const im = @import("saveImage.zig");

const Vector = std.meta.Vector;

test "perspective proj" {
    print("\n",.{});
    // c.HMM_Perspective(float FOV (in degrees), float AspectRatio, float Near, float Far)
    const pMat = cc.hm.HMM_Perspective(80, 1.2, 0.0, 1.0);
    // const elems:[*]f32 = [_]f32{pMat.Elements;
    print("{d:.2} \n", .{pMat.Elements});
    print("\n",.{});
}

test "Build volumecaster2.cl program, but don't run it." {
    print("\n",.{});
    print("** running test **\n", .{});

    var errCode: cc.cl.cl_int = undefined;

    // Get a device. Build a context and command queue.
    // This is the same every time.
    // var platDev = try get_cl_device();
    // print("{any}\n", .{platDev});
    // var device = platDev.device_ids[0];
    var device = try clbridge.get_cl_device();
    var ctx = cc.cl.clCreateContext(null, 1, &device, null, null, null); // future: last arg is error code
    if (ctx == null) return clbridge.MyCLError.CreateContextFailed;
    defer _ = cc.cl.clReleaseContext(ctx);
    var command_queue = cc.cl.clCreateCommandQueue(ctx, device, 0, null); // future: last arg is error code
    if (command_queue == null) return clbridge.MyCLError.CreateCommandQueueFailed;
    defer {
        _ = cc.cl.clFlush(command_queue);
        _ = cc.cl.clFinish(command_queue);
        _ = cc.cl.clReleaseCommandQueue(command_queue);
    }

    // Load the program source and build it.
    // Print the Build Errors from CL compiler if build fails.
    var _f1 = @embedFile("volumecaster2.cl");
    // var _f2 = @embedFile("utils.cl");
    var srcFiles = @ptrCast([*c][*c]u8, &.{&_f1[0], });
    // 2nd arg is "the number of source file points in `srcFiles`"
    var program = cc.cl.clCreateProgramWithSource(ctx, 1, srcFiles, null, &errCode); // future: last arg is error code
    try clbridge.testForCLError(errCode);
    defer _ = cc.cl.clReleaseProgram(program);
    var options = "-I /Users/broaddus/Desktop/ProjectsPersonal/zig/zig-opencl-test/src/";
    errCode = cc.cl.clBuildProgram(program, 1, &device, null, null, null);

    if (errCode != cc.cl.CL_SUCCESS) {
        // var len = 0;
        // _ = cc.cl.clGetProgramBuildInfo(program, device, cc.cl.CL_PROGRAM_BUILD_LOG, 0, null, &len);
        var len:usize = 10_000;
        var lenOut:usize = undefined;
        var buffer = try gpa.allocator.alloc(u8, len);
        _ = cc.cl.clGetProgramBuildInfo(program, device, cc.cl.CL_PROGRAM_BUILD_LOG, len, &buffer[0], &lenOut);
        print("==CL_PROGRAM_BUILD_LOG== \n\n {s}\n\n", .{buffer[0..lenOut]});
    }


    try clbridge.testForCLError(errCode);
    print("\n",.{});
}

test "max_project_float 400x500" {

    print("\n",.{});

    // Create mock 3D input data
    var  input_array = try gpa.allocator.alloc(f32, 40 * 60 * 80);
    for (input_array) |*v, i| v.* = @intToFloat(f32, i % 30);
    defer gpa.allocator.free(input_array);
    print("The input array:\n {e:9.2} \n", .{input_array[0..10].*});

    // Output data should be 2D perspective projection of 3D image
    const Nx: u32 = 400;
    const Ny: u32 = 500;
    var output_array   = try gpa.allocator.alloc(f32, Nx * Ny);
    var output_array_a = try gpa.allocator.alloc(f32, Nx * Ny);
    var output_array_d = try gpa.allocator.alloc(f32, Nx * Ny);
    print("The output array (pre):\n {e:9.2} \n", .{output_array[Nx*Ny-10..Nx*Ny].*});

    // volume:image3d_t 

    // try max_project_float(
    //     input_array,
    //     output_array,
    //     );

    print("The output array:\n {e:9.2} \n", .{output_array[Nx*Ny-10..Nx*Ny].*});

    try im.saveF32AsTGAGreyNormed(&gpa.allocator, output_array, Ny, Nx, "testF32output.tga", );

    // THIS ERROR NO LONGER OCCURS.
    // catch |err| switch (err) {
    //     error.DivByZeroNormalizationError => {print("We caught a div by zero error!\n",.{});},
    //     // error.DivByZeroNormalizationError => {return err;},
    //     else => {},
    // };

    // saveU8AsTGAGrey(, output_array, Nx, Ny);

    print("\n",.{});
}

// pub fn maxProj(img3D:[]f32) {
//     const Mat4 = [16]f32 ;
//     const Nx:u32 = 500;
//     const Ny:u32 = 500;
//     // const mProj:Mat4 = [_]{}
// }





// Orthographic projection along x,y or z.
pub fn orthProj(comptime T: type, allocator: *std.mem.Allocator, img3D:[]T, shape:[3]u32, dim: u8) ![]T {

    const Nz = shape[0];
    const Ny = shape[1];
    const Nx = shape[2];
    var z:u32 = 0;
    var x:u32 = 0;
    var y:u32 = 0;

    switch (dim) {

        // Poject over Z. Order of dimensions is Z,Y,X. So X is fast and Z is slow.
        0 => {
            var res = try gpa.allocator.alloc(T,Ny*Nx);
            const Nxy = Nx*Ny;

            z=0;
            while (z<Nz):(z+=1){
                const z2 = z*Nxy;

                y=0;
                while (y<Ny):(y+=1){
                    const y2 = y*Nx;

                    x=0;
                    while (x<Nx):(x+=1){

                        if (res[y2+x] < img3D[z2+y2+x]) {res[y2+x] = img3D[z2+y2+x];}

                    }
                }
            }
            return res;
        },
        else => {unreachable;},
    }
}

test "ortho project" {
    print("\n",.{});
    var  input_array = try gpa.allocator.alloc(f32, 40 * 60 * 80);
    for (input_array) |*v, i| v.* = @intToFloat(f32, i % 2);
    defer gpa.allocator.free(input_array);
    print("The input array:\n {d:3.2} \n", .{input_array[0..10].*});

    const res = try orthProj(f32, &gpa.allocator, input_array, [_]u32{40,60,80}, 0);
    try im.saveF32AsTGAGreyNormed(&gpa.allocator, res, 60, 80, "projImage.tga");
    print("\n",.{});
}


// fn sdf(al:*std.mem.Allocator, shapes: []Shape, size: [3]u32) ![]f32 {    
// }

test "SiMD ?" {
    print("\n",.{});
    // const pt1 = Vector(3,u16);
    const x1:f32 = 1.0;
    const x2:f32 = 1.5;
    const pt1 = @splat(3, x1);
    const pt2 = @splat(3, x2);
    const d = pt1-pt2;
    print("\n",.{});
}


fn sdf1(z:u32,y:u32,x:u32,Nz:u32,Ny:u32,Nx:u32) f32 {
    const a  = (z-Nz/2);
    const a2 = a*a;
    const b  = (y-Ny/2);
    const b3 = b*b*b;
}


const image3d_t = *f32;

// fn max_project_float(
//         d_output: *f32,       // probably Nx x Ny
//         d_alpha_output: *f32, // same
//         d_depth_output: *f32, // same
//         Nx:u32, Ny:u32,       // width & height of output (also compute grid?)
//         volume:image3d_t,     // __read_only 
//         ) !void {

//     const boxMin_x: f32  = 0 ;  // // view clip box ?
//     const boxMax_x: f32  = 1 ;  //
//     const boxMin_y: f32  = 0 ;  //
//     const boxMax_y: f32  = 1 ;  //
//     const boxMin_z: f32  = 0 ;  //
//     const boxMax_z: f32  = 1 ;  //
//     const minVal: f32    = 0 ;  // // intensity clip
//     const maxVal: f32    = 1 ;  //
//     const gamma: f32     = 1 ;  //
//     const alpha_pow: f32 = 0 ;  //
//     const numParts:i32 = 100; // scale the number of steps
//     const currentPart:i32 = 0; // ????
//     const invP:*f32 = [_]f32{1}**9 ; // matrix of perspective ?
//     const invM:*f32 = [_]f32{1}**9 ; // 
    
//     // print("** running test **\n", .{});

//     var errCode: cc.cl.cl_int = undefined;

//     // Get a device. Build a context and command queue.
//     // This is the same every time.
//     var device = try get_cl_device();
//     var ctx = cc.cl.clCreateContext(null, 1, &device, null, null, &errCode);
//     try testForCLError(errCode);
//     defer _ = cc.cl.clReleaseContext(ctx);
//     var command_queue = cc.cl.clCreateCommandQueue(ctx, device, 0, &errCode);
//     try testForCLError(errCode);
//     defer {
//         _ = cc.cl.clFlush(command_queue);
//         _ = cc.cl.clFinish(command_queue);
//         _ = cc.cl.clReleaseCommandQueue(command_queue);
//     }

//     // Load the program source and build it.
//     // Print the Build Errors from CL compiler if build fails.
//     var _f1 = @embedFile("volumecaster2.cl");
//     var _f2 = @embedFile("utils.cl");
//     var srcFiles = @ptrCast([*c][*c]u8, &.{_f1,_f2});
//     var program = cc.cl.clCreateProgramWithSource(ctx, 1, srcFiles, null, &errCode); // future: last arg is error code
//     try testForCLError(errCode);
//     defer _ = cc.cl.clReleaseProgram(program);
//     errCode = cc.cl.clBuildProgram(program, 1, &device, null, null, null);
//     try testForCLError(errCode);

//     // if ( != cc.cl.CL_SUCCESS) {
//     //     // var len = 0;
//     //     // _ = cc.cl.clGetProgramBuildInfo(program, device, cc.cl.CL_PROGRAM_BUILD_LOG, 0, null, &len);
//     //     var len:usize = 10_000;
//     //     var buffer = try gpa.allocator.alloc(u8, len);
//     //     _ = cc.cl.clGetProgramBuildInfo(program, device, cc.cl.CL_PROGRAM_BUILD_LOG, len, &buffer, null);
//     //     print("==CL_PROGRAM_BUILD_LOG== \n\n {any}", .{buffer});
//     //     return MyError.BuildProgramFailed;
//     // }

//     // Create a Kernel
//     var kernel = cc.cl.clCreateKernel(program, "max_project_float", &errCode);
//     try testForCLError(errCode);
//     defer _ = cc.cl.clReleaseKernel(kernel);

//     // Create input and output buffers
//     var input_buffer = cc.cl.clCreateBuffer(ctx, cc.cl.CL_MEM_READ_ONLY, @sizeOf(f32)*input_array.len, null, &errCode);
//     try testForCLError(errCode);
//     defer _ = cc.cl.clReleaseMemObject(input_buffer);

//     var output_buffer = cc.cl.clCreateBuffer(ctx, cc.cl.CL_MEM_WRITE_ONLY, @sizeOf(f32)*output_array.len, null, &errCode);
//     try testForCLError(errCode);
//     defer _ = cc.cl.clReleaseMemObject(output_buffer);

//     // print("Buffers Created\n",.{});

//     // Fill input buffer
//     errCode = cc.cl.clEnqueueWriteBuffer(command_queue, input_buffer, cc.cl.CL_TRUE, 0, @sizeOf(f32)*input_array.len, &input_array[0], 0, null, null);
//     try testForCLError(errCode);

//     // print("Write Buffer Enqueued\n",.{});
//     // print("Buffer \n{any}\n", .{input_buffer});

//     // Pass buffers as kernel arguments
//     errCode = cc.cl.clSetKernelArg(kernel, 0, @sizeOf(cc.cl.cl_mem), &input_buffer); try testForCLError(errCode);
//     // print("Set Arg 1\n",.{});
//     errCode = cc.cl.clSetKernelArg(kernel, 1, @sizeOf(cc.cl.cl_mem), &output_buffer); try testForCLError(errCode);
//     // print("Set Arg 2\n",.{});

//     // Execute kernel
//     // var global_item_size: usize = input_array.len;
//     // var global_item_size: usize = output_array.len;
//     // var local_item_size: usize = 64;
//     // Set work_dim to two ? not yet.
//     // TODO: UnSet local_item_size from null

//     var nproc:usize = output_array.len;
//     var err: cc.cl.cl_int = cc.cl.clEnqueueNDRangeKernel(command_queue, kernel, 1, null, &nproc, null, 0, null, null);
//     try testForCLError(err);
//     // print("Ran the Kernel\n",.{});

//     // print("Size: {}\n", .{@sizeOf(f32)});
//     errCode = cc.cl.clEnqueueReadBuffer(command_queue, output_buffer, cc.cl.CL_TRUE, 0, @sizeOf(f32)*output_array.len, &output_array[0], 0, null, null);
//     try testForCLError(errCode);
//     // print("Read the output buffer\n",.{});
// }

