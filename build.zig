const std = @import("std");
const builtin = @import("builtin");

// from https://github.com/hanatos/vkdt/blob/master/src/pipe/flat.mk
// PIPE_O=\
// pipe/alloc.o\
// pipe/connector.o\
// pipe/global.o\
// pipe/graph.o\
// pipe/graph-io.o\
// pipe/graph-export.o\
// pipe/module.o\
// pipe/raytrace.o\
// pipe/res.o
// PIPE_H=\
// core/fs.h\
// pipe/alloc.h\
// pipe/connector.h\
// pipe/connector.inc\
// pipe/cycles.h\
// pipe/dlist.h\
// pipe/draw.h\
// pipe/global.h\
// pipe/graph.h\
// pipe/graph-run-modules.h\
// pipe/graph-run-nodes-allocate.h\
// pipe/graph-run-nodes-upload.h\
// pipe/graph-run-nodes-record-cmd.h\
// pipe/graph-run-nodes-download.h\
// pipe/graph-io.h\
// pipe/graph-print.h\
// pipe/graph-export.h\
// pipe/graph-traverse.inc\
// pipe/modules/api.h\
// pipe/asciiio.h\
// pipe/module.h\
// pipe/node.h\
// pipe/params.h\
// pipe/pipe.h\
// pipe/res.h\
// pipe/raytrace.h\
// pipe/token.h
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
// const libvkdt_pipe_headers = [_][]const u8{
//     "src/core/fs.h",
//     "src/pipe/alloc.h",
//     "src/pipe/connector.h",
//     "src/pipe/connector.inc",
//     "src/pipe/cycles.h",
//     "src/pipe/dlist.h",
//     "src/pipe/draw.h",
//     "src/pipe/global.h",
//     "src/pipe/graph.h",
//     "src/pipe/graph-run-modules.h",
//     "src/pipe/graph-run-nodes-allocate.h",
//     "src/pipe/graph-run-nodes-upload.h",
//     "src/pipe/graph-run-nodes-record-cmd.h",
//     "src/pipe/graph-run-nodes-download.h",
//     "src/pipe/graph-io.h",
//     "src/pipe/graph-print.h",
//     "src/pipe/graph-export.h",
//     "src/pipe/graph-traverse.inc",
//     "src/pipe/modules/api.h",
//     "src/pipe/asciiio.h",
//     "src/pipe/module.h",
//     "src/pipe/node.h",
//     "src/pipe/params.h",
//     "src/pipe/pipe.h",
//     "src/pipe/res.h",
//     "src/pipe/raytrace.h",
//     "src/pipe/token.h",
// };

// from src\qvk\flat.mk
// QVK_O=qvk/qvk.o\
//       qvk/qvk_util.o

const sources_qvk = [_][]const u8{
    "src/qvk/qvk.c",
    "src/qvk/qvk_util.c",
};

// from src\core\flat.mk
// CORE_O=core/log.o \
//        core/threads.o
// CORE_H=core/colour.h \
//        core/core.h \
//        core/log.h \
//        core/mat3.h \
//        core/threads.h
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
// DB_O=\
// db/db.o\
// db/rc.o\
// db/thumbnails.o
// DB_H=\
// db/db.h\
// db/exif.h\
// db/hash.h\
// db/thumbnails.h\
// db/stringpool.h
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
        .flags = &.{},
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

    // these rely on ucrt64
    libvkdt_clib.linkSystemLibrary("dl");
    libvkdt_clib.linkSystemLibrary("vulkan-1.dll");
    // libvkdt.root_module.linkSystemLibrary("dl", .{});

    // =================================================================================
    // INSTALL
    // =================================================================================
    // install headers to output directory
    // libvkdt_clib.installHeadersDirectory(upstream.path("src"), "vkdt", .{});
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
