# YarnRake control plane (HTTP + Stratum)
# Build: docker build -t yarnrake .
# Run:   docker run --rm -p 8787:8787 -p 3333:3333 -v yr-data:/data yarnrake
FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl xz-utils \
    && rm -rf /var/lib/apt/lists/*
ARG ZIG_VER=0.14.0
RUN curl -fsSL "https://ziglang.org/download/${ZIG_VER}/zig-linux-x86_64-${ZIG_VER}.tar.xz" \
    | tar -xJ -C /opt \
    && ln -s /opt/zig-linux-x86_64-${ZIG_VER}/zig /usr/local/bin/zig
WORKDIR /src
COPY . .
RUN zig build -Doptimize=ReleaseSafe

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -r -u 1000 -m yarnrake
COPY --from=build /src/zig-out/bin/yarnrake /usr/local/bin/yarnrake
WORKDIR /data
ENV YARNRAKE_PORT=8787 \
    YARNRAKE_STRATUM_PORT=3333 \
    YARNRAKE_ALGO=skein \
    YARNRAKE_SHARES=/data/shares.jsonl \
    YARNRAKE_DEVICES=/data/devices.jsonl \
    PORT=8787
EXPOSE 8787 3333
USER yarnrake
VOLUME ["/data"]
ENTRYPOINT ["yarnrake"]
