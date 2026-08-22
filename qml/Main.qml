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
    property string operationText: ""
    property bool operationSuccess: true
    property bool screenDimmed: false
    property int brightnessBeforeDim: -1
    property int idleDimDelayMs: 90000
    property string lastSettingsSection: ""
    property string initialSettingsSection: Qt.application.arguments.indexOf("--ethernet") >= 0
                                            ? "ethernet"
                                            : (Qt.application.arguments.indexOf("--wifi") >= 0
                                            || Qt.application.arguments.indexOf("--wifi-keyboard") >= 0
                                            || Qt.application.arguments.indexOf("--wifi-keyboard-symbols") >= 0
                                            ? "wifi"
                                            : (Qt.application.arguments.indexOf("--performance") >= 0
                                               ? "performance"
                                            : (Qt.application.arguments.indexOf("--sound") >= 0
                                               ? "sound"
                                            : (Qt.application.arguments.indexOf("--display") >= 0
                                               ? "display"
                                               : (Qt.application.arguments.indexOf("--storage") >= 0 ? "storage" : "battery")))))
    property bool startInSettings: Qt.application.arguments.indexOf("--settings") >= 0
                                   || Qt.application.arguments.indexOf("--sound") >= 0
                                   || Qt.application.arguments.indexOf("--display") >= 0
                                   || Qt.application.arguments.indexOf("--storage") >= 0
                                   || Qt.application.arguments.indexOf("--wifi") >= 0
                                   || Qt.application.arguments.indexOf("--wifi-keyboard") >= 0
                                   || Qt.application.arguments.indexOf("--wifi-keyboard-symbols") >= 0
                                   || Qt.application.arguments.indexOf("--performance") >= 0
                                   || Qt.application.arguments.indexOf("--ethernet") >= 0

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

    function checkIdleState() {
        if (screenDimmed) {
            if (systemBackend.idleMs() < 3000) restoreBrightness()
            return
        }
        if (systemBackend.idleMs() > idleDimDelayMs) dimScreen()
    }

    function dimScreen() {
        if (screenDimmed || !systemBackend.brightnessAvailable) return
        screenDimmed = true
        brightnessBeforeDim = systemBackend.displayBrightnessPercent >= 0 ? systemBackend.displayBrightnessPercent : 30
        systemBackend.setActiveScope("idle")
        systemBackend.setDisplayBrightness(30)
    }

    function restoreBrightness() {
        if (!screenDimmed) return
        screenDimmed = false
        if (brightnessBeforeDim > 0) systemBackend.setDisplayBrightness(brightnessBeforeDim)
        brightnessBeforeDim = -1
        systemBackend.setActiveScope(lastSettingsSection.length ? lastSettingsSection : "home")
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

    function wifiSignalColor(signal) {
        if (signal >= 75) return "#34C759"
        if (signal >= 45) return "#FF9F0A"
        return "#FF3B30"
    }

    function batteryPowerLabel() {
        if (!systemBackend.batteryAvailable || systemBackend.batteryPowerW < 0) return "--"
        var sign = systemBackend.batteryCharging ? "+" : (systemBackend.batteryCurrentMa < 0 || systemBackend.batteryStatus === "Discharging" ? "−" : "")
        return sign + systemBackend.batteryPowerW.toFixed(1) + " W"
    }

    function batteryPowerColor() {
        if (!systemBackend.batteryAvailable || systemBackend.batteryPowerW < 0) return "#8E8993"
        var watts = systemBackend.batteryPowerW
        if (systemBackend.batteryCharging) {
            if (watts >= 8) return "#248A3D"
            if (watts >= 3) return "#34C759"
            return "#5AC8A0"
        }
        if (systemBackend.batteryStatus === "Full") return "#34C759"
        if (watts >= 6) return "#FF3B30"
        if (watts >= 3) return "#FF9F0A"
        if (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 20) return "#FF3B30"
        if (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 40) return "#FFCC00"
        return "#6F6A74"
    }

    function batteryFillColor() {
        if (systemBackend.batteryCharging) return batteryPowerColor()
        if (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 20) return "#FF3B30"
        if (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 40) return "#FFCC00"
        if (systemBackend.batteryStatus === "Discharging" && systemBackend.batteryPowerW >= 6) return "#FF3B30"
        if (systemBackend.batteryStatus === "Discharging" && systemBackend.batteryPowerW >= 3) return "#FF9F0A"
        return "#4B4650"
    }

    function batteryOutlineColor() {
        if (systemBackend.batteryCharging) return batteryPowerColor()
        if (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 20) return "#FF3B30"
        if (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 40) return "#FFCC00"
        if (systemBackend.batteryStatus === "Discharging" && systemBackend.batteryPowerW >= 3) return batteryPowerColor()
        return "#C7C7CC"
    }

    function ethernetDuplexText(duplex) {
        if (duplex === "full") return "全双工"
        if (duplex === "half") return "半双工"
        return "--"
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
        id: statusRefreshTimer
        interval: window.screenDimmed ? 20000 : 5000
        running: true
        repeat: true
        onTriggered: systemBackend.refreshStatus()
    }

    Timer {
        id: idleWatch
        interval: 5000
        running: true
        repeat: true
        onTriggered: window.checkIdleState()
    }

    Connections {
        target: systemBackend
        function onOperationMessage(message, success) {
            window.operationText = message
            window.operationSuccess = success
            operationToast.open()
        }
        function onInputActivity() {
            if (window.screenDimmed) window.restoreBrightness()
        }
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
            pushEnter: Transition {
                OpacityAnimator { from: 0.55; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
            }
            pushExit: Transition {
                OpacityAnimator { from: 1.0; to: 0.55; duration: 160; easing.type: Easing.InCubic }
            }
            popEnter: Transition {
                OpacityAnimator { from: 0.55; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
            }
            popExit: Transition {
                OpacityAnimator { from: 1.0; to: 0.55; duration: 160; easing.type: Easing.InCubic }
            }
            onDepthChanged: {
                if (depth === 1) {
                    window.lastSettingsSection = ""
                    systemBackend.setActiveScope("home")
                }
            }
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

        Rectangle {
            id: operationToast
            z: 2200
            visible: false
            opacity: 0
            property bool opened: false
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 18 }
            width: toastText.implicitWidth + 56; height: 54; radius: 27
            color: window.operationSuccess ? "#2FAD72" : "#E64B55"
            Text {
                id: toastText
                anchors.centerIn: parent
                text: window.operationText
                color: "white"
                font.family: window.uiFont; font.pixelSize: 17; font.weight: Font.DemiBold
            }
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on anchors.bottomMargin { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            onOpacityChanged: if (!opened && opacity === 0) visible = false

            function open() {
                if (opened) {
                    toastHideTimer.restart()
                    return
                }
                visible = true
                opened = true
                opacity = 1
                anchors.bottomMargin = 40
                toastHideTimer.restart()
            }
            function hide() {
                opened = false
                opacity = 0
                anchors.bottomMargin = 18
                toastHideTimer.stop()
            }
            Timer {
                id: toastHideTimer
                interval: 2400
                onTriggered: operationToast.hide()
            }
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
                                                : section === "ethernet" ? 1
                                                : section === "battery" ? 2
                                                : section === "sound" ? 3
                                                : section === "ch592" ? 4
                                                : section === "display" ? 5
                                                : section === "performance" ? 6
                                                : section === "storage" ? 7 : 8
            onSectionChanged: {
                window.lastSettingsSection = section
                systemBackend.setActiveScope(section)
            }
            Component.onCompleted: {
                window.lastSettingsSection = section
                systemBackend.setActiveScope(section)
            }

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
                    SettingsNavRow { title: "有线网络"; icon: "qrc:/assets/icons/ethernet-port.svg"; accent: "#4A90E2"; selected: settingsPage.section === "ethernet"; onClicked: settingsPage.section = "ethernet" }
                    SettingsNavRow { title: "电池"; icon: "qrc:/assets/icons/battery-charging.svg"; accent: "#F1A244"; selected: settingsPage.section === "battery"; onClicked: settingsPage.section = "battery" }
                    SettingsNavRow { title: "声音"; icon: "qrc:/assets/icons/volume-2.svg"; accent: window.pink; selected: settingsPage.section === "sound"; onClicked: settingsPage.section = "sound" }
                    SettingsNavRow { title: "隔空喵传"; icon: "qrc:/assets/icons/zap-dark.svg"; accent: window.mint; selected: settingsPage.section === "ch592"; onClicked: settingsPage.section = "ch592" }
                    SettingsNavRow { title: "显示与触摸"; icon: "qrc:/assets/icons/monitor.svg"; accent: window.purple; selected: settingsPage.section === "display"; onClicked: settingsPage.section = "display" }
                    SettingsNavRow { title: "性能"; icon: "qrc:/assets/icons/cpu.svg"; accent: "#4AC7C2"; selected: settingsPage.section === "performance"; onClicked: settingsPage.section = "performance" }
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
                    Loader { active: settingsPage.section === "wifi"; asynchronous: true; sourceComponent: wifiSettings }
                    Loader { active: settingsPage.section === "ethernet"; asynchronous: true; sourceComponent: ethernetSettings }
                    Loader { active: settingsPage.section === "battery"; asynchronous: true; sourceComponent: batterySettings }
                    Loader { active: settingsPage.section === "sound"; asynchronous: true; sourceComponent: soundSettings }
                    Loader { active: settingsPage.section === "ch592"; asynchronous: true; sourceComponent: ch592Settings }
                    Loader { active: settingsPage.section === "display"; asynchronous: true; sourceComponent: displaySettings }
                    Loader { active: settingsPage.section === "performance"; asynchronous: true; sourceComponent: performanceSettings }
                    Loader { active: settingsPage.section === "storage"; asynchronous: true; sourceComponent: storageSettings }
                    Loader { active: settingsPage.section === "about"; asynchronous: true; sourceComponent: aboutSettings }
                }
            }
        }
    }

    Component {
        id: wifiSettings
        Item {
            id: wifiPage
            property string expandedSsid: ""
            property var currentNetwork: {
                for (var i = 0; i < systemBackend.wifiNetworks.length; ++i) {
                    if (systemBackend.wifiNetworks[i].active) return systemBackend.wifiNetworks[i]
                }
                return ({})
            }
            function selectNetwork(network) {
                if (systemBackend.wifiOperating) return
                if (network.active) {
                    wifiPage.expandedSsid = ""
                } else if (network.saved || network.security === "开放") {
                    wifiPage.expandedSsid = ""
                    systemBackend.connectWifi(network.ssid, "")
                } else {
                    wifiPage.expandedSsid = ""
                    passwordDialog.openFor(network.ssid)
                }
            }
            Component.onCompleted: {
                systemBackend.scanWifi()
                if (Qt.application.arguments.indexOf("--wifi-keyboard") >= 0)
                    Qt.callLater(function() { passwordDialog.openFor("English Keyboard") })
                else if (Qt.application.arguments.indexOf("--wifi-keyboard-symbols") >= 0)
                    Qt.callLater(function() {
                        passwordDialog.openFor("Special Symbols")
                        passwordDialog.keyboardPage = 2
                    })
            }

            Flickable {
                anchors.fill: parent
                contentHeight: wifiColumn.height + 60
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: wifiColumn
                    width: parent.width - 60
                    x: 30; y: 30
                    spacing: 16
                RowLayout {
                    width: parent.width
                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Wi-Fi"; color: window.ink; font.family: window.uiFont; font.pixelSize: 34; font.weight: Font.Bold }
                        Text {
                            text: systemBackend.wifiOperating
                                  ? (systemBackend.wifiOperation === "connect"
                                     ? "正在连接到 " + systemBackend.wifiOperationSsid + "…"
                                     : "正在忘记 " + systemBackend.wifiOperationSsid + "…")
                                  : (systemBackend.wifiConnected ? "已连接到 " + systemBackend.wifiName : "未连接")
                            color: systemBackend.wifiOperating ? window.purple : window.secondary
                            font.family: window.uiFont; font.pixelSize: 18
                        }
                    }
                    Rectangle {
                        Layout.preferredWidth: 128; Layout.preferredHeight: 46; radius: 15
                        color: scanMouse.pressed ? "#6558D9" : window.purple
                        opacity: systemBackend.wifiScanning || systemBackend.wifiOperating ? 0.62 : 1
                        Text { anchors.centerIn: parent; text: systemBackend.wifiScanning ? "正在扫描…" : "重新扫描"; color: "white"; font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.DemiBold }
                        MouseArea { id: scanMouse; anchors.fill: parent; enabled: !systemBackend.wifiScanning && !systemBackend.wifiOperating; onClicked: systemBackend.scanWifi() }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: systemBackend.wifiConnected ? 274 : 112
                    radius: 20
                    color: systemBackend.wifiConnected ? "#EAF8F1" : "#F4F2F6"
                    border.color: systemBackend.wifiConnected ? "#BCE8D1" : window.separator

                    MouseArea {
                        anchors.fill: parent; enabled: systemBackend.wifiConnected && !systemBackend.wifiOperating
                        onClicked: wifiPage.expandedSsid = ""
                    }

                    Column {
                        anchors.fill: parent; anchors.margins: 18; spacing: 14
                        RowLayout {
                            width: parent.width; spacing: 16
                            Rectangle {
                                Layout.preferredWidth: 60; Layout.preferredHeight: 60; radius: 18
                                color: systemBackend.wifiConnected ? window.wifiSignalColor(wifiPage.currentNetwork.signal || 0) : "#B8B4BC"
                                Image { anchors.centerIn: parent; width: 34; height: 34; source: "qrc:/assets/icons/wifi.svg"; sourceSize.width: 68; sourceSize.height: 68 }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 3
                                Text { text: systemBackend.wifiConnected ? systemBackend.wifiName : "Wi-Fi 未连接"; color: window.ink; font.family: window.uiFont; font.pixelSize: 22; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                                Text {
                                    text: systemBackend.wifiConnected
                                          ? ((wifiPage.currentNetwork.band || "")
                                             + " · 信道 " + (wifiPage.currentNetwork.channel || "--")
                                             + " · " + (wifiPage.currentNetwork.security || "--"))
                                          : "选择下方网络进行连接"
                                    color: window.secondary; font.family: window.uiFont; font.pixelSize: 15
                                }
                            }
                            ColumnLayout {
                                visible: systemBackend.wifiConnected; spacing: 2
                                Text { text: (wifiPage.currentNetwork.signal || 0) + "%"; color: window.wifiSignalColor(wifiPage.currentNetwork.signal || 0); font.family: window.uiFont; font.pixelSize: 24; font.weight: Font.Bold; Layout.alignment: Qt.AlignRight }
                                Text { text: wifiPage.currentNetwork.rate || ""; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14; Layout.alignment: Qt.AlignRight }
                            }
                        }

                        Rectangle {
                            visible: systemBackend.wifiConnected
                            width: parent.width; height: 1; color: "#BCE8D1"
                        }

                        RowLayout {
                            visible: systemBackend.wifiConnected
                            width: parent.width; height: 74; spacing: 18
                            ColumnLayout {
                                Layout.preferredWidth: 168; spacing: 5
                                Text { text: "主机名"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 13 }
                                Text {
                                    text: systemBackend.hostname.length ? systemBackend.hostname : "--"
                                    color: window.ink; font.family: window.uiFont; font.pixelSize: 17; font.weight: Font.DemiBold
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                            }
                            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 48; color: "#BCE8D1" }
                            ColumnLayout {
                                Layout.preferredWidth: 188; spacing: 5
                                Text { text: "IPv4 地址"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 13 }
                                Text {
                                    text: systemBackend.wifiIpv4.length ? systemBackend.wifiIpv4 : "正在获取…"
                                    color: window.ink; font.family: window.uiFont; font.pixelSize: 17; font.weight: Font.DemiBold
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                            }
                            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 48; color: "#BCE8D1" }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 5
                                Text { text: "网关 · " + (systemBackend.wifiDevice.length ? systemBackend.wifiDevice : "wlan0"); color: window.secondary; font.family: window.uiFont; font.pixelSize: 13 }
                                Text {
                                    text: systemBackend.wifiGateway.length ? systemBackend.wifiGateway : "--"
                                    color: window.ink; font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.DemiBold
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                            }
                        }

                        Rectangle {
                            visible: systemBackend.wifiConnected
                            width: parent.width; height: 1; color: "#BCE8D1"
                        }

                        RowLayout {
                            visible: systemBackend.wifiConnected
                            width: parent.width; height: 46; spacing: 14
                            Text {
                                text: "已连接到 “" + systemBackend.wifiName + "”"
                                color: "#3E8F6E"
                                font.family: window.uiFont; font.pixelSize: 14
                                Layout.fillWidth: true; elide: Text.ElideRight
                            }
                            Rectangle {
                                Layout.preferredWidth: 128; Layout.preferredHeight: 40; radius: 12
                                color: forgetMouse.pressed ? "#D93645" : "#EB4D5C"
                                opacity: systemBackend.wifiOperating ? 0.6 : 1
                                Text { anchors.centerIn: parent; text: "忘记此网络"; color: "white"; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold }
                                MouseArea {
                                    id: forgetMouse
                                    anchors.fill: parent
                                    enabled: !systemBackend.wifiOperating
                                    onClicked: systemBackend.forgetWifi(systemBackend.wifiName)
                                }
                            }
                        }
                    }
                }

                Text { text: "附近网络"; color: window.ink; font.family: window.uiFont; font.pixelSize: 19; font.weight: Font.DemiBold }
                Rectangle {
                    visible: systemBackend.wifiScanError.length > 0
                    width: parent.width; height: visible ? 52 : 0; radius: 15
                    color: "#FFF0F1"; border.color: "#FFD0D4"; border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 10
                        Rectangle { Layout.preferredWidth: 9; Layout.preferredHeight: 9; radius: 5; color: "#E24B58" }
                        Text {
                            text: "扫描失败 · " + systemBackend.wifiScanError
                            color: "#A92F3B"; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold
                            Layout.fillWidth: true; elide: Text.ElideRight
                        }
                        Text { text: "请重试"; color: "#B43A46"; font.family: window.uiFont; font.pixelSize: 14 }
                    }
                }
                Flickable {
                    width: parent.width; height: systemBackend.wifiConnected ? 250 : 360; contentHeight: wifiList.height; clip: true
                    Column {
                        id: wifiList; width: parent.width; spacing: 8
                        Repeater {
                            model: systemBackend.wifiNetworks
                            delegate: Column {
                                id: networkEntry
                                width: parent.width
                                spacing: 8
                                visible: !modelData.active
                                Rectangle {
                                    id: networkCard
                                    width: parent.width; height: 82; radius: 18
                                    color: networkMouse.pressed ? "#EEEAFE" : "#F9F9FB"
                                    border.color: window.separator; border.width: 1
                                    opacity: systemBackend.wifiOperating ? 0.72 : 1
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 13; spacing: 13
                                        Rectangle {
                                            Layout.preferredWidth: 48; Layout.preferredHeight: 48; radius: 14
                                            color: window.wifiSignalColor(modelData.signal)
                                            Image { anchors.centerIn: parent; width: 27; height: 27; source: "qrc:/assets/icons/wifi.svg"; sourceSize.width: 54; sourceSize.height: 54 }
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            RowLayout {
                                                Layout.fillWidth: true
                                                Text { text: modelData.ssid; color: window.ink; font.family: window.uiFont; font.pixelSize: 19; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                                                Text {
                                                    visible: systemBackend.wifiOperating && systemBackend.wifiOperationSsid === modelData.ssid
                                                    text: systemBackend.wifiOperation === "connect" ? "连接中…" : "处理中…"
                                                    color: window.purple; font.family: window.uiFont; font.pixelSize: 13; font.weight: Font.DemiBold
                                                }
                                                Rectangle {
                                                    visible: modelData.saved && !(systemBackend.wifiOperating && systemBackend.wifiOperationSsid === modelData.ssid)
                                                    Layout.preferredWidth: 54; Layout.preferredHeight: 30; radius: 10
                                                    color: manageMouse.pressed ? "#DED8FF" : "#EEEAFE"
                                                    Text { anchors.centerIn: parent; text: "管理"; color: "#6555D5"; font.family: window.uiFont; font.pixelSize: 13; font.weight: Font.DemiBold }
                                                    MouseArea {
                                                        id: manageMouse
                                                        anchors.fill: parent
                                                        onClicked: wifiPage.expandedSsid = (wifiPage.expandedSsid === modelData.ssid ? "" : modelData.ssid)
                                                    }
                                                }
                                            }
                                            Text { text: modelData.band + " · 信道 " + modelData.channel + " · " + modelData.rate; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14 }
                                        }
                                        ColumnLayout {
                                            spacing: 2
                                            Text { text: modelData.signal + "%"; color: window.wifiSignalColor(modelData.signal); font.family: window.uiFont; font.pixelSize: 18; font.weight: Font.Bold; Layout.alignment: Qt.AlignRight }
                                            Text { text: modelData.security; color: window.secondary; font.family: window.uiFont; font.pixelSize: 13; Layout.alignment: Qt.AlignRight }
                                        }
                                    }
                                    MouseArea {
                                        id: networkMouse; anchors.fill: parent; enabled: !systemBackend.wifiOperating
                                        onClicked: wifiPage.selectNetwork(modelData)
                                    }
                                }
                                WifiManagePanel {
                                    id: managePanel
                                    width: parent.width
                                    expanded: wifiPage.expandedSsid === modelData.ssid
                                    onForget: systemBackend.forgetWifi(modelData.ssid)
                                    onReenter: { wifiPage.expandedSsid = ""; passwordDialog.openFor(modelData.ssid) }
                                    onConnect: { wifiPage.expandedSsid = ""; systemBackend.connectWifi(modelData.ssid, "") }
                                }
                            }
                        }
                        Text {
                            visible: !systemBackend.wifiScanning
                                     && systemBackend.wifiScanError.length === 0
                                     && systemBackend.wifiNetworks.length <= (systemBackend.wifiConnected ? 1 : 0)
                            width: parent.width; horizontalAlignment: Text.AlignHCenter
                            text: "没有发现其他网络"
                            color: window.secondary; font.family: window.uiFont; font.pixelSize: 16
                            topPadding: 24
                        }
                    }
                }
                }
            }
        }
    }

    Component {
        id: ethernetSettings
        Item {
            id: ethernetPage
            readonly property int connectedCount: {
                var count = 0
                for (var i = 0; i < systemBackend.ethernetPorts.length; ++i) {
                    if (systemBackend.ethernetPorts[i].connected) ++count
                }
                return count
            }
            readonly property string connectionSummary: connectedCount === 0
                                                        ? "两个网口均未连接"
                                                        : (connectedCount === 1
                                                           ? "已连接 1 个网口"
                                                           : "两个网口均已连接")

            Column {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 30 }
                spacing: 16

                RowLayout {
                    width: parent.width
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: "有线网络"; color: window.ink; font.family: window.uiFont; font.pixelSize: 34; font.weight: Font.Bold }
                        Text { text: ethernetPage.connectionSummary; color: window.secondary; font.family: window.uiFont; font.pixelSize: 18 }
                    }
                    Rectangle {
                        Layout.preferredWidth: 134; Layout.preferredHeight: 42; radius: 14
                        color: "#EDF5FF"
                        Row {
                            anchors.centerIn: parent; spacing: 8
                            Rectangle { width: 9; height: 9; radius: 5; color: ethernetPage.connectedCount > 0 ? "#34C759" : "#8E98A8"; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "2 个物理接口"; color: "#41678F"; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold }
                        }
                    }
                }

                Column {
                    width: parent.width; spacing: 14
                    Repeater {
                        model: systemBackend.ethernetPorts
                        delegate: EthernetPortCard {
                            width: parent.width
                            port: modelData
                            portNumber: index + 1
                            accent: index === 0 ? "#438DE5" : "#8B68E8"
                            tint: index === 0 ? "#F0F7FF" : "#F7F2FF"
                            outline: index === 0 ? "#C9E1FA" : "#DED0F8"
                        }
                    }
                    Text {
                        visible: systemBackend.ethernetPorts.length === 0
                        width: parent.width; topPadding: 80
                        horizontalAlignment: Text.AlignHCenter
                        text: "正在读取网口状态…"
                        color: window.secondary; font.family: window.uiFont; font.pixelSize: 17
                    }
                }

                Rectangle {
                    visible: systemBackend.ethernetPorts.length > 0
                    width: parent.width; height: 52; radius: 16
                    color: "#F7F7F9"
                    Row {
                        anchors.centerIn: parent; spacing: 9
                        Rectangle { width: 8; height: 8; radius: 4; color: "#A6A1AB"; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "插入网线后将自动获取网络地址"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 15 }
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
                        border.color: window.batteryOutlineColor()
                        clip: true
                        Rectangle {
                            id: detailBatteryFill
                            x: 8; y: 8; height: detailBatteryBody.height - 16
                            width: systemBackend.batteryPercent >= 0
                                   ? (detailBatteryBody.width - 16) * systemBackend.batteryPercent / 100 : 0
                            radius: 14
                            color: window.batteryFillColor()
                        }
                        Row {
                            id: detailBatteryLabelBase
                            anchors.centerIn: parent
                            spacing: systemBackend.batteryCharging ? 9 : 0
                            Image {
                                visible: systemBackend.batteryCharging
                                width: 26; height: 26
                                anchors.verticalCenter: parent.verticalCenter
                                source: "qrc:/assets/icons/zap-dark.svg"
                                sourceSize.width: 52; sourceSize.height: 52
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: systemBackend.batteryPercent >= 0 ? systemBackend.batteryPercent + "%" : "--"
                                color: "#3A3540"
                                font.family: window.uiFont; font.pixelSize: 36; font.weight: Font.Bold
                            }
                        }
                        Item {
                            x: 0; y: 0
                            width: detailBatteryFill.x + detailBatteryFill.width
                            height: detailBatteryBody.height
                            clip: true
                            Row {
                                x: detailBatteryLabelBase.x
                                y: detailBatteryLabelBase.y
                                spacing: detailBatteryLabelBase.spacing
                                Image {
                                    visible: systemBackend.batteryCharging
                                    width: 26; height: 26
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: "qrc:/assets/icons/zap-white.svg"
                                    sourceSize.width: 52; sourceSize.height: 52
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: systemBackend.batteryPercent >= 0 ? systemBackend.batteryPercent + "%" : "--"
                                    color: !systemBackend.batteryCharging
                                           && systemBackend.batteryPercent > 20
                                           && systemBackend.batteryPercent <= 40
                                           ? "#3A3540" : "white"
                                    font.family: window.uiFont; font.pixelSize: 36; font.weight: Font.Bold
                                }
                            }
                        }
                    }
                    Rectangle {
                        x: 223; y: 44; width: 9; height: 30; radius: 4
                        color: window.batteryOutlineColor()
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 7
                    Text { text: window.batteryStateText(systemBackend.batteryStatus); color: window.ink; font.family: window.uiFont; font.pixelSize: 27; font.weight: Font.DemiBold }
                    Text {
                        text: window.batteryPowerLabel() + (systemBackend.batteryTemperatureC > -100
                              ? "  ·  " + systemBackend.batteryTemperatureC.toFixed(1) + " °C" : "")
                        color: window.batteryPowerColor()
                        font.family: window.uiFont; font.pixelSize: 18; font.weight: Font.DemiBold
                    }
                }
            }
            IosGroup {
                width: parent.width
                IosInfoRow { height: 54; label: "状态"; value: window.batteryStateText(systemBackend.batteryStatus) }
                IosInfoRow {
                    height: 54; label: "实时功率"
                    value: systemBackend.batteryPowerW >= 0 ? window.batteryPowerLabel() : "--"
                    valueColor: window.batteryPowerColor()
                    emphasize: true
                }
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
            Rectangle {
                width: parent.width; height: 96; radius: 20
                color: "#FFF1F6"; border.color: "#FFD0DF"; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 18; spacing: 16
                    Rectangle {
                        Layout.preferredWidth: 58; Layout.preferredHeight: 58; radius: 17
                        color: window.pink
                        Image { anchors.centerIn: parent; width: 32; height: 32; source: "qrc:/assets/icons/volume-2.svg"; sourceSize.width: 64; sourceSize.height: 64 }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 3
                        Text { text: "内置扬声器"; color: window.ink; font.family: window.uiFont; font.pixelSize: 21; font.weight: Font.DemiBold }
                        Text { text: systemBackend.audioAvailable ? "NS4168 · 单声道输出" : "声卡驱动未就绪"; color: "#B35A78"; font.family: window.uiFont; font.pixelSize: 15 }
                    }
                    Text {
                        text: systemBackend.volumePercent >= 0 ? systemBackend.volumePercent + "%" : "--"
                        color: window.pink; font.family: window.uiFont; font.pixelSize: 26; font.weight: Font.Bold
                    }
                }
            }
            IosGroup {
                width: parent.width
                IosInfoRow { label: "输出设备"; value: systemBackend.audioAvailable ? "内置扬声器" : "--" }
                IosInfoRow { label: "主音量"; value: systemBackend.volumePercent >= 0 ? systemBackend.volumePercent + "%" : "--"; valueColor: window.pink; emphasize: true; last: true }
            }
            Rectangle {
                width: parent.width; height: 132; radius: 18
                color: "#FFF7FA"; border.color: "#F3D5E1"; border.width: 1
                Column {
                    anchors.fill: parent; anchors.margins: 18; spacing: 14
                    RowLayout {
                        width: parent.width
                        Text { text: "音量"; color: window.ink; font.family: window.uiFont; font.pixelSize: 19; font.weight: Font.DemiBold; Layout.fillWidth: true }
                        Text { text: systemBackend.volumePercent >= 0 ? systemBackend.volumePercent + "%" : "--"; color: window.pink; font.family: window.uiFont; font.pixelSize: 18; font.weight: Font.DemiBold }
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
                                color: "#F0D5DF"
                                Rectangle {
                                    width: volumeSlider.visualPosition * parent.width; height: parent.height; radius: parent.radius
                                    color: window.pink
                                }
                            }
                            handle: Rectangle {
                                x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                width: 26; height: 26; radius: 13
                                color: "white"; border.color: "#E7B8C8"; border.width: 1
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
            Rectangle {
                width: parent.width; height: 108; radius: 20
                color: "#EAF8F2"; border.color: "#BFE8D4"; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 18; spacing: 16
                    Rectangle {
                        Layout.preferredWidth: 58; Layout.preferredHeight: 58; radius: 17
                        color: window.mint
                        Image { anchors.centerIn: parent; width: 32; height: 32; source: "qrc:/assets/icons/cpu.svg"; sourceSize.width: 64; sourceSize.height: 64 }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Text { text: "CH592F"; color: window.ink; font.family: window.uiFont; font.pixelSize: 22; font.weight: Font.DemiBold }
                        Text { text: "常驻 USB IAP · 正常升级无需按 BOOT"; color: "#3E8F6E"; font.family: window.uiFont; font.pixelSize: 15 }
                    }
                    Rectangle {
                        Layout.preferredWidth: 88; Layout.preferredHeight: 36; radius: 13
                        color: "#D8F3E6"
                        Text { anchors.centerIn: parent; text: "待接入"; color: "#2F8A62"; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold }
                    }
                }
            }
            IosGroup {
                width: parent.width
                IosInfoRow { label: "正常更新"; value: "无需按 BOOT"; valueColor: window.mint; emphasize: true }
                IosInfoRow { label: "首次烧录 / 救砖"; value: "物理 BOOT 或 SWD"; last: true }
            }
        }
    }

    Component {
        id: displaySettings
        SettingsPageBody {
            title: "显示与触摸"
            subtitle: "屏幕与亮度"
            Rectangle {
                width: parent.width; height: 96; radius: 20
                color: "#F3F0FF"; border.color: "#D9D2FA"; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 18; spacing: 16
                    Rectangle {
                        Layout.preferredWidth: 58; Layout.preferredHeight: 58; radius: 17
                        color: window.purple
                        Image { anchors.centerIn: parent; width: 32; height: 32; source: "qrc:/assets/icons/monitor.svg"; sourceSize.width: 64; sourceSize.height: 64 }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 3
                        Text { text: "屏幕"; color: window.ink; font.family: window.uiFont; font.pixelSize: 21; font.weight: Font.DemiBold }
                        Text { text: "1280 × 800"; color: "#6A5CC4"; font.family: window.uiFont; font.pixelSize: 15 }
                    }
                    Text {
                        text: systemBackend.brightnessAvailable ? systemBackend.displayBrightnessPercent + "%" : "--"
                        color: window.purple; font.family: window.uiFont; font.pixelSize: 26; font.weight: Font.Bold
                    }
                }
            }
            Rectangle {
                width: parent.width; height: 132; radius: 18
                color: "#F7F5FF"; border.color: "#DDD7F5"; border.width: 1
                Column {
                    anchors.fill: parent; anchors.margins: 18; spacing: 14
                    RowLayout {
                        width: parent.width
                        Text { text: "亮度"; color: window.ink; font.family: window.uiFont; font.pixelSize: 19; font.weight: Font.DemiBold; Layout.fillWidth: true }
                        Text { text: systemBackend.brightnessAvailable ? systemBackend.displayBrightnessPercent + "%" : "--"; color: window.purple; font.family: window.uiFont; font.pixelSize: 18; font.weight: Font.DemiBold }
                    }
                    RowLayout {
                        width: parent.width; spacing: 15
                        Image { Layout.preferredWidth: 25; Layout.preferredHeight: 25; source: "qrc:/assets/icons/sun.svg"; sourceSize.width: 50; sourceSize.height: 50; opacity: brightnessSlider.enabled ? 1 : 0.3 }
                        Slider {
                            id: brightnessSlider
                            Layout.fillWidth: true; Layout.preferredHeight: 34
                            from: 10; to: 100; stepSize: 1; live: true
                            enabled: systemBackend.brightnessAvailable
                            value: systemBackend.displayBrightnessPercent >= 0 ? systemBackend.displayBrightnessPercent : 10
                            onMoved: systemBackend.setDisplayBrightness(Math.round(value))
                            background: Rectangle {
                                x: brightnessSlider.leftPadding
                                y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                                width: brightnessSlider.availableWidth; height: 7; radius: 4
                                color: "#DDD8EF"
                                Rectangle {
                                    width: brightnessSlider.visualPosition * parent.width; height: parent.height; radius: parent.radius
                                    color: window.purple
                                }
                            }
                            handle: Rectangle {
                                x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                                y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                                width: 26; height: 26; radius: 13
                                color: "white"; border.color: "#C9C1E8"; border.width: 1
                            }
                        }
                    }
                }
            }
            Rectangle {
                width: parent.width; height: 132; radius: 18
                color: "#F7F5FF"; border.color: "#DDD7F5"; border.width: 1
                Column {
                    anchors.fill: parent; anchors.margins: 18; spacing: 14
                    RowLayout {
                        width: parent.width
                        Text { text: "亮度"; color: window.ink; font.family: window.uiFont; font.pixelSize: 19; font.weight: Font.DemiBold; Layout.fillWidth: true }
                        Text { text: systemBackend.brightnessAvailable ? systemBackend.displayBrightnessPercent + "%" : "--"; color: window.purple; font.family: window.uiFont; font.pixelSize: 18; font.weight: Font.DemiBold }
                    }
                    RowLayout {
                        width: parent.width; spacing: 15
                        Image { Layout.preferredWidth: 25; Layout.preferredHeight: 25; source: "qrc:/assets/icons/sun.svg"; sourceSize.width: 50; sourceSize.height: 50; opacity: brightnessSlider.enabled ? 1 : 0.3 }
                        Slider {
                            id: brightnessSlider
                            Layout.fillWidth: true; Layout.preferredHeight: 34
                            from: 10; to: 100; stepSize: 1; live: true
                            enabled: systemBackend.brightnessAvailable
                            value: systemBackend.displayBrightnessPercent >= 0 ? systemBackend.displayBrightnessPercent : 10
                            onMoved: systemBackend.setDisplayBrightness(Math.round(value))
                            background: Rectangle {
                                x: brightnessSlider.leftPadding
                                y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                                width: brightnessSlider.availableWidth; height: 7; radius: 4
                                color: "#DDD8EF"
                                Rectangle {
                                    width: brightnessSlider.visualPosition * parent.width; height: parent.height; radius: parent.radius
                                    color: window.purple
                                }
                            }
                            handle: Rectangle {
                                x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                                y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                                width: 26; height: 26; radius: 13
                                color: "white"; border.color: "#C9C1E8"; border.width: 1
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: storageSettings
        SettingsPageBody {
            title: "存储空间"
            subtitle: "系统盘与扩展存储"
            StorageDiskCard {
                width: parent.width
                title: "系统存储"
                detail: systemBackend.diskUsed + " 已使用，共 " + systemBackend.diskTotal
                percent: systemBackend.diskPercent
                accent: "#7B6DF0"
                accent2: "#D875D4"
            }
            StorageDiskCard {
                width: parent.width
                title: systemBackend.nvmeModel.length ? systemBackend.nvmeModel : "NVMe 固态硬盘"
                detail: !systemBackend.nvmeAvailable
                        ? "未检测到硬盘，请检查 PCIe 连接"
                        : (systemBackend.nvmeMounted
                           ? systemBackend.nvmeUsed + " 已使用，共 " + systemBackend.nvmeTotal
                             + (systemBackend.nvmeMountPoint.length ? " · " + systemBackend.nvmeMountPoint : "")
                           : (systemBackend.nvmeTotal.length ? systemBackend.nvmeTotal + " · 未挂载" : "已检测，未挂载"))
                percent: systemBackend.nvmePercent
                available: systemBackend.nvmeAvailable
                mounted: systemBackend.nvmeMounted
                accent: "#4A90E2"
                accent2: "#42C7C2"
            }
        }
    }

    Component {
        id: aboutSettings
        SettingsPageBody {
            title: "关于本机"
            subtitle: "Radxa Cubie A5E"
            Rectangle {
                width: parent.width; height: 138; radius: 22
                color: "#FFF7FA"; border.color: "#F3D5E1"; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 22
                    Image { Layout.preferredWidth: 96; Layout.preferredHeight: 96; source: "qrc:/assets/meowkj-avatar-circle.png"; fillMode: Image.PreserveAspectFit; smooth: true }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Text { text: "Meow OS"; color: window.ink; font.family: window.uiFont; font.pixelSize: 30; font.weight: Font.Bold }
                        Text { text: "为这台设备打造"; color: "#B35A78"; font.family: window.uiFont; font.pixelSize: 17 }
                        Text { text: systemBackend.hostname.length ? systemBackend.hostname : "radxa"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 15 }
                    }
                }
            }
            IosGroup {
                width: parent.width
                IosInfoRow { label: "系统版本"; value: "Meow OS " + systemBackend.version; valueColor: window.pink; emphasize: true }
                IosInfoRow { label: "主机名"; value: systemBackend.hostname }
                IosInfoRow { label: "Linux 内核"; value: systemBackend.kernel; last: true }
            }
        }
    }

    Item {
        id: passwordDialog
        property string ssid: ""
        property bool shift: false
        property int keyboardPage: 0 // 0 letters, 1 numbers, 2 extended symbols
        property bool showPassword: false
        property bool opened: false
        function openFor(networkName) {
            ssid = networkName
            shift = false
            keyboardPage = 0
            showPassword = false
            wifiPassword.text = ""
            open()
        }
        function typeKey(key) {
            wifiPassword.text += key
            if (shift && keyboardPage === 0) shift = false
        }
        function backspace() {
            if (wifiPassword.text.length > 0) wifiPassword.text = wifiPassword.text.slice(0, -1)
        }
        function open() {
            visible = true
            opened = true
            dialogContent.opacity = 1
            dialogContent.scale = 1
            keyboardShell.opacity = 1
            keyboardShell.y = 0
            wifiPassword.forceActiveFocus()
        }
        function close() {
            opened = false
            dialogContent.opacity = 0
            dialogContent.scale = 0.96
            keyboardShell.opacity = 0
            keyboardShell.y = keyboardShell.height
            closeAnimation.restart()
        }
        function submit() {
            if (wifiPassword.text.length === 0) return
            systemBackend.connectWifi(ssid, wifiPassword.text)
            close()
            wifiPassword.text = ""
        }
        parent: scene; anchors.fill: parent; z: 2100; visible: false
        Rectangle { anchors.fill: parent; color: opened ? "#590B0A0D" : "#00000000"; opacity: opened ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 180 } }; MouseArea { anchors.fill: parent; onClicked: passwordDialog.close() } }
        Rectangle {
            id: dialogContent
            width: 840; height: 154
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 78 }
            radius: 24; color: "#FCFBFD"; border.color: "#DEDCE2"; border.width: 1
            opacity: 0; scale: 0.96; layer.enabled: opened || opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Column {
                anchors.fill: parent; anchors.margins: 22; spacing: 13
                RowLayout {
                    width: parent.width; height: 46
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text {
                            text: "输入 Wi-Fi 密码"
                            color: window.ink; font.family: window.uiFont; font.pixelSize: 23; font.weight: Font.Bold
                        }
                        Text {
                            text: passwordDialog.ssid
                            color: window.secondary; font.family: window.uiFont; font.pixelSize: 14
                            elide: Text.ElideRight; Layout.fillWidth: true
                        }
                    }
                    Text {
                        text: "安全网络"
                        color: "#5D4BC7"; font.family: window.uiFont; font.pixelSize: 14; font.weight: Font.DemiBold
                        leftPadding: 12; rightPadding: 12; topPadding: 7; bottomPadding: 7
                        Rectangle { anchors.fill: parent; z: -1; radius: 12; color: "#EEEAFE" }
                    }
                }
                Item {
                    width: parent.width; height: 58
                    TextField {
                        id: wifiPassword
                        anchors.fill: parent
                        placeholderText: "密码"
                        echoMode: passwordDialog.showPassword ? TextInput.Normal : TextInput.Password
                        font.family: window.uiFont; font.pixelSize: 20
                        leftPadding: 17; rightPadding: 98
                        background: Rectangle {
                            radius: 13; color: "white"
                            border.color: wifiPassword.activeFocus ? "#7D6CF2" : "#D8D5DD"; border.width: 2
                        }
                        Keys.onReturnPressed: passwordDialog.submit()
                    }
                    Rectangle {
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        width: 78; height: 40; radius: 10
                        color: showPasswordMouse.pressed ? "#E1DDF8" : "#EEEAFE"
                        Text {
                            anchors.centerIn: parent
                            text: passwordDialog.showPassword ? "隐藏" : "显示"
                            color: "#6555D5"; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold
                        }
                        MouseArea { id: showPasswordMouse; anchors.fill: parent; onClicked: passwordDialog.showPassword = !passwordDialog.showPassword }
                    }
                }
            }
        }

        Rectangle {
            id: keyboardShell
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 320; color: "#CED2D9"
            border.color: "#B9BEC7"; border.width: 1
            opacity: 0
            y: height
            layer.enabled: passwordDialog.opened || opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Column {
                id: keyboardContent
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 18; rightMargin: 18 }
                spacing: 9
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 9
                    Repeater {
                        model: passwordDialog.keyboardPage === 0
                               ? ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
                               : (passwordDialog.keyboardPage === 1
                                  ? ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
                                  : ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="])
                        delegate: IpadKey {
                            label: passwordDialog.keyboardPage === 0
                                   ? (passwordDialog.shift ? modelData : modelData.toLowerCase())
                                   : modelData
                            keyWidth: 108
                            onTapped: passwordDialog.typeKey(label)
                        }
                    }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 9
                    Repeater {
                        model: passwordDialog.keyboardPage === 0
                               ? ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
                               : (passwordDialog.keyboardPage === 1
                                  ? ["@", "#", "$", "%", "&", "*", "(", ")", "\""]
                                  : ["_", "\\", "|", "~", "<", ">", "€", "£", "¥"])
                        delegate: IpadKey {
                            label: passwordDialog.keyboardPage === 0
                                   ? (passwordDialog.shift ? modelData : modelData.toLowerCase())
                                   : modelData
                            keyWidth: 108
                            onTapped: passwordDialog.typeKey(label)
                        }
                    }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 9
                    IpadKey {
                        label: passwordDialog.keyboardPage === 0 ? "⇧"
                                                                  : (passwordDialog.keyboardPage === 1 ? "#+=" : "123")
                        keyWidth: 142; functionKey: true; active: passwordDialog.shift
                        onTapped: {
                            if (passwordDialog.keyboardPage === 0) passwordDialog.shift = !passwordDialog.shift
                            else passwordDialog.keyboardPage = passwordDialog.keyboardPage === 1 ? 2 : 1
                        }
                    }
                    Repeater {
                        model: passwordDialog.keyboardPage === 0
                               ? ["Z", "X", "C", "V", "B", "N", "M"]
                               : (passwordDialog.keyboardPage === 1
                                  ? ["-", "_", "=", "+", "/", "\\", "?"]
                                  : [".", ",", ":", ";", "!", "?", "'"])
                        delegate: IpadKey {
                            label: passwordDialog.keyboardPage === 0
                                   ? (passwordDialog.shift ? modelData : modelData.toLowerCase())
                                   : (modelData === "'" ? "’" : modelData)
                            keyWidth: 108
                            onTapped: passwordDialog.typeKey(passwordDialog.keyboardPage === 2 && modelData === "'" ? "'" : label)
                        }
                    }
                    IpadKey { label: "⌫"; keyWidth: 142; functionKey: true; onTapped: passwordDialog.backspace() }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter; spacing: 9
                    IpadKey {
                        label: passwordDialog.keyboardPage === 0 ? "123" : "ABC"
                        keyWidth: 142; functionKey: true
                        onTapped: {
                            passwordDialog.keyboardPage = passwordDialog.keyboardPage === 0 ? 1 : 0
                            passwordDialog.shift = false
                        }
                    }
                    IpadKey { label: ","; keyWidth: 90; onTapped: passwordDialog.typeKey(",") }
                    IpadKey { label: "English (US)"; keyWidth: 502; onTapped: passwordDialog.typeKey(" ") }
                    IpadKey { label: "."; keyWidth: 90; onTapped: passwordDialog.typeKey(".") }
                    IpadKey { label: "取消"; keyWidth: 130; functionKey: true; onTapped: passwordDialog.close() }
                    IpadKey { label: "连接"; keyWidth: 180; returnKey: true; onTapped: passwordDialog.submit() }
                }
            }
        }

        Timer {
            id: closeAnimation
            interval: 220
            onTriggered: passwordDialog.visible = false
        }
    }

    component ManageButton: Rectangle {
        property string label: ""
        property color baseColor: window.purple
        signal clicked()
        width: 140; height: 44; radius: 12
        color: manageBtnMouse.pressed ? Qt.darker(baseColor, 1.15) : baseColor
        Text { anchors.centerIn: parent; text: label; color: "white"; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold }
        MouseArea { id: manageBtnMouse; anchors.fill: parent; onClicked: parent.clicked() }
    }

    component WifiManagePanel: Rectangle {
        id: wifiPanelRoot
        property bool expanded: false
        signal forget()
        signal reenter()
        signal connect()
        width: parent ? parent.width : 0
        height: 0
        clip: true
        radius: 18
        color: "#F5F3FF"
        border.color: "#D8D0F5"; border.width: 1
        Column {
            id: panelContent
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: 12
            Text { text: "已保存此网络的连接信息，密码变化时请重新输入"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14; wrapMode: Text.WordWrap; width: parent.width; leftPadding: 16; rightPadding: 16; topPadding: 14 }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
                ManageButton { label: "重新输入密码"; baseColor: window.purple; onClicked: reenter() }
                ManageButton { label: "连接"; baseColor: window.mint; onClicked: connect() }
                ManageButton { label: "忘记网络"; baseColor: "#EB4D5C"; onClicked: forget() }
            }
        }
        states: [
            State { name: "collapsed"; when: !wifiPanelRoot.expanded; PropertyChanges { target: wifiPanelRoot; height: 0; opacity: 0 } },
            State { name: "expanded"; when: wifiPanelRoot.expanded; PropertyChanges { target: wifiPanelRoot; height: panelContent.height + 28; opacity: 1 } }
        ]
        transitions: Transition { NumberAnimation { properties: "height,opacity"; duration: 240; easing.type: Easing.OutCubic } }
        visible: expanded || height > 1
        enabled: expanded
        layer.enabled: expanded || opacity > 0.01
    }

    component PerfTile: Rectangle {
        property string title: ""
        property string value: "--"
        property string subtext: ""
        property color accent: window.purple
        property int percent: -1
        Layout.fillWidth: true
        height: 150; radius: 20
        color: "#F9F9FB"; border.color: window.separator; border.width: 1
        Column {
            anchors.fill: parent; anchors.margins: 18; spacing: 8
            Text { text: title; color: window.secondary; font.family: window.uiFont; font.pixelSize: 15 }
            Text { text: value; color: window.ink; font.family: window.uiFont; font.pixelSize: 40; font.weight: Font.Bold }
            Rectangle {
                width: parent.width; height: 8; radius: 4; color: "#E7E5EA"
                Rectangle { width: Math.max(percent, 0) / 100 * parent.width; height: parent.height; radius: 4; color: accent }
            }
            Text { text: subtext; color: window.secondary; font.family: window.uiFont; font.pixelSize: 13; elide: Text.ElideRight; width: parent.width }
        }
    }

    Component {
        id: performanceSettings
        SettingsPageBody {
            title: "性能"
            subtitle: "处理器 · 图形 · 内存 实时占用"
            RowLayout {
                width: parent.width; spacing: 14
                PerfTile { title: "CPU"; value: systemBackend.cpuTotal >= 0 ? systemBackend.cpuTotal + "%" : "--"; accent: window.purple; percent: systemBackend.cpuTotal }
                PerfTile { title: "GPU"; value: systemBackend.gpuUsage >= 0 ? systemBackend.gpuUsage + "%" : "--"; accent: window.mint; percent: systemBackend.gpuUsage }
                PerfTile { title: "内存"; value: systemBackend.memoryPercent >= 0 ? systemBackend.memoryPercent + "%" : "--"; accent: "#4AC7C2"; percent: systemBackend.memoryPercent; subtext: systemBackend.memoryUsed + " / " + systemBackend.memoryTotal }
            }
            IosGroup {
                width: parent.width
                IosInfoRow { label: "内存用量"; value: systemBackend.memoryUsed + " / " + systemBackend.memoryTotal; last: true }
            }
            Column {
                width: parent.width; spacing: 10
                Text { text: "逻辑处理器"; color: window.ink; font.family: window.uiFont; font.pixelSize: 19; font.weight: Font.DemiBold }
                Repeater {
                    model: systemBackend.cpuUsage
                    delegate: RowLayout {
                        width: parent.width; height: 34
                        Text { text: index === 0 ? "总体" : "处理器 " + index; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14; Layout.preferredWidth: 120 }
                        Rectangle {
                            Layout.fillWidth: true; height: 8; radius: 4; color: "#E7E5EA"
                            Rectangle { width: Math.max(modelData, 0) / 100 * parent.width; height: parent.height; radius: 4; color: window.purple }
                        }
                        Text { text: modelData + "%"; color: window.ink; font.family: window.uiFont; font.pixelSize: 14; Layout.alignment: Qt.AlignRight }
                    }
                }
            }
            Timer { interval: 2000; running: settingsPage.section === "performance"; repeat: true; triggeredOnStart: true; onTriggered: systemBackend.refreshPerformance() }
        }
    }

    Item {
        id: wifiOperationBanner
        parent: scene
        z: 2050
        visible: systemBackend.wifiOperating
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: window.statusBarHeight + 10 }
        height: 56
        Rectangle {
            anchors { horizontalCenter: parent.horizontalCenter }
            width: Math.min(parent.width - 48, bannerText.implicitWidth + 78)
            height: parent.height
            radius: 18
            color: "#F4F1FF"
            border.color: "#D4CDF5"
            border.width: 1
            Row {
                anchors.centerIn: parent; spacing: 12
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: window.purple
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    id: bannerText
                    anchors.verticalCenter: parent.verticalCenter
                    text: systemBackend.wifiOperation === "connect"
                          ? "正在连接到 “" + systemBackend.wifiOperationSsid + "”…"
                          : "正在忘记 “" + systemBackend.wifiOperationSsid + "”…"
                    color: "#5A4CC4"
                    font.family: window.uiFont; font.pixelSize: 17; font.weight: Font.DemiBold
                }
            }
        }
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
            spacing: 16

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

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: window.batteryPowerLabel()
                color: window.batteryPowerColor()
                font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.DemiBold
            }

            Item {
                id: statusBattery
                width: 64; height: 30
                property color trackColor: "#E5E5EA"
                property color outlineColor: window.batteryOutlineColor()
                property color fillColor: window.batteryFillColor()
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

                    Row {
                        id: statusBatteryLabelBase
                        anchors.centerIn: parent
                        spacing: systemBackend.batteryCharging ? 2 : 0
                        Image {
                            visible: systemBackend.batteryCharging
                            width: 11; height: 14
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/assets/icons/zap-dark.svg"
                            sourceSize.width: 22; sourceSize.height: 28
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: systemBackend.batteryPercent >= 0 ? systemBackend.batteryPercent : "--"
                            color: "#3A3540"
                            font.family: window.uiFont
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                    }

                    Item {
                        x: 0; y: 0
                        width: batteryFill.x + batteryFill.width
                        height: batteryBody.height
                        clip: true
                        Row {
                            x: statusBatteryLabelBase.x
                            y: statusBatteryLabelBase.y
                            spacing: statusBatteryLabelBase.spacing
                            Image {
                                visible: systemBackend.batteryCharging
                                width: 11; height: 14
                                anchors.verticalCenter: parent.verticalCenter
                                source: "qrc:/assets/icons/zap-white.svg"
                                sourceSize.width: 22; sourceSize.height: 28
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: systemBackend.batteryPercent >= 0 ? systemBackend.batteryPercent : "--"
                                color: statusBattery.fillTextColor
                                font.family: window.uiFont
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }
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
        property color valueColor: window.secondary
        property bool emphasize: false
        property bool last: false
        width: parent.width; height: 62
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 18
            Text { text: label; color: window.ink; font.family: window.uiFont; font.pixelSize: 18; Layout.fillWidth: true }
            Text { text: value; color: valueColor; font.family: window.uiFont; font.pixelSize: 17; font.weight: emphasize ? Font.DemiBold : Font.Normal }
        }
        Rectangle { visible: !last; anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 18 } height: 1; color: window.separator }
    }

    component KeyboardKey: Rectangle {
        property string label: ""
        property real keyWidth: 65
        property bool active: false
        property bool accent: false
        property bool destructive: false
        signal tapped()
        width: keyWidth; height: 48; radius: 12
        color: keyMouse.pressed
               ? (accent ? "#6558D9" : (destructive ? "#D93645" : "#DED9E3"))
               : (accent ? window.purple : (destructive ? "#EB4D5C" : (active ? "#DED8FF" : "#F0EDF3")))
        border.color: active ? window.purple : "transparent"
        border.width: active ? 2 : 0
        Text {
            anchors.centerIn: parent
            text: label
            color: accent || destructive ? "white" : window.ink
            font.family: window.uiFont; font.pixelSize: 17; font.weight: Font.Medium
        }
        MouseArea { id: keyMouse; anchors.fill: parent; onClicked: parent.tapped() }
    }

    component IpadKey: Rectangle {
        property string label: ""
        property real keyWidth: 108
        property bool functionKey: false
        property bool returnKey: false
        property bool active: false
        signal tapped()
        width: keyWidth; height: 58; radius: 8
        color: ipadKeyMouse.pressed
               ? (returnKey ? "#0068D7" : (functionKey ? "#969CA6" : "#D9DCE1"))
               : (returnKey ? "#087CFA" : (active ? "#FFFFFF" : (functionKey ? "#AAB0BA" : "#FFFFFF")))
        border.color: returnKey ? "#087CFA" : (functionKey && !active ? "#9FA5AF" : "#B8BDC5")
        border.width: 1
        Rectangle {
            visible: !ipadKeyMouse.pressed
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 2; radius: 1; color: returnKey ? "#0064CA" : "#A3A8B0"; opacity: 0.65
        }
        Text {
            anchors.centerIn: parent
            text: label
            color: returnKey ? "white" : "#1D1D1F"
            font.family: window.uiFont
            font.pixelSize: label.length > 4 ? 15 : (label.length > 2 ? 17 : 21)
            font.weight: returnKey || functionKey ? Font.DemiBold : Font.Medium
        }
        MouseArea { id: ipadKeyMouse; anchors.fill: parent; onClicked: parent.tapped() }
    }

    component EthernetPortCard: Rectangle {
        property var port: ({})
        property int portNumber: 1
        property color accent: "#438DE5"
        property color tint: "#F0F7FF"
        property color outline: "#C9E1FA"
        readonly property bool connected: port && port.connected === true
        readonly property string interfaceName: port && port.name ? port.name : "--"
        height: 210
        radius: 22
        color: tint
        border.color: outline
        border.width: 1

        RowLayout {
            id: ethernetHeader
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            height: 62; spacing: 14
            Rectangle {
                Layout.preferredWidth: 56; Layout.preferredHeight: 56; radius: 17
                color: accent
                Image {
                    anchors.centerIn: parent; width: 31; height: 31
                    source: "qrc:/assets/icons/ethernet-port.svg"
                    sourceSize.width: 62; sourceSize.height: 62; smooth: true
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text {
                    text: "网口 " + portNumber + "  ·  " + interfaceName
                    color: window.ink; font.family: window.uiFont; font.pixelSize: 22; font.weight: Font.DemiBold
                }
                Text {
                    text: connected
                          ? ((port.ipv4 || "").length > 0 ? "已接入局域网" : "网线已连接，正在获取地址")
                          : "未连接，请插入网线"
                    color: window.secondary; font.family: window.uiFont; font.pixelSize: 15
                }
            }
            Rectangle {
                Layout.preferredWidth: connected ? 92 : 82
                Layout.preferredHeight: 36; radius: 13
                color: connected ? "#DDF5E7" : "#E8E8ED"
                Row {
                    anchors.centerIn: parent; spacing: 7
                    Rectangle { width: 8; height: 8; radius: 4; color: connected ? "#26A65B" : "#98949D"; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: connected ? "已连接" : "未连接"
                        color: connected ? "#20844A" : "#6F6A74"
                        font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold
                    }
                }
            }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: ethernetHeader.bottom; leftMargin: 18; rightMargin: 18; topMargin: 14 }
            height: 1; color: outline
        }

        RowLayout {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 20; rightMargin: 20; bottomMargin: 20 }
            height: 74; spacing: 22
            ColumnLayout {
                Layout.preferredWidth: 218; spacing: 5
                Text { text: "IPv4 地址"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14 }
                Text {
                    text: connected ? ((port.ipv4 || "").length > 0 ? port.ipv4 : "正在获取…") : "--"
                    color: window.ink; font.family: window.uiFont; font.pixelSize: 17; font.weight: Font.DemiBold
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 52; color: outline }
            ColumnLayout {
                Layout.preferredWidth: 150; spacing: 5
                Text { text: "连接速率"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14 }
                Text {
                    text: connected && port.speed > 0
                          ? port.speed + " Mb/s · " + window.ethernetDuplexText(port.duplex)
                          : "未协商"
                    color: window.ink; font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.DemiBold
                }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 52; color: outline }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 5
                Text {
                    text: port && port.mtu > 0 ? "硬件地址  ·  MTU " + port.mtu : "硬件地址"
                    color: window.secondary; font.family: window.uiFont; font.pixelSize: 14
                }
                Text {
                    text: port && port.mac ? port.mac.toUpperCase() : "--"
                    color: window.ink; font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.DemiBold
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
            }
        }
    }

    component StorageDiskCard: Rectangle {
        property string title: ""
        property string detail: ""
        property int percent: 0
        property color accent: window.purple
        property color accent2: accent
        property bool available: true
        property bool mounted: true
        height: available && mounted ? 170 : 104
        radius: 20
        color: "#F9F9FB"
        border.color: window.separator
        border.width: 1

        RowLayout {
            id: diskHeader
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            height: 54
            spacing: 14
            Rectangle {
                Layout.preferredWidth: 50; Layout.preferredHeight: 50
                radius: 14
                color: available ? accent : "#B9B5BE"
                Image {
                    anchors.centerIn: parent
                    width: 28; height: 28
                    source: "qrc:/assets/icons/hard-drive.svg"
                    sourceSize.width: 56; sourceSize.height: 56
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { text: title; color: window.ink; font.family: window.uiFont; font.pixelSize: 20; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: detail; color: window.secondary; font.family: window.uiFont; font.pixelSize: 15; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            Text {
                text: !available ? "未检测到" : (mounted ? percent + "%" : "未挂载")
                color: available ? window.secondary : "#8E8993"
                font.family: window.uiFont; font.pixelSize: 17; font.weight: Font.DemiBold
            }
        }

        Rectangle {
            id: storageTrack
            visible: available && mounted
            anchors { left: parent.left; right: parent.right; top: diskHeader.bottom; leftMargin: 18; rightMargin: 18; topMargin: 15 }
            height: 14; radius: 7
            color: "#E7E5EA"
            clip: true
            Rectangle {
                width: percent > 0 ? Math.max(height, parent.width * Math.max(0, Math.min(100, percent)) / 100) : 0
                height: parent.height; radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: accent }
                    GradientStop { position: 1.0; color: accent2 }
                }
            }
        }

        RowLayout {
            visible: available && mounted
            anchors { left: parent.left; right: parent.right; top: storageTrack.bottom; leftMargin: 18; rightMargin: 18; topMargin: 12 }
            spacing: 22
            Row {
                spacing: 7
                Rectangle { width: 10; height: 10; radius: 5; color: accent; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "已使用"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14 }
            }
            Row {
                spacing: 7
                Rectangle { width: 10; height: 10; radius: 5; color: "#D2CFD7"; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "可用空间"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14 }
            }
            Item { Layout.fillWidth: true }
        }
    }
}
