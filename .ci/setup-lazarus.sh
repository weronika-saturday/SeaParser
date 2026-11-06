#!/usr/bin/env bash
# Gets Lazarus (lazbuild only, no IDE) from source and registers the csscontrols package.
#
# usage: ci/setup-lazarus.sh <lazarus-dir> <lazarus-tag> <csscontrols-dir> <csscontrols-tag> <config-dir>
#   ci/setup-lazarus.sh ~/lazarus lazarus_4_8 ~/csscontrols v0.2.3 ~/.lazcfg
set -euo pipefail
LAZ=$(realpath -m "$1"); LAZ_TAG=$2; CSS=$(realpath -m "$3"); CSS_TAG=$4; PCP=$(realpath -m "$5")

if [ ! -x "$LAZ/lazbuild" ]; then
  rm -rf "$LAZ"
  git clone -q --depth 1 --branch "$LAZ_TAG" https://github.com/fpc/Lazarus.git "$LAZ"
  make -C "$LAZ" lazbuild > "$LAZ/../lazbuild-make.log" 2>&1 || { tail -50 "$LAZ/../lazbuild-make.log"; exit 1; }
fi
if [ ! -f "$CSS/csspckg_lazarus.lpk" ]; then
  rm -rf "$CSS"
  git clone -q --depth 1 --branch "$CSS_TAG" https://github.com/pst2d/csscontrols.git "$CSS"
fi
"$LAZ/lazbuild" --pcp="$PCP" --lazarusdir="$LAZ" --add-package-link "$CSS/csspckg_lazarus.lpk"
"$LAZ/lazbuild" --pcp="$PCP" --lazarusdir="$LAZ" --version
