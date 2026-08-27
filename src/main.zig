const std = @import("std");
const pool = @import("pool.zig");

pub fn main() !void {
    const algo_name = std.posix.getenv("YARNRAKE_ALGO") orelse "skein";
    const algo = pool.algo.Algo.fromName(algo_name) orelse .skein;
    const stratum_port = parsePort(std.posix.getenv("YARNRAKE_STRATUM_PORT") orelse "3333");
    const http_port = parsePort(std.posix.getenv("PORT") orelse std.posix.getenv("YARNRAKE_PORT") orelse "8787");
    std.log.info("YarnRake algo={s} http=:{d} stratum=:{d}", .{ algo.name(), http_port, stratum_port });
    const addr = try std.net.Address.parseIp4("0.0.0.0", http_port);
    var server = try addr.listen(.{ .reuse_address = true });
    defer server.deinit();
    while (true) {
        var conn = try server.accept();
        defer conn.stream.close();
        var buf: [512]u8 = undefined;
        _ = conn.stream.read(&buf) catch 0;
        const body = "YarnRake ok\n";
        const hdr = try std.fmt.bufPrint(&buf, "HTTP/1.1 200 OK\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n{s}", .{ body.len, body });
        _ = conn.stream.writeAll(hdr) catch {};
    }
}

fn parsePort(s: []const u8) u16 {
    return std.fmt.parseInt(u16, s, 10) catch 8787;
}
