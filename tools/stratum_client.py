#!/usr/bin/env python3
"""Lab stratum client for YarnRake (MineBright miner.py, localhost defaults)."""
import argparse, json, os, socket, time

p = argparse.ArgumentParser()
p.add_argument("--host", default=os.environ.get("YARNRAKE_HOST", "127.0.0.1"))
p.add_argument("--port", type=int, default=int(os.environ.get("YARNRAKE_STRATUM_PORT", "3333")))
p.add_argument("--user", default=os.environ.get("STRATUM_USER", "lab-worker"))
p.add_argument("--pass", dest="pwd", default=os.environ.get("STRATUM_PASS", "x"))
p.add_argument("--duration", type=int, default=int(os.environ.get("DURATION_S", "30")))
p.add_argument("--report-interval", type=int, default=15)
args = p.parse_args()

buf = b""
_id = 0
shares = rejected = 0

def next_id():
    global _id
    _id += 1
    return _id

def send(sock, obj):
    sock.sendall((json.dumps(obj) + "\n").encode())

def readline(sock):
    global buf
    while b"\n" not in buf:
        chunk = sock.recv(4096)
        if not chunk:
            raise ConnectionError("disconnected")
        buf += chunk
    line, buf = buf.split(b"\n", 1)
    line = line.decode().strip()
    return json.loads(line) if line else {}

def main():
    global shares, rejected
    print(f"[yarnrake-client] {args.host}:{args.port} user={args.user}", flush=True)
    sock = socket.create_connection((args.host, args.port), timeout=20)
    sock.settimeout(15)
    send(sock, {"id": next_id(), "method": "mining.subscribe", "params": ["yarnrake-lab/0.1"]})
    print("[subscribe]", readline(sock), flush=True)
    send(sock, {"id": next_id(), "method": "mining.authorize", "params": [args.user, args.pwd]})
    print("[authorize]", readline(sock), flush=True)
    start = last = time.time()
    while time.time() - start < args.duration:
        send(sock, {"id": next_id(), "method": "mining.submit",
                    "params": [args.user, "job", "00000000", "00000000", "00000001"]})
        try:
            r = readline(sock)
            if r.get("result"):
                shares += 1
            else:
                rejected += 1
            print("[submit]", r, flush=True)
        except socket.timeout:
            rejected += 1
        now = time.time()
        if now - last >= args.report_interval:
            print(f"[report] uptime={int(now-start)}s shares={shares} rejected={rejected}", flush=True)
            last = now
        time.sleep(0.5)
    sock.close()
    print(f"[done] shares={shares} rejected={rejected}", flush=True)

if __name__ == "__main__":
    main()
