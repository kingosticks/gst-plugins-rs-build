#!/bin/sh
# Cross-compile the plugin for $TARGET and strip the resulting .so.
# Emits the path to the stripped .so on stdout; everything else
# (cargo output, ls, etc.) goes to stderr.
#
# We do the build ourselves rather than letting cargo-deb do it: cargo-deb
# doesn't recognise that the lib<plugin>.so asset comes from the plugin
# package (because the asset name has lib/.so mangled in), so without
# --no-build it would build the entire workspace, which is slow and pulls
# extra deps. Don't try to "simplify" this back into one cargo deb call.
#
# Args: <plugin-path>     e.g. audio/spotify
# Env:  TARGET, LINKER_TOOLS  (from cross-env.sh)
# Cwd:  the working tree containing gst-plugins-rs/<plugin>/
set -eu

PLUGIN="$1"
GST_SRC_DIR=gst-plugins-rs/$PLUGIN

(cd "$GST_SRC_DIR" && cargo build --target="$TARGET" --release -v) >&2

SO_FILE=$(find "gst-plugins-rs/target/$TARGET/release"/*.so)
ls -l "$SO_FILE" >&2
"${LINKER_TOOLS}"-strip "$SO_FILE"
ls -l "$SO_FILE" >&2

printf '%s\n' "$SO_FILE"
