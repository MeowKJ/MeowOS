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
    make -C "$TMP_DIR" -j"${MEOW_BUILD_JOBS:-2}"
    test -x "$TMP_DIR/meow-os"
    printf '%s\n' 'qt_build=passed'
else
    printf '%s\n' 'qt_build=skipped (qmake unavailable)'
fi

if [ "${1:-}" = "--performance-baseline" ]; then
    command -v systemctl >/dev/null 2>&1 || { printf '%s\n' 'systemd=unavailable' >&2; exit 1; }
    pid=$(systemctl show -p MainPID --value meow-os.service)
    [ -n "$pid" ] && [ "$pid" -gt 1 ] && [ -r "/proc/$pid/stat" ] || exit 1
    hz=$(getconf CLK_TCK)
    set -- $(awk '{print $14, $15}' "/proc/$pid/stat")
    beforeTicks=$(( $1 + $2 ))
    beforeCtx=$(awk '/voluntary_ctxt_switches|nonvoluntary_ctxt_switches/{sum+=$2} END{print sum+0}' "/proc/$pid/status")
    sampleSeconds=${MEOW_PERF_SAMPLE_SECONDS:-30}
    sleep "$sampleSeconds"
    set -- $(awk '{print $14, $15}' "/proc/$pid/stat")
    afterTicks=$(( $1 + $2 ))
    afterCtx=$(awk '/voluntary_ctxt_switches|nonvoluntary_ctxt_switches/{sum+=$2} END{print sum+0}' "/proc/$pid/status")
    cpu=$(awk -v delta=$((afterTicks-beforeTicks)) -v hz="$hz" -v seconds="$sampleSeconds" 'BEGIN{printf "%.2f",100*delta/(hz*seconds)}')
    rssKb=$(awk '/VmRSS:/{print $2}' "/proc/$pid/status")
    threads=$(awk '/Threads:/{print $2}' "/proc/$pid/status")
    printf 'idle_cpu_percent=%s\nrss_kb=%s\nthreads=%s\ncontext_switches=%s\n' \
        "$cpu" "$rssKb" "$threads" "$((afterCtx-beforeCtx))"
    awk -v cpu="$cpu" 'BEGIN{exit !(cpu <= 3.0)}'
    [ "$rssKb" -le 180000 ]
    [ "$threads" -le 24 ]
    printf '%s\n' 'performance_baseline=passed'
fi

if [ "${1:-}" = "--live" ]; then
    printf '%s\n' '[live] checking current desktop/session state'
    if command -v systemctl >/dev/null 2>&1; then
        systemctl is-active --quiet meow-os.service
        printf '%s\n' 'meow_os_service=active'
        if systemctl is-active --quiet meow-mindustry.service; then
            printf '%s\n' 'foreground_app=mindustry'
        else
            printf '%s\n' 'foreground_app=shell'
        fi
    else
        printf '%s\n' 'systemd=unavailable (state check skipped)'
    fi
    if command -v xrandr >/dev/null 2>&1; then
        if xrandr --query >"$TMP_DIR/xrandr.txt" 2>/dev/null; then
            awk '$2 == "connected" { print "display_output=" $1; found=1 } END { exit(found ? 0 : 1) }' "$TMP_DIR/xrandr.txt" \
                || printf '%s\n' 'display_output=none detected'
        else
            printf '%s\n' 'display_query=unavailable (no active display session)'
        fi
    else
        printf '%s\n' 'display_query=unavailable (xrandr skipped)'
    fi
fi

if [ "${1:-}" = "--stability" ]; then
    command -v systemctl >/dev/null 2>&1 || { printf '%s\n' 'systemd=unavailable' >&2; exit 1; }
    printf '%s\n' '[stability] three foreground-session cycles'
    for round in 1 2 3; do
        sudo -n systemctl reset-failed meow-mindustry.service >/dev/null 2>&1 || true
        sudo -n systemctl start meow-mindustry.service
        sleep 12
        startState=$(systemctl is-active meow-mindustry.service 2>/dev/null || true)
        if [ "$startState" != "active" ]; then
            printf 'round=%s start=%s\n' "$round" "$startState" >&2
            exit 1
        fi
        set +e
        timeout 20s sudo -n systemctl stop meow-mindustry.service
        stopRc=$?
        set -e
        stopState=$(systemctl is-active meow-mindustry.service 2>/dev/null || true)
        shellState=$(systemctl is-active meow-os.service 2>/dev/null || true)
        if pgrep -af '[j]ava.*Mindustry.jar|[o]nboard|[f]citx|[X]org' >/dev/null 2>&1; then
            remnants=present
        else
            remnants=none
        fi
        printf 'round=%s start=%s stop_rc=%s stopped=%s shell=%s remnants=%s\n' \
            "$round" "$startState" "$stopRc" "$stopState" "$shellState" "$remnants"
        [ "$stopRc" -eq 0 ] && [ "$shellState" = "active" ] && [ "$remnants" = "none" ] || exit 1
    done
    printf '%s\n' 'stability_verification=passed'
fi

printf '%s\n' 'runtime_tests=passed'
printf '%s\n' 'device_verification=passed'
