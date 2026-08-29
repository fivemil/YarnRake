//! Miner control: named pools, worker assignments, auto/manual/custom modes.
const std = @import("std");

pub const Mode = enum {
    manual,
    automatic,
    failover,
    round_robin,
    all_pools,
    custom,

    pub fn fromName(s: []const u8) ?Mode {
        if (eql(s, "manual")) return .manual;
        if (eql(s, "automatic") or eql(s, "auto")) return .automatic;
        if (eql(s, "failover")) return .failover;
        if (eql(s, "round_robin") or eql(s, "rr")) return .round_robin;
        if (eql(s, "all_pools") or eql(s, "all")) return .all_pools;
        if (eql(s, "custom")) return .custom;
        return null;
    }

    pub fn name(self: Mode) []const u8 {
        return switch (self) {
            .manual => "manual",
            .automatic => "automatic",
            .failover => "failover",
            .round_robin => "round_robin",
            .all_pools => "all_pools",
            .custom => "custom",
        };
    }

    fn eql(a: []const u8, b: []const u8) bool {
        return std.ascii.eqlIgnoreCase(a, b);
    }
};

pub const Pool = struct {
    id: [32]u8 = [_]u8{0} ** 32,
    id_len: usize = 0,
    name: [64]u8 = [_]u8{0} ** 64,
    name_len: usize = 0,
    url: [192]u8 = [_]u8{0} ** 192,
    url_len: usize = 0,
    algo: [32]u8 = [_]u8{0} ** 32,
    algo_len: usize = 0,
    enabled: bool = true,
    priority: u8 = 100,

    pub fn idSlice(self: *const Pool) []const u8 {
        return self.id[0..self.id_len];
    }
    pub fn nameSlice(self: *const Pool) []const u8 {
        return self.name[0..self.name_len];
    }
    pub fn urlSlice(self: *const Pool) []const u8 {
        return self.url[0..self.url_len];
    }
    pub fn algoSlice(self: *const Pool) []const u8 {
        return self.algo[0..self.algo_len];
    }
};

pub const Assignment = struct {
    worker: [64]u8 = [_]u8{0} ** 64,
    worker_len: usize = 0,
    mode: Mode = .manual,
    pool_ids: [256]u8 = [_]u8{0} ** 256,
    pool_ids_len: usize = 0,
    custom_url: [192]u8 = [_]u8{0} ** 192,
    custom_url_len: usize = 0,
    notes: [64]u8 = [_]u8{0} ** 64,
    notes_len: usize = 0,

    pub fn workerSlice(self: *const Assignment) []const u8 {
        return self.worker[0..self.worker_len];
    }
    pub fn poolsSlice(self: *const Assignment) []const u8 {
        return self.pool_ids[0..self.pool_ids_len];
    }
};

