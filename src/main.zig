const std = @import("std");
const pool = @import("pool.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const algo_name = std.posix.getenv("YARNRAKE_ALGO") orelse "skein";
    const algo = pool.algo.Algo.fromName(algo_name) orelse .skein;
    const stratum_port = parsePort(std.posix.getenv("YARNRAKE_STRATUM_PORT") orelse "3333");
    const http_port = parsePort(std.posix.getenv("PORT") orelse std.posix.getenv("YARNRAKE_PORT") orelse "8787");

    var stratum = pool.stratum.Server{ .cfg = .{ .port = stratum_port, .algo = algo } };
    if (stratum_port != 0) {
        const t = try std.Thread.spawn(.{}, pool.stratum.Server.serve, .{&stratum});
        t.detach();
    }

    std.log.info("YarnRake algo={s} http=:{d} stratum=:{d}", .{ algo.name(), http_port, stratum_port });

    const addr = try std.net.Address.parseIp4("0.0.0.0", http_port);
    var server = try addr.listen(.{ .reuse_address = true });
    defer server.deinit();

    while (true) {
        var conn = try server.accept();
        defer conn.stream.close();
        var req: [1024]u8 = undefined;
        const n = conn.stream.read(&req) catch 0;
        const path = parsePath(req[0..n]);
        const snap = stratum.stats.snapshot();
        var body_buf: [1024]u8 = undefined;
        const body = if (std.mem.eql(u8, path, "/pool") or std.mem.eql(u8, path, "/pool.json"))
            std.fmt.bufPrint(&body_buf,
                "{{\"ok\":true,\"algo\":\"{s}\",\"stratum_port\":{d},\"subscribe\":{d},\"authorize\":{d},\"submit\":{d},\"sessions\":{d}}}\n",
                .{ algo.name(), stratum_port, snap.subscribe, snap.authorize, snap.submit, snap.sessions },
            ) catch "error\n"
        else
            "YarnRake ok — GET /pool\n";
        var hdr: [256]u8 = undefined;
        const out = std.fmt.bufPrint(&hdr, "HTTP/1.1 200 OK\r\nContent-Type: {s}\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n", .{
            if (std.mem.startsWith(u8, path, "/pool")) "application/json" else "text/plain",
            body.len,
        }) catch continue;
        conn.stream.writeAll(out) catch {};
        conn.stream.writeAll(body) catch {};
    }
}

fn parsePort(s: []const u8) u16 {
    return std.fmt.parseInt(u16, s, 10) catch 8787;
}

fn parsePath(req: []const u8) []const u8 {
    const nl = std.mem.indexOf(u8, req, "\r\n") orelse req.len;
    const line = req[0..nl];
    var it = std.mem.splitScalar(u8, line, ' ');
    _ = it.next();
    return it.next() orelse "/";
}
