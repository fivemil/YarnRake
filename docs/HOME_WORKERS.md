# Home workers — run hashrate on your LAN

Point **your** PCs, GPUs, and ASICs at a YarnRake pool on the same network (or VPN).

## 1. Pool host

```bash
zig build && ./zig-out/bin/yarnrake
# or: docker compose up -d --build yarnrake
hostname -I | awk '{print $1}'   # LAN IP for workers
sudo ufw allow 3333/tcp
```

## 2. Each worker

```bash
export YARNRAKE_HOST=192.168.1.50
export YARNRAKE_WORKER=$(hostname -s)
export YARNRAKE_ALGO=randomx

./tools/home_workers/setup.sh --check
./tools/home_workers/setup.sh --xmrig --run
# --cpuminer | --lolminer
```

## 3. Multi-miner on one PC

```bash
./tools/home_workers/run_home.sh --xmrig --worker desk-cpu --algo randomx
./tools/home_workers/run_home.sh --lolminer --worker desk-gpu --algo kawpow --host 192.168.1.50
./tools/home_workers/run_home.sh --stop
```

## 4. systemd

```bash
sudo cp tools/home_workers/yarnrake-worker@.service /etc/systemd/system/
sudo mkdir -p /etc/yarnrake
sudo cp tools/home_workers/env.example /etc/yarnrake/worker.env
# edit YARNRAKE_HOST, WORKER, ALGO, YARNRAKE_ROOT
sudo systemctl enable --now yarnrake-worker@xmrig
```

## Algo → launcher

| Hardware | Algo examples | Script |
|----------|---------------|--------|
| CPU | randomx, ghostrider | run_xmrig.sh |
| CPU | skein, yescrypt_r16 | run_cpuminer.sh |
| GPU | kawpow, etchash | run_lolminer.sh |
| ASIC | sha256d, scrypt | firmware / cgminer |

Control assignments: [CONTROL.md](./CONTROL.md). Launch UI: [LAUNCH.md](./LAUNCH.md).
