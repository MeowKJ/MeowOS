#!/bin/sh
set -eu

JAR=/opt/mindustry/Mindustry.jar
XORG_PID=
[ -r "$JAR" ] || { echo "Mindustry.jar not found" >&2; exit 1; }

cleanup() {
    if [ -n "$XORG_PID" ]; then kill "$XORG_PID" 2>/dev/null || true; wait "$XORG_PID" 2>/dev/null || true; fi
}
trap cleanup EXIT INT TERM

rm -f /tmp/.X11-unix/X0
/usr/bin/Xorg :0 vt1 -keeptty -nolisten tcp -noreset >/var/log/meow-mindustry-xorg.log 2>&1 &
XORG_PID=$!
i=0
while [ ! -S /tmp/.X11-unix/X0 ]; do
    kill -0 "$XORG_PID" 2>/dev/null || { cat /var/log/meow-mindustry-xorg.log >&2; exit 1; }
    i=$((i + 1)); [ "$i" -lt 50 ] || { echo "Xorg startup timeout" >&2; exit 1; }
    sleep 0.1
done

/usr/sbin/runuser -u radxa -- env DISPLAY=:0 SDL_VIDEODRIVER=x11 HOME=/home/radxa \
    /usr/lib/jvm/java-17-openjdk-arm64/bin/java -Xms128m -Xmx512m -jar "$JAR" \
    -gl 2.1 -compatibilityGl -maximized true "$@"
