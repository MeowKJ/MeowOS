#!/bin/sh
set -eu

HOST="${MEOW_HOST:-radxa@192.168.8.178}"
DEST_DIR="${MEOW_DEST_DIR:-~/meow-os-review}"
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERIFY_DIR="$ROOT_DIR/verify"

echo "==> [1/4] 同步代码到 $HOST:$DEST_DIR"
rsync -az --delete --exclude .git --exclude verify --exclude '*.raw' --exclude '*.png' "$ROOT_DIR"/ "$HOST":"$DEST_DIR"/

echo "==> [2/4] 设备上构建并安装"
ssh "$HOST" "cd $DEST_DIR && sudo ./scripts/install-live.sh"

echo "==> [3/4] 重启 meow-os 服务"
ssh "$HOST" 'sudo systemctl restart meow-os && sleep 4 && systemctl --no-pager --no-legend status meow-os | head -5'

echo "==> [4/4] 抓取屏幕帧并回传"
mkdir -p "$VERIFY_DIR"
ssh "$HOST" '
  fb=/dev/fb0
  [ -e "$fb" ] || fb=$(ls /dev/fb* 2>/dev/null | head -1)
  if [ -n "${fb:-}" ]; then
    dd if="$fb" of=/tmp/meow-screen.raw bs=4096 2>/dev/null
    echo "FB=$fb size=$(stat -c%s /tmp/meow-screen.raw 2>/dev/null || stat -f%z /tmp/meow-screen.raw)"
  else
    echo "NO_FB"
    : > /tmp/meow-screen.raw
  fi
  echo "virtual_size=$(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo unknown)"
  echo "bits_per_pixel=$(cat /sys/class/graphics/fb0/bits_per_pixel 2>/dev/null || echo unknown)"
' | tee "$VERIFY_DIR/fb-meta.txt"
scp "$HOST":/tmp/meow-screen.raw "$VERIFY_DIR/screen.raw" 2>/dev/null || true

if [ -s "$VERIFY_DIR/screen.raw" ]; then
  echo "==> 转换 screen.raw -> screen.png"
  python3 "$ROOT_DIR/scripts/raw2png.py" "$VERIFY_DIR/screen.raw" "$VERIFY_DIR/fb-meta.txt" "$VERIFY_DIR/screen.png"
  echo "完成: $VERIFY_DIR/screen.png"
else
  echo "警告: 未抓到帧，请检查 fb-meta.txt"
fi
