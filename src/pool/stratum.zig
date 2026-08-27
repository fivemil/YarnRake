const std = @import("std");
const algo_mod = @import("algo.zig");
const vardiff = @import("vardiff.zig");

pub const Config = struct {
    port: u16 = 3333,
    algo: algo_mod.Algo = .skein,
    start_diff: f64 = 0.01,
};

pub const Server = struct {
    cfg: Config,
    vd: vardiff.VarDiff = .{},
    pub fn replySubscribe(id: []const u8, extra1: []const u8, buf: []u8) []const u8 {
        return std.fmt.bufPrint(buf, "{{\"id\":{s},\"result\":[[[\"mining.set_difficulty\",\"1\"],[\"mining.notify\",\"1\"]],\"{s}\",4],\"error\":null}}", .{ id, extra1 }) catch buf[0..0];
    }
    pub fn replyOk(id: []const u8, buf: []u8) []const u8 {
        return std.fmt.bufPrint(buf, "{{\"id\":{s},\"result\":true,\"error\":null}}", .{id}) catch buf[0..0];
    }
};

test "subscribe json" {
    var buf: [256]u8 = undefined;
    const s = Server.replySubscribe("1", "abcd", &buf);
    try std.testing.expect(std.mem.indexOf(u8, s, "mining.notify") != null);
}
