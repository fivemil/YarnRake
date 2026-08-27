//! Local mining device onboarding — CPU / GPU / ASIC / mobile / hybrid.
const std = @import("std");

pub const DeviceType = enum {
    cpu,
    gpu,
    asic,
    mobile,
    hybrid,
    other,

    pub fn fromName(name: []const u8) ?DeviceType {
        if (eql(name, "cpu") or eql(name, "processor")) return .cpu;
        if (eql(name, "gpu") or eql(name, "graphics") or eql(name, "nvidia") or eql(name, "amd")) return .gpu;
        if (eql(name, "asic") or eql(name, "antminer") or eql(name, "whatsminer")) return .asic;
        if (eql(name, "mobile") or eql(name, "android") or eql(name, "phone") or eql(name, "tablet")) return .mobile;
        if (eql(name, "hybrid") or eql(name, "rig") or eql(name, "mixed")) return .hybrid;
        if (eql(name, "other") or eql(name, "fpga")) return .other;
        return null;
    }

    pub fn name(self: DeviceType) []const u8 {
        return switch (self) {
            .cpu => "cpu",
            .gpu => "gpu",
            .asic => "asic",
            .mobile => "mobile",
            .hybrid => "hybrid",
            .other => "other",
        };
    }

    fn eql(a: []const u8, b: []const u8) bool {
        return std.ascii.eqlIgnoreCase(a, b);
    }
};

pub const Device = struct {
    uuid: [64]u8 = [_]u8{0} ** 64,
    uuid_len: usize = 0,
    name: [64]u8 = [_]u8{0} ** 64,
    name_len: usize = 0,
    worker: [64]u8 = [_]u8{0} ** 64,
    worker_len: usize = 0,
    algo: [32]u8 = [_]u8{0} ** 32,
    algo_len: usize = 0,
    software: [32]u8 = [_]u8{0} ** 32,
    software_len: usize = 0,
    dtype: DeviceType = .other,
    platform: [16]u8 = [_]u8{0} ** 16,
    platform_len: usize = 0,
};

pub const Registry = struct {
    mu: std.Thread.Mutex = .{},
    devices: [64]Device = [_]Device{.{}} ** 64,
    count: usize = 0,
    path: []const u8,
    next_id: u64 = 1,

    pub fn init(path: []const u8) Registry {
        var r = Registry{ .path = path };
        r.load() catch {};
        return r;
    }

    pub fn onboard(
        self: *Registry,
        name: []const u8,
        dtype: DeviceType,
        worker: []const u8,
        algo: []const u8,
        software: []const u8,
        platform: []const u8,
    ) !Device {
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
        copyField(&d.worker, &d.worker_len, worker);
        copyField(&d.algo, &d.algo_len, algo);
        copyField(&d.software, &d.software_len, software);
        copyField(&d.platform, &d.platform_len, if (platform.len > 0) platform else "linux");

        self.devices[self.count] = d;
        self.count += 1;
        self.appendFile(d) catch {};
        return d;
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
            w.print(
                "{{\"uuid\":\"{s}\",\"name\":\"{s}\",\"type\":\"{s}\",\"worker\":\"{s}\",\"algo\":\"{s}\",\"software\":\"{s}\",\"platform\":\"{s}\"}}",
                .{
                    d.uuid[0..d.uuid_len],
                    d.name[0..d.name_len],
                    d.dtype.name(),
                    d.worker[0..d.worker_len],
                    d.algo[0..d.algo_len],
                    d.software[0..d.software_len],
                    d.platform[0..d.platform_len],
                },
            ) catch {};
        }
        w.writeAll("],\"count\":") catch {};
        w.print("{d}}}\n", .{self.count}) catch {};
        return fbs.getWritten();
    }

    fn copyField(dst: []u8, len: *usize, src: []const u8) void {
        const n = @min(src.len, dst.len);
        @memcpy(dst[0..n], src[0..n]);
        len.* = n;
    }

    fn appendFile(self: *Registry, d: Device) !void {
        const f = try std.fs.cwd().createFile(self.path, .{ .truncate = false, .read = true });
        defer f.close();
        try f.seekFromEnd(0);
        var buf: [512]u8 = undefined;
        const line = try std.fmt.bufPrint(&buf,
            "{{\"uuid\":\"{s}\",\"name\":\"{s}\",\"type\":\"{s}\",\"worker\":\"{s}\",\"algo\":\"{s}\",\"software\":\"{s}\",\"platform\":\"{s}\"}}\n",
            .{
                d.uuid[0..d.uuid_len],
                d.name[0..d.name_len],
                d.dtype.name(),
                d.worker[0..d.worker_len],
                d.algo[0..d.algo_len],
                d.software[0..d.software_len],
                d.platform[0..d.platform_len],
            },
        );
        try f.writeAll(line);
    }

    fn load(self: *Registry) !void {
        const f = std.fs.cwd().openFile(self.path, .{}) catch return;
        defer f.close();
        var buf: [8192]u8 = undefined;
        const n = try f.readAll(&buf);
        var it = std.mem.splitScalar(u8, buf[0..n], '\n');
        while (it.next()) |line| {
            if (line.len < 10) continue;
            if (self.count >= self.devices.len) break;
            var d = Device{};
            if (extract(line, "uuid")) |v| copyField(&d.uuid, &d.uuid_len, v);
            if (extract(line, "name")) |v| copyField(&d.name, &d.name_len, v);
            if (extract(line, "worker")) |v| copyField(&d.worker, &d.worker_len, v);
            if (extract(line, "algo")) |v| copyField(&d.algo, &d.algo_len, v);
            if (extract(line, "software")) |v| copyField(&d.software, &d.software_len, v);
            if (extract(line, "platform")) |v| copyField(&d.platform, &d.platform_len, v);
            if (extract(line, "type")) |v| {
                d.dtype = DeviceType.fromName(v) orelse .other;
            }
            if (d.uuid_len > 0) {
                self.devices[self.count] = d;
                self.count += 1;
                self.next_id += 1;
            }
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
    try std.testing.expect(DeviceType.fromName("android").? == .mobile);
}
