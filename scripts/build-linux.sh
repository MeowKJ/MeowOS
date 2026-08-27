#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

QMAKE_BIN=$(command -v qmake || command -v qmake-qt5 || true)
if [ -z "$QMAKE_BIN" ]; then
    printf '%s\n' 'qmake or qmake-qt5 is required' >&2
    exit 1
fi

BUILD_DIR=${MEOW_BUILD_DIR:-"$ROOT_DIR/build"}
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
"$QMAKE_BIN" "$ROOT_DIR/meow-os.pro" -o Makefile
make -j"${MEOW_BUILD_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
