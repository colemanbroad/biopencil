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
- #todo how to draw only on sub rectangle?
- 




# Questions

- when to use `@as` vs `@intCast`.


# Todo

## more interactive

- [x] two rotation angles
- [ ] box around border
- [ ] clicking with fw/bw 3D map 
- [ ] dragging with cursor
- [ ] text box that exposes dynamic parts of program and allow user costomization. has autocomplete.
        ideally the internal interface allows us to expose arbitrary (nested) structs and update them interactively via user.
- [ ] 

- [ ] colors: smoother color pallete...