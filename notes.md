
# Commands

-- Print a table of contents from `notes.md` 
grep '^#' notes.md | sed 's/#/-/'  

-- Create demo.gif from a screen recording
ffmpeg -ss 00:00:10.000 -i screen-recording.mov -pix_fmt rgb24 -r 10 -s 694x532 -t 00:00:10.000 demo.gif




# Thu Oct  6 14:56:58 2022

-[x] use `setPixels()` for faster surface blitting.

Q: how to draw only on sub rectangle?

- Refactor using `View` struct in zig and opencl.
- Got `max_project_float()` kernel execution down to 15ms.
- Note single pass on Cele volume to calculate min/max takes 60ms ?!?! That's so slow. But it does touch every pixel once.
- bugfix 3D `boxImage()`



# App structure

Unfortunately a zig bug prevents us from keeping app state in a single global
namespace, ala

```zig
const app = struct {
      var mouse = ...
      var window_main = ...
      var window_side = ...
      ...
};
```



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

- Model / View style or mixed view and control style?
  
  Model / View style requires that I have separate control flow (1) for updating my model(input) and (2) for updating my view(model).
  While the everything-together approach mixes view updates into the model update control flow...
  I'm going to try separating them and see what happens...





# Cacheing and memoization

Simply *naming a variable* is a way of caching a computation that might be
considered "intermediate". E.g. see how `a` caches an intermediate result in
computing `res`.

```
res = (x**2 - 3)(x**2 + 3)
--- vs 
a = x**2
res = (a-3)(a+3)
```

# How to debug OpenCL ?

Or any highly parallel GPU code? 
On the CPU LLDB gives you the ability to jump between threads, and each thread has it's own callstack.
The GPU is the same, it's just that it has thousands of threads instead of 16... Why doesn't it provide the same
interface?

If this isn't possible, and it's not possible to do printf debugging anymore on macos 12, then how can we debug kernels?
MAC must provide good kernel debugging tools for metal.

And there must be a way for me to use them from zig...
What about webgpu? I think it's syntax looks like metal. does google's DAWN also provide good debugging tools?
I think the endgame is either using metal directly + SDL, or Metal + sokol bindings.
WebGPU ...

