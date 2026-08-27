# MeowOS Runtime Architecture (experimental)

This document defines the low-coupling direction for the Linux runtime. It is
an additive design: the current Qt/EGLFS shell remains the production fallback
while the new runtime pieces are introduced behind stable contracts.

## Boundaries

```text
meow-shell (Qt Quick)
        │ asynchronous IPC / adapter
meow-core (policy and immutable state snapshots)
        ├── HAL adapters (display, input, power, audio, network, storage)
        └── meow-sessiond (one foreground app session)
                  ├── display backend (EGLFS / X11 / Wayland)
                  └── input + IME backend (evdev / XInput / Fcitx5)
```

The HAL contracts are pure C++ and do not include Qt, QML, systemd, or a
specific SoC. This includes the application process adapter: systemd is only
one possible implementation of `IAppProcessHal`. A Rockchip adapter can
therefore replace the Allwinner adapter without changing policy or UI code.

## Scheduling model

`meow::TaskScheduler` is a bounded-priority executor:

- `Critical`: input and display hand-off work;
- `Interactive`: application state and network actions;
- `Background`: telemetry, storage indexing, and history maintenance.

Workers drain higher-priority work first and preserve FIFO order within a
priority. The UI thread never waits on hardware or process I/O. Results are
returned as futures/events and published as immutable snapshots.
The test suite also locks the priority ordering with a single-worker scenario,
so a critical hand-off cannot be delayed behind queued background work.

`RuntimeSnapshotStore` is the first concrete state boundary: workers publish a
complete immutable metrics snapshot, while QML-facing code obtains an atomic
read-only pointer. No UI binding can observe half-written CPU/RAM/GPU values or
retain a mutable worker-owned container.

The queue has a configurable pending-task limit (1024 by default). Producers
receive an explicit `TaskScheduler queue is full` failure instead of silently
creating unbounded memory pressure; callers can then coalesce telemetry or
retry interactive work according to policy.
The scheduler also exposes pending and running counts separately, allowing the
RGB performance UI to distinguish queue pressure from active CPU work.

There is no thread-per-device rule. The worker count is bounded by available
cores, and shutdown drains queued work before joining workers. Long-running
application processes remain isolated in their own systemd session so they
cannot consume shell threads or leave background processes behind.

## One-foreground-app invariant

`AppSession` and `AppSessionSupervisor` are policy contracts for this invariant.
The supervisor owns at most one session, rejects a second foreground launch,
and releases the slot on a clean stop or failure. A future systemd/Wayland
adapter can perform the actual process and surface hand-off without changing
this policy code.
`beginStart()` and `markRunning()` are separate so asynchronous process launch
and surface negotiation are represented explicitly instead of being reported
as running before the adapter confirms readiness.

The Qt shell follows the same rule: application views are created on demand,
never prewarmed invisibly, and are destroyed when popped from the foreground
stack. This prevents hidden QML timers and signal connections from becoming
accidental background applications.

```text
Stopped → Starting → Running → Stopping → Stopped
                         └──────────────→ Failed
```

Only the session supervisor may transition this state. The shell observes
state changes; it does not launch or kill application processes directly.

## Display orientation and input coordinates

The HAL `DisplayGeometry` contract carries the panel's physical orientation
and the resulting logical size. A DRM/device-tree adapter may declare a fixed
panel mount (for example, native 800×1280 mounted as landscape), while the
display backend exposes 1280×800 to applications. The input adapter applies
the same quarter-turn to touch coordinates. QML and games therefore never
rotate independently, avoiding double rotation and keeping an RK adapter
binary-compatible with the Allwinner policy layer.
`IInputHal::setDisplayGeometry()` makes this synchronization explicit: an
adapter must accept the display geometry before it starts delivering touches.

## Migration order

1. Compile and test the pure runtime/HAL contracts (current change).
2. Move blocking `SystemBackend` operations behind core workers while keeping
   the existing QML adapter.
3. Move Mindustry, Onboard, and Fcitx5 into `meow-sessiond`.
4. Add a Wayland backend beside the current EGLFS/X11 backend.
5. Make the Wayland path default only after real-device touch, text input,
   fullscreen, and recovery tests pass.
