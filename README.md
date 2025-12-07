an attempt to provide a minimal libvkdt to zig

TODO: Build modules and embed data and modules with `library.root_module.addEmbedPath()` or similar

Currently I am building the modules from the src repo by hand, then manually copying the modules folder into the .zig-cache/o/... directory. This also relies on msys2 ucrt64 but the whole plan is to do away with that for cross-compile builds.
