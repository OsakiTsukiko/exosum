const std = @import("std");
const Allocator = std.mem.Allocator;

pub const GraphTree = struct {
    root: *Node,

    pub const Node = struct {
        allocator: Allocator, // allocator
        children: std.ArrayList(*Node), // list of children pointers
        // pointers lead to cache misses
        worker: *const fn (self: *Node) void, // worker function to compute something

        pub fn new(allocator: Allocator, worker: *const fn (self: *Node) void) !*Node {
            var node = try allocator.create(Node);
            node.allocator = allocator;
            node.worker = worker;
            node.children = try std.ArrayList(*Node).initCapacity(allocator, 8); // random number for initial capacity
            return node;
        }

        pub fn deinit(self: *Node) void {
            for (self.children.items) |child| {
                child.deinit();
            }
            self.children.deinit(self.allocator);
            self.allocator.destroy(self);
        }

        pub fn addChild(self: *Node, child: *Node) void {
            self.children.append(self.allocator, child) catch {
                @panic("THIS SHOULD BE UNREACHABLE!");
            };
        }

        pub fn work(self: *Node) void {
            self.worker(self);
            for (self.children.items) |child| {
                child.work();
            }
        }
    };

    pub fn work(self: *GraphTree) void {
        self.root.work();
    }
};
