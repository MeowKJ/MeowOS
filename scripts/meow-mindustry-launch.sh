#!/bin/sh
set -eu
GAME_DIR=/opt/mindustry
JAR="$GAME_DIR/Mindustry.jar"
GL4ES="$GAME_DIR/gl4es/lib"
[ -r "$JAR" ] || { echo "Mindustry.jar not found" >&2; exit 1; }
export LD_LIBRARY_PATH="$GL4ES${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export LIBGL_ES=2
export LIBGL_GL=21
export MINDUSTRY_DATA="$HOME/.local/share/Mindustry"
mkdir -p "$MINDUSTRY_DATA"
exec /usr/lib/jvm/java-17-openjdk-arm64/bin/java -Xms128m -Xmx512m -jar "$JAR" "$@"
