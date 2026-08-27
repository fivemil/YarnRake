const std = @import("std");

pub fn notify(job_id: u64, buf: []u8) []const u8 {
    return std.fmt.bufPrint(buf,
        "{{\"id\":null,\"method\":\"mining.notify\",\"params\":[\"yr-{d}\",\"0000000000000000000000000000000000000000000000000000000000000000\",\"\",\"\",[],\"20000000\",\"1d00ffff\",\"00000000\",true]}}",
        .{job_id},
    ) catch buf[0..0];
}

test "notify contains job id" {
    var buf: [512]u8 = undefined;
    const s = notify(7, &buf);
    try std.testing.expect(std.mem.indexOf(u8, s, "yr-7") != null);
}
