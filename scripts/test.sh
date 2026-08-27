#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

printf '%s\n' '[1/5] shell syntax'
sh -n scripts/install-live.sh scripts/mount-nvme-data scripts/meow-display-launcher scripts/meow-wait-display scripts/configure-boot-branding scripts/install-early-splash scripts/meow-mindustry-launch.sh

printf '%s\n' '[2/5] required deployment files'
for file in scripts/mount-nvme-data systemd/meow-nvme-mount@.service udev/90-meow-nvme-data.rules; do
    test -f "$file"
done
test -f config/hardware-profiles/a5e.env
test -f config/hardware-profiles/a733-generic.env
test -f systemd/meow-mindustry.service
test -f config/meow-mindustry-sudoers
grep -q 'meow-mindustry-sudoers' scripts/install-live.sh
grep -q '/bin/systemctl --no-block start meow-mindustry.service' config/meow-mindustry-sudoers
grep -q 'NoNewPrivileges=false' systemd/meow-os.service
grep -q 'QProcess::execute(QStringLiteral("sudo")' src/systembackend.cpp
grep -q 'QStringLiteral("--no-block")' src/systembackend.cpp
grep -q 'QStringLiteral("/bin/systemctl")' src/systembackend.cpp
grep -q 'x11-xserver-utils xinput xserver-xorg-input-libinput' scripts/install-live.sh
grep -q 'xrandr --output "$OUTPUT" --rotate left' scripts/meow-mindustry-launch.sh
grep -q 'Coordinate Transformation Matrix' scripts/meow-mindustry-launch.sh
grep -q 'TERMINATING=1' scripts/meow-mindustry-launch.sh
grep -q -- '-width 1280 -height 800 -maximized false -testMobile' scripts/meow-mindustry-launch.sh
grep -q 'SDL_TOUCH_MOUSE_EVENTS=1' scripts/meow-mindustry-launch.sh
! grep -q 'SDL_MOUSE_TOUCH_EVENTS=1' scripts/meow-mindustry-launch.sh
grep -q 'command -v onboard' scripts/install-live.sh
grep -q 'command -v fcitx5' scripts/install-live.sh
grep -q 'dpkg-query -W' scripts/install-live.sh
grep -q 'onboard -D 0' scripts/meow-mindustry-launch.sh
grep -q 'org.onboard.Onboard.Keyboard.Hide' scripts/meow-mindustry-launch.sh
grep -q 'org.onboard.Onboard.Keyboard.Show' scripts/meow-mindustry-launch.sh
grep -q 'xwininfo -root -tree' scripts/meow-mindustry-launch.sh
grep -q 'XMODIFIERS=@im=fcitx' scripts/meow-mindustry-launch.sh
grep -q 'HOME=/home/radxa' scripts/meow-mindustry-launch.sh
grep -q 'Name=pinyin' scripts/install-live.sh
grep -q 'preventStealing: true' qml/components/IosSwitch.qml
! grep -q 'Behavior on color' qml/components/IosSwitch.qml
grep -q 'switchRoot.toggled(!switchRoot.checked)' qml/components/IosSwitch.qml
grep -q 'systemBackend.keepScreenOnApps.indexOf' qml/apps/SettingsApp.qml
grep -q 'appId: "mindustry", title: "像素工厂"' qml/apps/SettingsApp.qml
grep -q 'model.appId === "mindustry"' qml/Main.qml
grep -q 'window.launchMindustryDirect()' qml/Main.qml
grep -q 'startInMindustry' qml/Main.qml
grep -q 'qrc:/assets/icons/mindustry.png' qml/Main.qml
grep -q 'assets/icons/mindustry.png' qml.qrc
test -f assets/icons/mindustry.png
! grep -q 'mindustryComponent' qml/Main.qml
! grep -q 'MindustryApp.qml' qml.qrc

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
grep -q 'maximumFlickVelocity' qml/components/SettingsFlickable.qml
grep -q 'pressDelay: 90' qml/components/SettingsFlickable.qml
grep -q 'stack.depth > 1' qml/Main.qml
grep -q 'inputLimit2400mA = 0x17' src/systembackend.cpp
grep -q 'chargeCurrent2400mA = 0x28' src/systembackend.cpp
grep -q 'reg05 & 0xcf' src/systembackend.cpp
grep -q 'zap-green.svg' qml.qrc
grep -q 'visible: !systemBackend.batteryCharging' qml/apps/SettingsApp.qml
grep -q 'readonly property bool settingsForeground' qml/Main.qml
grep -q 'running: window.settingsForeground && window.lastSettingsSection === "performance"' qml/apps/SettingsApp.qml
grep -q 'boundsBehavior: Flickable.DragAndOvershootBounds' qml/components/SettingsFlickable.qml
grep -q 'PerformanceCpuCard' qml/apps/SettingsApp.qml
grep -q 'PerformanceRamGpuCard' qml/apps/SettingsApp.qml
grep -q 'PerformanceCoreMatrix' qml/apps/SettingsApp.qml
grep -q 'IosSwitch' qml/components/qmldir
grep -q 'PerformanceCpuCard' qml/components/qmldir
! grep -q 'id: pagePrewarm' qml/apps/SettingsApp.qml
test "$(grep -c 'PageLoader; active: false' qml/apps/SettingsApp.qml)" -eq 8
test "$(grep -c 'PageLoader; active: false; asynchronous: true' qml/apps/SettingsApp.qml)" -eq 8
grep -q 'function openSection(name, index)' qml/apps/SettingsApp.qml
grep -q 'prewarmTimer' qml/apps/SettingsApp.qml
grep -q 'settings-switch' qml/apps/SettingsApp.qml
grep -q 'qaSwitchTimer' qml/apps/SettingsApp.qml
! grep -q '驱动未提供忙碌率' qml/apps/SettingsApp.qml
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

printf '%s\n' '[2a/5] runtime kernel and HAL contract'
test -f src/runtime/task_scheduler.cpp
test -f src/runtime/app_session.cpp
test -f src/hal/hal_interfaces.h
test -f docs/MEOW_RUNTIME_ARCHITECTURE.md
test -x scripts/build-linux.sh
if [ "$(uname -s)" = Linux ]; then
    c++ -std=c++11 -Wall -Wextra -Werror -pthread \
        -Isrc tools/test-runtime.cpp src/runtime/task_scheduler.cpp \
        src/hal/hal_interfaces.cpp \
        src/runtime/app_session.cpp -o /tmp/meow-runtime-test
    /tmp/meow-runtime-test
fi

if [ "$(uname -s)" = Linux ]; then
    "${CXX:-c++}" -std=c++11 -Wall -Wextra -Werror tools/sgm41511-registers.cpp -o /tmp/sgm41511-registers-test
fi

grep -q 'meow-nvme-mount@' scripts/install-live.sh

printf '%s\n' '[3/5] qmake and C++ build'
QMAKE_BIN=$(command -v qmake || command -v qmake-qt5 || true)
if [ -n "$QMAKE_BIN" ]; then
    BUILD_TMP=$(mktemp -d "${TMPDIR:-/tmp}/meow-build.XXXXXX")
    trap 'rm -rf "$BUILD_TMP"' EXIT
    "$QMAKE_BIN" meow-os.pro -o "$BUILD_TMP/Makefile"
    make -C "$BUILD_TMP" -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"
    test -x "$BUILD_TMP/meow-os"
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
