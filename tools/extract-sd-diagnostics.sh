#!/bin/sh
set -eu

DEV="${1:-/dev/rdisk6s3}"
OUT="${2:-$PWD/meow-os-sd-diagnostics-$(date +%Y%m%d-%H%M%S)}"
E2=${E2FSPROGS_DIR:-/opt/homebrew/opt/e2fsprogs/sbin}

[ "$(id -u)" -eq 0 ] || { echo "Run with sudo to read the raw SD partition." >&2; exit 1; }
[ -b "$DEV" ] || { echo "Root partition not found: $DEV" >&2; exit 1; }
[ -x "$E2/e2fsck" ] && [ -x "$E2/debugfs" ] || { echo "e2fsprogs not found: $E2" >&2; exit 1; }

mkdir -p "$OUT/files" "$OUT/meow-logs" "$OUT/journal"
"$E2/e2fsck" -fn "$DEV" >"$OUT/e2fsck.txt" 2>&1 || true
"$E2/debugfs" -R 'stats' "$DEV" >"$OUT/ext4-stats.txt" 2>&1

dump_file() {
    src="$1"
    name="$2"
    "$E2/debugfs" -R "dump -p $src $OUT/files/$name" "$DEV" >/dev/null 2>&1 || true
}

dump_file /etc/meow-os-release meow-os-release
dump_file /etc/meow-os/build.sha256 build.sha256
dump_file /etc/meow-os/display.conf display.conf
dump_file /etc/systemd/system/meow-os.service meow-os.service
dump_file /etc/systemd/system/meow-mindustry.service meow-mindustry.service
dump_file /opt/meow-os/bin/meow-display-launcher meow-display-launcher
dump_file /opt/meow-os/bin/meow-wait-display meow-wait-display
dump_file /opt/meow-os/eglfs-kms.json eglfs-kms.json
"$E2/debugfs" -R "rdump /var/log/meow-os $OUT/meow-logs" "$DEV" >/dev/null 2>&1 || true
"$E2/debugfs" -R "rdump /var/log/journal $OUT/journal" "$DEV" >/dev/null 2>&1 || true

if [ -n "${SUDO_USER:-}" ]; then
    chown -R "$SUDO_USER":staff "$OUT" 2>/dev/null || true
fi
echo "Diagnostics extracted read-only to: $OUT"

