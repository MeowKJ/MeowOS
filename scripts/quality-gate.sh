#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

score_elegance=0
score_complete=0
score_optimize=0

# Static evidence only. Runtime screenshot and device measurements are reported
# separately and must not be silently converted into points.
grep -q 'SettingsFlickable' qml/Main.qml && score_elegance=$((score_elegance + 8))
grep -q 'DragAndOvershootBounds' qml/Main.qml && score_elegance=$((score_elegance + 5))
grep -q 'SettingsNavRow' qml/Main.qml && score_elegance=$((score_elegance + 5))
grep -q 'hardwareCapabilities' src/systembackend.h && score_complete=$((score_complete + 8))
grep -q 'gaugeCommunication' src/systembackend.h && score_complete=$((score_complete + 8))
grep -q 'calibrateBattery' src/systembackend.h && score_complete=$((score_complete + 8))
grep -q 'settingsForeground' qml/Main.qml && score_optimize=$((score_optimize + 8))
grep -q 'asynchronous: false' qml/Main.qml && score_optimize=$((score_optimize + 6))
grep -q 'QtConcurrent::run' src/systembackend.cpp && score_optimize=$((score_optimize + 6))

total=$((score_elegance + score_complete + score_optimize))
printf '优雅度=%d/35\n完整度=%d/35\n优化度=%d/30\n总分=%d/100\n' \
    "$score_elegance" "$score_complete" "$score_optimize" "$total"
if [ -s verify/battery-0.2.0.png ]; then
    printf '%s\n' 'runtime_evidence=partial-battery-screenshot-power-sample'
else
    printf '%s\n' 'runtime_evidence=pending-device-screenshot-and-power-sample'
fi
printf '%s\n' 'bq_write_calibration=disabled-until-datasheet-command-review'

if [ "${1:-}" = "--strict" ] && [ "$total" -lt 94 ]; then
    printf '%s\n' 'QUALITY_GATE=FAIL' >&2
    exit 1
fi
printf '%s\n' 'QUALITY_GATE=REPORT_ONLY'
