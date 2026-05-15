#!/bin/sh
# Package the plugin as a .deb. Assumes the .so is already built (via
# compile-plugin.sh or equivalent). Emits the path to the .deb on stdout; all
# other output (cargo, dpkg-deb, log) goes to stderr.
#
# Args: <plugin-path>     e.g. audio/spotify
# Env:  TARGET (from cross-env.sh), GST_GIT_BRANCH
# Cwd:  the working tree containing gst-plugins-rs/<plugin>/
set -eu

PLUGIN="$1"
GST_SRC_DIR=gst-plugins-rs/$PLUGIN
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

"$SCRIPT_DIR/inject-deb-metadata.sh" "$GST_SRC_DIR" >&2

DEB_VERSION=$("$SCRIPT_DIR/compose-version.sh" --deb "$GST_SRC_DIR")
echo "Building .deb version: $DEB_VERSION" >&2

# Must specify --target despite --no-build, else cargo-deb looks in the
# workspace for the asset (see comment in compile-plugin.sh).
(cd "$GST_SRC_DIR" && cargo deb --target="$TARGET" --no-build --deb-version "$DEB_VERSION" -v) >&2

DEB_FILE=$(find "gst-plugins-rs/target/$TARGET/debian"/*.deb)
dpkg-deb --field "$DEB_FILE" Package Architecture Version Installed-Size >&2

printf '%s\n' "$DEB_FILE"
