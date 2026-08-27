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

    const devices_path = std.posix.getenv("YARNRAKE_DEVICES") orelse "devices.jsonl";
    var registry = pool.onboard.Registry.init(devices_path);

    var stratum = pool.stratum.Server{ .cfg = .{ .port = stratum_port, .algo = algo }, .store = &store };
    if (stratum_port != 0) {
        const t = try std.Thread.spawn(.{}, pool.stratum.Server.serve, .{&stratum});
        t.detach();
    }

    std.log.info("YarnRake algo={s} http=:{d} stratum=:{d} devices={d}", .{
        algo.name(), http_port, stratum_port, registry.count,
    });

    const addr = try std.net.Address.parseIp4("0.0.0.0", http_port);
    var server = try addr.listen(.{ .reuse_address = true });
    defer server.deinit();

    while (true) {
        var conn = try server.accept();
        defer conn.stream.close();
        var req: [8192]u8 = undefined;
        const n = conn.stream.read(&req) catch 0;
        const raw = req[0..n];
        const path = parsePath(raw);
        const method = parseMethod(raw);
        const snap = stratum.stats.snapshot();

        var body_buf: [12288]u8 = undefined;
        var body: []const u8 = undefined;
        var status: []const u8 = "200 OK";
        var ctype: []const u8 = "text/html; charset=utf-8";

        if (std.mem.eql(u8, path, "/pool") or std.mem.eql(u8, path, "/pool.json")) {
            ctype = "application/json";
            body = std.fmt.bufPrint(&body_buf,
                "{{\"ok\":true,\"algo\":\"{s}\",\"stratum_port\":{d},\"subscribe\":{d},\"authorize\":{d},\"submit\":{d},\"sessions\":{d},\"miners\":{d},\"shares_total\":{d},\"rejected_total\":{d},\"devices\":{d}}}\n",
                .{ algo.name(), stratum_port, snap.subscribe, snap.authorize, snap.submit, snap.sessions, store.countMiners(), store.shares_total, store.rejected_total, registry.count },
            ) catch "{\"ok\":false}\n";
        } else if (std.mem.eql(u8, path, "/algos") or std.mem.eql(u8, path, "/algos.json")) {
            ctype = "application/json";
            body = algosJson(&body_buf);
        } else if (std.mem.eql(u8, path, "/miners") or std.mem.eql(u8, path, "/miners.json")) {
            ctype = "application/json";
            body = minersJson(&body_buf);
        } else if (std.mem.eql(u8, path, "/devices") or std.mem.eql(u8, path, "/devices.json")) {
            ctype = "application/json";
            body = registry.listJson(&body_buf);
        } else if (std.mem.eql(u8, path, "/onboard") and std.mem.eql(u8, method, "POST")) {
            ctype = "application/json";
            body = handleOnboardPost(&registry, raw, &body_buf, &status);
        } else if (std.mem.eql(u8, path, "/onboard")) {
            body = onboardHtml();
        } else if (std.mem.eql(u8, path, "/types")) {
            ctype = "application/json";
            body = "{\"ok\":true,\"types\":[{\"id\":\"cpu\"},{\"id\":\"gpu\"},{\"id\":\"asic\"},{\"id\":\"mobile\"},{\"id\":\"hybrid\"},{\"id\":\"other\"}]}\n";
        } else {
            body = dashHtml();
        }

        var hdr: [256]u8 = undefined;
        const out = std.fmt.bufPrint(&hdr, "HTTP/1.1 {s}\r\nContent-Type: {s}\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n", .{ status, ctype, body.len }) catch continue;
        conn.stream.writeAll(out) catch {};
        conn.stream.writeAll(body) catch {};
    }
}

fn handleOnboardPost(reg: *pool.onboard.Registry, raw: []const u8, buf: []u8, status: *[]const u8) []const u8 {
    const body = bodyOf(raw) orelse {
        status.* = "400 Bad Request";
        return "{\"ok\":false,\"error\":\"no body\"}\n";
    };
    const name = formOrJson(body, "name") orelse "unnamed";
    const type_s = formOrJson(body, "type") orelse formOrJson(body, "device_type") orelse "cpu";
    const worker = formOrJson(body, "worker") orelse name;
    const algo = formOrJson(body, "algo") orelse "";
    const software = formOrJson(body, "software") orelse "";
    const platform = formOrJson(body, "platform") orelse "linux";
    const dtype = pool.onboard.DeviceType.fromName(type_s) orelse {
        status.* = "400 Bad Request";
        return "{\"ok\":false,\"error\":\"invalid type\"}\n";
    };
    const d = reg.onboard(name, dtype, worker, algo, software, platform) catch {
        status.* = "507 Insufficient Storage";
        return "{\"ok\":false,\"error\":\"registry full\"}\n";
    };
    return std.fmt.bufPrint(buf,
        "{{\"ok\":true,\"uuid\":\"{s}\",\"name\":\"{s}\",\"type\":\"{s}\",\"worker\":\"{s}\",\"algo\":\"{s}\",\"software\":\"{s}\",\"platform\":\"{s}\"}}\n",
        .{ d.uuid, d.name, @tagName(d.dtype), d.worker, d.algo, d.software, d.platform },
    ) catch "{\"ok\":false}\n";
}

