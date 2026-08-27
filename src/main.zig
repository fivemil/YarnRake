const std = @import("std");
const pool = @import("pool.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const algo_name = std.posix.getenv("YARNRAKE_ALGO") orelse "skein";
    const algo = pool.algo.Algo.fromName(algo_name) orelse .skein;
    const stratum_port = parsePort(std.posix.getenv("YARNRAKE_STRATUM_PORT") orelse "3333");
    const http_port = parsePort(std.posix.getenv("PORT") orelse std.posix.getenv("YARNRAKE_PORT") orelse "8787");
    const share_path = std.posix.getenv("YARNRAKE_SHARES") orelse "shares.jsonl";
    var store = pool.store.Store.init(gpa.allocator(), share_path);
    defer store.deinit();
    var stratum = pool.stratum.Server{ .cfg = .{ .port = stratum_port, .algo = algo }, .store = &store };
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
        const json_pool = std.mem.eql(u8, path, "/pool") or std.mem.eql(u8, path, "/pool.json");
        const body = if (json_pool)
            std.fmt.bufPrint(&body_buf,
                "{{\"ok\":true,\"algo\":\"{s}\",\"stratum_port\":{d},\"subscribe\":{d},\"authorize\":{d},\"submit\":{d},\"sessions\":{d},\"miners\":{d},\"shares_total\":{d}}}\n",
                .{ algo.name(), stratum_port, snap.subscribe, snap.authorize, snap.submit, snap.sessions, store.countMiners(), store.shares_total },
            ) catch "error\n"
        else
            dashHtml();
        var hdr: [256]u8 = undefined;
        const ctype: []const u8 = if (json_pool) "application/json" else "text/html; charset=utf-8";
        const out = std.fmt.bufPrint(&hdr, "HTTP/1.1 200 OK\r\nContent-Type: {s}\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n", .{ ctype, body.len }) catch continue;
        conn.stream.writeAll(out) catch {};
        conn.stream.writeAll(body) catch {};
    }
}
fn parsePort(s: []const u8) u16 { return std.fmt.parseInt(u16, s, 10) catch 8787; }
fn dashHtml() []const u8 {
    return "<!doctype html><html><head><meta charset=utf-8><title>YarnRake</title>" ++
        "<style>body{font-family:Consolas,monospace;background:#0f1117;color:#e8e8f0;padding:24px}" ++
        "a{color:#5e9bdc}.card{background:#1a1d27;border:1px solid #2a2d3e;border-radius:8px;padding:16px;max-width:480px}" ++
        "h1{color:#7c5cbf;font-size:16px}</style></head><body>" ++
        "<div class=card><h1>YarnRake pool</h1><p>Fleet stats: <a href=/pool>/pool</a></p>" ++
        "<p>Lab client: <code>python3 tools/stratum_client.py</code></p>" ++
        "<p>Policy-gated. No CI dispatch.</p></div></body></html>";
}
fn parsePath(req: []const u8) []const u8 {
    const nl = std.mem.indexOf(u8, req, "\r\n") orelse req.len;
    var it = std.mem.splitScalar(u8, req[0..nl], ' ');
    _ = it.next();
    return it.next() orelse "/";
}
