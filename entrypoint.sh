#!/bin/sh

mkdir -p /release

export GIT_REPO=https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git
export GIT_BRANCH=main
git clone --depth 1 -b $GIT_BRANCH $GIT_REPO
cd gst-plugins-rs

export GST_PLUGINS_DIR=$(pkg-config --variable=pluginsdir gstreamer-1.0)
sed "s@%GST_PLUGINS_DIR%@$GST_PLUGINS_DIR@" ../Cargo-deb.toml >> audio/spotify/Cargo.toml

# Must do the build ourselves as cargo-deb doesn't understand the asset target
# is from our package (because the name was mangled by adding "lib" and ".so") and
# so will build the whole workspace (all packages) which is slow and requires
# more deps.
cargo build -p gst-plugin-spotify --release --no-default-features
cargo deb --no-build -p gst-plugin-spotify --separate-debug-symbols -o /release -v

export DEB_FILE=$(find /release/gst-plugin-spotify_*.deb)

dpkg-deb -c $DEB_FILE
echo "DEB_FILE=$DEB_FILE" >> $GITHUB_OUTPUT
