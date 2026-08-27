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

    std.log.info("YarnRake algo={s} status={s} http=:{d} stratum=:{d}", .{
        algo.name(),
        @tagName(algo.status()),
        http_port,
        stratum_port,
    });

    const addr = try std.net.Address.parseIp4("0.0.0.0", http_port);
    var server = try addr.listen(.{ .reuse_address = true });
    defer server.deinit();

    while (true) {
        var conn = try server.accept();
        defer conn.stream.close();
        var req: [2048]u8 = undefined;
        const n = conn.stream.read(&req) catch 0;
        const path = parsePath(req[0..n]);
        const snap = stratum.stats.snapshot();

        var body_buf: [8192]u8 = undefined;
        const body: []const u8 = if (std.mem.eql(u8, path, "/pool") or std.mem.eql(u8, path, "/pool.json"))
            (std.fmt.bufPrint(&body_buf,
                "{{\"ok\":true,\"algo\":\"{s}\",\"status\":\"{s}\",\"hw\":\"{s}\",\"miner\":\"{s}\",\"stratum_port\":{d},\"subscribe\":{d},\"authorize\":{d},\"submit\":{d},\"sessions\":{d},\"miners\":{d},\"shares_total\":{d},\"rejected_total\":{d}}}\n",
                .{
                    algo.name(),
                    @tagName(algo.status()),
                    @tagName(algo.hw()),
                    algo.miner(),
                    stratum_port,
                    snap.subscribe,
                    snap.authorize,
                    snap.submit,
                    snap.sessions,
                    store.countMiners(),
                    store.shares_total,
                    store.rejected_total,
                },
            ) catch "{\"ok\":false}\n")
        else if (std.mem.eql(u8, path, "/algos") or std.mem.eql(u8, path, "/algos.json"))
            algosJson(&body_buf)
        else
            dashHtml();

        var hdr: [256]u8 = undefined;
        const ctype: []const u8 = if (std.mem.startsWith(u8, path, "/pool") or std.mem.startsWith(u8, path, "/algos"))
            "application/json"
        else
            "text/html; charset=utf-8";
        const out = std.fmt.bufPrint(&hdr, "HTTP/1.1 200 OK\r\nContent-Type: {s}\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n", .{
            ctype,
            body.len,
        }) catch continue;
        conn.stream.writeAll(out) catch {};
        conn.stream.writeAll(body) catch {};
    }
}

fn algosJson(buf: []u8) []const u8 {
    var fbs = std.io.fixedBufferStream(buf);
    const w = fbs.writer();
    w.writeAll("{\"ok\":true,\"algos\":[") catch return "{\"ok\":false}\n";
    const list = pool.algo.Algo.all();
    for (list, 0..) |a, i| {
        if (i > 0) w.writeAll(",") catch {};
        w.print(
            "{{\"id\":\"{s}\",\"hw\":\"{s}\",\"status\":\"{s}\",\"coins\":\"{s}\",\"miner\":\"{s}\"}}",
            .{ a.name(), @tagName(a.hw()), @tagName(a.status()), a.coins(), a.miner() },
        ) catch {};
    }
    w.writeAll("]}\n") catch {};
    return fbs.getWritten();
}

fn parsePort(s: []const u8) u16 {
    return std.fmt.parseInt(u16, s, 10) catch 8787;
}

fn dashHtml() []const u8 {
    return "<!doctype html><html><head><meta charset=utf-8><title>YarnRake</title>" ++
        "<style>body{font-family:Consolas,monospace;background:#0f1117;color:#e8e8f0;padding:24px}" ++
        "a{color:#5e9bdc}.card{background:#1a1d27;border:1px solid #2a2d3e;border-radius:8px;padding:16px;max-width:640px}" ++
        "h1{color:#7c5cbf;font-size:16px}</style></head><body>" ++
        "<div class=card><h1>YarnRake multi-algo pool</h1>" ++
        "<p><a href=/pool>/pool</a> · <a href=/algos>/algos</a></p>" ++
        "<p>Set <code>YARNRAKE_ALGO</code> (skein, randomx, kawpow, sha256d, …)</p>" ++
        "<p>Integrated miners: xmrig, cpuminer-opt, lolMiner — see <code>tools/miners/</code></p>" ++
        "<p>Mining stays policy-gated via MagiMDM. Native PoW: sha256d lab only.</p></div></body></html>";
}

fn parsePath(req: []const u8) []const u8 {
    const nl = std.mem.indexOf(u8, req, "\r\n") orelse req.len;
    const line = req[0..nl];
    var it = std.mem.splitScalar(u8, line, ' ');
    _ = it.next();
    return it.next() orelse "/";
}
