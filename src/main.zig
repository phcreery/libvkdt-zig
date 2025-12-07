const std = @import("std");

// using translate-c
// const libvkdt = @import("libvkdt");

// using @cImport
const vkdt = @cImport({
    @cInclude("core/core.h");
    @cInclude("core/tools.h");
    @cInclude("core/log.h");
    @cInclude("core/threads.h");
    @cInclude("pipe/global.h");
    @cInclude("pipe/graph-export.h");
    @cInclude("pipe/module.h");
    @cInclude("pipe/graph.h");
    @cInclude("pipe/graph-print.h");
    @cInclude("qvk/qvk.h");
});

pub fn main() !void {
    // using translate-c
    // libvkdt.dt_tool_print_usage();

    // using @cImport
    // vkdt.dt_tool_print_usage();
    vkdt.dt_log_init(vkdt.s_log_all); // s_log_none, s_log_cli, or s_log_all

    // vkdt assigned basedir inside dt_pipe_global_init(), so this will get overridden
    // var basedir: [260]u8 = @import("std").mem.zeroes([260]u8);
    // const basedir_slice = "C:/Users/phcre/Documents/c/vkdt/bin";
    // @memcpy(basedir[0..basedir_slice.len], basedir_slice);
    // vkdt.dt_pipe.basedir = basedir;

    _ = vkdt.dt_pipe_global_init();
    vkdt.threads_global_init();

    const cfg_file = "C:/Users/phcre/Pictures/DSC_6765.NEF.cfg";
    // const cfg_file = "C:/Users/phcre/Pictures/IMG_8916.jpg.cfg";
    const output_file = "output_test";
    const output_format = 0x72_78_65_2D_6F; // "rxe-o" in hex ("o-exr")
    var param: vkdt.dt_graph_export_t = .{};
    param.p_cfgfile = cfg_file.ptr;
    param.output[0].colour_primaries = vkdt.s_colour_primaries_unknown;
    param.output[0].colour_trc = vkdt.s_colour_primaries_unknown;
    param.output[0].p_filename = output_file.ptr;
    // vkdt.dt_token does not work with zig translate-c headers
    // param.output[0].mod = vkdt.dt_token(output_format.ptr);
    param.output[0].mod = output_format;
    param.output_cnt = 1;

    const gpu_name = null;
    const gpu_id = -1;
    const status = vkdt.qvk_init(gpu_name, gpu_id, 0, 0, 0);
    if (status != 0) {
        std.debug.print("qvk_init failed with status {d}\n", .{status});
        return;
    }

    var graph: vkdt.dt_graph_t = .{};
    const s_queue_compute = 1;
    vkdt.dt_graph_init(&graph, s_queue_compute);

    const res = vkdt.dt_graph_export(&graph, &param);
    const VK_SUCCESS = 0;
    if (res != VK_SUCCESS) {
        std.debug.print("dt_graph_export failed with VkResult {d}\n", .{res});
        return;
    }

    vkdt.dt_graph_print_nodes(&graph);
    vkdt.dt_graph_cleanup(&graph);
    vkdt.threads_global_cleanup();
    _ = vkdt.qvk_cleanup();
}
