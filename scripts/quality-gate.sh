#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

# Runtime architecture invariants: these are intentionally fail-fast because
# removing any one of them silently regresses isolation or resource safety.
test -f src/runtime/task_scheduler.cpp
grep -q 'queue_\.size() >= maxPendingTasks_' src/runtime/task_scheduler.cpp
grep -q 'runningTasks_' src/runtime/task_scheduler.cpp
test -f src/runtime/app_session_supervisor.cpp
grep -q 'if (appId.empty() || active_)' src/runtime/app_session_supervisor.cpp
test -f src/runtime/runtime_snapshot.cpp
grep -q 'atomic_load_explicit' src/runtime/runtime_snapshot.cpp
test -f src/hal/hal_interfaces.cpp
grep -q 'transformTouchPoint' src/hal/hal_interfaces.cpp
grep -q 'class IAppProcessHal' src/hal/hal_interfaces.h

score_elegance=0
score_complete=0
score_optimize=0

# Static evidence only. Runtime screenshot and device measurements are reported
# separately and must not be silently converted into points.
test -f qml/components/SettingsFlickable.qml && score_elegance=$((score_elegance + 8))
grep -q 'DragAndOvershootBounds' qml/components/SettingsFlickable.qml && score_elegance=$((score_elegance + 5))
test -f qml/components/SettingsNavRow.qml && score_elegance=$((score_elegance + 5))
test -f qml/components/PerformanceCpuCard.qml && score_elegance=$((score_elegance + 6))
test -f qml/components/IosSwitch.qml && score_elegance=$((score_elegance + 6))
test -f qml/components/PerformanceCoreMatrix.qml && score_elegance=$((score_elegance + 5))

grep -q 'hardwareCapabilities' src/systembackend.h && score_complete=$((score_complete + 8))
grep -q 'gaugeCommunication' src/systembackend.h && score_complete=$((score_complete + 8))
grep -q 'calibrateBattery' src/systembackend.h && score_complete=$((score_complete + 8))
grep -q 'sleepPowerLevel' src/systembackend.h && score_complete=$((score_complete + 6))
grep -q 'keepScreenOnApps' src/systembackend.h && score_complete=$((score_complete + 5))

grep -q 'settingsForeground' qml/Main.qml && score_optimize=$((score_optimize + 8))
grep -q 'loader.asynchronous = false' qml/apps/SettingsApp.qml && score_optimize=$((score_optimize + 6))
grep -q 'QtConcurrent::run' src/systembackend.cpp && score_optimize=$((score_optimize + 8))
grep -q 'renderTarget: Canvas.Image' qml/components/PerformanceCpuCard.qml && score_optimize=$((score_optimize + 8))

total=$((score_elegance + score_complete + score_optimize))
printf '优雅度=%d/35\n完整度=%d/35\n优化度=%d/30\n总分=%d/100\n' \
    "$score_elegance" "$score_complete" "$score_optimize" "$total"
if [ -s verify/perf-dashboard-ui.png ]; then
    printf '%s\n' 'runtime_evidence=verified-dashboard-screenshot'
else
    printf '%s\n' 'runtime_evidence=pending-device-screenshot'
fi

if [ "${1:-}" = "--strict" ] && [ "$total" -lt 94 ]; then
    printf '%s\n' 'QUALITY_GATE=FAIL' >&2
    exit 1
fi
printf '%s\n' 'QUALITY_GATE=REPORT_ONLY'
