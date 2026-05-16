#!/bin/sh
# Print KEY=VALUE env vars for cross-compiling the given target arch.
#
# Output is plain `KEY=VALUE` lines (no quotes, no escaping) suitable for
# either:
#   - sourcing into bash with a read loop, e.g.
#       while IFS='=' read -r k v; do export "$k=$v"; done < <(package/cross-env.sh armhf)
#   - appending to GitHub Actions' $GITHUB_ENV.
#
# The linker and per-target RUSTFLAGS are emitted as target-scoped vars
# (CARGO_TARGET_<TRIPLE>_LINKER / _RUSTFLAGS), not as a global RUSTFLAGS.
# Cargo only honours those when building for $TARGET, so they're harmless
# during host builds (e.g. `cargo install cargo-deb`).
#
# armhf relies on $RPI_BIN and $RPI_SYSROOT being set by Dockerfile.armhf
# (the rpi-tools sysroot keeps binaries armv6-compatible).
set -eu

case "$1" in
amd64)
    TARGET=x86_64-unknown-linux-gnu
    LINKER=x86_64-linux-gnu
    LINKER_PATH=
    EXTRA_RUSTFLAGS=
    ;;
arm64)
    TARGET=aarch64-unknown-linux-gnu
    LINKER=aarch64-linux-gnu
    LINKER_PATH=
    EXTRA_RUSTFLAGS=
    ;;
armhf)
    TARGET=arm-unknown-linux-gnueabihf
    LINKER=arm-linux-gnueabihf
    LINKER_PATH=$RPI_BIN/
    EXTRA_RUSTFLAGS="-L$RPI_SYSROOT/lib -L$RPI_SYSROOT/usr/lib"
    ;;
riscv64)
    TARGET=riscv64gc-unknown-linux-gnu
    LINKER=riscv64-linux-gnu
    LINKER_PATH=
    EXTRA_RUSTFLAGS=
    ;;
*)
    echo "cross-env.sh: unknown arch '$1'" >&2
    exit 1
    ;;
esac

LINKER_TOOLS="${LINKER_PATH}${LINKER}"
PKG_CONFIG_PATH="/usr/lib/${LINKER}/pkgconfig"

# CARGO_TARGET_<TRIPLE>_* var name: uppercase + dashes to underscores.
TARGET_VAR=$(printf '%s' "$TARGET" | tr '[:lower:]' '[:upper:]' | tr '-' '_')

cat <<EOF
TARGET=$TARGET
LINKER=$LINKER
LINKER_PATH=$LINKER_PATH
LINKER_TOOLS=$LINKER_TOOLS
PKG_CONFIG_PATH=$PKG_CONFIG_PATH
CARGO_TARGET_${TARGET_VAR}_LINKER=${LINKER_TOOLS}-gcc
EOF

if [ -n "$EXTRA_RUSTFLAGS" ]; then
    echo "CARGO_TARGET_${TARGET_VAR}_RUSTFLAGS=$EXTRA_RUSTFLAGS"
fi

if [ "$(gcc -dumpmachine 2>/dev/null)" != "$LINKER" ]; then
    echo "PKG_CONFIG_ALLOW_CROSS=1"
fi
