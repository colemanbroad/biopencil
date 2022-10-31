# Tue Sep 27 10:29:35 2022

Get rendered image to appear in a SDL window.

# Wed Sep 28 00:29:14 2022

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
which required a view_angles →  rotation matrix transformation (`rotmatFromAngles()`), but we could update view_angles by 
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


---

# Performance

Reading TIFF is slow. 95MB tiff file reads in 2s... Most of this must be decoding, because I can `dd` the file to `/dev/null/` at 4GB/s.
      UPDATE: 84MB tiff Tribolium reads in 1.3s. This is def too slow.
OpenCL device & context creation is slow and highly variable. Between 60ms .. 450ms. Also I feel noticeable lag on my screen when working with most apps. This is a problem with my laptop's graphics hardware.

Thu Oct 27 01:33:24 EDT 2022
UPDATE: No idea why... but suddenly after the refactor into Window.init() we can suddenly open an SDL window in 15 ms.

We can profile our application with a simple sampling profiler!
[mac profiling tips](https://gist.github.com/loderunner/36724cc9ee8db66db305)
1. [call stack sampling](https://stackoverflow.com/questions/375913/how-do-i-profile-c-code-running-on-linux/378024#378024)
2. [more call stack sampling](https://stackoverflow.com/questions/1777556/alternatives-to-gprof?noredirect=1&lq=1)
3. [using instruments on mac](https://stackoverflow.com/questions/11445619/profiling-c-on-mac-os-x)


`sample clbridge 30 -f sample.txt`
`sample [pid | app name] [time in s [sample rate default 1 ms]] `

Thu Oct 27 12:02:50 EDT 2022
Profiling reveals that reading from the volume sampler in OpenCL is ACTUALLY a hot spot. And 
that calling kernels in general is slow.

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

# Hierarchy

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


Since View is used in and out of Kernels it cannot be a Kernel-specific type.
We can also use View for drawing loops w CPU.

embedLoops(View)
perspective_projection.kernel.call(View)

View must be global?


# Modal Editing

Modal editing should include modes for editing LABEL IMAGES / RAW FLUORESCENCE / etc !
The way we select objects, etc should know the difference between image types.
This is in addition to modes for tasks like tracking, segmentation, spot counting, etc.
Different image semantics: nuclear marker, membrane marker, u16 object labels, pixelwise labels, 
generic fluorescence, histology rgb?


# Drawing in 3D

We want to draw smooth lines at the precision level of the _view_ not of the underlying image.
Thus we want 3x f32 coordinates and linear interpolation between those points.
We can save, sort, color, select, name, etc objects at the object level, and objects don't merge
together even if our lines cross!

We can use pixelToRay() to get the ray to cast into the volume, but then how far do we go?
go until each ray hits the z from zbuffer.


# Max projection mode

easy 3D bounding box creation and extension in depth

# Mouse controls | View

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


# Let's rethink how we describe kernel parameters

Parameters may be read or write (rw), they may be written once or repeatedly (1!)...
they may describe buffers that require special buffer commands, or non-buffer args (bn).


# Tracking Mode

- [ ] allow object to occlude tracking tails
- [ ] manual tracking annotation in max projection view uses smart depth inference
- [ ] extend tracks by dragging mouse with right hand and tapping "space" with left to advance time point.
      - [ ] use same workflow for moving bounding boxes through time.

# Features

- [x] two rotation angles
- [x] box around border
- [ ] clicking with fw/bw 3D map 
- [ ] dragging with cursor
- [ ] REPL interface with autocomplete to adjust params. access nested, internal structs. interactive.
- [ ] colors: smoother color pallete...
- [ ] semantic labels for objects, object selection and manipulation, colors based on object label.
- [ ] add text labels pointing to objects that follow them over time and during view manipulation, rotation, etc.
- [x] proper window size. has a max width, but otherwise is h/w proportional to x,y image size. anisotropy interpreted from image.
- [ ] Loops and BoundingBox are always drawn on top of image... Should they be ? No, this is why we started this project in the first place.
- [ ] Dynamically adjust the quality of depth rendering while view is updating. (lower density sampling in X,Y,and Z) Still shots get higher quality?



# Bugs

- [ ] The rendering uses `maxSteps=30` which causes severe aliasing from undersampled depth dimension, but increasing causes severse slowdown.
- [ ] `r.direc` needs rescaling by `view.anisotropy`. Use dot product?
- [ ] make depth coloring use colors of equal luminance! blue is much darker than yellow!
- [x] `/fisheye/training/ce_024/train_cp/pimgs/train1/pimg_211.tif`: "Sorry, can not handle images with IEEE floating-point samples."

# Zig Questions

- when to use `@as` vs `@intCast` ?


