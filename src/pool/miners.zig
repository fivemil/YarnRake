//! Integrated mining software catalog — external binaries YarnRake launches or documents.
const std = @import("std");
const algo = @import("algo.zig");

pub const MinerSoft = struct {
    id: []const u8,
    hw: algo.Hw,
    algos: []const []const u8,
    homepage: []const u8,
    notes: []const u8,
};

pub const catalog = [_]MinerSoft{
    .{ .id = "xmrig", .hw = .cpu, .algos = &.{"randomx", "ghostrider"}, .homepage = "https://github.com/xmrig/xmrig", .notes = "Primary CPU miner for Monero RandomX" },
    .{ .id = "cpuminer-opt", .hw = .cpu, .algos = &.{"skein", "yescrypt_r16", "scrypt", "x11", "neoscrypt", "lyra2rev3", "blake2s", "sha256d"}, .homepage = "https://github.com/JayDDee/cpuminer-opt", .notes = "Multi-algo CPU; DigiByte / classic" },
    .{ .id = "srbminer-multi", .hw = .mixed, .algos = &.{"randomx", "kawpow", "etchash", "autolykos2", "blake3", "kheavyhash"}, .homepage = "https://github.com/doktor83/SRBMiner-Multi", .notes = "CPU + GPU multi-algo" },
    .{ .id = "lolminer", .hw = .gpu, .algos = &.{"etchash", "autolykos2", "equihash", "blake3", "kawpow"}, .homepage = "https://github.com/Lolliedieb/lolMiner-releases", .notes = "Popular NVIDIA/AMD GPU miner" },
    .{ .id = "t-rex", .hw = .gpu, .algos = &.{"kawpow", "etchash", "octopus", "autolykos2"}, .homepage = "https://github.com/trexminer/T-Rex", .notes = "NVIDIA-focused GPU miner" },
};

pub fn forAlgo(a: algo.Algo) []const u8 {
    return a.miner();
}
