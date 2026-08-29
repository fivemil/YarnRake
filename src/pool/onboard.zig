//! Mining device onboarding — MDM-style for CPU / GPU / ASIC / mobile / hybrid.
const std = @import("std");

pub const DeviceType = enum {
    cpu, gpu, asic, mobile, hybrid, other,

    pub fn fromName(name: []const u8) ?DeviceType {
        if (eql(name, "cpu") or eql(name, "processor")) return .cpu;
        if (eql(name, "gpu") or eql(name, "graphics") or eql(name, "nvidia") or eql(name, "amd") or eql(name, "radeon")) return .gpu;
        if (eql(name, "asic") or eql(name, "antminer") or eql(name, "whatsminer") or eql(name, "goldshell")) return .asic;
        if (eql(name, "mobile") or eql(name, "android") or eql(name, "phone") or eql(name, "tablet")) return .mobile;
        if (eql(name, "hybrid") or eql(name, "rig") or eql(name, "mixed")) return .hybrid;
        if (eql(name, "other") or eql(name, "fpga")) return .other;
        return null;
    }
    pub fn name(self: DeviceType) []const u8 {
        return switch (self) {
            .cpu => "cpu", .gpu => "gpu", .asic => "asic", .mobile => "mobile", .hybrid => "hybrid", .other => "other",
        };
    }
    fn eql(a: []const u8, b: []const u8) bool { return std.ascii.eqlIgnoreCase(a, b); }
};

pub const Device = struct {
    uuid: [64]u8 = [_]u8{0} ** 64, uuid_len: usize = 0,
    name: [64]u8 = [_]u8{0} ** 64, name_len: usize = 0,
    worker: [64]u8 = [_]u8{0} ** 64, worker_len: usize = 0,
    algo: [32]u8 = [_]u8{0} ** 32, algo_len: usize = 0,
    software: [48]u8 = [_]u8{0} ** 48, software_len: usize = 0,
    dtype: DeviceType = .other,
    platform: [16]u8 = [_]u8{0} ** 16, platform_len: usize = 0,
    vendor: [32]u8 = [_]u8{0} ** 32, vendor_len: usize = 0,
    model: [48]u8 = [_]u8{0} ** 48, model_len: usize = 0,
    hashrate: [24]u8 = [_]u8{0} ** 24, hashrate_len: usize = 0,
    notes: [64]u8 = [_]u8{0} ** 64, notes_len: usize = 0,
    status: [16]u8 = [_]u8{0} ** 16, status_len: usize = 0,
};

pub const EnrollToken = struct {
    token: [32]u8 = [_]u8{0} ** 32, token_len: usize = 0,
    dtype: DeviceType = .cpu,
    label: [48]u8 = [_]u8{0} ** 48, label_len: usize = 0,
    used: bool = false,
};

