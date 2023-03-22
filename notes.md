Get rendered image to appear in a SDL window.

# Commands

-- Print a table of contents from `notes.md` 
grep '^#' notes.md | sed 's/#/-/'  

-- Create demo.gif from a screen recording
ffmpeg -ss 00:00:10.000 -i screen-recording.mov -pix_fmt rgb24 -r 10 -s 694x532 -t 00:00:10.000 demo.gif



# Wed Sep 28 00:29:14 2022

Get rendered image to appear in a SDL window.
IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    
IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    
IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    
IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    

1. load an ISBI tiff
2. volume render it with perspective in OpenCL
3. display the result in an SDL window

# Tue Oct  4 16:54:47 2022

fast and efficient volume renderning with rotation and color, takes a TIFF path as cmd line arg.


# Wed Oct  5 15:16:13 2022

Parameterize view state by 3x3 rotation matrix and update it with arrow keys.
This is more powerful representation than the previous `view_angles:[2]f32` model
which required a view_angles → rotation matrix transformation (`rotmatFromAngles()`), but we could update view_angles by 
simply adding a scalar value. 

- [x] use `setPixels()` for faster surface blitting.
- Q: how to draw only on sub rectangle?


# Thu Oct  6 14:56:58 2022

- Refactor using `View` struct in zig and opencl.
- Got `max_project_float()` kernel execution down to 15ms.
- Note single pass on Cele volume to calculate min/max takes 60ms ?!?! That's so slow. But it does touch every pixel once.
- bugfix 3D `boxImage()`

# Mon Oct 17 12:40:49 EDT 2022

Let's speed test load TIF vs load RAW...
It's the same! Saving an f32 was 30ms, loading was 90ms with significant variability, but was less if we use f16 instead of f32.
But doing the same in python with skimge.io was > 300ms !
With python's `tifffile.imread` it was 280ms !
The image is 12.3e6 pixels, and 5.7MB! It uses LZW compression to get down to 5.7MB when it should be 12.3MB. So the 90ms load includes decompression ?!
So maybe we don't actually pay a huge price for TIFF format, if we avoid using python to load ?


```
DevCtxQueProg.init           [85ms]
struct{w: u32, h: u32, depth: u32, n_strips: u32}{ .w = 708, .h = 512, .depth = 34, .n_strips = 47 }
load TIFF and convert to f32 [177ms]
initialize buffers           [2ms]
find min/max of f32 img      [70ms]
define kernel                [0ms]
call kernel                  [11ms]
SDL_Init                     [163ms]
CreateWindow                 [20ms]
SDL_GetWindowSurface         [1081ms]
update surface               [6ms]
```

Drawing in 3D works! But the z-resolution is weak. Naive Blurring on CPU is too slow.

# Thu Oct 20 13:28:27 EDT 2022

What about the fact that the most common bit depth coming off of the microscope is actually 12?
I need a single function and it can return a union over various image types.


# Sun Oct 23 12:37:26 EDT 2022

When data is too thick we should be able to narrow the volume through which we perform projection.
This volume should be easily customizable and draggable through the full volume.
This also makes computing the projection easier as we make the volume smaller.

# BUG: CL_INVALID_KERNEL (Sat Mar 18, 2023)

How am i going to debug this?
I can build the program, but there is an error in `clCreateKernel()`.
When I adjust the kernel to have the same arguments, but not to use them, then I don't have this error.
I'll make a minimal function that prints out the values of passed function parameters.
This tells me that I can print all the args up through `colormap` just fine, but from `Nx` onwards I get the error.
One theory is I'm passing a pointer when I should be passing a value to `setKerelArgs()`. 
Is it ever OK to pass a value ?
Another is that I'm passing a pointer to memory with shorter lifetime than my kernel...
If I want to pass a value like `[1000]u8` to the GPU do I need to put that data into a buffer?
Or can I simply pass it as a value.
Well, `[1000]u8` doesn't exist as a value in `C`! So, you have to allocate, and pass them around as `*u8` pointers.
But for structs that hold actual `C` values I should be able to pass these around no problem...

But I have been able to pass around `colormap` without using buffers in the past!
How did my kernel have any idea how large an array `colormap` was? How did it know how much data to pass to the GPU?

