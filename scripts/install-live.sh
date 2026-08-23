#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION=$(cat "$ROOT_DIR/VERSION")

case "$VERSION" in
    *[!0-9.]*|*.*.*.*|.*|*.)
        printf '%s\n' "Invalid Meow OS version: $VERSION (expected MAJOR.MINOR.PATCH)" >&2
        exit 1
        ;;
esac
if ! printf '%s\n' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    printf '%s\n' "Invalid Meow OS version: $VERSION (expected MAJOR.MINOR.PATCH)" >&2
    exit 1
fi

HEADER_VERSION=$(sed -n 's/^#define MEOW_OS_VERSION "\([^"]*\)"/\1/p' "$ROOT_DIR/src/version.h")
if [ "$HEADER_VERSION" != "$VERSION" ]; then
    printf '%s\n' "VERSION ($VERSION) does not match src/version.h ($HEADER_VERSION)" >&2
    printf '%s\n' 'Run scripts/bump-version before deploying.' >&2
    exit 1
fi

# Fingerprint all maintained product inputs, excluding generated build output.
# If those inputs change, reusing the installed version is rejected.
SOURCE_HASH=$(
    find VERSION meow-os.pro qml.qrc src qml assets config polkit systemd udev scripts plymouth hardware tools \
        -type f ! -name '*.o' ! -name 'moc_*' ! -name 'qrc_*' -print \
        | LC_ALL=C sort \
        | xargs sha256sum \
        | sha256sum \
        | awk '{print $1}'
)
INSTALLED_VERSION=$(sed -n 's/^VERSION="\{0,1\}\([^" ]*\)"\{0,1\}$/\1/p' /etc/meow-os-release 2>/dev/null || true)
INSTALLED_HASH=$(cat /etc/meow-os/build.sha256 2>/dev/null || true)
if [ -n "$INSTALLED_HASH" ] && [ "$SOURCE_HASH" != "$INSTALLED_HASH" ]; then
    if [ "$VERSION" = "$INSTALLED_VERSION" ]; then
        printf '%s\n' "Source changed but version is still $VERSION." >&2
        printf '%s\n' 'Run scripts/bump-version before deploying.' >&2
        exit 1
    fi
    if [ "$(printf '%s\n%s\n' "$INSTALLED_VERSION" "$VERSION" | sort -V | head -n 1)" != "$INSTALLED_VERSION" ]; then
        printf '%s\n' "Refusing version rollback: installed=$INSTALLED_VERSION incoming=$VERSION" >&2
        exit 1
    fi
fi

cd "$ROOT_DIR"
./scripts/quality-gate.sh
if [ "${MEOW_QUALITY_STRICT:-0}" = "1" ]; then
    ./scripts/quality-gate.sh --strict
fi
qmake meow-os.pro -o Makefile
make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"

install -d -m 0755 /opt/meow-os/bin /opt/meow-os/assets/sounds /opt/meow-os/share/early-splash/theme /opt/meow-os/share/early-splash/assets /etc/meow-os /etc/systemd/system /etc/polkit-1/rules.d /etc/polkit-1/localauthority/50-local.d /etc/udev/rules.d
install -m 0755 meow-os /opt/meow-os/meow-os
install -m 0755 scripts/mount-nvme-data /opt/meow-os/bin/mount-nvme-data
install -m 0644 assets/sounds/volume-meow.wav /opt/meow-os/assets/sounds/volume-meow.wav
install -m 0755 scripts/meow-display-launcher /opt/meow-os/bin/meow-display-launcher
install -m 0755 scripts/meow-backlight-permissions /opt/meow-os/bin/meow-backlight-permissions
install -m 0755 scripts/meow-wait-display /opt/meow-os/bin/meow-wait-display
install -m 0755 scripts/configure-boot-branding /opt/meow-os/bin/configure-boot-branding
install -m 0755 scripts/install-early-splash /opt/meow-os/bin/install-early-splash
install -m 0644 plymouth/meow-os/meow-os.plymouth /opt/meow-os/share/early-splash/theme/meow-os.plymouth
install -m 0644 plymouth/meow-os/meow-os.script /opt/meow-os/share/early-splash/theme/meow-os.script
install -m 0755 plymouth/meow-os/init-top-meow-plymouth /opt/meow-os/share/early-splash/theme/init-top-meow-plymouth
install -m 0755 plymouth/meow-os/init-premount-meow-plymouth /opt/meow-os/share/early-splash/theme/init-premount-meow-plymouth
install -m 0755 plymouth/meow-os/zz-meow-plymouth /opt/meow-os/share/early-splash/theme/zz-meow-plymouth
install -m 0644 assets/boot/meow-boot-landscape.png /opt/meow-os/share/early-splash/assets/meow-boot-landscape.png
install -m 0644 assets/boot/meow-boot-portrait.png /opt/meow-os/share/early-splash/assets/meow-boot-portrait.png
install -m 0755 systemd/vt_mode.py /opt/meow-os/vt_mode.py
install -m 0644 systemd/meow-os.service /etc/systemd/system/meow-os.service
install -m 0644 systemd/meow-charge-enable.service /etc/systemd/system/meow-charge-enable.service
install -m 0644 systemd/meow-nvme-mount@.service /etc/systemd/system/meow-nvme-mount@.service
install -m 0644 config/display.conf /etc/meow-os/display.conf
install -m 0644 config/eglfs-kms.json /opt/meow-os/eglfs-kms.json
install -m 0644 config/asound.conf /etc/asound.conf
install -m 0644 polkit/49-meow-os-network.rules /etc/polkit-1/rules.d/49-meow-os-network.rules
install -m 0644 polkit/49-meow-os-network.pkla /etc/polkit-1/localauthority/50-local.d/49-meow-os-network.pkla
install -m 0644 udev/99-meow-os-input.rules /etc/udev/rules.d/99-meow-os-input.rules
install -m 0644 udev/90-meow-nvme-data.rules /etc/udev/rules.d/90-meow-nvme-data.rules
printf 'NAME="Meow OS"\nVERSION="%s"\nID=meow-os\nPRETTY_NAME="Meow OS %s"\n' "$VERSION" "$VERSION" > /etc/meow-os-release
printf '%s\n' "$SOURCE_HASH" > /etc/meow-os/build.sha256

usermod -aG input,video,render,audio,i2c,netdev radxa
systemctl daemon-reload
udevadm control --reload-rules
systemctl enable meow-os.service
systemctl enable meow-charge-enable.service
/opt/meow-os/bin/configure-boot-branding
/opt/meow-os/bin/install-early-splash
for partition in /dev/nvme*n*p[0-9]; do
    [ -b "$partition" ] || continue
    if command -v mountpoint >/dev/null 2>&1 && mountpoint -q /data; then
        break
    fi
    systemctl start "meow-nvme-mount@$(basename "$partition").service" || true
    break
done
