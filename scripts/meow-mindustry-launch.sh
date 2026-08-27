#!/bin/sh
set -eu

JAR=/opt/mindustry/Mindustry.jar
XORG_PID=
[ -r "$JAR" ] || { echo "Mindustry.jar not found" >&2; exit 1; }

cleanup() {
    if [ -n "$XORG_PID" ]; then kill "$XORG_PID" 2>/dev/null || true; wait "$XORG_PID" 2>/dev/null || true; fi
}
trap cleanup EXIT INT TERM

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

# The attached panel is physically portrait (800x1280), while the game UI is
# designed for the Meow OS landscape workspace.  Rotate only this temporary
# Xorg session; the normal Meow OS EGLFS configuration is left untouched.
# The modesetting driver exposes the panel as DSI-1 and applies the rotation
# before SDL queries the desktop size, yielding a 1280x800 game surface.
if command -v xrandr >/dev/null 2>&1; then
    xrandr --display :0 --output DSI-1 --rotate left >/var/log/meow-mindustry-xrandr.log 2>&1 || true
fi

# Debian image does not ship util-linux runuser; setpriv provides the same
# privilege drop without requiring an interactive shell.
/usr/bin/setpriv --reuid=radxa --regid=radxa --init-groups env DISPLAY=:0 SDL_VIDEODRIVER=x11 HOME=/home/radxa \
    /usr/lib/jvm/java-17-openjdk-arm64/bin/java -Xms128m -Xmx512m -jar "$JAR" \
    -gl 2.1 -compatibilityGl -maximized true "$@"
