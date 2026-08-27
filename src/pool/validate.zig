const std = @import("std");

pub const Verdict = enum { accept, stale_job, dup, bad_format };

pub const Seen = struct {
    job_id: [32]u8 = [_]u8{0} ** 32,
    job_len: usize = 0,
    nonce: [16]u8 = [_]u8{0} ** 16,
    nonce_len: usize = 0,
};

pub const Gate = struct {
    current_job: [32]u8 = [_]u8{0} ** 32,
    current_len: usize = 0,
    seen: [32]Seen = [_]Seen{.{}} ** 32,
    seen_n: usize = 0,

    pub fn setJob(self: *Gate, job_id: []const u8) void {
        const n = @min(job_id.len, self.current_job.len);
        @memcpy(self.current_job[0..n], job_id[0..n]);
        self.current_len = n;
        self.seen_n = 0;
    }

    pub fn check(self: *Gate, job_id: []const u8, nonce: []const u8) Verdict {
        if (job_id.len == 0 or nonce.len == 0) return .bad_format;
        if (self.current_len == 0 or !std.mem.eql(u8, job_id, self.current_job[0..self.current_len]))
            return .stale_job;
        var i: usize = 0;
        while (i < self.seen_n) : (i += 1) {
            const s = self.seen[i];
            if (std.mem.eql(u8, nonce, s.nonce[0..s.nonce_len]) and std.mem.eql(u8, job_id, s.job_id[0..s.job_len]))
                return .dup;
        }
        if (self.seen_n < self.seen.len) {
            var row = Seen{};
            const jn = @min(job_id.len, row.job_id.len);
            const nn = @min(nonce.len, row.nonce.len);
            @memcpy(row.job_id[0..jn], job_id[0..jn]);
            @memcpy(row.nonce[0..nn], nonce[0..nn]);
            row.job_len = jn;
            row.nonce_len = nn;
            self.seen[self.seen_n] = row;
            self.seen_n += 1;
        }
        return .accept;
    }
};

test "stale and dup" {
    var g = Gate{};
    g.setJob("yr-1");
    try std.testing.expectEqual(Verdict.stale_job, g.check("yr-9", "aa"));
    try std.testing.expectEqual(Verdict.accept, g.check("yr-1", "aa"));
    try std.testing.expectEqual(Verdict.dup, g.check("yr-1", "aa"));
}
