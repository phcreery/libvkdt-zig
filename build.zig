const std = @import("std");
const builtin = @import("builtin");

// from /src/pipe/flat.mk
// PIPE_CFLAGS=
// PIPE_LDFLAGS=-ldl
const sources_pipe = [_][]const u8{
    "src/pipe/alloc.c",
    "src/pipe/connector.c",
    "src/pipe/global.c",
    "src/pipe/graph.c",
    "src/pipe/graph-io.c",
    "src/pipe/graph-export.c",
    "src/pipe/module.c",
    "src/pipe/raytrace.c",
    "src/pipe/res.c",
};

// from src\qvk\flat.mk
const sources_qvk = [_][]const u8{
    "src/qvk/qvk.c",
    "src/qvk/qvk_util.c",
};

// from src\core\flat.mk
// CORE_CFLAGS=
// CORE_LDFLAGS=-pthread -ldl
//
// ifeq ($(OS),Windows_NT)
// CORE_O+=core/utf8_manifest.o
// core/utf8_manifest.o: core/utf8.rc
// windres -O coff $< $@
// endif
const sources_core = [_][]const u8{
    "src/core/log.c",
    "src/core/threads.c",
};

// from db\flat.mk
// DB_CFLAGS=
// DB_LDFLAGS=
const sources_db = [_][]const u8{
    "src/db/db.c",
    "src/db/rc.c",
    "src/db/thumbnails.c",
};

// combine all sources
const sources = sources_pipe ++ sources_qvk ++ sources_core ++ sources_db;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const link_mode = b.option(std.builtin.LinkMode, "linkage", "how the library should be linked (default: static)");

    // =================================================================================
    // libvkdt
    // =================================================================================
    const upstream = b.dependency("vkdt-src", .{});
    const libvkdt_clib = b.addLibrary(.{
        .name = "libvkdt",
        .linkage = link_mode orelse .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    // =================================================================================
    // vkdt/pipe/*.c
    // =================================================================================
    // libvkdt.root_module.addIncludePath ??
    libvkdt_clib.root_module.addIncludePath(upstream.path(""));
    libvkdt_clib.root_module.addIncludePath(upstream.path("src"));
    libvkdt_clib.root_module.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &sources,
        .flags = &.{"-fPIC"},
    });
    // libvkdt_clib.root_module.addEmbedPath(lazy_path: LazyPath)

    // =================================================================================
    // include external stuff
    // =================================================================================
    // if (builtin.os.tag == .windows) {
    const system_library_path: std.Build.LazyPath = .{ .cwd_relative = "C:/Windows/System32" };
    libvkdt_clib.addLibraryPath(system_library_path);
    const msys2_ucrt64_header_path: std.Build.LazyPath = .{ .cwd_relative = "C:/msys64/ucrt64/include" };
    libvkdt_clib.addIncludePath(msys2_ucrt64_header_path);
    const msys2_ucrt64_library_path: std.Build.LazyPath = .{ .cwd_relative = "C:/msys64/ucrt64/lib" };
    libvkdt_clib.addLibraryPath(msys2_ucrt64_library_path);
    // }

    // in case of windows, these rely on msys2 ucrt64
    libvkdt_clib.root_module.linkSystemLibrary("dl");
    libvkdt_clib.root_module.linkSystemLibrary("vulkan-1.dll");

    // =================================================================================
    // INSTALL
    // =================================================================================
    // install headers to output directory
    // libvkdt_clib.installHeadersDirectory(upstream.path("src"), "vkdt", .{}); // recursive?
    libvkdt_clib.installHeadersDirectory(upstream.path("src/pipe"), "pipe", .{});
    libvkdt_clib.installHeadersDirectory(upstream.path("src/core"), "core", .{});
    libvkdt_clib.installHeadersDirectory(upstream.path("src/db"), "db", .{});
    libvkdt_clib.installHeadersDirectory(upstream.path("src/qvk"), "qvk", .{});
    libvkdt_clib.installHeadersDirectory(upstream.path("src/gui"), "gui", .{});
    // for exposing raw c library to other packages
    b.installArtifact(libvkdt_clib);

    // =================================================================================
    // TRANSLATE-C (incomplete)
    // =================================================================================
    // translate-c the *.h file
    const translateC = b.addTranslateC(.{
        // .root_source_file = upstream.path("src/pipe/global.h"),
        .root_source_file = upstream.path("src/core/tools.h"),
        .target = target,
        .optimize = optimize,
    });
    translateC.addIncludePath(upstream.path("src"));
    translateC.addIncludePath(msys2_ucrt64_header_path);

    // ...and the Zig module for the generated bindings
    const mod = b.addModule("vkdt_pipe_global", .{
        .root_source_file = translateC.getOutput(),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });
    mod.linkLibrary(libvkdt_clib);
    mod.addLibraryPath(msys2_ucrt64_library_path);

    // =================================================================================
    // EXAMPLE SRC EXE
    // =================================================================================
    const exe = b.addExecutable(.{
        .name = "vkdt_zig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                // .{ .name = "libvkdt", .module = mod }, // for translate-c generated module
            },
        }),
    });
    exe.addIncludePath(msys2_ucrt64_header_path);
    exe.addLibraryPath(msys2_ucrt64_library_path);
    exe.linkLibrary(libvkdt_clib);

    b.installArtifact(exe);
    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
}
