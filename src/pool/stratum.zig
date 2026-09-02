const std = @import("std");
const algo_mod = @import("algo.zig");
const vardiff = @import("vardiff.zig");
const store_mod = @import("store.zig");
const job = @import("job.zig");
const validate = @import("validate.zig");

pub const Config = struct {
    port: u16 = 3333,
    algo: algo_mod.Algo = .skein,
    start_diff: f64 = 0.01,
};

pub const Stats = struct {
    subscribe: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    authorize: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    submit: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    sessions: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),
    pub fn snapshot(self: *Stats) struct { subscribe: u64, authorize: u64, submit: u64, sessions: u64 } {
        return .{ .subscribe = self.subscribe.load(.monotonic), .authorize = self.authorize.load(.monotonic), .submit = self.submit.load(.monotonic), .sessions = self.sessions.load(.monotonic) };
    }
};

pub const Server = struct {
    cfg: Config,
    stats: Stats = .{},
    running: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    vd: vardiff.VarDiff = .{},
    store: ?*store_mod.Store = null,

    pub fn replySubscribe(id: []const u8, extra1: []const u8, buf: []u8) []const u8 {
        return std.fmt.bufPrint(buf, "{{\"id\":{s},\"result\":[[[\"mining.set_difficulty\",\"1\"],[\"mining.notify\",\"1\"]],\"{s}\",4],\"error\":null}}", .{ id, extra1 }) catch buf[0..0];
    }
    pub fn replyOk(id: []const u8, buf: []u8) []const u8 {
        return std.fmt.bufPrint(buf, "{{\"id\":{s},\"result\":true,\"error\":null}}", .{id}) catch buf[0..0];
    }
    pub fn replyFail(id: []const u8, reason: []const u8, buf: []u8) []const u8 {
        return std.fmt.bufPrint(buf, "{{\"id\":{s},\"result\":false,\"error\":[21,\"{s}\",null]}}", .{ id, reason }) catch buf[0..0];
    }
    pub fn setDifficulty(diff: f64, buf: []u8) []const u8 {
        return std.fmt.bufPrint(buf, "{{\"id\":null,\"method\":\"mining.set_difficulty\",\"params\":[{d}]}}", .{diff}) catch buf[0..0];
    }
    pub fn notify(job_id: u64, buf: []u8) []const u8 {
        return job.notify(job_id, buf);
    }

    pub fn serve(self: *Server) !void {
        if (self.cfg.port == 0) return;
        self.running.store(true, .release);
        const addr = try std.net.Address.parseIp4("0.0.0.0", self.cfg.port);
        var listener = try addr.listen(.{ .reuse_address = true });
        defer listener.deinit();
        std.log.info("[stratum] {s} on 0.0.0.0:{d}", .{ self.cfg.algo.name(), self.cfg.port });
        while (self.running.load(.acquire)) {
            const conn = listener.accept() catch continue;
            const t = std.Thread.spawn(.{}, session, .{ self, conn.stream }) catch {
                conn.stream.close();
                continue;
            };
            t.detach();
        }
    }

    fn session(self: *Server, stream: std.net.Stream) void {
        defer stream.close();
        _ = self.stats.sessions.fetchAdd(1, .monotonic);
        defer _ = self.stats.sessions.fetchSub(1, .monotonic);
        var worker_buf: [64]u8 = [_]u8{0} ** 64;
        var worker_len: usize = 0;
        var gate = validate.Gate{ .algo = self.cfg.algo, .difficulty = self.cfg.start_diff };
        var out: [512]u8 = undefined;
        sendLine(stream, setDifficulty(self.cfg.start_diff, &out));
        var buf: [4096]u8 = undefined;
        var have: usize = 0;
        while (true) {
            const n = stream.read(buf[have..]) catch break;
            if (n == 0) break;
            have += n;
            var search: usize = 0;
            while (std.mem.indexOfScalarPos(u8, buf[0..have], search, '\n')) |nl| {
                const line = std.mem.trim(u8, buf[search..nl], " \t\r");
                if (line.len > 0) handleLine(self, stream, line, &worker_buf, &worker_len, &gate);
                search = nl + 1;
            }
            if (search > 0) {
                std.mem.copyForwards(u8, &buf, buf[search..have]);
                have -= search;
            }
            if (have >= buf.len) have = 0;
        }
    }

    fn handleLine(self: *Server, stream: std.net.Stream, line: []const u8, worker_buf: *[64]u8, worker_len: *usize, gate: *validate.Gate) void {
        const method = extractJsonField(line, "method") orelse return;
        const id = extractJsonField(line, "id") orelse "null";
        var out: [512]u8 = undefined;
        if (std.mem.eql(u8, method, "mining.subscribe")) {
            _ = self.stats.subscribe.fetchAdd(1, .monotonic);
            const jn = self.stats.subscribe.load(.monotonic);
            var jbuf: [24]u8 = undefined;
            const jid = std.fmt.bufPrint(&jbuf, "yr-{d}", .{jn}) catch "yr-0";
            gate.setJob(jid);
            sendLine(stream, replySubscribe(id, "yr01", &out));
            sendLine(stream, job.notify(jn, &out));
        } else if (std.mem.eql(u8, method, "mining.authorize")) {
            _ = self.stats.authorize.fetchAdd(1, .monotonic);
            if (paramAt(line, 0)) |w| {
                const n = @min(w.len, worker_buf.len);
                @memcpy(worker_buf[0..n], w[0..n]);
                worker_len.* = n;
                if (self.store) |st| st.touch(worker_buf[0..n]);
            }
            sendLine(stream, replyOk(id, &out));
        } else if (std.mem.eql(u8, method, "mining.submit")) {
            _ = self.stats.submit.fetchAdd(1, .monotonic);
            const authorized = worker_len.* > 0;
            const w = if (authorized) worker_buf[0..worker_len.*] else "anon";
            const job_id = paramAt(line, 1) orelse "";
            const nonce = paramAt(line, 4) orelse "";
            const v = if (!authorized) validate.Verdict.bad_format else gate.check(job_id, nonce);
            if (self.store) |st| {
                if (v == .accept) st.accept(w, self.cfg.algo.name(), self.cfg.start_diff) else st.reject(w, self.cfg.algo.name(), self.cfg.start_diff);
            }
            if (v == .accept) sendLine(stream, replyOk(id, &out)) else sendLine(stream, replyFail(id, @tagName(v), &out));
        }
    }
};

