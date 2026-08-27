const std = @import("std");

pub const Share = struct { worker: []const u8, difficulty: f64 };

pub const Pplns = struct {
    window: usize,
    shares: std.ArrayList(Share),
    earnings: std.StringHashMap(f64),
    allocator: std.mem.Allocator,
    pub fn init(allocator: std.mem.Allocator, window: usize) Pplns {
        return .{ .window = window, .shares = .empty, .earnings = std.StringHashMap(f64).init(allocator), .allocator = allocator };
    }
    pub fn deinit(self: *Pplns) void {
        self.shares.deinit(self.allocator);
        self.earnings.deinit();
    }
    pub fn addShare(self: *Pplns, share: Share) !void {
        try self.shares.append(self.allocator, share);
        if (self.shares.items.len > self.window) _ = self.shares.orderedRemove(0);
    }
};

test "window trims" {
    const a = std.testing.allocator;
    var p = Pplns.init(a, 2);
    defer p.deinit();
    try p.addShare(.{ .worker = "a", .difficulty = 1 });
    try p.addShare(.{ .worker = "b", .difficulty = 1 });
    try p.addShare(.{ .worker = "c", .difficulty = 1 });
    try std.testing.expectEqual(@as(usize, 2), p.shares.items.len);
}
