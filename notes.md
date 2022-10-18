# Tue Sep 27 10:29:35 2022

Get rendered image to appear in a GLFW window.

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
readTIFF3D [96..105]ms
convert to grey [87..92]ms
save grey [19..22]ms
load raw [69..75]ms
```

Drawing in 3D works! But the z-resolution is weak. Naive Blurring on CPU is too slow.

# Questions

- when to use `@as` vs `@intCast`.

# Features

- [x] two rotation angles
- [x] box around border
- [ ] clicking with fw/bw 3D map 
- [ ] dragging with cursor
- [ ] REPL interface with autocomplete to adjust params. access nested, internal structs. interactive.
- [ ] colors: smoother color pallete...


# Bugs

- [ ] The rendering uses `maxSteps=15` which causes severe aliasing from undersampled depth dimension, but increasing causes severse slowdown.
- [ ] Reading TIFF is slow. 95MB tiff file reads in 2s... Most of this must be decoding, because I can `dd` the file to `/dev/null/` at 4GB/s.
- [ ] OpenCL device & context creation is slow and highly variable. Between 60ms .. 450ms. Also I feel noticeable lag on my screen when working with most apps. This is a problem with my laptop's graphics hardware.
- [ ] `r.direc` needs rescaling by `view.anisotropy`. Use dot product?
- [ ] make depth coloring use colors of equal luminance! blue is much darker than yellow!

# Drawing in 3D

We want to draw smooth lines at the precision level of the _view_ not of the underlying image.
Thus we want 3x f32 coordinates and linear interpolation between those points.
We can save, sort, color, select, name, etc objects at the object level, and objects don't merge
together even if our lines cross!

We can use pixelToRay() to get the ray to cast into the volume, but then how far do we go?
go until each ray hits the z from zbuffer.



