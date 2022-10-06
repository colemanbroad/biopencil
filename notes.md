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

# Questions

- when to use `@as` vs `@intCast`.

# Features

- [x] two rotation angles
- [ ] box around border
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



