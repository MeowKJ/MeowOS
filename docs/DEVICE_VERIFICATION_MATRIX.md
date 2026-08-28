# MeowOS device verification matrix

Run `scripts/verify-device.sh` from the deployed checkout on the target Linux
device. The script is intentionally non-destructive and builds into `/tmp`.
Add `--live` after the build checks to read the active desktop service and
connected display without changing system state.
Add `--stability` to run three start/stop cycles with orphan-process checks.

| Gate | Evidence | Pass condition |
| --- | --- | --- |
| Architecture | `uname -m`, `uname -sr` | Expected ARM kernel/device reported |
| Runtime/HAL | `runtime_tests=passed` | scheduler, sessions, snapshots and transforms pass |
| Qt build | `qt_build=passed` | qmake + parallel make produce executable |
| Foreground lifecycle | service journal + process list | one user app; no hidden app process after stop |
| Display | screenshot at boot, shell and app | logical landscape geometry is consistent |
| Touch | scripted corner/center taps | all points map to expected logical coordinates |
| Recovery | stop/start cycle and journal | shell returns, no orphaned game/IME processes |

The final three rows require a physical display and are not inferred from a
successful compiler run. Record screenshots and `ps`/journal output alongside
the script output for release evidence.
