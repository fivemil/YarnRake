const std = @import("std");

pub const VarDiff = struct {
    min_diff: f64 = 0.001,
    max_diff: f64 = 1000.0,
    target_time: f64 = 15.0,
    retarget_secs: f64 = 60.0,
    variance_pct: f64 = 30.0,
    pub fn check(self: VarDiff, shares: u64, elapsed_secs: f64, current_diff: f64) ?f64 {
        if (elapsed_secs < self.retarget_secs) return null;
        const rate = if (shares > 0) @as(f64, @floatFromInt(shares)) / elapsed_secs else 0.0;
        const actual = if (rate > 0.0) 1.0 / rate else self.target_time * 2.0;
        const ratio = actual / self.target_time;
        if (@abs(ratio - 1.0) > self.variance_pct / 100.0) {
            const nd = @max(self.min_diff, @min(self.max_diff, current_diff / ratio));
            if (@abs(nd - current_diff) / current_diff > 0.1) return nd;
        }
        return null;
    }
};

test "no retarget before interval" {
    try std.testing.expect((VarDiff{}).check(10, 30.0, 1.0) == null);
}