?? There are no bounds checks on buffers passed into OpenCL ??
The kernel may be valid / invalid depending on whether or not I print one of the parameters?
That's insane. Why can't it just type check at the boundaries properly?
What about using a different GPU programming tool instead of OpenCL 1.2...






# Performance / Profiling

Reading TIFF is slow. 95MB tiff file reads in 2s... Most of this must be decoding, because I can `dd` the file to `/dev/null/` at 4GB/s.
      UPDATE: 84MB tiff Tribolium reads in 1.3s. This is def too slow.
OpenCL device & context creation is slow and highly variable. Between 60ms .. 450ms. Also I feel noticeable lag on my screen when working with most apps. This is a problem with my laptop's graphics hardware?

Thu Oct 27 01:33:24 EDT 2022
UPDATE: No idea why... but suddenly after the refactor into Window.init() we can open an SDL window in 15 ms.
UPDATE: Now (Sat Nov 5) it's back to 900ms. Previous results may have been a timing mistake?

We can profile our application with a simple sampling profiler!
[mac profiling tips](https://gist.github.com/loderunner/36724cc9ee8db66db305)
1. [call stack sampling](https://stackoverflow.com/questions/375913/how-do-i-profile-c-code-running-on-linux/378024#378024)
2. [more call stack sampling](https://stackoverflow.com/questions/1777556/alternatives-to-gprof?noredirect=1&lq=1)
3. [using instruments on mac](https://stackoverflow.com/questions/11445619/profiling-c-on-mac-os-x)


`sample clbridge 30 -f sample.txt`
`sample [pid | app name] [time in s [sample rate default 1 ms]] `

Thu Oct 27 12:02:50 EDT 2022
Profiling reveals that reading from the volume sampler in OpenCL is ACTUALLY a hot spot. And 
that calling kernels in general is slow. Also, our line-by-line timing is misleading, because the asynchronous execution of `executeKernel()` 
makes it look like we spend all our time _reading out data_, when in fact it's executing kernels.

# Loading data

Make sure we can open:

- [x] multiple bit depth
- [x] uint,int,float
- [ ] multiple samples per pixel (channels)
- [ ] 2D/3D/4D (time)


Reading from TIFF is slower than reading from RAW using `Img3D.load()`.

- readTIFF3D 231 ms
- save img f32 33 ms
- load raw f32 109 ms
- save img f16 21 ms
- load raw f16 68 ms

It may actually be faster to load using the RGBA tiff interface than the `TIFFRasterScanlineSize64` interface!? confirm and explain this.

# App structure

Unfortunately a zig bug prevents us from keeping app state in a single global namespace, ala
```zig
const app = struct {
      var mouse = ...
      var window_main = ...
      var window_side = ...
      ...
};
```
This would 


```
App.mouse : Mouse
App.window_main : Window
App.window_view : Window
App.mode : Mode
App.keys : KeySystem

Data.imgs : Img3D(f32)
Data.anno : 
Data.anno.loops : Loop
Data.anno.regions : RectRegion

Window.dims
Window._surface
Window.pixels : Img2D([4]u8)
Window.blit(new_pixels)

myCL is a namespace that holds:
      Kernel : type
      DevCtxQueProg : type
      perspective_projection.kernel : Kernel
      perspective_projection.view : View
      perspective_projection.args : Tuple
      median_filter
```


Since View is used in and out of Kernels it cannot be a Kernel-specific type.
We can also use View for drawing loops w CPU.

```
embedLoops(View)
perspective_projection.kernel.call(View)
```

View must be global?


# Architecture and control flow

- Why is updating loop.temp... allowed ?
- Can i edit namespaced vars from a method i.e. loops.method() ?
- Model / View style or mixed view and control style?
  
  Model / View style requires that I have separate control flow (1) for updating my model(input) and (2) for updating my view(model).
  While the everything-together approach mixes view updates into the model update control flow...
  I'm going to try separating them and see what happens...

- What are the intermediate computations I should save / cache / use as named variables ... 

Cacheing vs memoization vs 
Simply *naming a variable* is a way of caching a computation that might be considered "intermediate".
E.g. see how `a` caches an intermediate result in computing `res`.

```
res = (x**2 - 3)(x**2 + 3)
--- vs 
a = x**2
res = (a-3)(a+3)
```

## OpenCL interaction architecture


At the momenet all the app logic and interfacing with opencl lives in biopencil.
This is fine, but I think the opencl logic is really quite distinct and probably too generic.
We really just want a way to call the max projection kernel.
This will require a setup() / init() function to get the (devi, ctx, cmd_q, prog, kernel), build the buffers
and enquqe all the args. Since we're only doing this for one function we may as well only do it one time.
Then we'll need a second function which takes the Kernel object with all it's state and renders into a buffer 
of our choosing.

# OpenCL Questions

- what does `global float*` mean vs normal float pointer as kernel parameter? Global is required for global mem access.
- why can't i create a readwrite buffer from a pointer i own and pass that to opencl successfully? the memory is zeroed out in the buffer somehow...
I could try all combinations.....


I've got it narrowed down to a very small test case. 
1. Using C I can run kernels which take a buffer and a non-buffer as arguments and successfully write to the buffer.
2. I can translate this to ZIG with `translate-c` and it runs exactly the same, so I know that passing normal args via `&number` works in zig even when I cast to `?*const anyopaque`.
The remaining possible causes for the error `error.CL_INVALID_KERNEL` returned from `clCreateKernel()` cannot be related to the later calls like `cl.clSetKernelArg(kernel, i_argnum, @sizeOf(cl.cl_mem), @ptrCast(?*anyopaque, &buffers_1))`...
It must be related to the actual kernel source... Maybe it doesn't type check? But this would be a problem 
during `buildProgram()`... 
3. Now I can run kernels that write to buffers, but I can't print when the buffer is called? This is strange.
      PRINTING IS ERRATIC. It doesn't work with regularity.
      IT WAS THE PROBLEM. PERFECTLY GOOD KERNELS WILL THROW `OPENCL ERROR: -48 ERROR.CL_INVALID_KERNEL` 
      WHENEVER THEY HAVE A CALL `PRINTF()`, BUT AT RANDOM. SOMETIMES THEY WORK PERFECTLY! INSANE.
      I also get the `-48` error `UNSUPPORTED (log once): createKernel: newComputePipelineState failed` 
      with `zig run gpt-opencl-simple-2.c.zig -framework OpenCL` whenver I use two calls
      to printf in the kernel... This is the same failure mode! This is entirely an OpenCL 1.2 on macos 12 issue.


## How should one debug OpenCL ?

Or any highly parallel GPU code? 
On the CPU lldb gives you the ability to jump between threads, and each thread has it's own callstack.
The GPU is the same, it's just that it has thousands of threads instead of 16... Why doesn't it provide the same
interface?

If this isn't possible, and it's not possible to do printf debugging anymore on macos 12, then how can we debug kernels?
MAC must provide good kernel debugging tools for metal.

And there must be a way for me to use them from zig...
What about webgpu? I think it's syntax looks like metal. does google's DAWN also provide good debugging tools?
I think the endgame is either using metal directly + SDL, or Metal + sokol bindings.
WebGPU ...





# comptime vs runtime polymorphism

How many times does your code need to pass through the compiler beofore it is executable by machine?
running commands that have already been compiled. Each command is a small program.

The comptime vs runtime distinction makes us think about DAGs of expressions / values. 
What expressions can we evalute given the values that we have?
What expressions depend on unknowns?
If a value can only be known at runtime then it's a runtime value.
The parts of the language that are available at runtime are different from the parts availabe at comptime!
We can only use the allocator at runtime? 
`comptime_int` is a type that only exist at comptime.
We can only do loop-unrolling 

- Comptime code: it has all the information that it needs to be evalua
Comptime code is interpretable at compile time. There is enough information to evaluate statements and expressions.
Runtime code is whatever can't be evaluated at compile time because it has a runtime-only dependency (e.g. user input).

JIT compilation is using the power of the compiler at runtime, once we know more about some of the values in our code.
This means we can get real array types with runtime known length.
This means we have to be able to run the compiler at runtime! This means our compiler must ship with our executable!
This is the biggest downside to JIT compilation. We have to ship the compiler (a massive runtime dependency) with our executable.
This is probablly not worth it! 
It would be nice to be able to do more dynamic stuff at runtime. 
At the moment we can do compile-time duck typing to enable highly generic functions that are type checked.
These functions are duplicated for each type signature of arguments used.
An alternative is to do _runtime_ dispatch, where we assert that everything type checks, but instead of duplicating 
the function for each type signature across all call sites we look up the right internal functions to call at runtime.

Ideally we would be able to do type checking, generic function instantiation, specialized optimization, etc 
SO FAST that we could do it at runtime! Then we continuously re-compile our code as we gain more and more information during the running of our program! 
Instead, we do all the really expensive function lookup, optimization passes, etc during compilation, 
and then we don't have to do anything tricky at runtime!
A program "having a runtime" means that the compiler inserts it's own code into our code!
Not knowing where or what will be inserted makes it harder to reason about performance and control flow.

JIT compilation essentially 

At the moment to do dynamic dispatch we have to create an interface as documented in `Allocator.zig` and `Random.zig`.
These interfaces are initialized with `Interface.init(ptr,vtable)` and the pointer is type-erased cast to `*anyopaque` and the vtable is one more many functions which depend on that `*anyopaque` pointer type (methods of that type).

How is this different from compile-time dispatch (which duplicates the function body for each input type)?
With interfaces we get a new interface type. Functions that depend on this type don't have to be duplicated,
because there is only one type the function sees! To create the interface we generate a _new_ type, then essentially
cast it to the interface, which compresses multiple types into one.

Does ZLS know where our method is implemented? or does it just point to the generaic interface's method?
At definition it has no idea who's calling. At call site it has no idea which method we want to jump to.
This is annoying. If all our code uses generic interfaces, then we rarely jump to real method implementations.

When we compile down to an executable object file there are `.text` (code) and `.data` sections...

- [github: vtables in zig? ](https://github.com/ziglang/zig/issues/130)
- [github: comptime interfaces in zig](https://github.com/ziglang/zig/issues/1268)
- [tutorial: dynamic polymorphism in zig](https://revivalizer.xyz/post/the-missing-zig-polymorphism-reference/)
- [github: Alex Nask's Interface code](https://github.com/alexnask/interface.zig)
- [gist: Alex Nask's Interface code (OLD)](https://gist.github.com/alexnask/1d39fbc01b42ce2b5b628828b6d1fb46)
- [Alex Nask's YouTube talk](https://www.youtube.com/watch?v=AHc4x1uXBQE&ab_channel=ZigSHOWTIME)

So does this Interface approach to runtime polymorphism allow us to write _precompiled libraries_ that 
have our Interface in the exposed API? Is this another advantage over functions which are generic taking an `anytype`?

- [ ] fix the bug in `reference/interface.zig` that causes printing random memory.


# Trees, Graphs, and Perfect Hash

Arrays are just efficiently packed perfect hash of positive integers.
The positive ints written in binary of length N are a description of a path down a binary tree to a node at layer N.

Decimal `13` is binary 8 + 4 + 1 = `0b1101`.
Each binary digit tells us `left` or `right` as we descend a binary tree, making binary numbers length N equivalent to a Path.
We have to keep leading zeros. `0b001101` is equivalent to `0b1101` as a number, but not the same path!
With the right [perfect hash](https://en.wikipedia.org/wiki/Perfect_hash_function) we can map an arbitrary Path description to a unique memory location.
Further, if our hash has collisions we can use buckets. 
Then we can accept the number of existing items in each bucket as an additional parameter, making a perfect hash again.
FAIL: Then the representation depends on the order of insertion.

This is only useful if we know the positions of elements won't change.
If our hash depends on the relationship between nodes in graph/tree then it is likely to break when the graph changes.
Static binary tree must remain static.
But sometimes we must explore the data to find the element we want.
Traversing multiple pointer (index) indirections may be necessary.
It's more efficient to store elements in array and use indices than to store elements in Allocator and use pointers.

A tree can be represented in memory [in many ways](https://stackoverflow.com/questions/2675756/efficient-array-storage-for-binary-tree)

- store mapping between node ids (edge list `(i,j),(i,k),...` or array where `arr[i]=n` means `n` points to `i`)
- dense representations without ids:
      + LISP syntax clearly represents an AST.
      + depth-first traversal with special symbols to mark e.g. "no child"
      + special case: store structure of tree only. data is just `1` marking node as "present".
- sparse representations without ids:
      + binary tree can has a perfect hash that is dense for complete tree i.e. bredth first traversal without compressing empty nodes. see also [Binary Heap](https://en.wikipedia.org/wiki/Binary_heap). The children of node stored at `i` are stored at `2i,2i+1`.

In most cases we probably just want to store 
1. node labels →  dense id's `[1..n]`
2. graph of dense id's (edge list or parent array)
3. dense id's → node data (all node info stored separately here)

OR we simply store `[]Elem` where `const Elem = struct {parent:u16, child1:u16, child2:u16, data:Data}`.
This can take the same form on disk and in RAM.

Serialization is not some special case we only think about when saving to disk.
How objects are laid out in memory is serialization.


```zig
const Step = enum {left,right,straight};
const Path = [10]Step;
fn getElem(tr:[]Elem, pa:Path) Elem {
      const idx = perfectHash(pa);
      return tr[idx];
}
```


Explicitly representing Paths also unlocks things like _relative locations_ of Elements in the tree.
e.g. we can have `const relative_path:RelPath = path_1 - path_2;` and `const next_elem:Elem = path_1 + relative_path;`.

But the point of trees is that they can easily grow and shrink... And we can easily add and remove nodes anywhere...
This is easiest is we simply pass the work of assigning memory to `malloc`... Maybe this is even fast if we use a FixedBufferAllocator... But we still have to include pointers at every node... 
Is there a middle ground? 


```
1 2 3 ↑ 4 5 ↑ ↑ ↑ 6 ↑ 7

-----------------------

          ┌────┐                
          │ 1  │                
          └────┘                
             │                  
       ┌─────┴────┬──────────┐  
       │          │          │  
       ▼          ▼          ▼  
    ┌────┐     ┌────┐     ┌────┐
    │ 2  │     │ 6  │     │ 7  │
    └────┘     └────┘     └────┘
       │                        
   ┌───┴─────┐                  
   │         ▼                  
   ▼      ┌────┐                
┌────┐    │ 4  │                
│ 3  │    └────┘                
└────┘       │                  
             └───┐              
                 ▼              
              ┌────┐            
              │ 5  │            
              └────┘            

```
- write lisp! `(1 (2 3 (4 5)) 6 7)` . Use special markers to begin / end subtrees. this is flexible enough to be used with trees of any shape.
- dense array mapping index to parent. _must assign unique positive integer ID to nodes_. This is not necessary with 
```
parent   1 2 3 4 5 6 7
child    0 1 2 2 4 1 1
```
- matrix of edges {0,1}^NxN for N nodes. 
- edgelist `(1,2), (2, 4), (1, 5), (2, 5), ... ` 
- So if we have to do e.g. a depth-first-search. How do we do this in the tree-


There are so many ways of representing graphs / trees.
It's like rotations. There are so many ways of representing rotations.
And these are really simple objects! But also highly flexible objects.




# Mouse controls / view / 3D Rotations

Idea to use spherical coordinates from [here](https://quaternions.online/).
R/gamedev also recommends spherical coords [here](https://www.reddit.com/r/gamedev/comments/16zejj/3d_camera_orbit_drag_zoom/).
NOTE: the spherical coords phi/theta system is like roll/pitch/yaw . 


But I wrote `R(theta,phi)` by manually taking derivatives of the following system:
This equates theta with "yaw" and phi with "pitch".

```
z' = r(theta,phi)
x' = norm [ dr/d_theta ] 
y' = dr/d_phi
```

where `r(theta,phi)` is a spherical coordinate system that aligns `r(0,0) = -z`.

```
r_x = norm(    cos(theta) * cos(phi), 0        ,   sin(theta) * cos(phi) )
r_y =         -sin(theta) * sin(phi),  cos(phi),   cos(theta) * sin(phi) 
r_z =         -sin(theta) * cos(phi), -sin(phi),   cos(theta) * cos(phi) 
```


# Building and Dependencies

Starting out, I thought this was a ZIG problem, but now I know it's really a MACOS problem.

I'd like to build a static version of `bioviewer` that works on other systems running macos-x86_64.
Brew installs static libraries (`.a`) in addition to dynamic (`.dylib`). 
But linking against them is not as simple as replacing `linkSystemLibrary` with `addObjectFile`.

My [github search](https://cs.github.com/?scopeName=All+repos&scope=&q=lang%3Azig+libSDL2) shows that
1. linking `*.a` requires explicitly including transitive deps
2. linking SDL2 on macos is usually done using brew and dynamic linking.

**I could include run some brew commands as a part of build!**
But this sounds scary. I don't want to mess up my user's brew system!

Attempting to build now reveals a littany of missing symbols during linking...
```
error(link): undefined reference to symbol '_objc_sync_enter'
error(link):   first referenced in '/usr/local/Cellar/sdl2/2.0.14_1/lib/libSDL2.a(SDL_cocoawindow.o)'
error(link): undefined reference to symbol '_jpeg_set_defaults'
error(link):   first referenced in '/usr/local/Cellar/libtiff/4.4.0_1/lib/libtiff.a(tif_jpeg.o)'
...
```
These missing symbols live in the transitive dependencies of my project, which are often the direct dependencies of `SDL` and `TIFF` libraries.

We can determine the set of dependencies by using `otool`.
We run `otool -L zig-out/bin/biopencil` to see our link dependencies.
Initially it shows `libtiff.dylib`,`libSDL2.dylib`, the `OpenCL.framework` and `libSystem.B.dylib`.
But these are only our direct dependencies!

We can use otool recursively [via python](https://stackoverflow.com/questions/1517614/using-otool-recursively-to-find-shared-libraries-needed-by-an-app) (see `detect_dylibs.py`), but in pracitce it was easier to do this manually...
This reveals 2nd order deps: `libjpeg.8.dylib` and `libz.1.dylib`.

- [dealing with iconv](https://stackoverflow.com/questions/57734434/libiconv-or-iconv-undefined-symbol-on-mac-osx)

Some of these deps live in macos Frameworks, e.g. `Cocoa`.
I can static link `libjpeg` and dynamic link (a lot of) Frameworks.
This in theory allows distributing binaries that don't require installing 3rd party libs.

__But I'm not using these dependencies!__
Unnecessary dependencies shrink viable set of target systems.

Q1: Is there a way to static build that avoids unnecessary dependencies?

- [How to remove unused C/C++ symbols with GCC and ld?](https://stackoverflow.com/questions/6687630/how-to-remove-unused-c-c-symbols-with-gcc-and-ld)
- [Remove dead code when linking static library into dynamic library](https://stackoverflow.com/questions/50881619/remove-dead-code-when-linking-static-library-into-dynamic-library)
- 

Q2: Does building from source allow me to avoid these dependencies?

- [attempting backwards compatibility on macos despite dynamic linking](https://stackoverflow.com/questions/15091105/confusion-of-how-to-make-osx-app-backward-compatible-how-to-test-them)
- [why don't people vendor SDL2?](https://www.reddit.com/r/gamedev/comments/o5qrao/sdl2_is_zlib_licensed_but_why_its_not_included_in/)

## Static linking on OSX is discouraged

Apparently [it is common](https://stackoverflow.com/questions/844819/how-to-static-link-on-os-x) to static link against a third user library while dynamically linking against the system frameworks and libraries.
[Pure static linking including all Frameworks is not possible.](https://developer.apple.com/library/archive/qa/qa1118/_index.html)


## Modal Editing

Proposed Modes

1. View and Explore: No annotations can be created. Optimized for easy exploration. Mouse Drag on 3D view rotates. Can move rectangles around on 2D projection. Dragging corner of rectangle resizes it and changes zoom. We can add multiple rectangles? This sounds like adding an annotation. Are our viewing rectangles equivalent to bbox annotations?

2. Label Images: Painting and relabel. Adjust boundaries.

3. 3D Pencil annotation. Should be available in perspective and orthogonal projections. 

- All annotations should be selectable. Easy creation, deletion, grouping, add metadata to annotations in bulk.
- Modes for tasks? Spot counting, Tracking, Semantic Seg, Instance Seg, Mitosis Detection, etc ?
- Or just some generic tools that are useful for many tasks? Pencil, Circle, Rectangle, Track. Labeling Annotations. 

The way we select objects, etc should know the difference between image types.
This is in addition to modes for tasks like tracking, segmentation, spot counting, etc.
Different image semantics: nuclear marker, membrane marker, u16 object labels, pixelwise labels, 
generic fluorescence, histology rgb?

### Tracking Mode

- [ ] allow object to occlude tracking tails
- [ ] manual tracking annotation in max projection view uses smart depth inference
- [ ] extend tracks by dragging mouse with right hand and tapping "space" with left to advance time point.
      - [ ] use same workflow for moving bounding boxes through time.



# Features

- [x] two rotation angles
- [x] box around border
- [x] dragging with cursor
- [x] drawing with fw/bw 3D map 
- [x] proper window size. has a max width, but otherwise is h/w proportional to x,y image size. anisotropy interpreted from image.
- [x] connect two windows via draggable box
- [ ] branch early on `mode` . move logic into mode-specific trees.
- [ ] save anno to disk
- [ ] Scroll through time. Live load of new data from disk / mem.
- [ ] REPL interface with autocomplete to adjust params. access nested, internal structs. interactive.
- [ ] colors: smoother color pallete...
- [ ] semantic labels for objects, object selection and manipulation, colors based on object label.
- [ ] add text labels pointing to objects that follow them over time and during view manipulation, rotation, etc.
- [ ] Loops and BoundingBox partial occlusion by nuclei
- [ ] #perf Allow window resize without changing the cost of opencl projection (keep number of rays small), then upscale them efficiently (maybe also on GPU?) related to kernel chaining?!
- [ ] #perf Dynamically adjust the quality of depth rendering while view is updating. (lower density sampling in X,Y,and Z) Still shots get higher quality?



## Loading data

Make sure we can open TIFF files with

- [x] multiple bit depth
- [x] uint,int,float
- [ ] multiple samples per pixel (channels)
- [ ] 2D/3D/4D (time)

## Drawing in 3D

We want to draw smooth lines at the precision level of the _view_ not of the underlying image.
Thus we want 3x f32 coordinates and linear interpolation between those points.
We can save, sort, color, select, name, etc objects at the object level, and objects don't merge
together even if our lines cross!

We can use pixelToRay() to get the ray to cast into the volume, but then how far do we go?
go until each ray hits the z from zbuffer.

--- 

We could provide a more precise option for 3D drawing, where you first draw in max-proj view, 
but then are presented with a side view (orthogonal?) to control the depth by tracing with your pencil.

The surface is defined by the intersection of the two sheets defined by the two view's Rays. 
Of course there may be multiple intersection points... We have to disambiguate them somehow.


## Easy 3D bounding box creation and extension in depth

We want a _collections_ of rectangles / bboxes.
- rendering during drawing and during rotation
- [ ] move existing rectangles
- [ ] live view updating in 2nd window
- Q: are they 2d or 3d ? 
      - [ ] 3D required for volume rendering in 2nd window / 3D bbox annotations
      - [ ] can infer 3D bbox from 2D using heuristics




# Bugs

- [ ] The rendering uses `maxSteps=30` which causes severe aliasing from undersampled depth dimension, but increasing causes severse slowdown.
- [ ] `r.direc` needs rescaling by `view.anisotropy`. Use dot product?
- [ ] make depth coloring use colors of equal luminance! blue is much darker than yellow!
- [x] `/fisheye/training/ce_024/train_cp/pimgs/train1/pimg_211.tif`: "Sorry, can not handle images with IEEE floating-point samples."

## Invalid Kernel on M1 mac

- Error: CL_INVALID_KERNEL
- Hypothesis: I'm instantiating the kernel with invalid arguments that happen to type check properly
- Experiment: Can I instantiate a simpler kernel where I know args are valid ? 
- Result: 

# Zig Questions

- when to use `@as` vs `@intCast` ?


