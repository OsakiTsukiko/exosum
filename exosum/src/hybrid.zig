const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Hybrid = struct {
    root: *Link,

    pub const Link = struct {
        allocator: Allocator, // allocator
        children: std.ArrayList(*Link), // list of children pointers
        // pointers lead to cache misses
        nodes: std.ArrayList(Node),

        pub const Node = struct {
            worker: *const fn (self: Node) void, // worker function to compute something

            pub fn init(worker: *const fn (self: Node) void) void {
                return Node{
                    .worker = worker,
                };
            }

            pub fn work(self: Node) void {
                self.worker(self);
            }
        };

        pub fn new(allocator: Allocator) !*Link {
            var node = try allocator.create(Link);
            node.allocator = allocator;
            node.children = try std.ArrayList(*Link).initCapacity(allocator, 8); // random number for initial capacity
            node.nodes = try std.ArrayList(Node).initCapacity(allocator, 128);
            return node;
        }

        pub fn deinit(self: *Link) void {
            for (self.children.items) |child| {
                child.deinit();
            }
            self.children.deinit(self.allocator);
            self.nodes.deinit(self.allocator);
            self.allocator.destroy(self);
        }

        pub fn addChild(self: *Link, child: *Link) void {
            self.children.append(self.allocator, child) catch {
                @panic("THIS SHOULD BE UNREACHABLE!");
            };
        }

        pub fn addNode(self: *Link, node: Node) void {
            self.nodes.append(self.allocator, node) catch {
                @panic("THIS SHOULD BE UNREACHABLE!");
            };
        }

        pub fn work(self: *Link) void {
            for (self.nodes.items) |node| {
                node.work();
            }

            for (self.children.items) |child| {
                child.work();
            }
        }
    };

    pub fn work(self: *Hybrid) void {
        self.root.work();
    }
};
