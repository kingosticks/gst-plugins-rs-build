# About

This repository is primarily for compiling (and currently, also hosting) Debian packages
for [gst-plugins-rs](https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs) plugins.
Right now this is geared around the spotify plugin but could be extended to other
plugins, either packaged individually or bundled together. At some point, upstream
packages will hopefully be provided but this is useful in the meantime.

Find the latest builds at https://github.com/kingosticks/gst-plugins-rs-build/releases/latest.
These are triggered manually, as required. We are currently focused on the 0.12 branch which
is compatible with GStreamer versions available in Ubuntu LTS, Debian stable, and latest
Raspberry Pi OS.

Alternatively, compile your own native library for your host machine, or build your own Debian
package with the provided cross-compiling Docker container and supporting files.

# Compiling

The following two methods compile the latest development version of
[gst-plugins-rs](https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs).

## Native compile

On a low-power device (e.g. Raspberry Pi), the compile will be slow and `cargo` may require
an additional `--jobs 1` argument to prevent memory exhaustion.

Example build instructions for `gst-plugins-spotify`:

1. [Install Rust](https://www.rust-lang.org/tools/install):

   ```
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. Install the
   [GStreamer Rust bindings](https://gitlab.freedesktop.org/gstreamer/gstreamer-rs#installation)
   dependencies:

   ```
   sudo apt install libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev clang gcc pkg-config git gstreamer1.0-tools
   ```

   Note that other plugins may require additional dependencies.

3. Download, build and install `gst-plugins-spotify` from source:

    ```
    git clone --depth 1 https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs
    cd gst-plugins-rs
    cargo build --package gst-plugin-spotify --release
    sudo install -m 644 target/release/libgstspotify.so $(pkg-config --variable=pluginsdir gstreamer-1.0)/
    ```

4. Verify the spotify plugin is available:

   ```
   gst-inspect-1.0 spotify
   ```


## Cross-compile (including Debian package)

Supported platforms:

* armhf (compatible with all Raspberry Pi boards)
* arm64
* x86_64

Example for armhf (target: arm-unknown-linux-gnueabihf):
```
git clone --depth 1 https://github.com/kingosticks/gst-plugins-rs-build.git
cd gst-plugins-rs-build
docker run  -v .:/src:z --workdir /src ghcr.io/mopidy/gst-plugins-rs-build:latest /bin/bash entrypoint.sh armhf audio/spotify
# or make build-armhf
```
The resulting Debian package will be in `gst-plugins-rs/target/arm-unknown-linux-gnueabihf/debian/`
(and the binary will be at `gst-plugins-rs/target/arm-unknown-linux-gnueabihf/release/libgstspotify.so`).
