const std = @import("std");
const time = std.time;

const GraphTree = @import("graph_tree.zig").GraphTree;
const BareECS = @import("bare_ecs.zig").BareECS;

var gt_state: u64 = 0;
fn gt_work(self: *GraphTree.Node) void {
    _ = self;
    gt_state += 1;
}

var becs_state: u64 = 0;
fn becs_work(self: BareECS.Node) void {
    _ = self;
    becs_state += 1;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    std.debug.print("Hello Exosum\n", .{});

    var tree = GraphTree{
        .root = try GraphTree.Node.new(allocator, &gt_work),
    };
    defer tree.root.deinit();

    tree.root.addChild(
        try GraphTree.Node.new(allocator, &gt_work),
    );

    var parent = try GraphTree.Node.new(allocator, &gt_work);
    tree.root.addChild(parent);
    for (0..1024 * 128) |_| {
        const child = try GraphTree.Node.new(allocator, &gt_work);
        parent.addChild(child);
        parent = child;
    }

    std.debug.print("GT STATE BEFORE WORK {d}\n", .{gt_state});
    const gt_t1 = time.microTimestamp();
    tree.work();
    const gt_t2 = time.microTimestamp();
    std.debug.print("GT STATE AFTER WORK {d}\n", .{gt_state});
    std.debug.print("GT DELTA {d}\n", .{gt_t2 - gt_t1});

    var ecs = try BareECS.init(allocator);
    defer ecs.deinit();

    for (0..1024 * 128) |_| {
        ecs.add(BareECS.Node{ .worker = &becs_work });
    }

    std.debug.print("BECS STATE BEFORE WORK {d}\n", .{becs_state});
    const becs_t1 = time.microTimestamp();
    ecs.work();
    const becs_t2 = time.microTimestamp();
    std.debug.print("BECS STATE AFTER WORK {d}\n", .{becs_state});
    std.debug.print("BECS DELTA {d}\n", .{becs_t2 - becs_t1});
}
