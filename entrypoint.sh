#!/bin/sh

function log() {
    printf -v MSG "$(date '+%Y-%m-%d %H:%M:%S') ** %s **\n" "$*"
    WIDTH=${#MSG}
    printf "\n"
    printf "%${WIDTH}s\n" | tr " " "*"
    printf "$MSG"
    printf "%${WIDTH}s\n" | tr " " "*"
}

GST_GIT_REPO=https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git
GST_GIT_BRANCH=main
GST_SRC_DIR=gst-plugins-rs/$2

case $1 in
armhf)
    export TARGET=arm-unknown-linux-gnueabihf
    export LINKER=arm-linux-gnueabihf
    export LINKER_PATH=$RPI_BIN/
    export EXTRA_RUSTFLAGS="-L$RPI_SYSROOT/lib -L$RPI_SYSROOT/usr/lib"
    ## Required for rustls
    export EXTRA_CARGO_PKG="bindgen-cli"
    ;;
arm64)
    export TARGET=aarch64-unknown-linux-gnu
    export LINKER=aarch64-linux-gnu
    ;;
x86_64)
    export TARGET=x86_64-unknown-linux-gnu
    export LINKER=x86_64-linux-gnu
    ;;
*)
    echo "Error: Unknown architecture $1"
    exit 1
    ;;
esac

log "Checkout gst-plugins-rs source if required"
[ ! -d "gst-plugins-rs" ] && git clone --depth 1 -b $GST_GIT_BRANCH $GST_GIT_REPO
[ ! -d "${GST_SRC_DIR}" ] && echo "Error: Can't find plugin source files at ${GST_SRC_DIR}" && exit 1

log "Install Rust stuff"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --target $TARGET
source "$HOME/.cargo/env"
cargo install cargo-deb $EXTRA_CARGO_PKG

log "Configure environment"
[ $(gcc -dumpmachine) != "${LINKER}" ] && export PKG_CONFIG_ALLOW_CROSS=1
export PKG_CONFIG_PATH=/usr/lib/${LINKER}/pkgconfig
export LINKER_TOOLS=${LINKER_PATH}${LINKER}
export RUSTFLAGS="-C linker=${LINKER_TOOLS}-gcc $EXTRA_RUSTFLAGS"
env | sort

log "Backup original ${GST_SRC_DIR}/Cargo.toml"
[ ! -f "Cargo.toml.orig" ] && cp ${GST_SRC_DIR}/Cargo.toml Cargo.toml.orig

log "Build GStreamer plugin $GST_SRC_DIR for $TARGET"
## We need to do the build ourselves as cargo-deb doesn't understand the asset target
## is from our package (because the asset name had "lib" and ".so" added) and
## so will build the whole workspace (all packages) which is slow and requires more deps.
pushd ${GST_SRC_DIR}
git status && git log -n 3
cargo build --target=$TARGET --release -v
popd

SO_FILE=$(find gst-plugins-rs/target/$TARGET/release/*.so)

log "Strip the binary at $SO_FILE"
ls -l $SO_FILE
${LINKER_TOOLS}-strip $SO_FILE
ls -l $SO_FILE

log "Prepare Debian package"
cat Cargo.toml.orig Cargo.toml.deb > ${GST_SRC_DIR}/Cargo.toml
TARGET_PLUGINS_DIR=$(pkg-config --variable=pluginsdir gstreamer-1.0)
sed -i "s@%GST_PLUGINS_DIR%@$TARGET_PLUGINS_DIR@" ${GST_SRC_DIR}/Cargo.toml

log "Build Debian package"
# Must specify target despite no-build else cargo-deb looks in the workspace for the asset, see comment at top.
#WITH_DEBUG=" --separate-debug-symbols"
pushd ${GST_SRC_DIR}
cargo deb --target=$TARGET --no-build $WITH_DEBUG -v
popd

DEB_FILE=$(find gst-plugins-rs/target/$TARGET/debian/*.deb)

log "Sanity check package $DEB_FILE"
dpkg-deb --field $DEB_FILE Package Architecture Version Installed-Size
