//! Integrated mining software catalog — external binaries YarnRake documents and launches via scripts.
const std = @import("std");
const algo = @import("algo.zig");

pub const MinerSoft = struct {
    id: []const u8,
    hw: algo.Hw,
    algos: []const []const u8,
    homepage: []const u8,
    run_script: []const u8,
    notes: []const u8,
};

/// Popular open / widely used miners. YarnRake does not vendor binaries (licenses / size);
/// `tools/miners/setup.sh` installs or links them; `run_*.sh` points them at local stratum.
pub const catalog = [_]MinerSoft{
    .{
        .id = "xmrig",
        .hw = .cpu,
        .algos = &.{"randomx", "randomx_wow", "ghostrider"},
        .homepage = "https://github.com/xmrig/xmrig",
        .run_script = "run_xmrig.sh",
        .notes = "Primary CPU miner (Monero RandomX, Raptoreum GhostRider)",
    },
    .{
        .id = "cpuminer-opt",
        .hw = .cpu,
        .algos = &.{"skein", "yescrypt_r16", "scrypt", "x11", "neoscrypt", "lyra2rev3", "blake2s", "blake2b", "sha256d", "argon2d"},
        .homepage = "https://github.com/JayDDee/cpuminer-opt",
        .run_script = "run_cpuminer.sh",
        .notes = "Multi-algo CPU; DigiByte Skein/Yescrypt and classic algos",
    },
    .{
        .id = "srbminer-multi",
        .hw = .mixed,
        .algos = &.{"randomx", "kawpow", "etchash", "autolykos2", "blake3", "kheavyhash", "eaglesong", "fishhash"},
        .homepage = "https://github.com/doktor83/SRBMiner-Multi",
        .run_script = "run_srbminer.sh",
        .notes = "CPU + GPU multi-algo (Windows/Linux builds)",
    },
    .{
        .id = "lolminer",
        .hw = .gpu,
        .algos = &.{"etchash", "autolykos2", "equihash", "blake3", "kawpow", "fishhash", "cuckatoo32"},
        .homepage = "https://github.com/Lolliedieb/lolMiner-releases",
        .run_script = "run_lolminer.sh",
        .notes = "NVIDIA/AMD GPU miner",
    },
    .{
        .id = "t-rex",
        .hw = .gpu,
        .algos = &.{"kawpow", "etchash", "octopus", "autolykos2"},
        .homepage = "https://github.com/trexminer/T-Rex",
        .run_script = "run_trex.sh",
        .notes = "NVIDIA-focused GPU miner",
    },
    .{
        .id = "bzminer",
        .hw = .gpu,
        .algos = &.{"etchash", "kawpow", "autolykos2", "octopus", "blake3", "fishhash"},
        .homepage = "https://www.bzminer.com/",
        .run_script = "run_bzminer.sh",
        .notes = "Multi-algo GPU",
    },
    .{
        .id = "teamredminer",
        .hw = .gpu,
        .algos = &.{"etchash", "kawpow", "autolykos2"},
        .homepage = "https://github.com/todxx/teamredminer",
        .run_script = "run_teamredminer.sh",
        .notes = "AMD-focused GPU miner",
    },
    .{
        .id = "miniz",
        .hw = .gpu,
        .algos = &.{"equihash"},
        .homepage = "https://miniz.ch/",
        .run_script = "run_miniz.sh",
        .notes = "Equihash family (ZEC / Flux variants)",
    },
    .{
        .id = "cgminer",
        .hw = .asic,
        .algos = &.{"sha256d", "scrypt"},
        .homepage = "https://github.com/ckolivas/cgminer",
        .run_script = "run_cgminer.sh",
        .notes = "Classic ASIC / USB stick firmware interface",
    },
};

pub fn forAlgo(a: algo.Algo) []const u8 {
    return a.miner();
}

pub fn writeJson(buf: []u8) []const u8 {
    var fbs = std.io.fixedBufferStream(buf);
    const w = fbs.writer();
    w.writeAll("[") catch return "[]";
    for (catalog, 0..) |m, i| {
        if (i > 0) w.writeAll(",") catch {};
        w.print(
            \\{{"id":"{s}","hw":"{s}","homepage":"{s}","run_script":"{s}","notes":"{s}"}}
        ,
            .{ m.id, @tagName(m.hw), m.homepage, m.run_script, m.notes },
        ) catch {};
    }
    w.writeAll("]") catch {};
    return fbs.getWritten();
}
