#!/usr/bin/env bash
# Packs the Linux (GTK2) build into an AppImage. GTK2 and its libraries are bundled,
# so the program also runs on distributions without GTK2 installed.
#
# usage: ci/appimage.sh <binary> <icon.png> <desktop-file> <out.AppImage>
# needs in $TOOLS (default ./tools): linuxdeploy-$(uname -m).AppImage, linuxdeploy-plugin-gtk.sh
set -euo pipefail
BIN=$(realpath "$1"); ICON=$(realpath "$2"); DESKTOP=$(realpath "$3"); OUT=$(realpath -m "$4")
TOOLS=$(realpath "${TOOLS:-tools}")
ARCH=$(uname -m)
mkdir -p "$(dirname "$OUT")"
APPDIR=$(mktemp -d)/AppDir

mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/512x512/apps"
install -m755 "$BIN" "$APPDIR/usr/bin/SeaParser"
cp "$DESKTOP" "$APPDIR/usr/share/applications/seaparser.desktop"
cp "$ICON" "$APPDIR/usr/share/icons/hicolor/512x512/apps/seaparser.png"

export APPIMAGE_EXTRACT_AND_RUN=1      # no FUSE on CI runners and in containers
export DEPLOY_GTK_VERSION=2
export LDAI_OUTPUT="$OUT" OUTPUT="$OUT"
export PATH="$TOOLS:$PATH"             # linuxdeploy looks for plugins in PATH
LD="$TOOLS/linuxdeploy-$ARCH.AppImage"

# 1. copy GTK2 and everything it needs into AppDir
"$LD" --appdir "$APPDIR" --plugin gtk
# 2. LCL (gtk2extra.inc) also calls LoadLibrary('libgdk-x11-2.0.so') without a version number.
#    Without these links the system GDK is loaded next to the bundled one, and GTK breaks
#    ("cannot register existing type 'GdkScreen'").
ln -sf libgdk-x11-2.0.so.0 "$APPDIR/usr/lib/libgdk-x11-2.0.so"
ln -sf libgtk-x11-2.0.so.0 "$APPDIR/usr/lib/libgtk-x11-2.0.so"
# 3. pack
"$LD" --appdir "$APPDIR" --output appimage
ls -la "$OUT"