pub const Board = struct {
    mu: std.Thread.Mutex = .{},
    pools: [32]Pool = [_]Pool{.{}} ** 32,
    pool_n: usize = 0,
    assigns: [64]Assignment = [_]Assignment{.{}} ** 64,
    assign_n: usize = 0,
    path: []const u8,
    next_pool: u64 = 1,

    pub fn init(path: []const u8) Board {
        var b = Board{ .path = path };
        b.ensureDefaultPool();
        b.load() catch {};
        if (b.pool_n == 0) b.ensureDefaultPool();
        return b;
    }

    fn ensureDefaultPool(self: *Board) void {
        if (self.pool_n > 0) return;
        _ = self.addPoolInternal("local", "Local YarnRake", "stratum+tcp://127.0.0.1:3333", "skein", 1) catch {};
    }

    fn addPoolInternal(self: *Board, id: []const u8, name: []const u8, url: []const u8, algo: []const u8, priority: u8) !void {
        if (self.pool_n >= self.pools.len) return error.Full;
        var p = Pool{};
        p.id_len = copy(&p.id, id);
        p.name_len = copy(&p.name, name);
        p.url_len = copy(&p.url, url);
        p.algo_len = copy(&p.algo, algo);
        p.priority = priority;
        p.enabled = true;
        self.pools[self.pool_n] = p;
        self.pool_n += 1;
    }

    pub fn addPool(self: *Board, name: []const u8, url: []const u8, algo: []const u8, priority: u8) ![]const u8 {
        self.mu.lock();
        defer self.mu.unlock();
        if (self.pool_n >= self.pools.len) return error.Full;
        var id_buf: [32]u8 = undefined;
        const id = std.fmt.bufPrint(&id_buf, "p{d}", .{self.next_pool}) catch "p0";
        self.next_pool += 1;
        try self.addPoolInternal(id, name, url, algo, priority);
        self.save() catch {};
        return self.pools[self.pool_n - 1].idSlice();
    }

    pub fn setPoolEnabled(self: *Board, id: []const u8, enabled: bool) bool {
        self.mu.lock();
        defer self.mu.unlock();
        for (self.pools[0..self.pool_n]) |*p| {
            if (std.mem.eql(u8, p.idSlice(), id)) {
                p.enabled = enabled;
                self.save() catch {};
                return true;
            }
        }
        return false;
    }

    pub fn assign(self: *Board, worker: []const u8, mode: Mode, pool_ids: []const u8, custom_url: []const u8, notes: []const u8) !void {
        self.mu.lock();
        defer self.mu.unlock();
        var i: usize = 0;
        while (i < self.assign_n) : (i += 1) {
            if (std.mem.eql(u8, self.assigns[i].workerSlice(), worker)) {
                self.assigns[i] = makeAssign(worker, mode, pool_ids, custom_url, notes);
                self.save() catch {};
                return;
            }
        }
        if (self.assign_n >= self.assigns.len) return error.Full;
        self.assigns[self.assign_n] = makeAssign(worker, mode, pool_ids, custom_url, notes);
        self.assign_n += 1;
        self.save() catch {};
    }

    fn makeAssign(worker: []const u8, mode: Mode, pool_ids: []const u8, custom_url: []const u8, notes: []const u8) Assignment {
        var a = Assignment{ .mode = mode };
        a.worker_len = copy(&a.worker, worker);
        a.pool_ids_len = copy(&a.pool_ids, pool_ids);
        a.custom_url_len = copy(&a.custom_url, custom_url);
        a.notes_len = copy(&a.notes, notes);
        return a;
    }

    pub fn resolve(self: *Board, worker: []const u8, worker_algo: []const u8, out: []u8) []const u8 {
        self.mu.lock();
        defer self.mu.unlock();
        var fbs = std.io.fixedBufferStream(out);
        const w = fbs.writer();

        var found: ?*const Assignment = null;
        for (self.assigns[0..self.assign_n]) |*a| {
            if (std.mem.eql(u8, a.workerSlice(), worker)) {
                found = a;
                break;
            }
        }

        if (found == null) {
            w.writeAll("{\"ok\":true,\"mode\":\"automatic\",\"urls\":[") catch {};
            var first = true;
            for (self.pools[0..self.pool_n]) |p| {
                if (!p.enabled) continue;
                if (worker_algo.len > 0 and p.algo_len > 0 and !std.ascii.eqlIgnoreCase(p.algoSlice(), worker_algo)) continue;
                if (!first) w.writeAll(",") catch {};
                w.print("\"{s}\"", .{p.urlSlice()}) catch {};
                first = false;
            }
            if (first) {
                for (self.pools[0..self.pool_n]) |p| {
                    if (!p.enabled) continue;
                    w.print("\"{s}\"", .{p.urlSlice()}) catch {};
                    break;
                }
            }
            w.writeAll("]}") catch {};
            return fbs.getWritten();
        }

        const a = found.?;
        w.print("{{\"ok\":true,\"mode\":\"{s}\",\"worker\":\"{s}\",\"urls\":[", .{ a.mode.name(), a.workerSlice() }) catch {};

        switch (a.mode) {
            .custom => {
                if (a.custom_url_len > 0) {
                    w.print("\"{s}\"", .{a.custom_url[0..a.custom_url_len]}) catch {};
                }
            },
            .all_pools => {
                var first = true;
                for (self.pools[0..self.pool_n]) |p| {
                    if (!p.enabled) continue;
                    if (!first) w.writeAll(",") catch {};
                    w.print("\"{s}\"", .{p.urlSlice()}) catch {};
                    first = false;
                }
            },
            .automatic => {
                var first = true;
                for (self.pools[0..self.pool_n]) |p| {
                    if (!p.enabled) continue;
                    if (worker_algo.len > 0 and p.algo_len > 0 and !std.ascii.eqlIgnoreCase(p.algoSlice(), worker_algo)) continue;
                    if (!first) w.writeAll(",") catch {};
                    w.print("\"{s}\"", .{p.urlSlice()}) catch {};
                    first = false;
                }
            },
            .manual, .failover, .round_robin => {
                const ids = a.poolsSlice();
                if (std.mem.eql(u8, ids, "*")) {
                    var first = true;
                    for (self.pools[0..self.pool_n]) |p| {
                        if (!p.enabled) continue;
                        if (!first) w.writeAll(",") catch {};
                        w.print("\"{s}\"", .{p.urlSlice()}) catch {};
                        first = false;
                    }
                } else {
                    var first = true;
                    var it = std.mem.splitScalar(u8, ids, ',');
                    while (it.next()) |pid| {
                        const id = std.mem.trim(u8, pid, " \t");
                        for (self.pools[0..self.pool_n]) |p| {
                            if (!p.enabled) continue;
                            if (!std.mem.eql(u8, p.idSlice(), id)) continue;
                            if (!first) w.writeAll(",") catch {};
                            w.print("\"{s}\"", .{p.urlSlice()}) catch {};
                            first = false;
                        }
                    }
                }
            },
        }
        w.writeAll("]}") catch {};
        return fbs.getWritten();
    }

    pub fn stateJson(self: *Board, buf: []u8) []const u8 {
        self.mu.lock();
        defer self.mu.unlock();
        var fbs = std.io.fixedBufferStream(buf);
        const w = fbs.writer();
        w.writeAll("{\"ok\":true,\"pools\":[") catch return "{\"ok\":false}\n";
        for (self.pools[0..self.pool_n], 0..) |p, i| {
            if (i > 0) w.writeAll(",") catch {};
            w.print(
                "{{\"id\":\"{s}\",\"name\":\"{s}\",\"url\":\"{s}\",\"algo\":\"{s}\",\"enabled\":{s},\"priority\":{d}}}",
                .{ p.idSlice(), p.nameSlice(), p.urlSlice(), p.algoSlice(), if (p.enabled) "true" else "false", p.priority },
            ) catch {};
        }
        w.writeAll("],\"assignments\":[") catch {};
        for (self.assigns[0..self.assign_n], 0..) |a, i| {
            if (i > 0) w.writeAll(",") catch {};
            w.print(
                "{{\"worker\":\"{s}\",\"mode\":\"{s}\",\"pool_ids\":\"{s}\",\"custom_url\":\"{s}\",\"notes\":\"{s}}}",
                .{ a.workerSlice(), a.mode.name(), a.poolsSlice(), a.custom_url[0..a.custom_url_len], a.notes[0..a.notes_len] },
            ) catch {};
        }
        w.writeAll("]}\n") catch {};
        return fbs.getWritten();
    }

    fn copy(dst: []u8, src: []const u8) usize {
        const n = @min(dst.len, src.len);
        @memcpy(dst[0..n], src[0..n]);
        return n;
    }

    fn save(self: *Board) !void {
        const f = try std.fs.cwd().createFile(self.path, .{});
        defer f.close();
        var buf: [4096]u8 = undefined;
        for (self.pools[0..self.pool_n]) |p| {
            const line = try std.fmt.bufPrint(&buf, "pool\t{s}\t{s}\t{s}\t{s}\t{d}\t{d}\n", .{
                p.idSlice(), p.nameSlice(), p.urlSlice(), p.algoSlice(), p.priority, @intFromBool(p.enabled),
            });
            try f.writeAll(line);
        }
        for (self.assigns[0..self.assign_n]) |a| {
            const line = try std.fmt.bufPrint(&buf, "assign\t{s}\t{s}\t{s}\t{s}\t{s}\n", .{
                a.workerSlice(), a.mode.name(), a.poolsSlice(), a.custom_url[0..a.custom_url_len], a.notes[0..a.notes_len],
            });
            try f.writeAll(line);
        }
    }

    fn load(self: *Board) !void {
        const f = std.fs.cwd().openFile(self.path, .{}) catch return;
        defer f.close();
        var buf: [256 * 1024]u8 = undefined;
        const n = try f.readAll(&buf);
        var it = std.mem.splitScalar(u8, buf[0..n], '\n');
        while (it.next()) |line| {
            if (line.len == 0) continue;
            var cols = std.mem.splitScalar(u8, line, '\t');
            const kind = cols.next() orelse continue;
            if (std.mem.eql(u8, kind, "pool")) {
                const id = cols.next() orelse continue;
                const name = cols.next() orelse "";
                const url = cols.next() orelse "";
                const algo = cols.next() orelse "";
                const pri_s = cols.next() orelse "100";
                const en_s = cols.next() orelse "1";
                const pri = std.fmt.parseInt(u8, pri_s, 10) catch 100;
                self.addPoolInternal(id, name, url, algo, pri) catch {};
                if (self.pool_n > 0) self.pools[self.pool_n - 1].enabled = !std.mem.eql(u8, en_s, "0");
            } else if (std.mem.eql(u8, kind, "assign")) {
                const worker = cols.next() orelse continue;
                const mode_s = cols.next() orelse "manual";
                const pools = cols.next() orelse "";
                const custom = cols.next() orelse "";
                const notes = cols.next() orelse "";
                const mode = Mode.fromName(mode_s) orelse .manual;
                if (self.assign_n < self.assigns.len) {
                    self.assigns[self.assign_n] = makeAssign(worker, mode, pools, custom, notes);
                    self.assign_n += 1;
                }
            }
        }
    }
};

test "mode parse" {
    try std.testing.expect(Mode.fromName("auto").? == .automatic);
    try std.testing.expect(Mode.fromName("all").? == .all_pools);
}
