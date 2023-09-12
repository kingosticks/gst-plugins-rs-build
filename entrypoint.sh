#!/bin/sh

BUILD_SRC=/gst-plugin-spotify-build
GST_PLUGIN=gst-plugin-spotify

arch="${1}"

# 1. Install Rust stuff
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
cargo install cargo-deb

## We need to do the build ourselves as cargo-deb doesn't understand the asset target
## is from our package (because the name was mangled by adding "lib" and ".so") and
## so will build the whole workspace (all packages) which is slow and requires
## more deps.

case $arch in
    armhf)
        export RUST_TARGET=arm-unknown-linux-gnueabihf
        export LINKER_TARGET=arm-linux-gnueabihf

        export PKG_CONFIG_ALLOW_CROSS=1
        export PKG_CONFIG_PATH=/usr/lib/$LINKER_TARGET/pkgconfig
        RPI_SYSROOT="$RPI_TOOLS_DIR/arm-bcm2708/$LINKER_TARGET/$LINKER_TARGET/sysroot"
        TARGET_TOOLS="$RPI_TOOLS_DIR/arm-bcm2708/$LINKER_TARGET/bin"
        export RUSTFLAGS="-C linker=$TARGET_TOOLS/$LINKER_TARGET-gcc -L$RPI_SYSROOT/lib -L$RPI_SYSROOT/usr/lib"
        ;;
    x86_64)
        export RUST_TARGET=x86_64-unknown-linux-gnu
        export LINKER_TARGET=x86_64-linux-gnu
        TARGET_TOOLS=/usr/bin
        ;;
    *)
        echo "Unkown architecture"
        exit 1
        ;;
esac
rustup target add $RUST_TARGET

# 2. Checkout source if required
GST_GIT_REPO=https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git
GST_GIT_BRANCH=main
GST_SRC=$(basename $GST_GIT_REPO .git)
[ ! -d "/$GST_SRC" ] && git clone --depth 1 -b $GST_GIT_BRANCH $GST_GIT_REPO

# 3. Backup the original .toml file
[ ! -f "Cargo.toml.orig" ] && cp $GST_SRC/audio/spotify/Cargo.toml Cargo.toml.orig

# 4. Build GStreamer plugin
cd $GST_SRC
cargo build --target=$RUST_TARGET --package $GST_PLUGIN --release --config 'profile.release.strip = true'

# 5. Create Debian package
cd $BUILD_SRC
export GST_PLUGINS_DIR=$(pkg-config --variable=pluginsdir gstreamer-1.0)
cat Cargo.toml.orig Cargo-deb.toml | \
    sed "s@%GST_PLUGINS_DIR%@$GST_PLUGINS_DIR@" > $GST_SRC/audio/spotify/Cargo.toml

# Got to specify target despite no-build else cargo-deb looks in the workspace for the asset, see comment at top.

#WITH_DEBUG=" --separate-debug-symbols"
cd $GST_SRC
cargo deb --target=$RUST_TARGET -p $GST_PLUGIN --no-build  $WITH_DEBUG -v

# Sanity check
DEB_FILE=$(find target/$RUST_TARGET/debian/gst-plugin-spotify_*.deb)
dpkg-deb --field $DEB_FILE Package Architecture Version Installed-Size