fn bodyOf(req: []const u8) ?[]const u8 {
    const sep = std.mem.indexOf(u8, req, "\r\n\r\n") orelse return null;
    const b = req[sep + 4 ..];
    return if (b.len == 0) null else b;
}

fn formOrJson(body: []const u8, key: []const u8) ?[]const u8 {
    // form: key=value
    var it = std.mem.splitScalar(u8, body, '&');
    while (it.next()) |pair| {
        if (std.mem.indexOfScalar(u8, pair, '=')) |eq| {
            if (std.mem.eql(u8, pair[0..eq], key)) return pair[eq + 1 ..];
        }
    }
    // naive json "key":"value"
    var needle_buf: [64]u8 = undefined;
    const needle = std.fmt.bufPrint(&needle_buf, "\"{s}\":\"", .{key}) catch return null;
    if (std.mem.indexOf(u8, body, needle)) |i| {
        const start = i + needle.len;
        if (std.mem.indexOfScalar(u8, body[start..], '"')) |end| return body[start .. start + end];
    }
    return null;
}

fn algosJson(buf: []u8) []const u8 {
    var fbs = std.io.fixedBufferStream(buf);
    const w = fbs.writer();
    w.writeAll("{\"ok\":true,\"algos\":[") catch return "{\"ok\":false}\n";
    for (pool.algo.Algo.all(), 0..) |a, i| {
        if (i > 0) w.writeAll(",") catch {};
        w.print(
            "{{\"id\":\"{s}\",\"hw\":\"{s}\",\"status\":\"{s}\",\"coins\":\"{s}\",\"miner\":\"{s}\",\"port_offset\":{d}}}",
            .{ a.name(), @tagName(a.hw()), @tagName(a.status()), a.coins(), a.miner(), a.portOffset() },
        ) catch {};
    }
    w.writeAll("]}\n") catch {};
    return fbs.getWritten();
}

fn minersJson(buf: []u8) []const u8 {
    var inner: [10240]u8 = undefined;
    const catalog = pool.miners.writeJson(&inner);
    return std.fmt.bufPrint(buf, "{{\"ok\":true,\"miners\":{s}}}\n", .{catalog}) catch "{\"ok\":false}\n";
}

fn parsePort(s: []const u8) u16 {
    return std.fmt.parseInt(u16, s, 10) catch 8787;
}
fn parseMethod(req: []const u8) []const u8 {
    const nl = std.mem.indexOf(u8, req, "\r\n") orelse req.len;
    var it = std.mem.splitScalar(u8, req[0..nl], ' ');
    return it.next() orelse "GET";
}
fn parsePath(req: []const u8) []const u8 {
    const nl = std.mem.indexOf(u8, req, "\r\n") orelse req.len;
    var it = std.mem.splitScalar(u8, req[0..nl], ' ');
    _ = it.next();
    const p = it.next() orelse "/";
    if (std.mem.indexOfScalar(u8, p, '?')) |q| return p[0..q];
    return p;
}
fn dashHtml() []const u8 {
    return "<!doctype html><html><head><meta charset=utf-8><title>YarnRake</title></head><body style=\"background:#0f1117;color:#eee;font-family:sans-serif;padding:24px\"><h1>YarnRake</h1><p><a href=/onboard style=color:#5e9bdc>Onboard device</a> · <a href=/devices style=color:#5e9bdc>Devices</a> · <a href=/pool style=color:#5e9bdc>Pool</a> · <a href=/types style=color:#5e9bdc>Types</a> · <a href=/algos style=color:#5e9bdc>Algos</a> · <a href=/miners style=color:#5e9bdc>Miners</a></p><p>CPU · GPU · ASIC · mobile · hybrid</p></body></html>";
}
fn onboardHtml() []const u8 {
    return "<!doctype html><html><head><meta charset=utf-8><title>Onboard</title></head><body style=\"background:#0f1117;color:#eee;font-family:sans-serif;padding:24px\"><h1>Onboard mining device</h1><form id=f><p>Name <input name=name required></p><p>Type <select name=type><option>cpu</option><option>gpu</option><option>asic</option><option>mobile</option><option>hybrid</option><option>other</option></select></p><p>Worker <input name=worker required></p><p>Algo <input name=algo></p><p>Software <input name=software></p><p>Platform <input name=platform value=linux></p><button>Register</button></form><pre id=out></pre><script>document.getElementById('f').onsubmit=async(e)=>{e.preventDefault();const b=new URLSearchParams(new FormData(e.target));const r=await fetch('/onboard',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:b});document.getElementById('out').textContent=await r.text();};</script></body></html>";
}
