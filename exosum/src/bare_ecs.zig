const std = @import("std");
const Allocator = std.mem.Allocator;

pub const BareECS = struct {
    list: std.ArrayList(Node),
    allocator: Allocator,

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

    pub fn init(allocator: Allocator) !BareECS {
        return BareECS{
            .list = try std.ArrayList(Node).initCapacity(allocator, 1024 * 1024),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *BareECS) void {
        self.list.deinit(self.allocator);
    }

    pub fn add(self: *BareECS, node: Node) void {
        self.list.append(self.allocator, node) catch {
            @panic("UNREACHABLE");
        };
    }

    pub fn work(self: *BareECS) void {
        for (self.list.items) |node| {
            node.work();
        }
    }
};
