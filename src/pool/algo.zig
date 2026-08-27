const std = @import("std");

pub const Algo = enum {
    skein,
    yescrypt_r16,
    pub fn fromName(name: []const u8) ?Algo {
        if (std.mem.eql(u8, name, "skein") or std.mem.eql(u8, name, "skein-512")) return .skein;
        if (std.mem.eql(u8, name, "yescrypt_r16") or std.mem.eql(u8, name, "yescrypt")) return .yescrypt_r16;
        return null;
    }
    pub fn name(self: Algo) []const u8 {
        return switch (self) {
            .skein => "skein",
            .yescrypt_r16 => "yescrypt_r16",
        };
    }
};

test "algo names" {
    try std.testing.expect(Algo.fromName("skein").? == .skein);
    try std.testing.expect(Algo.fromName("sha256") == null);
}
