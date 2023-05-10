# Get rendered image to appear in a SDL window

This is the beginning of a beautiful friendship...

Wed Sep 28 00:29:14 2022

Get rendered image to appear in a SDL window.
IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    
IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    
IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    
IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    IT WORKS    

1. load an ISBI tiff
2. volume render it with perspective in OpenCL
3. display the result in an SDL window

Tue Oct  4 16:54:47 2022

Fast and efficient volume renderning with 1D rotation and color, takes a TIFF path as cmd line arg.


# Use two rotation angles instead of one

Wed Oct  5 15:16:13 2022

Parameterize view state by 3x3 rotation matrix and update it with arrow keys.
This is more powerful representation than the previous `view_angles:
[2]f32` model which required a view_angles → rotation matrix transformation
(`rotmatFromAngles()`), but we could update view_angles by simply adding a
scalar value.

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

# Mouse controls rotation, not keyboard

see `mouseMoveCamera()`


# White box around image volume

I want a bright box around the outside of the rendered image to enhance the 3D 
effect. This box should be drawn directly on screen (not via OpenCL). This will
require knowing the image volume's bounding coordinates and a function that 
maps from the volume's 3D coordinates to screen coordinates.

see `pointToPixel: View,Pt -> Pix`


# Draw pencil loops in 3D

Mon Oct 17 12:40:49 EDT 2022

We want to draw smooth lines at the precision level of the _view_ not of the
underlying image. Thus we want 3x f32 coordinates and linear interpolation
between those points for path segments. With discrete loops we can save,
sort, color, select, name, etc objects at the object level, and objects don't
merge together even if our lines cross!

We can use `pixelToRay()` to get the ray to cast into the volume, but then how
far do we go? go until each ray hits the z from zbuffer.

Drawing in 3D works! But the z-resolution is weak. Naive Blurring on CPU is too slow.
So let's not blur/denoise the depth map, and instead take an average over the depth
values _along the loop_! We can keep the depth value constant for simplicity, but we 
may want to do a local denoising (convolution with box or gaussian) along the 1D loop
path. This would allow for some variation in depth without looking too noisy. 

# Connect Two Windows Via Draggable Box

We can have a high-level overview of an image at a low resolution and connect
it to a zoomed-in high resolution view of the same image by controlling a window
that can be panned / dragged around the low-res view.


# Building portable binaries on mac

Starting out, I thought this was a ZIG problem, but now I know it's really a MACOS problem.

I'd like to build a static version of that works on other systems running macos-x86_64.
Brew installs static libraries (`.a`) in addition to dynamic (`.dylib`). 
But linking against them is not as simple as replacing `linkSystemLibrary` with `addObjectFile`.

