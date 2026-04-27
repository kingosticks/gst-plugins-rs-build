#!/bin/bash
# Cross-compile a gst-plugins-rs plugin for the given arch and produce a .deb.
# Runs inside one of the per-arch images from images/. Three bind mounts:
#   /package (ro) — this script + Cargo.toml.deb + the helper scripts.
#   /build         — working tree (cloned source + cargo target/).
#   /dist          — final outputs.
#
# Args: <arch> <plugin-path>     e.g. build.sh armhf audio/spotify

set -eu

function log() {
    printf -v MSG "$(date '+%Y-%m-%d %H:%M:%S') ** %s **\n" "$*"
    WIDTH=${#MSG}
    printf "\n"
    printf "%${WIDTH}s\n" | tr " " "*"
    printf "$MSG"
    printf "%${WIDTH}s\n" | tr " " "*"
}

export GST_GIT_REPO="${GST_GIT_REPO:-https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git}"
export GST_GIT_BRANCH="${GST_GIT_BRANCH:-main}"
ARCH=$1
PLUGIN=$2
GST_SRC_DIR=gst-plugins-rs/$PLUGIN

cd /build

log "Checkout gst-plugins-rs source if required"
[ ! -d "gst-plugins-rs" ] && git clone --depth 1 -b "$GST_GIT_BRANCH" "$GST_GIT_REPO"
[ ! -d "${GST_SRC_DIR}" ] && echo "Error: Can't find plugin source files at ${GST_SRC_DIR}" && exit 1
git -C "${GST_SRC_DIR}" status && git -C "${GST_SRC_DIR}" remote -v

log "Install Rust toolchain"
# Pull TARGET out early so rustup knows which target stdlib to add. The full
# cross-compile env is deferred until after `cargo install cargo-deb` — that
# step is a host build and would trip over cross-target PKG_CONFIG_PATH /
# linker settings if they were in the env.
export TARGET=$(/package/cross-env.sh "$ARCH" | sed -n 's/^TARGET=//p')
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --target "$TARGET"
source "$HOME/.cargo/env"

log "Install cargo-deb"
# Pinned; keep in sync with .github/workflows/base.yml.
cargo install cargo-deb@3.4.1 --locked

log "Configure cross-compile environment"
# Now source the full per-arch env (LINKER, LINKER_TOOLS, PKG_CONFIG_PATH,
# CARGO_TARGET_<TRIPLE>_LINKER, ...).
while IFS='=' read -r k v; do
    export "$k=$v"
done < <(/package/cross-env.sh "$ARCH")
env | sort

log "Compile $GST_SRC_DIR for $TARGET"
SO_FILE=$(/package/compile-plugin.sh "$PLUGIN")

log "Build Debian package"
DEB_FILE=$(/package/make-deb.sh "$PLUGIN")

log "Copy outputs to /dist"
mkdir -p /dist
cp -v "$DEB_FILE" /dist/
PKG_NAME=$(dpkg-deb --field "$DEB_FILE" Package)
SO_VERSION=$(/package/compose-version.sh "$GST_SRC_DIR")
SO_DIR="/dist/${PKG_NAME}_${SO_VERSION}_${ARCH}"
mkdir -p "$SO_DIR"
cp -v "$SO_FILE" "$SO_DIR/"
ls -lR /dist