pub const Registry = struct {
    mu: std.Thread.Mutex = .{},
    devices: [64]Device = [_]Device{.{}} ** 64,
    count: usize = 0,
    tokens: [32]EnrollToken = [_]EnrollToken{.{}} ** 32,
    token_n: usize = 0,
    path: []const u8,
    next_id: u64 = 1,

    pub fn init(path: []const u8) Registry {
        var r = Registry{ .path = path };
        r.load() catch {};
        return r;
    }

    pub fn onboard(self: *Registry, name: []const u8, dtype: DeviceType, worker: []const u8, algo: []const u8, software: []const u8, platform: []const u8) !Device {
        return self.onboardEx(name, dtype, worker, algo, software, platform, "", "", "", "");
    }

    pub fn onboardEx(self: *Registry, name: []const u8, dtype: DeviceType, worker: []const u8, algo: []const u8, software: []const u8, platform: []const u8, vendor: []const u8, model: []const u8, hashrate: []const u8, notes: []const u8) !Device {
        self.mu.lock();
        defer self.mu.unlock();
        if (self.count >= self.devices.len) return error.Full;
        var d = Device{};
        d.dtype = dtype;
        var ubuf: [64]u8 = undefined;
        const us = try std.fmt.bufPrint(&ubuf, "yr-{s}-{d}", .{ dtype.name(), self.next_id });
        self.next_id += 1;
        copyField(&d.uuid, &d.uuid_len, us);
        copyField(&d.name, &d.name_len, name);
        copyField(&d.worker, &d.worker_len, if (worker.len > 0) worker else name);
        copyField(&d.algo, &d.algo_len, algo);
        copyField(&d.software, &d.software_len, software);
        copyField(&d.platform, &d.platform_len, if (platform.len > 0) platform else defaultPlatform(dtype));
        copyField(&d.vendor, &d.vendor_len, vendor);
        copyField(&d.model, &d.model_len, model);
        copyField(&d.hashrate, &d.hashrate_len, hashrate);
        copyField(&d.notes, &d.notes_len, notes);
        copyField(&d.status, &d.status_len, "enrolled");
        self.devices[self.count] = d;
        self.count += 1;
        self.appendFile(d) catch {};
        return d;
    }

    pub fn createToken(self: *Registry, dtype: DeviceType, label: []const u8) ![]const u8 {
        self.mu.lock();
        defer self.mu.unlock();
        if (self.token_n >= self.tokens.len) return error.Full;
        var t = EnrollToken{ .dtype = dtype };
        var tb: [32]u8 = undefined;
        const tok = try std.fmt.bufPrint(&tb, "enr-{d}-{s}", .{ self.next_id, dtype.name() });
        self.next_id += 1;
        copyField(&t.token, &t.token_len, tok);
        copyField(&t.label, &t.label_len, label);
        self.tokens[self.token_n] = t;
        self.token_n += 1;
        return self.tokens[self.token_n - 1].token[0..self.tokens[self.token_n - 1].token_len];
    }

    pub fn claimToken(self: *Registry, token: []const u8, name: []const u8, worker: []const u8, algo: []const u8, software: []const u8, platform: []const u8, vendor: []const u8, model: []const u8, hashrate: []const u8) !Device {
        self.mu.lock();
        var idx: ?usize = null;
        var i: usize = 0;
        while (i < self.token_n) : (i += 1) {
            const t = self.tokens[i];
            if (!t.used and std.mem.eql(u8, t.token[0..t.token_len], token)) { idx = i; break; }
        }
        const ti = idx orelse { self.mu.unlock(); return error.InvalidToken; };
        const dtype = self.tokens[ti].dtype;
        self.tokens[ti].used = true;
        self.mu.unlock();
        return try self.onboardEx(name, dtype, worker, algo, software, platform, vendor, model, hashrate, "claimed-via-token");
    }

    pub fn listJson(self: *Registry, buf: []u8) []const u8 {
        self.mu.lock();
        defer self.mu.unlock();
        var fbs = std.io.fixedBufferStream(buf);
        const w = fbs.writer();
        w.writeAll("{\"ok\":true,\"devices\":[") catch return "{\"ok\":false}\n";
        var i: usize = 0;
        while (i < self.count) : (i += 1) {
            const d = self.devices[i];
            if (i > 0) w.writeAll(",") catch {};
            w.print("{{\"uuid\":\"{s}\",\"name\":\"{s}\",\"type\":\"{s}\",\"worker\":\"{s}\",\"algo\":\"{s}\",\"software\":\"{s}\",\"platform\":\"{s}\",\"vendor\":\"{s}\",\"model\":\"{s}\",\"hashrate\":\"{s}\",\"status\":\"{s}\",\"notes\":\"{s}\"}}", .{
                d.uuid[0..d.uuid_len], d.name[0..d.name_len], d.dtype.name(), d.worker[0..d.worker_len],
                d.algo[0..d.algo_len], d.software[0..d.software_len], d.platform[0..d.platform_len],
                d.vendor[0..d.vendor_len], d.model[0..d.model_len], d.hashrate[0..d.hashrate_len],
                d.status[0..d.status_len], d.notes[0..d.notes_len],
            }) catch {};
        }
        w.writeAll("],\"count\":") catch {};
        w.print("{d}}}\n", .{self.count}) catch {};
        return fbs.getWritten();
    }

    pub fn tokensJson(self: *Registry, buf: []u8) []const u8 {
        self.mu.lock();
        defer self.mu.unlock();
        var fbs = std.io.fixedBufferStream(buf);
        const w = fbs.writer();
        w.writeAll("{\"ok\":true,\"tokens\":[") catch return "{\"ok\":false}\n";
        var i: usize = 0;
        var shown: usize = 0;
        while (i < self.token_n) : (i += 1) {
            const t = self.tokens[i];
            if (t.used) continue;
            if (shown > 0) w.writeAll(",") catch {};
            w.print("{{\"token\":\"{s}\",\"type\":\"{s}\",\"label\":\"{s}\"}}", .{ t.token[0..t.token_len], t.dtype.name(), t.label[0..t.label_len] }) catch {};
            shown += 1;
        }
        w.writeAll("]}\n") catch {};
        return fbs.getWritten();
    }

    fn defaultPlatform(dtype: DeviceType) []const u8 {
        return switch (dtype) { .asic => "firmware", .mobile => "android", else => "linux" };
    }
    fn copyField(dst: []u8, len: *usize, src: []const u8) void {
        const n = @min(src.len, dst.len);
        if (n > 0) @memcpy(dst[0..n], src[0..n]);
        len.* = n;
    }
    fn appendFile(self: *Registry, d: Device) !void {
        const f = try std.fs.cwd().createFile(self.path, .{ .truncate = false, .read = true });
        defer f.close();
        try f.seekFromEnd(0);
        var buf: [768]u8 = undefined;
        const line = try std.fmt.bufPrint(&buf, "{{\"uuid\":\"{s}\",\"name\":\"{s}\",\"type\":\"{s}\",\"worker\":\"{s}\",\"algo\":\"{s}\",\"software\":\"{s}\",\"platform\":\"{s}\",\"vendor\":\"{s}\",\"model\":\"{s}\",\"hashrate\":\"{s}\",\"status\":\"{s}\",\"notes\":\"{s}\"}}\n", .{
            d.uuid[0..d.uuid_len], d.name[0..d.name_len], d.dtype.name(), d.worker[0..d.worker_len],
            d.algo[0..d.algo_len], d.software[0..d.software_len], d.platform[0..d.platform_len],
            d.vendor[0..d.vendor_len], d.model[0..d.model_len], d.hashrate[0..d.hashrate_len],
            d.status[0..d.status_len], d.notes[0..d.notes_len],
        });
        try f.writeAll(line);
    }
    fn load(self: *Registry) !void {
        const f = std.fs.cwd().openFile(self.path, .{}) catch return;
        defer f.close();
        var data: [512 * 1024]u8 = undefined;
        const n = try f.readAll(&data);
        var it = std.mem.splitScalar(u8, data[0..n], '\n');
        while (it.next()) |line| {
            if (line.len < 8) continue;
            if (self.count >= self.devices.len) break;
            var d = Device{};
            if (extract(line, "uuid")) |v| copyField(&d.uuid, &d.uuid_len, v);
            if (extract(line, "name")) |v| copyField(&d.name, &d.name_len, v);
            if (extract(line, "worker")) |v| copyField(&d.worker, &d.worker_len, v);
            if (extract(line, "algo")) |v| copyField(&d.algo, &d.algo_len, v);
            if (extract(line, "software")) |v| copyField(&d.software, &d.software_len, v);
            if (extract(line, "platform")) |v| copyField(&d.platform, &d.platform_len, v);
            if (extract(line, "vendor")) |v| copyField(&d.vendor, &d.vendor_len, v);
            if (extract(line, "model")) |v| copyField(&d.model, &d.model_len, v);
            if (extract(line, "hashrate")) |v| copyField(&d.hashrate, &d.hashrate_len, v);
            if (extract(line, "status")) |v| copyField(&d.status, &d.status_len, v);
            if (extract(line, "notes")) |v| copyField(&d.notes, &d.notes_len, v);
            if (extract(line, "type")) |v| d.dtype = DeviceType.fromName(v) orelse .other;
            if (d.uuid_len > 0) { self.devices[self.count] = d; self.count += 1; self.next_id += 1; }
        }
    }
};

fn extract(json: []const u8, key: []const u8) ?[]const u8 {
    var nb: [48]u8 = undefined;
    const needle = std.fmt.bufPrint(&nb, "\"{s}\":\"", .{key}) catch return null;
    const si = std.mem.indexOf(u8, json, needle) orelse return null;
    const vs = si + needle.len;
    const ve = std.mem.indexOfScalarPos(u8, json, vs, '"') orelse return null;
    return json[vs..ve];
}

test "device type aliases" {
    try std.testing.expect(DeviceType.fromName("GPU").? == .gpu);
    try std.testing.expect(DeviceType.fromName("antminer").? == .asic);
}
