#!/bin/sh

GST_GIT_REPO=https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git
GST_GIT_BRANCH=main
GST_PLUGIN=gst-plugin-spotify

cd gst-plugins-rs-build

# 1. Install Rust stuff
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
source "$HOME/.cargo/env"
cargo install cargo-deb

## We need to do the build ourselves as cargo-deb doesn't understand the asset target
## is from our package (because the name was mangled by adding "lib" and ".so") and
## so will build the whole workspace (all packages) which is slow and requires
## more deps.

case $1 in
armhf)
    export TARGET=arm-unknown-linux-gnueabihf
    export LINKER=arm-linux-gnueabihf
    export LINKER_PATH=$RPI_BIN
    export PKG_CONFIG_ALLOW_CROSS=1
    export EXTRA_RUSTFLAGS="-L$RPI_SYSROOT/lib -L$RPI_SYSROOT/usr/lib"
    ;;
arm64)
    export TARGET=aarch64-unknown-linux-gnu
    export LINKER=aarch64-linux-gnu
    export PKG_CONFIG_ALLOW_CROSS=1
    ;;
x86_64)
    export TARGET=x86_64-unknown-linux-gnu
    export LINKER=x86_64-linux-gnu
    ;;
*)
    echo "Unkown architecture"
    exit 1
    ;;
esac

export PATH="${LINKER_PATH}:$PATH"
export RUSTFLAGS="-C linker=${LINKER}-gcc $EXTRA_RUSTFLAGS"
export PKG_CONFIG_PATH=/usr/lib/${LINKER}/pkgconfig
export GST_PLUGINS_DIR=$(pkg-config --variable=pluginsdir gstreamer-1.0)

env | sort

rustup target add $TARGET

# 2. Checkout source if required
[ ! -d "gst-plugins-rs" ] && git clone --depth 1 -b $GST_GIT_BRANCH $GST_GIT_REPO

# 3. Backup the original .toml file
[ ! -f "Cargo.toml.orig" ] && cp gst-plugins-rs/audio/spotify/Cargo.toml Cargo.toml.orig

# 4. Build GStreamer plugin
pushd gst-plugins-rs
cargo build --target=$TARGET --package $GST_PLUGIN --release -v
popd

# 5. Strip the binary
SO_FILE=$(find gst-plugins-rs/target/$TARGET/release/*.so)
ls -l $SO_FILE
${LINKER}-strip $SO_FILE
ls -l $SO_FILE

# 6. Repare Debian package
cat Cargo.toml.orig Cargo.toml.deb > gst-plugins-rs/audio/spotify/Cargo.toml
sed -i "s@%GST_PLUGINS_DIR%@$GST_PLUGINS_DIR@" gst-plugins-rs/audio/spotify/Cargo.toml

# 7. Build Debian package
# Got to specify target despite no-build else cargo-deb looks in the workspace for the asset, see comment at top.
#WITH_DEBUG=" --separate-debug-symbols"
pushd gst-plugins-rs
cargo deb --target=$TARGET --package $GST_PLUGIN --no-build  $WITH_DEBUG -v
popd

# Sanity check
DEB_FILE=$(find gst-plugins-rs/target/$TARGET/debian/gst-plugin-spotify_*.deb)
dpkg-deb --field $DEB_FILE Package Architecture Version Installed-Size
