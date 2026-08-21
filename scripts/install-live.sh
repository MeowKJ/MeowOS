#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=$(cat "$ROOT_DIR/VERSION")

cd "$ROOT_DIR"
qmake meow-os.pro -o Makefile
make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"

install -d -m 0755 /opt/meow-os/bin /opt/meow-os/assets/sounds /etc/meow-os /etc/systemd/system /etc/polkit-1/rules.d /etc/udev/rules.d
install -m 0755 meow-os /opt/meow-os/meow-os
install -m 0644 assets/sounds/volume-meow.wav /opt/meow-os/assets/sounds/volume-meow.wav
install -m 0755 scripts/meow-display-launcher /opt/meow-os/bin/meow-display-launcher
install -m 0755 scripts/meow-backlight-permissions /opt/meow-os/bin/meow-backlight-permissions
install -m 0755 systemd/vt_mode.py /opt/meow-os/vt_mode.py
install -m 0644 systemd/meow-os.service /etc/systemd/system/meow-os.service
install -m 0644 systemd/meow-charge-enable.service /etc/systemd/system/meow-charge-enable.service
install -m 0644 config/display.conf /etc/meow-os/display.conf
install -m 0644 config/eglfs-kms.json /opt/meow-os/eglfs-kms.json
install -m 0644 config/asound.conf /etc/asound.conf
install -m 0644 polkit/49-meow-os-network.rules /etc/polkit-1/rules.d/49-meow-os-network.rules
install -m 0644 udev/99-meow-os-input.rules /etc/udev/rules.d/99-meow-os-input.rules
printf 'NAME="Meow OS"\nVERSION="%s"\nID=meow-os\nPRETTY_NAME="Meow OS %s"\n' "$VERSION" "$VERSION" > /etc/meow-os-release

usermod -aG input,video,render,audio,i2c,netdev radxa
systemctl daemon-reload
udevadm control --reload-rules
systemctl enable meow-os.service
systemctl enable meow-charge-enable.service
