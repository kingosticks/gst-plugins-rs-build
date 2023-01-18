#!/bin/sh

export GIT_REPO=https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git
export GIT_BRANCH=main
git clone --depth 1 -b $GIT_BRANCH $GIT_REPO
cd gst-plugins-rs

export GST_PLUGINS_DIR=$(pkg-config --variable=pluginsdir gstreamer-1.0)
echo "
[package.metadata.deb]
maintainer = 'Nick Steel <nick@nsteel.co.uk>'
assets = [
    ['target/release/libgstspotify.so', '$GST_PLUGINS_DIR/', '755'],
]" >> audio/spotify/Cargo.toml

# Must do the build ourselves as cargo-deb doesn't understand the asset target
# is from our package (because the name was mangled with "lib" and ".so") and
# so will build the whole workspace (all packages) which is slow and requires
# more deps.
cargo build -p gst-plugin-spotify --release --no-default-features
cargo deb --no-build -p gst-plugin-spotify --separate-debug-symbols -v

dpkg-deb -c target/debian/gst-plugin-spotify_*.deb