My [github search](https://cs.github.com/?scopeName=All+repos&scope=&q=lang%3Azig+libSDL2) shows that
1. linking `*.a` requires explicitly including transitive deps
2. linking SDL2 on macos is usually done using brew and dynamic linking.

Solutions
1. run some brew commands to install SDL as a part of build
      But this sounds scary. I don't want to mess up my user's brew system. 
2. download SDL with curl and install to local folder

Attempting to build now reveals a littany of missing symbols during linking:
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

-[dealing with iconv](https://stackoverflow.com/questions/57734434/libiconv-or-iconv-undefined-symbol-on-mac-osx)

Some of these deps live in macos Frameworks, e.g. `Cocoa`.
I can static link `libjpeg` and dynamic link (a lot of) Frameworks.
This in theory allows distributing binaries that don't require installing 3rd party libs.

But I'm not using these dependencies!
Unnecessary dependencies shrink viable set of target systems.

Q: Is there a way to static build that strips unused transitive dependencies?

-[How to remove unused C/C++ symbols with GCC and ld?](https://stackoverflow.com/questions/6687630/how-to-remove-unused-c-c-symbols-with-gcc-and-ld)
-[Remove dead code when linking static library into dynamic library](https://stackoverflow.com/questions/50881619/remove-dead-code-when-linking-static-library-into-dynamic-library)


Q: Does building from source allow me to avoid these dependencies?

-[attempting backwards compatibility on macos despite dynamic linking](https://stackoverflow.com/questions/15091105/confusion-of-how-to-make-osx-app-backward-compatible-how-to-test-them)
-[why don't people vendor SDL2?](https://www.reddit.com/r/gamedev/comments/o5qrao/sdl2_is_zlib_licensed_but_why_its_not_included_in/)

_Static linking on OSX is discouraged_

Apparently [it is common](https://stackoverflow.com/questions/844819/how-to-static-link-on-os-x) to static link against a third user library while dynamically linking against the system frameworks and libraries.
[Pure static linking including all Frameworks is not possible.](https://developer.apple.com/library/archive/qa/qa1118/_index.html)


# Modal Editing

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

# Smart Tracking Annotation

Manual tracking annotation in max projection view uses smart depth inference.
We could also extend tracks by dragging mouse with right hand and
tapping "space" with left to advance time point. We could use the same
workflow for moving bounding boxes through time.

# Nuclear occlusion

If we return both the perspective projection AND the z-depth buffer from our
kernel then we can add tails to objects in the same way that we add loops,
but whenever the tail/loop pixel drawn has a 3D coordinate that is behind the
z-depth then it's not drawn. This could work for tracking tails, annotation
loops and bounding boxes!

# High precision 3D drawing

We could provide a more precise option for 3D drawing, where you first draw in
max-proj view, but then are presented with a side view (orthogonal?) to
control the depth by tracing with your pencil. The surface is defined by the
intersection of the two sheets defined by the two view's Rays. Of course
there may be multiple intersection points... We have to disambiguate them
somehow.

# Save and reload loop annotations

Let's save and load to a consistent file name in the local directory to simplify
things initially. Loading is done at startup so the loops just appear. But eventually
we'll need to decide between this automatic behaviour (similar to Skim's PDF annotations)
and manual save/load. Also, we'll have to revisit this when we add more object types
to our annotations!

# Easy 3D bounding box creation

We want to be able to extend objects in along the Z dimension easily. Creating
a 2D bbox is a simple drag, then with a single click the view should rotate
90deg and we can place the rectangle (now a line segment) along the depth
dimension and extrude it to form a box.

# Make window dimensions proportional to image

Give the window a proper size proportional to the image using minimal code.
There should be a max width ? Or should the window width be fixed and the height
should scale? Can we determine the voxel anisotropy and incorporate that?

# Scroll through time

Live load of new data from disk / mem.

# Editing collections of annotations

We want a _collection_ of rectangles / bboxes / lines and curves. These
collections should be editable: add / move / delete and possibly reshape for
bboxes and circles. Objects need to be selectable, which requires
highlighting selected objects and having an intuitive way to select in 3D.

_WARNGING!!! We'll need separate rendering during object creation / standard viewing._

# Severe aliasing on depth dimension

The rendering uses `maxSteps=30` which causes severe aliasing from
undersampled depth dimension, but increasing causes severse slowdown. Maybe
`r.direc` needs rescaling by `view.anisotropy`. Use dot product?

# Equal luminance depth coloring

Make depth coloring use colors of equal luminance! blue is much darker than
yellow!

# Open variety of file types

`/fisheye/training/ce_024/train_cp/pimgs/train1/pimg_211.tif` 
-[x] Sorry, can not handle images with IEEE floating-point samples." This is now
fixed. 

-[x] open files with multiple bit depth
-[x] open files with uint, int, float
-[skip] open files with multiple samples per pixel (channels) 
-[skip] open files with 2D/3D/4D (time)

What about the fact that the most common bit depth coming off of the
microscope is actually 12? I need a single function and it can return a union
over various image types.


# Invalid Kernel on M1 mac

- Error: CL_INVALID_KERNEL
- Hypothesis: I'm instantiating the kernel with invalid arguments that happen to type check properly
- Experiment: Can I instantiate a simpler kernel where I know args are valid ? 

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

- why can't i create a readwrite buffer from a pointer i own and pass that to opencl successfully? the memory is zeroed out in the buffer somehow...
I could try all combinations.....

I've got it narrowed down to a very small test case. 

1. Using C I can run kernels which take a buffer and a non-buffer as arguments
and successfully write to the buffer.

2. I can translate this to ZIG with `translate-c` and it runs exactly the
same, so I know that passing normal args via `&number` works in zig even when
I cast to `?*const anyopaque`. The remaining possible causes for the error
`error.CL_INVALID_KERNEL` returned from `clCreateKernel()` cannot be related
to the later calls like `cl.clSetKernelArg(kernel, i_argnum, @sizeOf
(cl.cl_mem), @ptrCast(?*anyopaque, &buffers_1))`... It must be related to the
actual kernel source... Maybe it doesn't type check? But this would be a
problem during `buildProgram()`... 

3. Now I can run kernels that write to buffers, but I can't print when the
buffer is called? This is strange. PRINTING IS ERRATIC. It doesn't work with
regularity. IT WAS THE PROBLEM. PERFECTLY GOOD KERNELS WILL THROW `OPENCL
ERROR: -48 ERROR.CL_INVALID_KERNEL` WHENEVER THEY HAVE A CALL `PRINTF()`, BUT
AT RANDOM. SOMETIMES THEY WORK PERFECTLY! INSANE. I also get the `-48` error
`UNSUPPORTED (log once): createKernel: newComputePipelineState failed` with
`zig run gpt-opencl-simple-2.c.zig -framework OpenCL` whenver I use two calls
to printf in the kernel... This is the same failure mode! This is entirely an
OpenCL 1.2 on macos 12 issue. OK, I've narrowed down the problem even
further... Printing only works THE FIRST TIME it's called in any kernel
thread! Trying to print twice causes an INVALID KERNEL crash. But with live
reload we can toggle which printf is active and transition between them
easitly.

# Debugging max projection

Wed Mar 22, 2023

The perspective projection is pure black, but the early-returning orthogonal
projection shows the correct image. This means there is a bug in the
perspective projection code (which hasn't changed) or some of the parameters
we're passing in are wrong... It was the packing of the struct! This was an
easy fix that I purely guessed... changing `struct View {}` to `extern struct
View {}` was the entire fix. No warning about wrong memory layout from OpenCL!


# Draggable projection subvolume for large images

see also [connect two windows via draggable box]

Sun Oct 23 12:37:26 EDT 2022

When data is too thick we should be able to narrow the volume through which we perform projection.
This volume should be easily customizable and draggable through the full volume.
This also makes computing the projection easier as we make the volume smaller.


# Slow Startup Time

Reading TIFF is slow. 95MB tiff file reads in 2s... Most of this must be
decoding, because I can `dd` the file to `/dev/null/` at 4GB/s. UPDATE: 84MB
tiff Tribolium reads in 1.3s. This is def too slow. OpenCL device & context
creation is slow and highly variable. Between 60ms .. 450ms. Also I feel
noticeable lag on my screen when working with most apps. This is a problem
with my laptop's graphics hardware?

Let's speed test load TIF vs load RAW... It's the same! Saving an f32 was
30ms, loading was 90ms with significant variability, but was less if we use
f16 instead of f32. But doing the same in python with skimge.io was > 300ms !
With python's `tifffile.imread` it was 280ms ! The image is 12.3e6 pixels,
and 5.7MB! It uses LZW compression to get down to 5.7MB when it should be
12.3MB. So the 90ms load includes decompression ?! So maybe we don't actually
pay a huge price for TIFF format, if we avoid using python to load ?

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

Thu Oct 27 12:02:50 EDT 2022 Profiling reveals that reading from the volume
sampler in OpenCL is ACTUALLY a hot spot. And that calling kernels in general
is slow. Also, our line-by-line timing is misleading, because the
asynchronous execution of `executeKernel()` makes it look like we spend all
our time _reading out data_, when in fact it's executing kernels.

Reading from TIFF is slower than reading from RAW using `Img3D.load()`.

*Read data timings*
- readTIFF3D 231 ms
- save img f32 33 ms
- load raw f32 109 ms
- save img f16 21 ms
- load raw f16 68 ms

It may actually be faster to load using the RGBA tiff interface than the
`TIFFRasterScanlineSize64` interface!? confirm and explain this.

# Live Reload of OpenCL Kernels

I want to be able to live edit the OpenCL code to change the projection and
have the app recompile the kernel on the fly. This is possible! But 

# High Level UI Approach

One approach is based on a *REPL interface* with autocomplete. Reading and
writing to in in-process terminal. This approach is makes it easy for the
user to record a series of commands, to create complex commands, and for the
app to display internal variables. We could use it to adjust params, access
nested and internal structs.

Another approach is a *standard GUI* with buttons, sliders, etc. App state is
displayed though graphical elements. Buttons have labels and icons to convey
their meaning. Tooltip hover can add detail on function. The whole GUI can be
hidden when our App is a single window (like `tab` in Affinity). But if we
have a multi-window App then layout tends to get messier...

For starters we're just listening for KeyEvents and internal App state is
simple enough. But even after a few months away I've forgotten the keys to
use and wish I had a "help" feature or a README.

# Add text labels on objects

These are visible labels that name objects and follow them over time and
during view manipulation, rotation, etc. They maintain their orientation when
the underlying image is rotated.

These labels could convey unerlying object semantics (cell, nucleus, membrane,
movement, division, death, etc) through their text e.g. `nucleus 1`, `cell
AB`, etc. Or they could be text + semantic icon? Or they could have semantic
colors. 

# Ziggify OpenCL Headers with translate-c

It is recommended that `@cImport()` only be used when the c header file is
changing often, as this runs `zig translate-c` under the hood. We should
instead run translate-c once and import it as normal. 

Q: But how does the new `cl.zig` file talk to C libraries? Doesn't it have
to do a transitive `@cImport()`?
A: No, I believe all transitive header definitions are collected in `cl.zig`
so all we have to do is link against the appropriate library!

# Refactor Event Loop and App State

Right now all our event code is stuck inside the event loop. We should
refactor this into a function that takes `(AppState, Events) -> AppState`. If
we branch early on the interaction mode we can move the update logic into
mode-specific trees.

# Refactor OpenCL maxproj out of biopencil

At the momenet all the app logic and interfacing with opencl lives in
biopencil. This is fine, but I think the opencl logic is really quite
distinct and probably too generic. We really just want a way to call the max
projection kernel. This will require a setup() / init() function to get the
(devi, ctx, cmd_q, prog, kernel), build the buffers and enquqe all the args.
Since we're only doing this for one function we may as well only do it one
time. Then we'll need a second function which takes the Kernel object with
all it's state and renders into a buffer of our choosing.

# Allow window resizing

Allow window resizing without changing the cost of opencl projection i.e. keep
same number of rays, then upscale them efficiently, maybe even also on the
GPU. Maybe the projection and depth buffers don't even have to leave the GPU?
Is this related to "kernel chaining"?

# Dynamic render depth

Dynamically adjust the quality of depth rendering while view is updating.
Start with lower density of points in X,Y and longer step length (lower Z
density). Then she image quality improves with time and still/stationary
views get high quality rendering?



