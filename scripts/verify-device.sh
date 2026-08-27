#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

printf 'device=%s\n' "$(uname -n)"
printf 'kernel=%s\n' "$(uname -sr)"
printf 'arch=%s\n' "$(uname -m)"

TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/meow-device.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT

printf '%s\n' '[runtime] compiling and running'
"${CXX:-c++}" -std=c++11 -Wall -Wextra -Werror -pthread \
    -Isrc tools/test-runtime.cpp \
    src/runtime/task_scheduler.cpp src/runtime/app_session.cpp \
    src/runtime/app_session_supervisor.cpp src/runtime/runtime_snapshot.cpp \
    src/hal/hal_interfaces.cpp -o "$TMP_DIR/meow-runtime-test"
"$TMP_DIR/meow-runtime-test"

QMAKE_BIN=$(command -v qmake || command -v qmake-qt5 || true)
if [ -n "$QMAKE_BIN" ]; then
    printf '%s\n' '[qt] qmake build'
    "$QMAKE_BIN" meow-os.pro -o "$TMP_DIR/Makefile"
    make -C "$TMP_DIR" -j"${MEOW_BUILD_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
    test -x "$TMP_DIR/meow-os"
    printf '%s\n' 'qt_build=passed'
else
    printf '%s\n' 'qt_build=skipped (qmake unavailable)'
fi

printf '%s\n' 'runtime_tests=passed'
printf '%s\n' 'device_verification=passed'