fn paramAt(line: []const u8, n: usize) ?[]const u8 {
    const p = std.mem.indexOf(u8, line, "\"params\"") orelse return null;
    var i = p;
    var seen: usize = 0;
    while (i < line.len) {
        const q1 = std.mem.indexOfScalarPos(u8, line, i, '"') orelse return null;
        const q2 = std.mem.indexOfScalarPos(u8, line, q1 + 1, '"') orelse return null;
        const sl = line[q1 + 1 .. q2];
        if (!std.mem.eql(u8, sl, "params")) {
            if (seen == n) return sl;
            seen += 1;
        }
        i = q2 + 1;
    }
    return null;
}

fn sendLine(stream: std.net.Stream, msg: []const u8) void {
    stream.writeAll(msg) catch return;
    stream.writeAll("\n") catch {};
}

fn extractJsonField(json: []const u8, key: []const u8) ?[]const u8 {
    var nb: [64]u8 = undefined;
    const needle = std.fmt.bufPrint(&nb, "\"{s}\":", .{key}) catch return null;
    const si = std.mem.indexOf(u8, json, needle) orelse return null;
    const vs = si + needle.len;
    if (vs >= json.len) return null;
    if (json[vs] == '"') {
        const ve = std.mem.indexOfScalarPos(u8, json, vs + 1, '"') orelse return null;
        return json[vs + 1 .. ve];
    }
    var e = vs;
    while (e < json.len and json[e] != ',' and json[e] != '}') e += 1;
    return json[vs..e];
}

test "subscribe json" {
    var buf: [256]u8 = undefined;
    const s = Server.replySubscribe("1", "abcd", &buf);
    try std.testing.expect(std.mem.indexOf(u8, s, "mining.notify") != null);
}
