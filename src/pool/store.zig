const std = @import("std");

pub const MinerRow = struct {
    worker: [64]u8 = [_]u8{0} ** 64,
    worker_len: usize = 0,
    accepted: u64 = 0,
    rejected: u64 = 0,
};

pub const Store = struct {
    mu: std.Thread.Mutex = .{},
    miners: std.StringHashMap(MinerRow),
    shares_total: u64 = 0,
    path: []const u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, path: []const u8) Store {
        return .{ .miners = std.StringHashMap(MinerRow).init(allocator), .path = path, .allocator = allocator };
    }
    pub fn deinit(self: *Store) void {
        var it = self.miners.keyIterator();
        while (it.next()) |k| self.allocator.free(k.*);
        self.miners.deinit();
    }
    pub fn touch(self: *Store, worker: []const u8) void {
        self.mu.lock();
        defer self.mu.unlock();
        if (self.miners.get(worker) != null) return;
        var row = MinerRow{};
        const n = @min(worker.len, row.worker.len);
        @memcpy(row.worker[0..n], worker[0..n]);
        row.worker_len = n;
        const key = self.allocator.dupe(u8, worker[0..n]) catch return;
        self.miners.put(key, row) catch self.allocator.free(key);
    }
    pub fn accept(self: *Store, worker: []const u8, algo: []const u8, diff: f64) void {
        self.touch(worker);
        self.mu.lock();
        defer self.mu.unlock();
        if (self.miners.getPtr(worker)) |row| row.accepted += 1;
        self.shares_total += 1;
        appendLine(self.path, worker, algo, diff, true);
    }
    pub fn countMiners(self: *Store) usize {
        self.mu.lock();
        defer self.mu.unlock();
        return self.miners.count();
    }
};

fn appendLine(path: []const u8, worker: []const u8, algo: []const u8, diff: f64, ok: bool) void {
    const f = std.fs.cwd().createFile(path, .{ .truncate = false, .read = true }) catch return;
    defer f.close();
    f.seekFromEnd(0) catch {};
    var buf: [256]u8 = undefined;
    const line = std.fmt.bufPrint(&buf, "{{\"worker\":\"{s}\",\"algo\":\"{s}\",\"difficulty\":{d:.4},\"accepted\":{s}}}\n", .{ worker, algo, diff, if (ok) "true" else "false" }) catch return;
    f.writeAll(line) catch {};
}

test "touch miner" {
    var s = Store.init(std.testing.allocator, "/tmp/yarnrake-test-shares.jsonl");
    defer s.deinit();
    s.touch("phone-1");
    s.accept("phone-1", "skein", 0.01);
    try std.testing.expectEqual(@as(usize, 1), s.countMiners());
}
