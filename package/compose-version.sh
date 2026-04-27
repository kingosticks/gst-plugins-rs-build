#!/bin/sh
# Print a version string composed from cargo's package version, the upstream
# branch ($GST_GIT_BRANCH), and the short git hash of the source. With --deb,
# also append the Debian package revision from Cargo.toml.deb.
#
# Default format:    <pkg_version>+<branch>.<hash>
#                    e.g. 0.15.1+spotify-logging.a3e8681
#                    (used to name artifacts that aren't Debian packages,
#                    like the bare .so subdir under dist/)
# With --deb:        <pkg_version>+<branch>.<hash>-<revision>
#                    e.g. 0.15.1+spotify-logging.a3e8681-0mopidy1
#
# Branch is sanitized to Debian's allowed upstream_version chars
# ([A-Za-z0-9.+~-]). Hyphens are kept because the trailing -<revision>
# means we have a debian_revision, which permits hyphens in upstream_version.
#
# Args: [--deb] <gst-src-dir>
# Env:  GST_GIT_BRANCH (required)
set -eu

ADD_REVISION=0
if [ "${1:-}" = "--deb" ]; then
    ADD_REVISION=1
    shift
fi

GST_SRC_DIR="$1"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEB_METADATA="${SCRIPT_DIR}/Cargo.toml.deb"

PKG_VERSION=$(cd "$GST_SRC_DIR" && cargo pkgid | sed 's/.*[#@]//')
GIT_HASH=$(git -C "$GST_SRC_DIR" rev-parse --short HEAD)
BRANCH_TAG=$(printf '%s' "$GST_GIT_BRANCH" | tr -c 'A-Za-z0-9.+~-' '.' | sed 's/\.\.*/./g; s/^\.//; s/\.$//')

UPSTREAM="${PKG_VERSION}+${BRANCH_TAG}.${GIT_HASH}"

if [ "$ADD_REVISION" -eq 1 ]; then
    REVISION=$(grep -E '^\s*revision\s*=' "$DEB_METADATA" | sed -E 's/.*"([^"]+)".*/\1/')
    printf '%s-%s\n' "$UPSTREAM" "$REVISION"
else
    printf '%s\n' "$UPSTREAM"
fi
