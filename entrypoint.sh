#!/bin/sh

GST_GIT_REPO=https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git
GST_GIT_BRANCH=main
GST_PLUGIN=gst-plugin-spotify

cd gst-plugin-spotify-build

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
    export TOOLCHAIN=arm-linux-gnueabihf
    export TOOLCHAIN_BIN=$RPI_BIN
    export PKG_CONFIG_ALLOW_CROSS=1
    export RUSTFLAGS="-C linker=${TOOLCHAIN_BIN}/${TOOLCHAIN}-gcc -L$RPI_SYSROOT/lib -L$RPI_SYSROOT/usr/lib"
    ;;
arm64)
    export TARGET=aarch64-unknown-linux-gnu
    export PKG_CONFIG_ALLOW_CROSS=1
    export PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig
    ;;
x86_64)
    export TARGET=x86_64-unknown-linux-gnu
    export TOOLCHAIN=x86_64-linux-gnu
    export TOOLCHAIN_BIN=/usr/bin
    ;;
*)
    echo "Unkown architecture"
    exit 1
    ;;
esac
TODO add ${TOOLCHAIN_BIN} to PATH
export STRIP=${TOOLCHAIN_BIN}/${TOOLCHAIN}-strip
export PKG_CONFIG_PATH=/usr/lib/$TOOLCHAIN/pkgconfig
export GST_PLUGINS_DIR=$(pkg-config --variable=pluginsdir gstreamer-1.0)

env | sort

rustup target add $TARGET

# 2. Checkout source if required
[ ! -d "/gst-plugins-rs" ] && git clone --depth 1 -b $GST_GIT_BRANCH $GST_GIT_REPO

# 3. Backup the original .toml file
[ ! -f "Cargo.toml.orig" ] && cp gst-plugins-rs/audio/spotify/Cargo.toml Cargo.toml.orig

# 4. Build GStreamer plugin
cd gst-plugins-rs
cargo build --target=$TARGET --package $GST_PLUGIN --release

# 5. Strip the binary
SO_FILE=$(find target/$TARGET/release/*.so)
ls -l $SO_FILE
$STRIP $SO_FILE
ls -l $SO_FILE

# 6. Repare Debian package
cat Cargo.toml.orig Cargo.toml.deb > gst-plugins-rs/audio/spotify/Cargo.toml
sed -i "s@%GST_PLUGINS_DIR%@$GST_PLUGINS_DIR@" gst-plugins-rs/audio/spotify/Cargo.toml

# 7. Build Debian package
# Got to specify target despite no-build else cargo-deb looks in the workspace for the asset, see comment at top.
#WITH_DEBUG=" --separate-debug-symbols"
cd gst-plugins-rs
cargo deb --target=$TARGET --package $GST_PLUGIN --no-build  $WITH_DEBUG -v

# Sanity check
DEB_FILE=$(find target/$TARGET/debian/gst-plugin-spotify_*.deb)
dpkg-deb --field $DEB_FILE Package Architecture Version Installed-Size