Some [research](https://stackoverflow.com/questions/2362186/debugger-for-opencl) shows multiple options for OpenCL debuggers, however I'm not sure they are active.

The other recommended approaches are [printf debugging] and [color debugging](https://computergraphics.stackexchange.com/questions/96/how-can-i-debug-glsl-shaders)
Macos and XCode has a [fully featured debugger](https://developer.apple.com/documentation/metal/developing_and_debugging_metal_shaders), but it's MacOS / Metal specific.

[Renderdoc](https://renderdoc.org/docs/how/how_debug_shader.html) is an alternative for Vulkan and DX3D. 
The simplest thing is to use printf (one at a time) and color debugging.


# comptime vs runtime polymorphism (#abstract)

How many times does your code need to pass through the compiler beofore it is
executable by machine? running commands that have already been compiled. Each
command is a small program.

The comptime vs runtime distinction makes us think about DAGs of expressions /
values. What expressions can we evalute given the values that we have? What
expressions depend on unknowns? If a value can only be known at runtime then
it's a runtime value. The parts of the language that are available at runtime
are different from the parts availabe at comptime! We can only use the
allocator at runtime? `comptime_int` is a type that only exist at comptime.
We can only do loop-unrolling 

- Comptime code: it has all the information that it needs to be evalua
  Comptime code is interpretable at compile time. There is enough information
  to evaluate statements and expressions. Runtime code is whatever can't be
  evaluated at compile time because it has a runtime-only dependency
  (e.g. user input).

JIT compilation is using the power of the compiler at runtime, once we know
more about some of the values in our code. This means we can get real array
types with runtime known length. This means we have to be able to run the
compiler at runtime! This means our compiler must ship with our executable!
This is the biggest downside to JIT compilation. We have to ship the
compiler (a massive runtime dependency) with our executable. This is
probablly not worth it! It would be nice to be able to do more dynamic stuff
at runtime. At the moment we can do compile-time duck typing to enable highly
generic functions that are type checked. These functions are duplicated for
each type signature of arguments used. An alternative is to do _runtime_
dispatch, where we assert that everything type checks, but instead of
duplicating the function for each type signature across all call sites we
look up the right internal functions to call at runtime.

Ideally we would be able to do type checking, generic function instantiation,
specialized optimization, etc SO FAST that we could do it at runtime! Then we
continuously re-compile our code as we gain more and more information during
the running of our program! Instead, we do all the really expensive function
lookup, optimization passes, etc during compilation, and then we don't have
to do anything tricky at runtime! A program "having a runtime" means that the
compiler inserts it's own code into our code! Not knowing where or what will
be inserted makes it harder to reason about performance and control flow.

JIT compilation essentially 

At the moment to do dynamic dispatch we have to create an interface as
documented in `Allocator.zig` and `Random.zig`. These interfaces are
initialized with `Interface.init(ptr,vtable)` and the pointer is type-erased
cast to `*anyopaque` and the vtable is one more many functions which depend
on that `*anyopaque` pointer type (methods of that type).

How is this different from compile-time dispatch (which duplicates the
function body for each input type)? With interfaces we get a new interface
type. Functions that depend on this type don't have to be duplicated, because
there is only one type the function sees! To create the interface we generate
a _new_ type, then essentially cast it to the interface, which compresses
multiple types into one.

Does ZLS know where our method is implemented? or does it just point to the
generaic interface's method? At definition it has no idea who's calling. At
call site it has no idea which method we want to jump to. This is annoying.
If all our code uses generic interfaces, then we rarely jump to real method
implementations.

When we compile down to an executable object file there are `.text` (code) and
`.data` sections...

-[github: vtables in zig? ](https://github.com/ziglang/zig/issues/130)
-[github: comptime interfaces in zig](https://github.com/ziglang/zig/issues/1268)
-[tutorial: dynamic polymorphism in zig](https://revivalizer.xyz/post/the-missing-zig-polymorphism-reference/)
-[github: Alex Nask's Interface code](https://github.com/alexnask/interface.zig)
-[gist: Alex Nask's Interface code (OLD)](https://gist.github.com/alexnask/1d39fbc01b42ce2b5b628828b6d1fb46)
-[Alex Nask's YouTube talk](https://www.youtube.com/watch?v=AHc4x1uXBQE&ab_channel=ZigSHOWTIME)

So does this Interface approach to runtime polymorphism allow us to
write _precompiled libraries_ that have our Interface in the exposed API? Is
this another advantage over functions which are generic taking an `anytype`?

-[ ] fix the bug in `reference/interface.zig` that causes printing random memory.


# Trees, Graphs, and Perfect Hash (#abstract)

Arrays are just efficiently packed perfect hashmap with nonnegative interger
keys! The ints >= 0 written in binary of length N are a description of a path
down a binary tree to a node at layer N.

Decimal `13` is binary 8 + 4 + 1 = `0b1101`. Each binary digit tells us `left`
or `right` as we descend a binary tree, making binary numbers length N
equivalent to a Path. We have to keep leading zeros. `0b001101` is equivalent
to `0b1101` as a number, but not the same path! With the right [perfect hash](https://en.wikipedia.org/wiki/Perfect_hash_function) 
we can map an arbitrary Path description to a unique memory location. Further,
if our hash has collisions we can use buckets. Then we can accept the number
of existing items in each bucket as an additional parameter, making a perfect
hash again. FAIL: Then the representation depends on the order of insertion.

This is only useful if we know the positions of elements won't change. If our
hash depends on the relationship between nodes in graph/tree then it is
likely to break when the graph changes. Static binary tree must remain
static. But sometimes we must explore the data to find the element we want.
Traversing multiple pointer (index) indirections may be necessary. It's more
efficient to store elements in array and use indices than to store elements
in Allocator and use pointers.

A tree can be represented in memory [in many ways](https://stackoverflow.com/questions/2675756/efficient-array-storage-for-binary-tree)

- store mapping between node ids (edge list `(i,j),(i,k),...` or array where
  `arr[i]=n` means `n` points to `i`)
- dense representations without ids:
      + LISP syntax clearly represents an AST.
      + depth-first traversal with special symbols to mark e.g. "no child"
      + special case: store structure of tree only. data is just `1` marking
        node as "present".
- sparse representations without ids:
      + binary tree can has a perfect hash that is dense for complete tree
        i.e. bredth first traversal without compressing empty nodes. see
        also [Binary Heap](https://en.wikipedia.org/wiki/Binary_heap). The children of node stored at `i` are 
        stored at `2i,2i+1`.

In most cases we probably just want to store 
1. node labels →  dense id's `[1..n]`
2. graph of dense id's (edge list or parent array)
3. dense id's → node data (all node info stored separately here)

OR we simply store `[]Elem` where `const Elem = struct{parent:u16, child1:u16,
child2:u16, data:Data}`. This can take the same form on disk and in RAM.

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


Explicitly representing Paths also unlocks things like _relative locations_ of
Elements in the tree. e.g. we can have `const relative_path:RelPath =
path_1 - path_2;` and `const next_elem:Elem = path_1 + relative_path;`.

But the point of trees is that they can easily grow and shrink... And we can
easily add and remove nodes anywhere... This is easiest if we simply pass the
work of assigning memory to `malloc`... Maybe this is even fast if we use a
FixedBufferAllocator... But we still have to include pointers at every
node... Is there a middle ground? 

## Representing trees

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
- So if we have to do e.g. a depth-first-search. How do we do this in the
  tree-

There are so many ways of representing graphs / trees.
It's like rotations. There are so many ways of representing rotations.
And these are really simple objects! But also highly flexible objects.


# OpenCL Questions

Q: What does `global float*` mean vs normal float pointer as kernel parameter?
A: `global` tells the OpenCL compiler that the float buffer should be kept in
global memory. 

# Zig Questions

- Why is updating loop.temp... (not) allowed ?
- Can i edit namespaced vars from a method i.e. loops.method() ?
- When to use `@as` vs `@intCast` ?


