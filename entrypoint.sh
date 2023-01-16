#!/bin/sh

# `$#` expands to the number of arguments and `$@` expands to the supplied `args`
printf '%d args:' "$#"
printf " '%s'" "$@"
printf '\n'


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
]
#default-features = false" >> audio/spotify/Cargo.toml

cat audio/spotify/Cargo.toml
bash

# Must do the build ourselves as cargo-deb doesn't understand the target file comes from our package (because the "lib" and "so") and will build the whole workspace (all packages)
#cargo build -p gst-plugin-spotify --release --no-default-features
#cargo deb --no-build -p gst-plugin-spotify --separate-debug-symbols -v

#cargo deb --manifest-path=audio/spotify/Cargo.toml --separate-debug-symbols -v
#cargo deb -p gst-plugin-spotify --separate-debug-symbols -v
