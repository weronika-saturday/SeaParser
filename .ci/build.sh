#!/usr/bin/env bash
# Release build of SeaParser (optimized, without debug info).
#
# usage: ci/build.sh <lazarus-dir> <config-dir> <os> <cpu> <out-file>
#   ci/build.sh ~/lazarus ~/.lazcfg linux  x86_64 dist/SeaParser
#   ci/build.sh ~/lazarus ~/.lazcfg win32  i386   dist/SeaParser-win32.exe
set -euo pipefail
LAZ=$(realpath "$1"); PCP=$(realpath -m "$2"); OS=$3; CPU=$4; OUT=$5
WS=gtk2; EXT=""
case "$OS" in win32|win64) WS=win32; EXT=.exe ;; esac

"$LAZ/lazbuild" --pcp="$PCP" --lazarusdir="$LAZ" \
  --os="$OS" --cpu="$CPU" --ws="$WS" --build-all \
  --opt=-O2 --opt=-g- --opt=-Xs --opt=-XX --opt=-CX \
  SeaParser.lpi

mkdir -p "$(dirname "$OUT")"
cp "SeaParser$EXT" "$OUT"
file "$OUT" 2>/dev/null || ls -la "$OUT"
