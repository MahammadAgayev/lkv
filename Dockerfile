# Build stage
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl xz-utils ca-certificates jq \
    && rm -rf /var/lib/apt/lists/*

# Detect arch (aarch64 on Apple Silicon, x86_64 elsewhere) and install Zig
RUN ARCH=$(uname -m) \
    && ZIG_ARCH=$([ "$ARCH" = "aarch64" ] && echo "aarch64-linux" || echo "x86_64-linux") \
    && URL=$(curl -fsSL https://ziglang.org/download/index.json \
        | jq -r --arg arch "$ZIG_ARCH" '."0.15.2" | .[$arch].tarball') \
    && mkdir -p /usr/local/zig \
    && curl -fsSL "$URL" | tar -xJ -C /usr/local/zig --strip-components=1

ENV PATH="/usr/local/zig:$PATH"

WORKDIR /app
COPY build.zig build.zig.zon ./
COPY src/ ./src/

RUN zig build -Doptimize=ReleaseSafe

# Runtime stage — io_uring requires Linux kernel 5.1+
FROM debian:bookworm-slim
COPY --from=builder /app/zig-out/bin/lkv /usr/local/bin/lkv
CMD ["/usr/local/bin/lkv"]
