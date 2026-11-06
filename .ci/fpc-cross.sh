#!/usr/bin/env bash
# Builds an FPC cross-compiler with RTL and packages for a Windows target
# and installs it next to the system FPC (Ubuntu/Debian package layout).
#
# usage: ci/fpc-cross.sh <cpu> <os> <fpc-source-dir> <cache-dir>
#   ci/fpc-cross.sh i386   win32 fpcsrc ~/fpc-cross
#   ci/fpc-cross.sh x86_64 win64 fpcsrc ~/fpc-cross
# fpc-source: https://github.com/fpc/FPCSource, tag of the same version as the system fpc
set -euo pipefail
CPU=$1; OS=$2; SRC=$3; OUT=$(realpath -m "$4")
VER=$(fpc -iV)
SYSLIB=$(dirname "$(readlink -f "$(fpc -PB)")")      # e.g. /usr/lib/x86_64-linux-gnu/fpc/3.2.2
SUDO=""; [ "$(id -u)" = 0 ] || SUDO=sudo

if [ ! -d "$OUT/lib/fpc/$VER/units/$CPU-$OS" ]; then
  SRC=$(realpath "$SRC")
  WORK=$(mktemp -d)
  cp -r "$SRC/." "$WORK/"
  echo "Building FPC $VER cross-compiler for $CPU-$OS..."
  make -C "$WORK" crossall crossinstall OS_TARGET="$OS" CPU_TARGET="$CPU" \
       INSTALL_PREFIX="$OUT" FPC=fpc -j"$(nproc)" > "$OUT-$CPU-$OS.log" 2>&1 \
    || { tail -50 "$OUT-$CPU-$OS.log"; exit 1; }
  rm -rf "$WORK"
fi

$SUDO mkdir -p "$SYSLIB/units"
$SUDO cp -r "$OUT/lib/fpc/$VER/units/$CPU-$OS" "$SYSLIB/units/"
for c in "$OUT"/lib/fpc/"$VER"/ppcross*; do
  [ -e "$c" ] || continue
  $SUDO cp "$c" "$SYSLIB/"
  $SUDO ln -sf "$SYSLIB/$(basename "$c")" "/usr/bin/$(basename "$c")"
done
echo "FPC $VER: cross-compiler for $CPU-$OS installed"
