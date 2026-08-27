//! Popular mining algorithm registry for YarnRake.
const std = @import("std");

pub const Hw = enum { cpu, gpu, asic, mixed };

pub const Status = enum {
    stratum_stub,
    native_validate,
    external,
};

pub const Algo = enum {
    skein,
    yescrypt_r16,
    randomx,
    ghostrider,
    argon2d,
    kawpow,
    etchash,
    ethash,
    autolykos2,
    equihash,
    verthash,
    blake3,
    octopus,
    sha256d,
    scrypt,
    x11,
    kheavyhash,
    neoscrypt,
    lyra2rev3,
    blake2b,
    blake2s,

    pub fn fromName(name: []const u8) ?Algo {
        if (eqlAny(name, &.{"skein", "skein-512", "skein512"})) return .skein;
        if (eqlAny(name, &.{"yescrypt_r16", "yescrypt", "yescryptr16", "yescryptR16"})) return .yescrypt_r16;
        if (eqlAny(name, &.{"randomx", "rx", "rx/0", "rx0"})) return .randomx;
        if (eqlAny(name, &.{"ghostrider", "gr"})) return .ghostrider;
        if (eqlAny(name, &.{"argon2d", "argon2"})) return .argon2d;
        if (eqlAny(name, &.{"kawpow", "rvn"})) return .kawpow;
        if (eqlAny(name, &.{"etchash", "etc"})) return .etchash;
        if (eqlAny(name, &.{"ethash", "eth"})) return .ethash;
        if (eqlAny(name, &.{"autolykos2", "autolykos", "ergo"})) return .autolykos2;
        if (eqlAny(name, &.{"equihash", "equihash200_9", "zec"})) return .equihash;
        if (eqlAny(name, &.{"verthash", "vtc"})) return .verthash;
        if (eqlAny(name, &.{"blake3", "alph"})) return .blake3;
        if (eqlAny(name, &.{"octopus", "cfx"})) return .octopus;
        if (eqlAny(name, &.{"sha256d", "sha256", "sha256double", "btc"})) return .sha256d;
        if (eqlAny(name, &.{"scrypt", "ltc"})) return .scrypt;
        if (eqlAny(name, &.{"x11", "dash"})) return .x11;
        if (eqlAny(name, &.{"kheavyhash", "kaspa", "kas"})) return .kheavyhash;
        if (eqlAny(name, &.{"neoscrypt"})) return .neoscrypt;
        if (eqlAny(name, &.{"lyra2rev3", "lyra2re3", "lyra2v3"})) return .lyra2rev3;
        if (eqlAny(name, &.{"blake2b"})) return .blake2b;
        if (eqlAny(name, &.{"blake2s"})) return .blake2s;
        return null;
    }

    pub fn name(self: Algo) []const u8 {
        return switch (self) {
            .skein => "skein",
            .yescrypt_r16 => "yescrypt_r16",
            .randomx => "randomx",
            .ghostrider => "ghostrider",
            .argon2d => "argon2d",
            .kawpow => "kawpow",
            .etchash => "etchash",
            .ethash => "ethash",
            .autolykos2 => "autolykos2",
            .equihash => "equihash",
            .verthash => "verthash",
            .blake3 => "blake3",
            .octopus => "octopus",
            .sha256d => "sha256d",
            .scrypt => "scrypt",
            .x11 => "x11",
            .kheavyhash => "kheavyhash",
            .neoscrypt => "neoscrypt",
            .lyra2rev3 => "lyra2rev3",
            .blake2b => "blake2b",
            .blake2s => "blake2s",
        };
    }

    pub fn hw(self: Algo) Hw {
        return switch (self) {
            .randomx, .ghostrider, .argon2d, .skein, .yescrypt_r16 => .cpu,
            .kawpow, .etchash, .ethash, .autolykos2, .equihash, .verthash, .blake3, .octopus, .neoscrypt, .lyra2rev3 => .gpu,
            .sha256d, .scrypt, .x11, .kheavyhash => .asic,
            .blake2b, .blake2s => .mixed,
        };
    }

    pub fn status(self: Algo) Status {
        return switch (self) {
            .sha256d => .native_validate,
            .skein, .yescrypt_r16 => .stratum_stub,
            else => .external,
        };
    }

    pub fn coins(self: Algo) []const u8 {
        return switch (self) {
            .skein => "DGB (Skein)",
            .yescrypt_r16 => "DGB (Yescrypt)",
            .randomx => "XMR, Zephyr",
            .ghostrider => "RTM",
            .argon2d => "various CPU coins",
            .kawpow => "RVN, Neoxa",
            .etchash => "ETC",
            .ethash => "ETHW, ETHF",
            .autolykos2 => "ERG",
            .equihash => "ZEC, Horizen",
            .verthash => "VTC",
            .blake3 => "ALPH, DCR",
            .octopus => "CFX",
            .sha256d => "BTC, BCH",
            .scrypt => "LTC, DOGE",
            .x11 => "DASH",
            .kheavyhash => "KAS",
            .neoscrypt => "FTC, others",
            .lyra2rev3 => "VTC (legacy)",
            .blake2b => "SIA, others",
            .blake2s => "KDA",
        };
    }

    pub fn miner(self: Algo) []const u8 {
        return switch (self) {
            .randomx, .ghostrider => "xmrig",
            .kawpow, .etchash, .ethash, .autolykos2, .octopus, .blake3 => "lolminer|t-rex|srbminer",
            .equihash => "lolminer|miniz",
            .verthash => "verthashminer|lolminer",
            .sha256d, .scrypt, .x11, .neoscrypt, .lyra2rev3, .blake2b, .blake2s, .skein, .yescrypt_r16, .argon2d, .kheavyhash => "cpuminer-opt|srbminer",
        };
    }

    pub fn all() []const Algo {
        return &[_]Algo{
            .skein, .yescrypt_r16, .randomx, .ghostrider, .argon2d,
            .kawpow, .etchash, .ethash, .autolykos2, .equihash,
            .verthash, .blake3, .octopus, .sha256d, .scrypt,
            .x11, .kheavyhash, .neoscrypt, .lyra2rev3, .blake2b, .blake2s,
        };
    }

    fn eqlAny(name: []const u8, list: []const []const u8) bool {
        for (list) |s| {
            if (std.ascii.eqlIgnoreCase(name, s)) return true;
        }
        return false;
    }
};

pub fn sha256d(data: []const u8, out: *[32]u8) void {
    var mid: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(data, &mid, .{});
    std.crypto.hash.sha2.Sha256.hash(&mid, out, .{});
}

pub fn validateSha256dLab(job_id: []const u8, nonce: []const u8, difficulty: f64) bool {
    var buf: [256]u8 = undefined;
    const msg = std.fmt.bufPrint(&buf, "{s}:{s}", .{ job_id, nonce }) catch return false;
    var hash: [32]u8 = undefined;
    sha256d(msg, &hash);
    const need: u8 = if (difficulty >= 16.0) 2 else if (difficulty >= 1.0) 1 else 0;
    var i: u8 = 0;
    while (i < need) : (i += 1) {
        if (hash[i] != 0) return false;
    }
    return true;
}

test "algo aliases" {
    try std.testing.expect(Algo.fromName("rx/0").? == .randomx);
    try std.testing.expect(Algo.fromName("BTC").? == .sha256d);
    try std.testing.expect(Algo.fromName("yescryptr16").? == .yescrypt_r16);
    try std.testing.expect(Algo.fromName("nope") == null);
}
