import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    visible: true
    visibility: Window.FullScreen
    width: 800
    height: 1280
    title: "Meow OS"
    color: "#000000"

    property int uiRotation: systemBackend.displayRotation
    property int statusBarHeight: 56
    property color canvas: "#F5F4F8"
    property color card: "#FFFFFF"
    property color ink: "#27222D"
    property color secondary: "#77717D"
    property color separator: "#E7E3EA"
    property color pink: "#FF7FA7"
    property color purple: "#7B6DF0"
    property color mint: "#49B990"
    property string uiFont: "Noto Sans CJK SC"
    property string clockTime: "--:--"
    property string clockDate: ""
    property int tapCount: 0
    property string initialSettingsSection: Qt.application.arguments.indexOf("--sound") >= 0 ? "sound" : "battery"
    property bool startInSettings: Qt.application.arguments.indexOf("--settings") >= 0
                                   || Qt.application.arguments.indexOf("--sound") >= 0

    function updateClock() {
        var now = new Date()
        var week = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        clockTime = Qt.formatDateTime(now, "HH:mm")
        clockDate = Qt.formatDateTime(now, "M月d日") + " " + week[now.getDay()]
    }

    function openApp(appId) {
        if (appId === "touch-test") stack.push(touchTestComponent)
        else if (appId === "settings") stack.push(settingsComponent)
    }

    function batteryStateText(status) {
        if (status === "Charging") return "正在充电"
        if (status === "Discharging") return "正在使用电池"
        if (status === "Full") return "已充满"
        if (status === "Not charging") return "已暂停充电"
        return status.length ? status : "无法读取"
    }

    function temperatureZoneText(zone) {
        if (zone === "cold") return "过冷"
        if (zone === "cool") return "偏冷"
        if (zone === "normal") return "正常"
        if (zone === "warm") return "偏热"
        if (zone === "hot") return "过热"
        return "等待驱动"
    }

    ListModel {
        id: appRegistry
        ListElement { appId: "touch-test"; appTitle: "点击测试"; iconSource: "qrc:/assets/icons/mouse-pointer-click.svg"; accent: "#FF7FA7" }
        ListElement { appId: "settings"; appTitle: "设置"; iconSource: "qrc:/assets/icons/settings.svg"; accent: "#7B6DF0" }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: window.updateClock()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: systemBackend.refreshStatus()
    }

    Item {
        id: scene
        width: Math.abs(window.uiRotation) === 90 ? window.height : window.width
        height: Math.abs(window.uiRotation) === 90 ? window.width : window.height
        x: window.uiRotation === -90 ? 0 : (window.uiRotation === 90 ? window.width : 0)
        y: window.uiRotation === -90 ? window.height : 0
        rotation: window.uiRotation
        transformOrigin: Item.TopLeft
        focus: true
        Keys.onEscapePressed: if (stack.depth > 1) stack.pop()

        Rectangle { anchors.fill: parent; color: window.canvas }

        StatusBar {
            id: statusBar
            z: 800
            anchors { left: parent.left; right: parent.right; top: parent.top }
            visible: !splash.visible
        }

        StackView {
            id: stack
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; topMargin: window.statusBarHeight }
            initialItem: window.startInSettings ? settingsComponent : homeComponent
            pushEnter: Transition {}
            pushExit: Transition {}
            popEnter: Transition {}
            popExit: Transition {}
        }

        MouseArea {
            z: 900
            visible: stack.depth > 1 && !splash.visible
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: window.statusBarHeight }
            width: 34
            property real pressX: 0
            onPressed: pressX = mouse.x
            onReleased: if (mouse.x - pressX > 92) stack.pop()
        }

        Rectangle {
            id: splash
            z: 1000
            anchors.fill: parent
            color: "#FFF9FB"
            visible: true

            Image {
                id: splashAvatar
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -34
                width: 220; height: 220
                source: "qrc:/assets/meowkj-avatar-circle.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
            Text {
                anchors { horizontalCenter: parent.horizontalCenter; top: splashAvatar.bottom; topMargin: 30 }
                text: "Meow OS " + systemBackend.version
                color: window.ink
                font.family: window.uiFont; font.pixelSize: 32; font.weight: Font.DemiBold
            }
            Timer { interval: 900; running: true; onTriggered: splash.visible = false }
        }
    }

    Component {
        id: homeComponent
        Rectangle {
            color: window.canvas

            Grid {
                id: appGrid
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -12
                columns: Math.max(1, Math.min(5, appRegistry.count))
                spacing: 30

                Repeater {
                    model: appRegistry
                    delegate: AppLauncher {
                        title: model.appTitle
                        icon: model.iconSource
                        accentColor: model.accent
                        onClicked: window.openApp(model.appId)
                    }
                }
            }

            Text {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 24 }
                text: "Meow OS " + systemBackend.version
                color: "#9B949F"
                font.family: window.uiFont; font.pixelSize: 13; font.letterSpacing: 1.3
            }
        }
    }

    Component {
        id: touchTestComponent
        Rectangle {
            color: window.canvas

            Rectangle {
                id: touchPad
                anchors.fill: parent
                anchors.margins: 28
                radius: 28
                color: "#FFF8FA"
                border.color: "#FFB6CC"
                border.width: 2
                property int activeTouches: (p1.pressed ? 1 : 0) + (p2.pressed ? 1 : 0) + (p3.pressed ? 1 : 0) + (p4.pressed ? 1 : 0)

                MultiPointTouchArea {
                    anchors.fill: parent
                    mouseEnabled: false
                    onReleased: if (touchPoints.length > 0) window.tapCount += touchPoints.length
                    touchPoints: [TouchPoint { id: p1 }, TouchPoint { id: p2 }, TouchPoint { id: p3 }, TouchPoint { id: p4 }]
                    Repeater {
                        model: [p1, p2, p3, p4]
                        delegate: Rectangle {
                            visible: modelData.pressed
                            x: modelData.x - width / 2; y: modelData.y - height / 2
                            width: 68; height: 68; radius: 34
                            color: index % 2 ? window.purple : window.pink
                            opacity: 0.78; border.color: "white"; border.width: 5
                            Text { anchors.centerIn: parent; text: index + 1; color: "white"; font.pixelSize: 18; font.weight: Font.DemiBold }
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: touchPad.activeTouches === 0 ? "请触摸或拖动" : (touchPad.activeTouches === 1 ? "单指位置正确" : touchPad.activeTouches + " 个触点"); color: window.ink; font.family: window.uiFont; font.pixelSize: 36; font.weight: Font.DemiBold }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "逻辑坐标 1280 × 800 · 累计 " + window.tapCount + " 次"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 18 }
                }
            }

            Row {
                z: 100
                anchors { left: parent.left; top: parent.top; leftMargin: 44; topMargin: 42 }
                spacing: 10
                CompactBackButton { onClicked: stack.pop() }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "点击测试"; color: window.ink; font.family: window.uiFont; font.pixelSize: 22; font.weight: Font.DemiBold }
            }

            Button {
                z: 100
                anchors { right: parent.right; top: parent.top; rightMargin: 44; topMargin: 46 }
                text: "清除轨迹"
                font.family: window.uiFont; font.pixelSize: 17
                onClicked: window.tapCount = 0
            }
        }
    }

    Component {
        id: settingsComponent
        Rectangle {
            id: settingsPage
            color: window.canvas
            property string section: window.initialSettingsSection
            readonly property int sectionIndex: section === "wifi" ? 0
                                                : section === "battery" ? 1
                                                : section === "sound" ? 2
                                                : section === "ch592" ? 3
                                                : section === "display" ? 4
                                                : section === "storage" ? 5 : 6

            Rectangle {
                id: settingsSidebar
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 24 }
                width: 318; radius: 26; color: window.card

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 5

                    Row {
                        height: 62
                        spacing: 8
                        CompactBackButton { anchors.verticalCenter: parent.verticalCenter; onClicked: stack.pop() }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "设置"; color: window.ink; font.family: window.uiFont; font.pixelSize: 25; font.weight: Font.DemiBold }
                    }

                    SettingsNavRow { title: "Wi-Fi"; icon: "qrc:/assets/icons/wifi.svg"; accent: window.mint; selected: settingsPage.section === "wifi"; onClicked: settingsPage.section = "wifi" }
                    SettingsNavRow { title: "电池"; icon: "qrc:/assets/icons/battery-charging.svg"; accent: "#F1A244"; selected: settingsPage.section === "battery"; onClicked: settingsPage.section = "battery" }
                    SettingsNavRow { title: "声音"; icon: "qrc:/assets/icons/volume-2.svg"; accent: window.pink; selected: settingsPage.section === "sound"; onClicked: settingsPage.section = "sound" }
                    SettingsNavRow { title: "隔空喵传"; icon: "qrc:/assets/icons/cpu.svg"; accent: window.mint; selected: settingsPage.section === "ch592"; onClicked: settingsPage.section = "ch592" }
                    SettingsNavRow { title: "显示与触摸"; icon: "qrc:/assets/icons/monitor.svg"; accent: window.purple; selected: settingsPage.section === "display"; onClicked: settingsPage.section = "display" }
                    SettingsNavRow { title: "存储空间"; icon: "qrc:/assets/icons/hard-drive.svg"; accent: "#5E93E8"; selected: settingsPage.section === "storage"; onClicked: settingsPage.section = "storage" }
                    SettingsNavRow { title: "关于本机"; icon: "qrc:/assets/icons/info.svg"; accent: "#8B8490"; selected: settingsPage.section === "about"; onClicked: settingsPage.section = "about" }
                }
            }

            Rectangle {
                anchors { left: settingsSidebar.right; right: parent.right; top: parent.top; bottom: parent.bottom; leftMargin: 18; rightMargin: 24; topMargin: 24; bottomMargin: 24 }
                radius: 26; color: window.card; clip: true
                StackLayout {
                    anchors.fill: parent
                    currentIndex: settingsPage.sectionIndex
                    Loader { active: true; sourceComponent: wifiSettings }
                    Loader { active: true; sourceComponent: batterySettings }
                    Loader { active: true; sourceComponent: soundSettings }
                    Loader { active: true; sourceComponent: ch592Settings }
                    Loader { active: true; sourceComponent: displaySettings }
                    Loader { active: true; sourceComponent: storageSettings }
                    Loader { active: true; sourceComponent: aboutSettings }
                }
            }
        }
    }

    Component {
        id: wifiSettings
        Item {
            Column {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 30 }
                spacing: 14
                RowLayout {
                    width: parent.width
                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Wi-Fi"; color: window.ink; font.family: window.uiFont; font.pixelSize: 34; font.weight: Font.Bold }
                        Text { text: systemBackend.wifiConnected ? "已连接到 " + systemBackend.wifiName : "未连接"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 18 }
                    }
                    Button { text: "重新扫描"; onClicked: systemBackend.scanWifi() }
                }
                Rectangle { width: parent.width; height: 1; color: window.separator }
                Flickable {
                    width: parent.width; height: 500; contentHeight: wifiList.height; clip: true
                    Column {
                        id: wifiList; width: parent.width
                        Repeater {
                            model: systemBackend.wifiNetworks
                            delegate: Rectangle {
                                width: parent.width; height: 64; color: "transparent"
                                RowLayout {
                                    anchors.fill: parent; spacing: 12
                                    Text { text: modelData.active ? "✓" : ""; color: window.mint; font.pixelSize: 22; Layout.preferredWidth: 24 }
                                    Text { text: modelData.ssid; color: window.ink; font.family: window.uiFont; font.pixelSize: 20; elide: Text.ElideRight; Layout.fillWidth: true }
                                    Text { text: modelData.security; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14 }
                                    Text { text: modelData.signal + "%"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 15; Layout.preferredWidth: 48 }
                                }
                                Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 36 } height: 1; color: window.separator }
                                MouseArea { anchors.fill: parent; enabled: !modelData.active; onClicked: { passwordDialog.ssid = modelData.ssid; passwordDialog.open() } }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: batterySettings
        SettingsPageBody {
            title: "电池"
            subtitle: systemBackend.batteryAvailable ? window.batteryStateText(systemBackend.batteryStatus)
                                                      : (systemBackend.chargerAvailable ? "充电管理已连接，电量监测未连接" : "暂未检测到电池硬件")
            RowLayout {
                width: parent.width
                spacing: 28
                Item {
                    Layout.preferredWidth: 238; Layout.preferredHeight: 118
                    Rectangle {
                        id: detailBatteryBody
                        x: 5; y: 7; width: 214; height: 104; radius: 22
                        color: "#E5E5EA"
                        border.width: 5
                        border.color: systemBackend.batteryCharging
                                      ? "#34C759"
                                      : (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 20
                                         ? "#FF3B30"
                                         : (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 40
                                            ? "#FFCC00" : "#C7C7CC"))
                        clip: true
                        Rectangle {
                            id: detailBatteryFill
                            x: 8; y: 8; height: detailBatteryBody.height - 16
                            width: systemBackend.batteryPercent >= 0
                                   ? (detailBatteryBody.width - 16) * systemBackend.batteryPercent / 100 : 0
                            radius: 14
                            color: systemBackend.batteryCharging
                                   ? "#34C759"
                                   : (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 20
                                      ? "#FF3B30"
                                      : (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 40
                                         ? "#FFCC00" : "#4B4650"))
                        }
                        Image {
                            visible: systemBackend.batteryCharging
                            x: 44; anchors.verticalCenter: parent.verticalCenter
                            width: 26; height: 26
                            source: "qrc:/assets/icons/zap-white.svg"
                            sourceSize.width: 52; sourceSize.height: 52
                        }
                        Text {
                            x: systemBackend.batteryCharging ? 20 : 0
                            width: parent.width - x; height: parent.height
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: systemBackend.batteryPercent >= 0 ? systemBackend.batteryPercent + "%" : "--"
                            color: "#3A3540"
                            font.family: window.uiFont; font.pixelSize: 36; font.weight: Font.Bold
                        }
                        Item {
                            x: 0; y: 0
                            width: detailBatteryFill.x + detailBatteryFill.width
                            height: detailBatteryBody.height
                            clip: true
                            Text {
                                x: systemBackend.batteryCharging ? 20 : 0
                                width: detailBatteryBody.width - x; height: detailBatteryBody.height
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: systemBackend.batteryPercent >= 0 ? systemBackend.batteryPercent + "%" : "--"
                                color: !systemBackend.batteryCharging
                                       && systemBackend.batteryPercent > 20
                                       && systemBackend.batteryPercent <= 40
                                       ? "#3A3540" : "white"
                                font.family: window.uiFont; font.pixelSize: 36; font.weight: Font.Bold
                            }
                        }
                    }
                    Rectangle {
                        x: 223; y: 44; width: 9; height: 30; radius: 4
                        color: systemBackend.batteryCharging ? "#34C759" : "#C7C7CC"
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 7
                    Text { text: window.batteryStateText(systemBackend.batteryStatus); color: window.ink; font.family: window.uiFont; font.pixelSize: 27; font.weight: Font.DemiBold }
                    Text { text: systemBackend.batteryTemperatureC > -100 ? "电池温度  " + systemBackend.batteryTemperatureC.toFixed(1) + " °C" : "电池温度  --"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 18 }
                }
            }
            IosGroup {
                width: parent.width
                IosInfoRow { height: 54; label: "状态"; value: window.batteryStateText(systemBackend.batteryStatus) }
                IosInfoRow { height: 54; label: "实时功率"; value: systemBackend.batteryPowerW >= 0 ? systemBackend.batteryPowerW.toFixed(2) + " W" : "--" }
                IosInfoRow { height: 54; label: "电压"; value: systemBackend.batteryVoltageMv >= 0 ? (systemBackend.batteryVoltageMv / 1000).toFixed(3) + " V" : "--" }
                IosInfoRow { height: 54; label: "电流"; value: systemBackend.batteryAvailable ? systemBackend.batteryCurrentMa + " mA" : "--" }
                IosInfoRow { height: 54; label: "电池温度"; value: systemBackend.batteryTemperatureC > -100 ? systemBackend.batteryTemperatureC.toFixed(1) + " °C" : "--" }
                IosInfoRow { height: 54; label: "外部电源"; value: systemBackend.chargerAvailable ? (systemBackend.externalPowerPresent ? "已接入" : "未接入") : "--" }
                IosInfoRow { height: 54; label: "温度保护"; value: window.temperatureZoneText(systemBackend.chargeTemperatureZone); last: true }
            }
        }
    }

    Component {
        id: soundSettings
        SettingsPageBody {
            title: "声音"
            subtitle: systemBackend.audioAvailable ? "内置扬声器已就绪" : "音频输出尚未就绪"
            IosGroup {
                width: parent.width
                IosInfoRow { label: "输出设备"; value: systemBackend.audioAvailable ? "内置扬声器" : "--" }
                IosInfoRow { label: "主音量"; value: systemBackend.volumePercent >= 0 ? systemBackend.volumePercent + "%" : "--"; last: true }
            }
            Rectangle {
                width: parent.width; height: 132; radius: 18
                color: "#F9F9FB"; border.color: window.separator; border.width: 1
                Column {
                    anchors.fill: parent; anchors.margins: 18; spacing: 14
                    RowLayout {
                        width: parent.width
                        Text { text: "音量"; color: window.ink; font.family: window.uiFont; font.pixelSize: 19; font.weight: Font.DemiBold; Layout.fillWidth: true }
                        Text { text: systemBackend.volumePercent >= 0 ? systemBackend.volumePercent + "%" : "--"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 18; font.weight: Font.DemiBold }
                    }
                    RowLayout {
                        width: parent.width; spacing: 15
                        Image { Layout.preferredWidth: 25; Layout.preferredHeight: 25; source: "qrc:/assets/icons/volume-2.svg"; sourceSize.width: 50; sourceSize.height: 50; opacity: volumeSlider.enabled ? 1 : 0.3 }
                        Slider {
                            id: volumeSlider
                            Layout.fillWidth: true; Layout.preferredHeight: 34
                            from: 0; to: 100; stepSize: 1; live: true
                            enabled: systemBackend.audioAvailable
                            value: systemBackend.volumePercent >= 0 ? systemBackend.volumePercent : 0
                            onMoved: systemBackend.setVolume(Math.round(value))
                            onPressedChanged: if (!pressed && enabled) systemBackend.playVolumeFeedback()
                            background: Rectangle {
                                x: volumeSlider.leftPadding
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                width: volumeSlider.availableWidth; height: 7; radius: 4
                                color: "#DEDCE2"
                                Rectangle {
                                    width: volumeSlider.visualPosition * parent.width; height: parent.height; radius: parent.radius
                                    color: window.purple
                                }
                            }
                            handle: Rectangle {
                                x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                width: 26; height: 26; radius: 13
                                color: "white"; border.color: "#D2CFD7"; border.width: 1
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: ch592Settings
        SettingsPageBody {
            title: "隔空喵传"
            subtitle: "USB IAP 服务待接入"
            IosGroup {
                width: parent.width
                IosInfoRow { label: "正常更新"; value: "无需按 BOOT" }
                IosInfoRow { label: "首次烧录 / 救砖"; value: "物理 BOOT 或 SWD"; last: true }
            }
        }
    }

    Component {
        id: displaySettings
        SettingsPageBody {
            title: "显示与触摸"
            subtitle: "WX101 · JD9366TC"
            IosGroup {
                width: parent.width
                IosInfoRow { label: "逻辑分辨率"; value: "1280 × 800" }
                IosInfoRow { label: "物理分辨率"; value: "800 × 1280" }
                IosInfoRow { label: "输出方向"; value: "逆时针 90°"; last: true }
            }
        }
    }

    Component {
        id: storageSettings
        SettingsPageBody {
            title: "存储空间"
            subtitle: systemBackend.diskUsed + " 已使用，共 " + systemBackend.diskTotal
            ProgressBar { width: parent.width; from: 0; to: 100; value: systemBackend.diskPercent }
            IosGroup {
                width: parent.width
                IosInfoRow { label: "已使用"; value: systemBackend.diskUsed }
                IosInfoRow { label: "总容量"; value: systemBackend.diskTotal }
                IosInfoRow { label: "使用比例"; value: systemBackend.diskPercent + "%"; last: true }
            }
        }
    }

    Component {
        id: aboutSettings
        SettingsPageBody {
            title: "关于本机"
            subtitle: "Radxa Cubie A5E"
            RowLayout {
                width: parent.width; spacing: 22
                Image { Layout.preferredWidth: 112; Layout.preferredHeight: 112; source: "qrc:/assets/meowkj-avatar-circle.png"; fillMode: Image.PreserveAspectFit; smooth: true }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4
                    Text { text: "Meow OS"; color: window.ink; font.family: window.uiFont; font.pixelSize: 30; font.weight: Font.Bold }
                    Text { text: "为这台设备打造"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 17 }
                }
            }
            IosGroup {
                width: parent.width
                IosInfoRow { label: "系统版本"; value: "Meow OS " + systemBackend.version }
                IosInfoRow { label: "主机名"; value: systemBackend.hostname }
                IosInfoRow { label: "Linux 内核"; value: systemBackend.kernel; last: true }
            }
        }
    }

    Dialog {
        id: passwordDialog
        property string ssid: ""
        parent: scene; anchors.centerIn: parent; width: 500; modal: true
        title: "连接到 “" + ssid + "”"
        standardButtons: Dialog.Ok | Dialog.Cancel
        contentItem: TextField { id: wifiPassword; placeholderText: "Wi-Fi 密码"; echoMode: TextInput.Password; font.family: window.uiFont; font.pixelSize: 20 }
        onAccepted: { systemBackend.connectWifi(ssid, wifiPassword.text); wifiPassword.text = "" }
    }

    component StatusBar: Rectangle {
        height: window.statusBarHeight
        color: "#FCFBFD"
        border.color: window.separator
        border.width: 1

        Row {
            anchors { left: parent.left; leftMargin: 34; verticalCenter: parent.verticalCenter }
            spacing: 16
            Text { text: window.clockTime; color: window.ink; font.family: window.uiFont; font.pixelSize: 18; font.weight: Font.DemiBold }
            Text { text: window.clockDate; color: window.secondary; font.family: window.uiFont; font.pixelSize: 17 }
        }

        Row {
            anchors { right: parent.right; rightMargin: 34; verticalCenter: parent.verticalCenter }
            spacing: 18

            Image {
                width: 25; height: 25
                source: "qrc:/assets/icons/wifi.svg"
                sourceSize.width: 50; sourceSize.height: 50
                opacity: systemBackend.wifiConnected ? 1 : 0.28
            }

            Row {
                spacing: 6
                Image { width: 25; height: 25; source: "qrc:/assets/icons/volume-2.svg"; sourceSize.width: 50; sourceSize.height: 50; opacity: systemBackend.volumePercent >= 0 ? 1 : 0.28 }
                Text { anchors.verticalCenter: parent.verticalCenter; text: systemBackend.volumePercent >= 0 ? systemBackend.volumePercent + "%" : "--"; color: window.ink; font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.Medium }
            }

            Item {
                id: statusBattery
                width: 64; height: 30
                property color trackColor: "#E5E5EA"
                property color outlineColor: systemBackend.batteryCharging
                                             ? "#34C759"
                                             : (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 20
                                                ? "#FF3B30"
                                                : (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 40
                                                   ? "#FFCC00" : "#AAA6AE"))
                property color fillColor: systemBackend.batteryCharging
                                          ? "#34C759"
                                          : (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 20
                                             ? "#FF3B30"
                                             : (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 40
                                                ? "#FFCC00" : "#4B4650"))
                property color fillTextColor: !systemBackend.batteryCharging
                                               && systemBackend.batteryPercent > 20
                                               && systemBackend.batteryPercent <= 40
                                               ? "#3A3540" : "white"

                Rectangle {
                    id: batteryBody
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    width: 56; height: 24; radius: 6
                    color: "transparent"
                    border.width: 2
                    border.color: statusBattery.outlineColor
                    clip: true

                    Rectangle {
                        anchors { fill: parent; margins: 3 }
                        radius: 4
                        color: statusBattery.trackColor
                    }

                    Rectangle {
                        id: batteryFill
                        x: 3; y: 3; height: batteryBody.height - 6
                        width: systemBackend.batteryPercent >= 0
                               ? (batteryBody.width - 6) * systemBackend.batteryPercent / 100 : 0
                        radius: 4
                        color: statusBattery.fillColor
                    }

                    Image {
                        visible: systemBackend.batteryCharging
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 11; height: 14
                        source: "qrc:/assets/icons/zap-white.svg"
                        sourceSize.width: 22; sourceSize.height: 28
                    }

                    Text {
                        x: systemBackend.batteryCharging ? 7 : 0
                        width: parent.width - x; height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: systemBackend.batteryPercent >= 0 ? systemBackend.batteryPercent : "--"
                        color: "#3A3540"
                        font.family: window.uiFont
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }

                    Item {
                        x: 0; y: 0
                        width: batteryFill.x + batteryFill.width
                        height: batteryBody.height
                        clip: true
                        Text {
                            x: systemBackend.batteryCharging ? 7 : 0
                            width: batteryBody.width - x; height: batteryBody.height
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: systemBackend.batteryPercent >= 0 ? systemBackend.batteryPercent : "--"
                            color: statusBattery.fillTextColor
                            font.family: window.uiFont
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                    }
                }

                Rectangle {
                    anchors { left: batteryBody.right; leftMargin: 2; verticalCenter: parent.verticalCenter }
                    width: 4; height: 9; radius: 2
                    color: statusBattery.outlineColor
                }
            }
        }
    }

    component AppLauncher: Item {
        property string title: ""
        property url icon: ""
        property color accentColor: window.purple
        signal clicked()
        width: 160; height: 154

        Column {
            anchors.centerIn: parent
            spacing: 14
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 96; height: 96; radius: 24
                color: accentColor
                Image { anchors.centerIn: parent; width: 52; height: 52; source: icon; sourceSize.width: 104; sourceSize.height: 104; smooth: true }
            }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: title; color: window.ink; font.family: window.uiFont; font.pixelSize: 18; font.weight: Font.Medium }
        }
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
    }

    component CompactBackButton: Item {
        signal clicked()
        width: 52; height: 52
        Rectangle {
            anchors.centerIn: parent
            width: 42; height: 42; radius: 21
            color: backMouse.pressed ? "#E5E1E9" : "#F0EDF3"
            Image { anchors.centerIn: parent; width: 24; height: 24; source: "qrc:/assets/icons/chevron-left.svg"; sourceSize.width: 48; sourceSize.height: 48 }
        }
        MouseArea { id: backMouse; anchors.fill: parent; onClicked: parent.clicked() }
    }

    component SettingsNavRow: Rectangle {
        property string title: ""
        property url icon: ""
        property color accent: window.purple
        property bool selected: false
        signal clicked()
        width: parent.width; height: 58; radius: 14
        color: selected ? "#EEEAFE" : "transparent"
        RowLayout {
            anchors.fill: parent; anchors.margins: 9; spacing: 11
            Rectangle {
                width: 38; height: 38; radius: 10; color: accent
                Image { anchors.centerIn: parent; width: 23; height: 23; source: icon; sourceSize.width: 46; sourceSize.height: 46 }
            }
            Text { text: title; color: window.ink; font.family: window.uiFont; font.pixelSize: 19; Layout.fillWidth: true }
            Text { visible: selected; text: "›"; color: window.purple; font.pixelSize: 24 }
        }
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
    }

    component SettingsPageBody: Column {
        property string title: ""
        property string subtitle: ""
        default property alias content: bodyContent.data
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 30 }
        spacing: 16
        Text { text: parent.title; color: window.ink; font.family: window.uiFont; font.pixelSize: 34; font.weight: Font.Bold }
        Text { width: parent.width; text: parent.subtitle; color: window.secondary; font.family: window.uiFont; font.pixelSize: 18; wrapMode: Text.WordWrap }
        Column { id: bodyContent; width: parent.width; spacing: 18 }
    }

    component IosGroup: Rectangle {
        default property alias content: groupColumn.data
        radius: 18; color: "#F9F9FB"; border.color: window.separator; border.width: 1
        implicitHeight: groupColumn.height
        Column { id: groupColumn; width: parent.width }
    }

    component IosInfoRow: Item {
        property string label: ""
        property string value: ""
        property bool last: false
        width: parent.width; height: 62
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 18
            Text { text: label; color: window.ink; font.family: window.uiFont; font.pixelSize: 18; Layout.fillWidth: true }
            Text { text: value; color: window.secondary; font.family: window.uiFont; font.pixelSize: 17 }
        }
        Rectangle { visible: !last; anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 18 } height: 1; color: window.separator }
    }
}
