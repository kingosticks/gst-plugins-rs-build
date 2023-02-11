#!/bin/sh

arch="${1}"
shift

case $arch in
    armhf)
        export BUILD_TARGET=arm-unknown-linux-gnueabihf
        export LINKER_TARGET=arm-linux-gnueabihf

        export PKG_CONFIG_ALLOW_CROSS=1
        export PKG_CONFIG_PATH=/usr/lib/$LINKER_TARGET/pkgconfig
        TARGET_TOOLS="$RPI_TOOLS_DIR/arm-bcm2708/$LINKER_TARGET/bin"
        TARGET_SYSROOT="$RPI_TOOLS_DIR/arm-bcm2708/$LINKER_TARGET/$LINKER_TARGET/sysroot"
        export RUSTFLAGS="-C linker=$TARGET_TOOLS/$LINKER_TARGET-gcc -L$TARGET_SYSROOT/lib -L$TARGET_SYSROOT/usr/lib"
        ;;
    x86_64)
        export BUILD_TARGET=x86_64-unknown-linux-gnu
        export LINKER_TARGET=x86_64-linux-gnu
        TARGET_TOOLS=/usr/bin
        ;;
    *)
        echo "Unkown architecture"
        exit 1
        ;;
esac

export GST_GIT_REPO=https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git
export GST_GIT_BRANCH=main
export GST_PLUGIN=gst-plugin-spotify

## We need to do the build ourselves as cargo-deb doesn't understand the asset target
## is from our package (because the name was mangled by adding "lib" and ".so") and
## so will build the whole workspace (all packages) which is slow and requires
## more deps.

# 1. Install Rust stuff
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup target add $BUILD_TARGET
cargo install cargo-deb

mkdir -p .cargo
cat >"${HOME}"/.cargo/config <<EOF
[target.$BUILD_TARGET]
#linker = '$TARGET_TOOLS/$LINKER_TARGET-gcc'
strip = { path = '$TARGET_TOOLS/$LINKER_TARGET-strip' }
objcopy = { path = '$TARGET_TOOLS/$LINKER_TARGET-objcopy' }
EOF

# 2. Checkout source if required
[ ! -d "/gst-plugins-rs" ] && git clone --depth 1 -b $GST_GIT_BRANCH $GST_GIT_REPO
cd gst-plugins-rs

# 3. Backup the original .toml file
[ ! -f "audio/spotify/Cargo.toml.orig" ] && cp audio/spotify/Cargo.toml audio/spotify/Cargo.toml.orig

# 4. Build GStreamer plugin
cargo build --target=$BUILD_TARGET --package $GST_PLUGIN --release --config 'profile.release.strip = true'

# 5. Create Debian package
LIB_FILE=/target/$BUILD_TARGET/release/libgstspotify.so

cat audio/spotify/Cargo.toml.orig /gst-plugins-rs-build/Cargo-deb.toml > audio/spotify/Cargo.toml
#from gettext-base package ?
#envsubst <audio/spotify/Cargo.toml >audio/spotify/Cargo.toml

sed -i "s@%GST_PLUGINS_DIR%@$(pkg-config --variable=pluginsdir gstreamer-1.0)@" audio/spotify/Cargo.toml

# Got to specify target despite no-build else cargo-deb looks in the workspace for the asset, see comment at top.

#WITH_DEBUG=" --separate-debug-symbols"
cargo deb --target=$BUILD_TARGET -p $GST_PLUGIN --no-build $WITH_DEBUG -v

# Sanity check
DEB_FILE=$(find /target/$BUILD_TARGET/debian/gst-plugin-spotify_*.deb)
dpkg-deb --field $DEB_FILE Package Architecture Version Installed-Size
#echo "DEB_FILE=$DEB_FILE" >> $GITHUB_OUTPUT
