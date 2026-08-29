# Wiring the control console into `main.zig`

`src/pool/control.zig` and `src/control_page.zig` are on `main`.
Until `main.zig` includes the routes below, open the console after merging this snippet.

## 1. After device registry init

```zig
const control_path = std.posix.getenv("YARNRAKE_CONTROL") orelse "control.tsv";
var board = pool.control.Board.init(control_path);
```

## 2. HTTP routes (before `/launch`)

```zig
} else if (std.mem.eql(u8, path, "/control") or std.mem.eql(u8, path, "/control/")) {
    body = @import("control_page.zig").html();
} else if (std.mem.eql(u8, path, "/control/state")) {
    ctype = "application/json";
    body = board.stateJson(&body_buf);
} else if (std.mem.eql(u8, path, "/control/resolve")) {
    ctype = "application/json";
    const worker_q = queryParam(raw, "worker") orelse "device-1";
    const algo_q = queryParam(raw, "algo") orelse "";
    body = board.resolve(worker_q, algo_q, body_buf[0..]);
} else if (std.mem.eql(u8, path, "/control/pools") and std.mem.eql(u8, method, "POST")) {
    ctype = "application/json";
    body = handleControlPoolAdd(&board, raw, &body_buf, &status);
} else if (std.mem.eql(u8, path, "/control/pools/enable") and std.mem.eql(u8, method, "POST")) {
    ctype = "application/json";
    body = handleControlPoolEnable(&board, raw, &body_buf, &status);
} else if (std.mem.eql(u8, path, "/control/assign") and std.mem.eql(u8, method, "POST")) {
    ctype = "application/json";
    body = handleControlAssign(&board, raw, &body_buf, &status);
```

Handlers: see local MagiMDM/YarnRake workspace `src/main.zig` after control merge, or [CONTROL.md](./CONTROL.md).

## Modes

manual · automatic · failover · round_robin · all_pools · custom
