#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

printf '%s\n' '[1/5] shell syntax'
sh -n scripts/install-live.sh scripts/mount-nvme-data scripts/meow-display-launcher scripts/meow-wait-display scripts/configure-boot-branding scripts/install-early-splash

printf '%s\n' '[2/5] required deployment files'
for file in scripts/mount-nvme-data systemd/meow-nvme-mount@.service udev/90-meow-nvme-data.rules; do
    test -f "$file"
done
test -f config/hardware-profiles/a5e.env
test -f config/hardware-profiles/a733-generic.env

grep -q 'MEOW_QPA_PLATFORM=eglfs' config/display.conf
VERSION_VALUE=$(cat VERSION)
HEADER_VERSION=$(sed -n 's/^#define MEOW_OS_VERSION "\([^"]*\)"/\1/p' src/version.h)
test "$VERSION_VALUE" = "$HEADER_VERSION"
printf '%s\n' "$VERSION_VALUE" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'
grep -q 'Source changed but version is still' scripts/install-live.sh
grep -q 'quality-gate.sh' scripts/install-live.sh
test -x scripts/bump-version
test -x scripts/quality-gate.sh
grep -q 'hardwareCapabilities' src/systembackend.h
grep -q 'calibrateBattery' src/systembackend.h
grep -q 'QT_QUICK_BACKEND' scripts/meow-display-launcher
grep -q 'performanceHistory' src/systembackend.h
grep -q 'cpuFrequencies' src/systembackend.h
grep -q 'maximumFlickVelocity' qml/Main.qml
grep -q 'pressDelay: 0' qml/Main.qml
grep -q 'stack.depth > 1' qml/Main.qml
grep -q 'inputLimit2400mA = 0x17' src/systembackend.cpp
grep -q 'chargeCurrent2400mA = 0x28' src/systembackend.cpp
grep -q 'reg05 & 0xcf' src/systembackend.cpp
grep -q 'zap-green.svg' qml.qrc
grep -q 'visible: !systemBackend.batteryCharging' qml/Main.qml
grep -q 'readonly property bool settingsForeground' qml/Main.qml
grep -q 'running: window.settingsForeground && window.lastSettingsSection === "performance"' qml/Main.qml
grep -q 'boundsBehavior: Flickable.DragAndOvershootBounds' qml/Main.qml
grep -q 'id: performanceReturnTimer' qml/Main.qml
grep -q 'performanceFlick.returnToBounds()' qml/Main.qml
! grep -q 'id: pagePrewarm' qml/Main.qml
test "$(grep -c 'PageLoader; active: false' qml/Main.qml)" -eq 9
test "$(grep -c 'PageLoader; active: false; asynchronous: true' qml/Main.qml)" -eq 9
grep -q 'function openSection(name, index)' qml/Main.qml
grep -q 'prewarmTimer' qml/Main.qml
grep -q 'settings-switch' qml/Main.qml
grep -q 'qaSwitchTimer' qml/Main.qml
! grep -q '驱动未提供忙碌率' qml/Main.qml
grep -q '\$1 == "timeout" { \$2 = "0" }' scripts/configure-boot-branding
grep -q 'U_BOOT_TIMEOUT=' scripts/configure-boot-branding
grep -q 'mask hdmi-toggle-once.service' scripts/configure-boot-branding
grep -q 'plymouth.ignore-serial-consoles' scripts/configure-boot-branding
grep -q 'plymouth quit --retain-splash' systemd/meow-os.service
grep -q 'plymouth-themes' scripts/install-early-splash
grep -q 'init-top-meow-plymouth' scripts/install-live.sh
test -f plymouth/meow-os/meow-os.plymouth
test -x plymouth/meow-os/init-top-meow-plymouth
test -x plymouth/meow-os/init-premount-meow-plymouth
test -x plymouth/meow-os/zz-meow-plymouth
test -f assets/boot/meow-boot-landscape.png
test -f assets/boot/meow-boot-portrait.png

if [ "$(uname -s)" = Linux ]; then
    "${CXX:-c++}" -std=c++11 -Wall -Wextra -Werror tools/sgm41511-registers.cpp -o /tmp/sgm41511-registers-test
fi

grep -q 'meow-nvme-mount@' scripts/install-live.sh

printf '%s\n' '[3/5] qmake and C++ build'
QMAKE_BIN=$(command -v qmake || command -v qmake-qt5 || true)
if [ -n "$QMAKE_BIN" ]; then
    "$QMAKE_BIN" meow-os.pro -o Makefile
    make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"
    test -x meow-os
else
    printf '%s\n' 'qmake not installed locally; build is covered by the device deployment check.'
fi

printf '%s\n' '[4/5] QML resource compilation'
RCC_BIN=$(command -v rcc || command -v rcc-qt5 || true)
if [ -n "$RCC_BIN" ]; then
    "$RCC_BIN" -name qml qml.qrc -o /tmp/meow-qml-test.cpp
    test -s /tmp/meow-qml-test.cpp
else
    printf '%s\n' 'rcc not installed locally; QML resource compilation is covered by the device deployment check.'
fi

printf '%s\n' '[5/5] completed'
printf '%s\n' 'All automated checks passed.'
