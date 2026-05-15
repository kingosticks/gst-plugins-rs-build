# gst-plugins-rs-build

This repository is primarily for compiling (and currently, also hosting) Debian packages
for [gst-plugins-rs](https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs) plugins.
Right now this is geared around the `spotify` plugin but could be extended to
other plugins, either packaged individually or bundled together. At some point,
packages will hopefully be provided by distros but this is useful in the meantime.

## Install releases from this repo

You can find the latest builds at https://github.com/mopidy/gst-plugins-rs-build/releases/latest.
These are triggered manually, as required.

### Install Debian package

To install the Debian package, download the appropriate `.deb` file for your
platform. Then run the following command to place the plugin in the correct
location for GStreamer to find it:

```sh
sudo dpkg -i path/to/downloaded-package.deb
```

### Install raw library

Alternatively, to install the raw library, download the appropriate `.so` file
for your platform. Then run the following command to place the plugin in correct
location for GStreamer to find it:

```sh
sudo install -m 644 ... $(pkg-config --variable=pluginsdir gstreamer-1.0)/
```

### Verify the installation

To verify that the plugin is available, run the following command:

```sh
gst-inspect-1.0 spotify
```

## Compile from source

To compile the latest development version of 
[gst-plugins-rs](https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs) on
Debian, you can follow the instructions below.

### On Debian

On a low-power device (e.g. Raspberry Pi), the compile will be slow and `cargo`
may require
an additional `--jobs 1` argument to prevent memory exhaustion.

Example build instructions for `gst-plugins-spotify`:

1. [Install Rust](https://www.rust-lang.org/tools/install):

    ```sh
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    ```

2. Install the dependencies of the
   [GStreamer Rust bindings](https://gitlab.freedesktop.org/gstreamer/gstreamer-rs#installation):

    ```sh
    sudo apt install clang libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
        gcc pkg-config git gstreamer1.0-tools
    ```

    Note that other plugins may require additional dependencies.

3. Download, build and install `gst-plugins-spotify` from source:

     ```sh
     git clone --depth 1 https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs
     cd gst-plugins-rs
     cargo build --package gst-plugin-spotify --release
     sudo install -m 644 target/release/libgstspotify.so $(pkg-config --variable=pluginsdir gstreamer-1.0)/
     ```

4. Verify that the `spotify` plugin is available:

    ```sh
    gst-inspect-1.0 spotify
    ```

### On macOS

1. Install Rust using Homebrew:

    ```sh
    brew install rust
    ```

2. Install GStreamer using Homebrew:

    ```sh
    brew install gstreamer
    ```

3. Download, build and install `gst-plugins-spotify` from source:

    ```sh
    git clone --depth 1 https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs
    cd gst-plugins-rs
    cargo cbuild -p gst-plugin-spotify --prefix=$(pkg-config --variable=pluginsdir gstreamer-1.0)/
    cargo cinstall -p gst-plugin-spotify --prefix=$(pkg-config --variable=pluginsdir gstreamer-1.0)/
    ```

4. Verify that the `spotify` plugin is available:

    ```sh
    gst-inspect-1.0 spotify
    ```

## Cross-compile and build Debian packages

To cross-compile for other CPU architectures, e.g. building for an ARM device on
your beefier AMD64 desktop, and build Debian packages using the Docker images
and supporting files in this repository, run the following commands on your host
machine:

```
git clone --depth 1 https://github.com/kingosticks/gst-plugins-rs-build.git
cd gst-plugins-rs-build
make build-amd64  # or build-arm64 or build-armhf
```

Cross-compiling for the following platforms are supported:

* amd64 - Run `make build-amd64`
* arm64 - Run `make build-arm64`
* armhf - Run `make build-armhf` (compatible with all Raspberry Pi boards)

To build for all platforms, run `make` without any arguments.

Once the build is complete, you'll find the results in the `dist/` directory:

- `dist/*.deb` — the Debian package, which can be installed with `sudo dpkg -i ...`
- `dist/<plugin>_<version>_<arch>/libgstspotify.so` — the raw stripped
  library, which can be installed with `sudo install -m 644 libgstspotify.so
  $(pkg-config --variable=pluginsdir gstreamer-1.0)/`.

To clean up the build artifacts, run `make clean`.

## Building other plugins or branches

The defaults compile the `audio/spotify` plugin from the latest `main` of the
upstream
[gst-plugins-rs](https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git)
repo. To build something else, like a fork, a different branch or tag, a
different plugin, or a local working copy, pass any of these on the `make`
command line:

| Variable | Default | Effect |
|----------|---------|--------|
| `GST_GIT_REPO` | `https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git` | Clone from a different upstream (e.g. a fork). |
| `GST_GIT_BRANCH` | `main` | Check out a different branch or tag. |
| `GST_PLUGINS_RS_SRC` | *(unset)* | Bind-mount a local working copy of `gst-plugins-rs` into the container instead of cloning fresh. Handy when iterating on local edits. Your changes are picked up immediately, no commit/push needed. |
| `PLUGIN` | `audio/spotify` | Path of the plugin to build, relative to the `gst-plugins-rs` root. |

Examples:

```sh
# Build the spotify plugin from a fork's feature branch
GST_GIT_REPO=https://github.com/kingosticks/gst-plugins-rs.git \
GST_GIT_BRANCH=spotify-logging \
    make build-amd64

# Build the aws plugin against a local working copy
GST_PLUGINS_RS_SRC=$HOME/src/gst-plugins-rs \
PLUGIN=net/aws \
    make build-amd64
```

The sanitized branch name and short git hash are baked into the resulting `.deb`
version, so fork/branch builds are distinguishable from upstream at a glance
without having to inspect the binary.
