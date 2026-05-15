#!/bin/sh
# Append [package.metadata.deb] to the plugin's Cargo.toml so cargo-deb has
# the maintainer/asset info it needs. Idempotent: strips any pre-existing
# block first, so re-runs against the same checkout don't duplicate.
#
# Args: <gst-src-dir> (path to the plugin source, e.g. gst-plugins-rs/audio/spotify)
set -eu

GST_SRC_DIR="$1"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEB_METADATA="${SCRIPT_DIR}/Cargo.toml.deb"

sed -i '/^\[package\.metadata\.deb\]$/,$d' "${GST_SRC_DIR}/Cargo.toml"
cat "$DEB_METADATA" >> "${GST_SRC_DIR}/Cargo.toml"

# Substitute the target-specific gstreamer plugins dir.
TARGET_PLUGINS_DIR=$(pkg-config --variable=pluginsdir gstreamer-1.0)
sed -i "s@%GST_PLUGINS_DIR%@$TARGET_PLUGINS_DIR@" "${GST_SRC_DIR}/Cargo.toml"
