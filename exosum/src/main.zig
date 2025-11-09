const std = @import("std");
const time = std.time;

const GraphTree = @import("graph_tree.zig").GraphTree;
const BareECS = @import("bare_ecs.zig").BareECS;
const Hybrid = @import("hybrid.zig").Hybrid;

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

var hy_state: u64 = 0;
fn hy_work(self: Hybrid.Link.Node) void {
    _ = self;
    hy_state += 1;
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

    var parent = try GraphTree.Node.new(allocator, &gt_work);
    tree.root.addChild(parent);
    for (0..1024 * 128) |_| {
        const child = try GraphTree.Node.new(allocator, &gt_work);
        parent.addChild(child);
        parent = child;
    }

    std.debug.print("GRAPH TREE STATE BEFORE WORK {d}\n", .{gt_state});
    const gt_t1 = time.microTimestamp();
    tree.work();
    const gt_t2 = time.microTimestamp();
    std.debug.print("GRAPH TREE STATE AFTER WORK {d}\n", .{gt_state});
    std.debug.print("GRAPH TREE DELTA {d}\n", .{gt_t2 - gt_t1});

    var ecs = try BareECS.init(allocator);
    defer ecs.deinit();

    for (0..1024 * 128) |_| {
        ecs.add(BareECS.Node{ .worker = &becs_work });
    }

    std.debug.print("BASIC ECS STATE BEFORE WORK {d}\n", .{becs_state});
    const becs_t1 = time.microTimestamp();
    ecs.work();
    const becs_t2 = time.microTimestamp();
    std.debug.print("BASIC ECS STATE AFTER WORK {d}\n", .{becs_state});
    std.debug.print("BASIC ECS DELTA {d}\n", .{becs_t2 - becs_t1});

    var hbr = Hybrid{
        .root = try Hybrid.Link.new(allocator),
    };
    defer hbr.root.deinit();

    var h_parent = try Hybrid.Link.new(allocator);
    hbr.root.addChild(h_parent);
    for (0..128) |_| {
        const h_child = try Hybrid.Link.new(allocator);
        for (0..1024) |_| {
            h_child.addNode(Hybrid.Link.Node{ .worker = hy_work });
        }
        h_parent.addChild(h_child);
        h_parent = h_child;
    }

    std.debug.print("HYBRID STATE BEFORE WORK {d}\n", .{hy_state});
    const hy_t1 = time.microTimestamp();
    ecs.work();
    const hy_t2 = time.microTimestamp();
    std.debug.print("HYBRID STATE AFTER WORK {d}\n", .{hy_state});
    std.debug.print("HYBRID DELTA {d}\n", .{hy_t2 - hy_t1});
}
