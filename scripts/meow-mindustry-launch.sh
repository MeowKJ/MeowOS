#!/bin/sh
set -eu

JAR=/opt/mindustry/Mindustry.jar
XORG_PID=
TERMINATING=0
[ -r "$JAR" ] || { echo "Mindustry.jar not found" >&2; exit 1; }

cleanup() {
    if [ -n "$XORG_PID" ]; then kill "$XORG_PID" 2>/dev/null || true; wait "$XORG_PID" 2>/dev/null || true; fi
}

handle_signal() {
    TERMINATING=1
    cleanup
}

trap cleanup EXIT
trap handle_signal INT TERM

# This appliance has no persistent desktop X server. Remove a stale process or
# lock left by an interrupted game session before taking over VT1/DRM.
# systemd normally stops Meow OS before entering this service, but allow a
# short hand-off window and terminate a stale shell so DRM master is released.
i=0
while pgrep -x meow-os >/dev/null 2>&1 && [ "$i" -lt 30 ]; do
    i=$((i + 1)); sleep 0.1
done
if pgrep -x meow-os >/dev/null 2>&1; then
    pkill -TERM -x meow-os 2>/dev/null || true
    sleep 0.5
    pkill -KILL -x meow-os 2>/dev/null || true
fi
pkill -TERM -x Xorg 2>/dev/null || true
sleep 0.5
pkill -KILL -x Xorg 2>/dev/null || true
rm -f /tmp/.X11-unix/X0 /tmp/.X0-lock
# Use a session-local Xorg configuration so the portrait panel is presented as
# landscape to SDL.  Do not modify /etc/X11: Meow OS uses its own EGLFS path.
XORG_CONF=/tmp/meow-mindustry-xorg.conf
cat >"$XORG_CONF" <<'EOF'
Section "Device"
    Identifier "Meow Mindustry GPU"
    Driver "modesetting"
    Option "kmsdev" "/dev/dri/card0"
    Option "AccelMethod" "glamor"
    Option "DRI" "2"
EndSection
Section "Monitor"
    Identifier "Meow Panel"
    Option "Rotate" "left"
EndSection
Section "Screen"
    Identifier "Meow Screen"
    Device "Meow Mindustry GPU"
    Monitor "Meow Panel"
EndSection
EOF
/usr/bin/Xorg :0 -config "$XORG_CONF" vt1 -keeptty -nolisten tcp -noreset >/var/log/meow-mindustry-xorg.log 2>&1 &
XORG_PID=$!
i=0
while [ ! -S /tmp/.X11-unix/X0 ]; do
    kill -0 "$XORG_PID" 2>/dev/null || { cat /var/log/meow-mindustry-xorg.log >&2; exit 1; }
    i=$((i + 1)); [ "$i" -lt 50 ] || { echo "Xorg startup timeout" >&2; exit 1; }
    sleep 0.1
done

# The panel is physically portrait (800x1280).  Rotate the connected output
# before SDL queries the desktop size, then apply the inverse transform to the
# touchscreen so physical taps continue to land on the rotated game surface.
# These tools are hard requirements: silently continuing creates a portrait,
# non-touchable game, which is worse than a clear service failure.
command -v xrandr >/dev/null 2>&1 || { echo "xrandr is required" >&2; exit 1; }
command -v xinput >/dev/null 2>&1 || { echo "xinput is required" >&2; exit 1; }

OUTPUT=$(DISPLAY=:0 xrandr --query | awk '$2 == "connected" { print $1; exit }')
[ -n "$OUTPUT" ] || { echo "No connected X11 output found" >&2; exit 1; }
DISPLAY=:0 xrandr --output "$OUTPUT" --rotate left >/var/log/meow-mindustry-xrandr.log 2>&1
DISPLAY=:0 xrandr --query >>/var/log/meow-mindustry-xrandr.log 2>&1

TOUCH_ID=
i=0
while [ -z "$TOUCH_ID" ] && [ "$i" -lt 30 ]; do
    TOUCH_ID=$(DISPLAY=:0 xinput list --id-only "jadard-touchscreen" 2>/dev/null || true)
    i=$((i + 1))
    [ -n "$TOUCH_ID" ] || sleep 0.1
done
[ -n "$TOUCH_ID" ] || {
    DISPLAY=:0 xinput list >&2 || true
    echo "jadard-touchscreen is not available through XInput" >&2
    exit 1
}

# x' = 1-y, y' = x is the inverse mapping for an XRandR left rotation.
DISPLAY=:0 xinput set-prop "$TOUCH_ID" "Coordinate Transformation Matrix" \
    0 -1 1 1 0 0 0 0 1
DISPLAY=:0 xinput list-props "$TOUCH_ID" >/var/log/meow-mindustry-xinput.log 2>&1

# Debian image does not ship util-linux runuser; setpriv provides the same
# privilege drop without requiring an interactive shell.
set +e
/usr/bin/setpriv --reuid=radxa --regid=radxa --init-groups env DISPLAY=:0 SDL_VIDEODRIVER=x11 HOME=/home/radxa \
    /usr/lib/jvm/java-17-openjdk-arm64/bin/java -Xms128m -Xmx512m -jar "$JAR" \
    -gl 2.1 -compatibilityGl -maximized true "$@"
GAME_STATUS=$?
set -e

# systemd terminates the complete cgroup.  Java may report a broken X
# connection while Xorg is being cleaned up; that is an expected normal stop.
[ "$TERMINATING" -eq 1 ] && exit 0
exit "$GAME_STATUS"
