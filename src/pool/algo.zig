//! Popular mining algorithm registry for YarnRake.
//! Stratum accepts all listed algos; native PoW validation is only for a subset.
const std = @import("std");

pub const Hw = enum { cpu, gpu, asic, mixed };

pub const Status = enum {
    /// Job + share format only (lab / until validator lands)
    stratum_stub,
    /// Zig checks PoW against difficulty (lab or production)
    native_validate,
    /// Expect external/full node or specialized validator later
    external,
};

/// Catalog of popular PoW algorithms (2024–2026 mining market).
pub const Algo = enum {
    // DigiByte / YarnRake heritage
    skein,
    yescrypt_r16,
    // CPU
    randomx,
    ghostrider,
    argon2d,
    // GPU
    kawpow,
    etchash,
    ethash,
    autolykos2,
    equihash,
    verthash,
    blake3,
    octopus,
    fishhash,
    // ASIC / classic
    sha256d,
    scrypt,
    x11,
    kheavyhash,
    eaglesong,
    neoscrypt,
    lyra2rev3,
    blake2b,
    blake2s,
    // Niche / still common on multi-algo miners
    cuckatoo32,
    randomx_wow,

    pub fn fromName(name: []const u8) ?Algo {
        if (eqlAny(name, &.{"skein", "skein-512", "skein512"})) return .skein;
        if (eqlAny(name, &.{"yescrypt_r16", "yescrypt", "yescryptr16", "yescryptR16"})) return .yescrypt_r16;
        if (eqlAny(name, &.{"randomx", "rx", "rx/0", "rx0", "monero"})) return .randomx;
        if (eqlAny(name, &.{"randomx_wow", "rx/wow", "wownero"})) return .randomx_wow;
        if (eqlAny(name, &.{"ghostrider", "gr", "rtm"})) return .ghostrider;
        if (eqlAny(name, &.{"argon2d", "argon2"})) return .argon2d;
        if (eqlAny(name, &.{"kawpow", "rvn", "ravencoin"})) return .kawpow;
        if (eqlAny(name, &.{"etchash", "etc"})) return .etchash;
        if (eqlAny(name, &.{"ethash", "eth", "ethw"})) return .ethash;
        if (eqlAny(name, &.{"autolykos2", "autolykos", "ergo", "erg"})) return .autolykos2;
        if (eqlAny(name, &.{"equihash", "equihash200_9", "equi144_5", "zec"})) return .equihash;
        if (eqlAny(name, &.{"verthash", "vtc"})) return .verthash;
        if (eqlAny(name, &.{"blake3", "alph", "alephium"})) return .blake3;
        if (eqlAny(name, &.{"octopus", "cfx", "conflux"})) return .octopus;
        if (eqlAny(name, &.{"fishhash", "ironfish", "iron"})) return .fishhash;
        if (eqlAny(name, &.{"sha256d", "sha256", "sha256double", "btc", "bch"})) return .sha256d;
        if (eqlAny(name, &.{"scrypt", "ltc", "doge"})) return .scrypt;
        if (eqlAny(name, &.{"x11", "dash"})) return .x11;
        if (eqlAny(name, &.{"kheavyhash", "kaspa", "kas"})) return .kheavyhash;
        if (eqlAny(name, &.{"eaglesong", "ckb", "nervos"})) return .eaglesong;
        if (eqlAny(name, &.{"neoscrypt"})) return .neoscrypt;
        if (eqlAny(name, &.{"lyra2rev3", "lyra2re3", "lyra2v3"})) return .lyra2rev3;
        if (eqlAny(name, &.{"blake2b", "sia"})) return .blake2b;
        if (eqlAny(name, &.{"blake2s", "kda", "kadena"})) return .blake2s;
        if (eqlAny(name, &.{"cuckatoo32", "cuckatoo", "grin"})) return .cuckatoo32;
        return null;
    }

    pub fn name(self: Algo) []const u8 {
        return switch (self) {
            .skein => "skein",
            .yescrypt_r16 => "yescrypt_r16",
            .randomx => "randomx",
            .randomx_wow => "randomx_wow",
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
            .fishhash => "fishhash",
            .sha256d => "sha256d",
            .scrypt => "scrypt",
            .x11 => "x11",
            .kheavyhash => "kheavyhash",
            .eaglesong => "eaglesong",
            .neoscrypt => "neoscrypt",
            .lyra2rev3 => "lyra2rev3",
            .blake2b => "blake2b",
            .blake2s => "blake2s",
            .cuckatoo32 => "cuckatoo32",
        };
    }

    pub fn hw(self: Algo) Hw {
        return switch (self) {
            .randomx, .randomx_wow, .ghostrider, .argon2d, .skein, .yescrypt_r16 => .cpu,
            .kawpow, .etchash, .ethash, .autolykos2, .equihash, .verthash, .blake3, .octopus, .fishhash, .neoscrypt, .lyra2rev3, .cuckatoo32 => .gpu,
            .sha256d, .scrypt, .x11, .kheavyhash, .eaglesong => .asic,
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
            .randomx_wow => "WOW",
            .ghostrider => "RTM",
            .argon2d => "CPU coins",
            .kawpow => "RVN, Neoxa",
            .etchash => "ETC",
            .ethash => "ETHW, ETHF",
            .autolykos2 => "ERG",
            .equihash => "ZEC, Horizen, Flux",
            .verthash => "VTC",
            .blake3 => "ALPH, DCR",
            .octopus => "CFX",
            .fishhash => "IRON",
            .sha256d => "BTC, BCH, BSV",
            .scrypt => "LTC, DOGE (merge)",
            .x11 => "DASH",
            .kheavyhash => "KAS",
            .eaglesong => "CKB",
            .neoscrypt => "FTC, others",
            .lyra2rev3 => "legacy Lyra2",
            .blake2b => "SC, others",
            .blake2s => "KDA",
            .cuckatoo32 => "GRIN",
        };
    }

    /// Recommended integrated miner package id(s)
    pub fn miner(self: Algo) []const u8 {
        return switch (self) {
            .randomx, .randomx_wow, .ghostrider => "xmrig",
            .kawpow, .etchash, .ethash, .autolykos2, .octopus, .blake3, .fishhash => "lolminer|t-rex|srbminer|bzminer",
            .equihash => "lolminer|miniz",
            .verthash => "verthashminer|lolminer",
            .cuckatoo32 => "lolminer|grin-miner",
            .sha256d, .scrypt, .x11, .neoscrypt, .lyra2rev3, .blake2b, .blake2s, .skein, .yescrypt_r16, .argon2d, .kheavyhash, .eaglesong => "cpuminer-opt|srbminer",
        };
    }

    /// Default stratum listen port offset from base (base=3333 → +offset)
    pub fn portOffset(self: Algo) u16 {
        return switch (self) {
            .sha256d => 0,
            .scrypt => 1,
            .randomx, .randomx_wow => 2,
            .kawpow => 3,
            .etchash, .ethash => 4,
            .autolykos2 => 5,
            .kheavyhash => 6,
            .skein, .yescrypt_r16 => 7,
            .ghostrider => 8,
            .equihash => 9,
            else => 0,
        };
    }

    pub fn all() []const Algo {
        return &[_]Algo{
            .skein,         .yescrypt_r16, .randomx,   .randomx_wow, .ghostrider, .argon2d,
            .kawpow,        .etchash,      .ethash,    .autolykos2,  .equihash,   .verthash,
            .blake3,        .octopus,      .fishhash,  .sha256d,     .scrypt,     .x11,
            .kheavyhash,    .eaglesong,    .neoscrypt, .lyra2rev3,   .blake2b,    .blake2s,
            .cuckatoo32,
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

/// Lab difficulty check: leading zero bytes on SHA256d(job:nonce)
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
    try std.testing.expect(Algo.fromName("fishhash").? == .fishhash);
    try std.testing.expect(Algo.fromName("ckb").? == .eaglesong);
    try std.testing.expect(Algo.fromName("nope") == null);
}
