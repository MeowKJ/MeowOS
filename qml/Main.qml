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
    property int statusBarHeight: 50
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
    readonly property bool settingsForeground: stack.currentItem
                                               && stack.currentItem.objectName === "meow-settings-page"
    property int brightnessBeforeDim: -1
    property int idleDimDelayMs: 90000
    property string lastSettingsSection: ""
    property string initialSettingsSection: Qt.application.arguments.indexOf("--ethernet") >= 0
                                            || Qt.application.arguments.indexOf("--ethernet-config") >= 0
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
                                   || Qt.application.arguments.indexOf("--ethernet-config") >= 0
    readonly property bool startInFiles: Qt.application.arguments.indexOf("--files") >= 0
    readonly property bool settingsQaMetrics: Qt.application.arguments.indexOf("--qa") >= 0
    readonly property bool settingsQaSwitch: Qt.application.arguments.indexOf("--qa-switch") >= 0

    function updateClock() {
        var now = new Date()
        var week = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        clockTime = Qt.formatDateTime(now, "HH:mm")
        clockDate = Qt.formatDateTime(now, "M月d日") + " " + week[now.getDay()]
    }

    function openApp(appId) {
        if (appId === "touch-test") stack.push(touchTestComponent)
        else if (appId === "reaction-game") stack.push(reactionGameComponent)
        else if (appId === "files") stack.push(fileManagerComponent)
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
        if (systemBackend.batteryCharging) return "#34C759"
        if (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 20) return "#FF3B30"
        if (systemBackend.batteryPercent >= 0 && systemBackend.batteryPercent <= 40) return "#FFCC00"
        if (systemBackend.batteryStatus === "Discharging" && systemBackend.batteryPowerW >= 6) return "#FF3B30"
        if (systemBackend.batteryStatus === "Discharging" && systemBackend.batteryPowerW >= 3) return "#FF9F0A"
        return "#4B4650"
    }

    function batteryOutlineColor() {
        if (systemBackend.batteryCharging) return "#34C759"
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

    function wifiDetailText(n) {
        if (!n) return ""
        var parts = []
        if (n.band && String(n.band).length) parts.push(n.band)
        if (n.channel && n.channel > 0) parts.push("信道 " + n.channel)
        if (n.security && String(n.security).length) parts.push(n.security)
        return parts.join(" · ")
    }

    ListModel {
        id: appRegistry
        ListElement { appId: "touch-test"; appTitle: "点击测试"; iconSource: "qrc:/assets/icons/mouse-pointer-click.svg"; accent: "#FF7FA7" }
        ListElement { appId: "reaction-game"; appTitle: "喵喵反应"; iconSource: "qrc:/assets/icons/mouse-pointer-click.svg"; accent: "#49B990" }
        ListElement { appId: "files"; appTitle: "文件"; iconSource: "qrc:/assets/icons/hard-drive.svg"; accent: "#5E93E8" }
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
        interval: window.screenDimmed ? 20000
                 : (stack.depth > 1 ? (window.lastSettingsSection === "wifi" || window.lastSettingsSection === "battery" ? 5000 : 8000) : 12000)
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
        Keys.onEscapePressed: {
            if (stack.depth <= 1) return
            if (stack.currentItem && stack.currentItem.objectName === "meow-files-page")
                stack.currentItem.handleBack()
            else
                stack.pop()
        }

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
            initialItem: window.startInFiles ? fileManagerComponent
                                             : (window.startInSettings ? settingsComponent : homeComponent)
            // Page changes are already visually structured by the settings
            // layout. Avoid an extra opacity animation on every tap.
            pushEnter: Transition { }
            pushExit: Transition { }
            popEnter: Transition { }
            popExit: Transition { }
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
            onReleased: {
                if (mouse.x - pressX <= 92) return
                if (stack.currentItem && stack.currentItem.objectName === "meow-files-page")
                    stack.currentItem.handleBack()
                else
                    stack.pop()
            }
        }

        Rectangle {
            id: splash
            z: 1000
            anchors.fill: parent
            color: "#FFF9FB"
            visible: true
            opacity: 1

            Rectangle {
                id: splashHalo
                anchors.centerIn: splashAvatar
                width: 278; height: 278; radius: 139
                color: "#FFE7F0"
                opacity: 0.72
                scale: 0.45
            }

            Image {
                id: splashAvatar
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -34
                width: 220; height: 220
                source: "qrc:/assets/meowkj-avatar-circle.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
                opacity: 0.18
                scale: 0.28
                rotation: -24
            }
            Text {
                id: splashTitle
                anchors { horizontalCenter: parent.horizontalCenter; top: splashAvatar.bottom; topMargin: 30 }
                text: "Meow OS " + systemBackend.version
                color: window.ink
                font.family: window.uiFont; font.pixelSize: 32; font.weight: Font.DemiBold
                opacity: 0
                scale: 0.96
            }
            SequentialAnimation {
                running: true
                ParallelAnimation {
                    NumberAnimation { target: splashHalo; property: "scale"; from: 0.45; to: 1; duration: 620; easing.type: Easing.OutCubic }
                    NumberAnimation { target: splashHalo; property: "opacity"; from: 0.18; to: 0.72; duration: 360; easing.type: Easing.OutCubic }
                    NumberAnimation { target: splashAvatar; property: "scale"; from: 0.28; to: 1.08; duration: 680; easing.type: Easing.OutBack }
                    NumberAnimation { target: splashAvatar; property: "rotation"; from: -24; to: 360; duration: 680; easing.type: Easing.OutCubic }
                    NumberAnimation { target: splashAvatar; property: "opacity"; from: 0.18; to: 1; duration: 300; easing.type: Easing.OutCubic }
                }
                ParallelAnimation {
                    NumberAnimation { target: splashAvatar; property: "scale"; from: 1.08; to: 1; duration: 180; easing.type: Easing.OutCubic }
                    NumberAnimation { target: splashTitle; property: "opacity"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
                    NumberAnimation { target: splashTitle; property: "scale"; from: 0.96; to: 1; duration: 260; easing.type: Easing.OutCubic }
                }
                PauseAnimation { duration: 850 }
                NumberAnimation { target: splash; property: "opacity"; from: 1; to: 0; duration: 280; easing.type: Easing.InOutCubic }
                ScriptAction { script: splash.visible = false }
            }
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
            id: touchPage
            objectName: "meow-app-page"
            color: window.canvas

            Rectangle {
                id: touchPad
                anchors.fill: parent
                anchors { leftMargin: 24; rightMargin: 24; topMargin: 78; bottomMargin: 24 }
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

            AppHeader { title: "点击测试"; subtitle: "触摸与坐标验证"; trailingText: "清除"; trailingEnabled: true; onBackRequested: stack.pop(); onTrailingRequested: window.tapCount = 0 }
        }
    }

    Component {
        id: reactionGameComponent
        Rectangle {
            id: reactionPage
            objectName: "meow-app-page"
            color: window.canvas
            property bool running: false
            property int remaining: 30
            property int score: 0
            property int streak: 0
            property int best: 0
            property int targetSize: 112

            function placeTarget() {
                var margin = 28
                var minX = margin
                var maxX = Math.max(minX, gameBoard.width - targetSize - margin)
                var minY = margin
                var maxY = Math.max(minY, gameBoard.height - targetSize - margin)
                target.x = minX + Math.floor(Math.random() * (maxX - minX + 1))
                target.y = minY + Math.floor(Math.random() * (maxY - minY + 1))
            }
            function startGame() {
                score = 0
                streak = 0
                remaining = 30
                running = true
                placeTarget()
                gameTimer.restart()
            }
            function finishGame() {
                running = false
                gameTimer.stop()
                if (score > best) best = score
            }

            Component.onCompleted: placeTarget()

            AppHeader { title: "喵喵反应"; subtitle: "30 秒触摸挑战"; trailingText: "最佳 " + reactionPage.best; onBackRequested: stack.pop() }

            Row {
                anchors { top: parent.top; topMargin: 82; horizontalCenter: parent.horizontalCenter }
                spacing: 34
                Text { text: "得分 " + reactionPage.score; color: window.ink; font.family: window.uiFont; font.pixelSize: 22; font.weight: Font.DemiBold }
                Text { text: "连击 " + reactionPage.streak; color: window.pink; font.family: window.uiFont; font.pixelSize: 22; font.weight: Font.DemiBold }
                Text { text: "时间 " + reactionPage.remaining + "s"; color: reactionPage.remaining <= 5 ? "#FF3B30" : window.secondary; font.family: window.uiFont; font.pixelSize: 22; font.weight: Font.DemiBold }
            }

            Rectangle {
                id: gameBoard
                anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 24; topMargin: 122 }
                radius: 28; color: "#FFF8FA"; border.color: "#EFDCE5"; border.width: 2
                Text {
                    anchors.centerIn: parent
                    visible: !reactionPage.running
                    text: reactionPage.remaining === 0 ? "本轮结束\n得分 " + reactionPage.score : "点击开始，然后尽快点中绿色喵爪"
                    horizontalAlignment: Text.AlignHCenter
                    color: window.secondary; font.family: window.uiFont; font.pixelSize: 26; lineHeight: 1.25
                }
                Rectangle {
                    id: target
                    width: reactionPage.targetSize; height: reactionPage.targetSize; radius: width / 2
                    color: "#49B990"; border.color: "#FFFFFF"; border.width: 6
                    visible: reactionPage.running
                    Text { anchors.centerIn: parent; text: "喵"; color: "white"; font.family: window.uiFont; font.pixelSize: 36; font.weight: Font.Bold }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            reactionPage.score += 1
                            reactionPage.streak += 1
                            reactionPage.placeTarget()
                        }
                    }
                }
            }

            Button {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 34 }
                text: reactionPage.running ? "进行中…" : (reactionPage.remaining === 0 ? "再来一局" : "开始游戏")
                enabled: !reactionPage.running
                font.family: window.uiFont; font.pixelSize: 19; font.weight: Font.DemiBold
                contentItem: Text { text: parent.text; color: parent.enabled ? "white" : "#AAA5AC"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
                background: Rectangle { radius: 18; color: parent.enabled ? window.purple : "#E5E2E7" }
                onClicked: reactionPage.startGame()
            }

            Text {
                anchors { right: parent.right; bottom: parent.bottom; rightMargin: 40; bottomMargin: 48 }
                text: "最佳 " + reactionPage.best
                color: window.secondary; font.family: window.uiFont; font.pixelSize: 16
            }

            Timer {
                id: gameTimer
                interval: 1000; repeat: true
                onTriggered: {
                    reactionPage.remaining -= 1
                    if (reactionPage.remaining <= 0) reactionPage.finishGame()
                }
            }
        }
    }

    Component {
        id: settingsComponent
        Rectangle {
            id: settingsPage
            objectName: "meow-settings-page"
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
            readonly property var pageLoaders: [wifiPageLoader, ethernetPageLoader,
                                                batteryPageLoader, soundPageLoader,
                                                ch592PageLoader, displayPageLoader,
                                                performancePageLoader, storagePageLoader,
                                                aboutPageLoader]
            property int prewarmIndex: 0
            property int qaSwitchIndex: 0
            readonly property var qaSections: ["wifi", "ethernet", "battery", "sound", "ch592", "display", "performance", "storage", "about"]
            property double sectionSwitchStartedAt: 0
            property int lastSectionSwitchMs: -1
            function ensureCurrentPage() {
                if (!pageLoaders || sectionIndex < 0 || sectionIndex >= pageLoaders.length) return
                var loader = pageLoaders[sectionIndex]
                if (loader) {
                    loader.asynchronous = false
                    loader.active = true
                }
            }
            function openSection(name, index) {
                if (!pageLoaders || index < 0 || index >= pageLoaders.length) return
                // Construct the page synchronously while the previous page is
                // still visible. Switching StackLayout first exposes its empty
                // Loader for one frame on the initial visit.
                var loader = pageLoaders[index]
                sectionSwitchStartedAt = Date.now()
                if (loader) {
                    // A page already incubated in the background is ready
                    // immediately. If not, force completion before changing
                    // StackLayout.currentIndex so no blank frame is exposed.
                    loader.asynchronous = false
                    loader.active = true
                }
                section = name
            }
            onSectionChanged: {
                ensureCurrentPage()
                window.lastSettingsSection = section
                systemBackend.setActiveScope(section)
                if (sectionSwitchStartedAt > 0) {
                    lastSectionSwitchMs = Date.now() - sectionSwitchStartedAt
                    if (window.settingsQaMetrics)
                        console.log("[MeowOS] settings-switch", section, lastSectionSwitchMs, "ms")
                    sectionSwitchStartedAt = 0
                }
            }
            Component.onCompleted: {
                ensureCurrentPage()
                window.lastSettingsSection = section
                systemBackend.setActiveScope(section)
                prewarmTimer.start()
            }

            Timer {
                id: prewarmTimer
                interval: 35
                repeat: true
                onTriggered: {
                    while (settingsPage.prewarmIndex < settingsPage.pageLoaders.length
                           && settingsPage.pageLoaders[settingsPage.prewarmIndex].active)
                        settingsPage.prewarmIndex++
                    if (settingsPage.prewarmIndex >= settingsPage.pageLoaders.length) {
                        stop()
                        return
                    }
                    var loader = settingsPage.pageLoaders[settingsPage.prewarmIndex]
                    settingsPage.prewarmIndex++
                    if (loader && !loader.active) {
                        loader.asynchronous = true
                        loader.active = true
                    }
                }
            }

            Timer {
                id: qaSwitchTimer
                interval: 350
                repeat: true
                running: window.settingsQaSwitch
                triggeredOnStart: true
                onTriggered: {
                    if (settingsPage.qaSwitchIndex >= settingsPage.qaSections.length) {
                        stop()
                        return
                    }
                    var index = settingsPage.qaSwitchIndex++
                    settingsPage.openSection(settingsPage.qaSections[index], index)
                }
            }

            Rectangle {
                id: settingsSidebar
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 24 }
                width: 318; radius: 26; color: window.card

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 5

                    AppHeader { width: parent.width; title: "设置"; compact: true; onBackRequested: stack.pop() }

                    SettingsNavRow { title: "Wi-Fi"; icon: "qrc:/assets/icons/wifi.svg"; accent: window.mint; selected: settingsPage.section === "wifi"; onClicked: settingsPage.openSection("wifi", 0) }
                    SettingsNavRow { title: "有线网络"; icon: "qrc:/assets/icons/ethernet-port.svg"; accent: "#4A90E2"; selected: settingsPage.section === "ethernet"; onClicked: settingsPage.openSection("ethernet", 1) }
                    SettingsNavRow { title: "电池"; icon: "qrc:/assets/icons/battery-charging.svg"; accent: "#F1A244"; selected: settingsPage.section === "battery"; onClicked: settingsPage.openSection("battery", 2) }
                    SettingsNavRow { title: "声音"; icon: "qrc:/assets/icons/volume-2.svg"; accent: window.pink; selected: settingsPage.section === "sound"; onClicked: settingsPage.openSection("sound", 3) }
                    SettingsNavRow { title: "隔空喵传"; icon: "qrc:/assets/icons/zap-dark.svg"; accent: window.mint; selected: settingsPage.section === "ch592"; onClicked: settingsPage.openSection("ch592", 4) }
                    SettingsNavRow { title: "显示与触摸"; icon: "qrc:/assets/icons/monitor.svg"; accent: window.purple; selected: settingsPage.section === "display"; onClicked: settingsPage.openSection("display", 5) }
                    SettingsNavRow { title: "性能"; icon: "qrc:/assets/icons/cpu.svg"; accent: "#4AC7C2"; selected: settingsPage.section === "performance"; onClicked: settingsPage.openSection("performance", 6) }
                    SettingsNavRow { title: "存储空间"; icon: "qrc:/assets/icons/hard-drive.svg"; accent: "#5E93E8"; selected: settingsPage.section === "storage"; onClicked: settingsPage.openSection("storage", 7) }
                    SettingsNavRow { title: "关于本机"; icon: "qrc:/assets/icons/info.svg"; accent: "#8B8490"; selected: settingsPage.section === "about"; onClicked: settingsPage.openSection("about", 8) }
                }
            }

            Rectangle {
                anchors { left: settingsSidebar.right; right: parent.right; top: parent.top; bottom: parent.bottom; leftMargin: 18; rightMargin: 24; topMargin: 24; bottomMargin: 24 }
                radius: 26; color: window.card; clip: true
                StackLayout {
                    anchors.fill: parent
                    currentIndex: settingsPage.sectionIndex
                    // Create pages only when first visited, then retain them.
                    // Preloading every settings page kept expensive bindings and
                    // performance sampling alive after the user had moved on.
                    Loader { id: wifiPageLoader; active: false; asynchronous: true; sourceComponent: wifiSettings }
                    Loader { id: ethernetPageLoader; active: false; asynchronous: true; sourceComponent: ethernetSettings }
                    Loader { id: batteryPageLoader; active: false; asynchronous: true; sourceComponent: batterySettings }
                    Loader { id: soundPageLoader; active: false; asynchronous: true; sourceComponent: soundSettings }
                    Loader { id: ch592PageLoader; active: false; asynchronous: true; sourceComponent: ch592Settings }
                    Loader { id: displayPageLoader; active: false; asynchronous: true; sourceComponent: displaySettings }
                    Loader { id: performancePageLoader; active: false; asynchronous: true; sourceComponent: performanceSettings }
                    Loader { id: storagePageLoader; active: false; asynchronous: true; sourceComponent: storageSettings }
                    Loader { id: aboutPageLoader; active: false; asynchronous: true; sourceComponent: aboutSettings }
                }
            }
        }
    }

    Component {
        id: fileManagerComponent
        Rectangle {
            id: filesPage
            objectName: "meow-files-page"
            color: window.canvas
            property string currentFolder: "/home/radxa"
            property string currentLabel: "用户目录"
            property var folderHistory: []
            property var previewEntry: ({})
            property bool previewVisible: false
            property var selectedEntry: ({})
            property string clipboardPath: ""
            property string clipboardName: ""
            property bool clipboardMove: false
            property bool pastePending: false
            function enterFolder(url, label) {
                folderHistory.push({ url: currentFolder, label: currentLabel })
                currentFolder = url
                currentLabel = label
                systemBackend.browseDirectory(url)
            }
            function goBackFolder() {
                if (folderHistory.length === 0) return
                var previous = folderHistory.pop()
                currentFolder = previous.url
                currentLabel = previous.label
                systemBackend.browseDirectory(currentFolder)
            }
            function handleBack() {
                if (folderHistory.length > 0) goBackFolder()
                else stack.pop()
            }
            function readableSize(bytes) {
                if (bytes < 1024) return bytes + " B"
                if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB"
                if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB"
                return (bytes / 1073741824).toFixed(1) + " GB"
            }
            function suffix(name) {
                var dot = name.lastIndexOf(".")
                return dot > 0 ? name.slice(dot + 1).toLowerCase() : ""
            }
            function isImage(name) { return ["png", "jpg", "jpeg", "webp", "bmp", "gif"].indexOf(suffix(name)) >= 0 }
            function isText(name) { return ["txt", "md", "json", "csv", "log", "ini", "conf", "qml", "js", "cpp", "c", "h", "py", "sh", "xml", "yaml", "yml"].indexOf(suffix(name)) >= 0 }
            function entryIcon(entry) {
                if (entry.directory) return "qrc:/assets/icons/folder.svg"
                if (isImage(entry.name)) return "qrc:/assets/icons/image.svg"
                if (isText(entry.name)) return "qrc:/assets/icons/file-text.svg"
                return "qrc:/assets/icons/file.svg"
            }
            function entryColor(entry) {
                if (entry.directory) return "#4A90E2"
                if (isImage(entry.name)) return "#E76D9B"
                if (isText(entry.name)) return "#8B68E8"
                return "#7E8794"
            }
            function pathParts() {
                var result = [{ label: "系统盘", path: "/" }]
                if (currentFolder === "/") return result
                var names = currentFolder.split("/")
                var accumulated = ""
                for (var i = 0; i < names.length; ++i) {
                    if (!names[i].length) continue
                    accumulated += "/" + names[i]
                    result.push({ label: names[i], path: accumulated })
                }
                return result
            }
            function openEntry(entry) {
                if (entry.directory) {
                    enterFolder(entry.path, entry.name)
                    return
                }
                previewEntry = entry
                previewVisible = true
                if (isText(entry.name)) systemBackend.previewDocument(entry.path)
            }
            function canTransfer(path) {
                return (path.indexOf("/home/radxa/") === 0 || path.indexOf("/data/") === 0)
            }
            function stageTransfer(move) {
                if (!selectedEntry.path) return
                clipboardPath = selectedEntry.path
                clipboardName = selectedEntry.name
                clipboardMove = move
                selectedEntry = ({})
            }
            function pasteHere() {
                if (!clipboardPath.length || systemBackend.fileOperationRunning) return
                pastePending = true
                systemBackend.transferFile(clipboardPath, currentFolder, clipboardMove)
                Qt.callLater(function() {
                    if (!systemBackend.fileOperationRunning) filesPage.pastePending = false
                })
            }
            Connections {
                target: systemBackend
                function onFileOperationChanged() {
                    if (filesPage.pastePending && !systemBackend.fileOperationRunning) {
                        filesPage.pastePending = false
                        filesPage.clipboardPath = ""
                        filesPage.clipboardName = ""
                    }
                }
            }
            Component.onCompleted: systemBackend.browseDirectory(currentFolder)
            AppHeader { title: "文件"; subtitle: filesPage.currentLabel; trailingText: "收藏"; trailingEnabled: true; onBackRequested: filesPage.handleBack(); onTrailingRequested: systemBackend.addFavoriteLocation(filesPage.currentFolder, filesPage.currentLabel) }
            Flickable {
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 24; rightMargin: 24; topMargin: 74 }
                height: 52; contentWidth: Math.max(width, favoriteRow.width); clip: true; flickableDirection: Flickable.HorizontalFlick
                Row {
                    id: favoriteRow; height: parent.height; spacing: 10
                    Text { visible: systemBackend.favoriteLocations.length === 0; anchors.verticalCenter: parent.verticalCenter; text: "暂无收藏 · 进入目录后点击右上角“收藏”"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 16 }
                    Repeater {
                        model: systemBackend.favoriteLocations
                        delegate: Rectangle {
                            width: favoriteLabel.implicitWidth + 38; height: 44; radius: 15
                            color: filesPage.currentFolder === modelData.path ? "#7B6DF0" : "#FFFFFF"
                            border.color: filesPage.currentFolder === modelData.path ? "#7B6DF0" : "#DCD7E1"; border.width: 1
                            Row { anchors.centerIn: parent; spacing: 7; Rectangle { width: 9; height: 9; radius: 5; color: filesPage.currentFolder === modelData.path ? "#FFFFFF" : (index % 3 === 0 ? "#7B6DF0" : (index % 3 === 1 ? "#49B990" : "#4A90E2")) } Text { id: favoriteLabel; text: modelData.label; color: filesPage.currentFolder === modelData.path ? "white" : window.ink; font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.DemiBold } }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: { filesPage.folderHistory = []; filesPage.currentFolder = modelData.path; filesPage.currentLabel = modelData.label; systemBackend.browseDirectory(modelData.path) }
                                onPressAndHold: systemBackend.removeFavoriteLocation(modelData.path)
                            }
                        }
                    }
                }
            }
            Flickable {
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 30; rightMargin: 30; topMargin: 130 }
                height: 38; contentWidth: breadcrumbRow.width; clip: true; flickableDirection: Flickable.HorizontalFlick
                Row {
                    id: breadcrumbRow; spacing: 6
                    Repeater {
                        model: filesPage.pathParts()
                        delegate: Row {
                            spacing: 6
                            Text { visible: index > 0; text: "›"; color: "#AAA5AE"; font.pixelSize: 22; anchors.verticalCenter: parent.verticalCenter }
                            Rectangle {
                                width: crumbText.implicitWidth + 22; height: 34; radius: 11
                                color: index === filesPage.pathParts().length - 1 ? "#EDEAFF" : "transparent"
                                Text { id: crumbText; anchors.centerIn: parent; text: modelData.label; color: index === filesPage.pathParts().length - 1 ? window.purple : window.secondary; font.family: window.uiFont; font.pixelSize: 15; font.weight: index === filesPage.pathParts().length - 1 ? Font.DemiBold : Font.Normal }
                                MouseArea { anchors.fill: parent; onClicked: filesPage.enterFolder(modelData.path, modelData.label) }
                            }
                        }
                    }
                }
            }
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; leftMargin: 24; rightMargin: 24; topMargin: 172; bottomMargin: (filesPage.selectedEntry.path || filesPage.clipboardPath.length) ? 92 : 24 }
                radius: 22; color: "#FFFFFF"; border.color: window.separator; border.width: 1; clip: true
                ListView {
                    anchors.fill: parent; anchors.margins: 10; clip: true
                    model: systemBackend.fileEntries
                    boundsBehavior: Flickable.DragAndOvershootBounds
                    maximumFlickVelocity: 3200
                    delegate: Rectangle {
                        width: ListView.view.width; height: 60; radius: 14
                        color: filesPage.selectedEntry.path === modelData.path ? "#EEEAFE" : (fileMouse.pressed ? "#F0EDF3" : "#FFFFFF")
                        border.color: filesPage.selectedEntry.path === modelData.path ? "#BEB3F5" : "transparent"; border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 14
                            Rectangle { Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 12; color: filesPage.entryColor(modelData); Image { anchors.centerIn: parent; width: 23; height: 23; source: filesPage.entryIcon(modelData); sourceSize.width: 46; sourceSize.height: 46 } }
                            Text { Layout.fillWidth: true; text: modelData.name; color: window.ink; font.family: window.uiFont; font.pixelSize: 17; elide: Text.ElideRight }
                            ColumnLayout { spacing: 1; Text { Layout.alignment: Qt.AlignRight; text: modelData.directory ? "文件夹" : filesPage.readableSize(modelData.size); color: window.secondary; font.family: window.uiFont; font.pixelSize: 14 } Text { Layout.alignment: Qt.AlignRight; visible: !modelData.directory; text: modelData.modified; color: "#AAA5AE"; font.family: window.uiFont; font.pixelSize: 11 } }
                        }
                        MouseArea {
                            id: fileMouse; anchors.fill: parent
                            property bool held: false
                            onPressed: held = false
                            onPressAndHold: {
                                held = true
                                if (filesPage.canTransfer(modelData.path)) filesPage.selectedEntry = modelData
                                else systemBackend.operationMessage("系统位置为只读，不能复制或移动", false)
                            }
                            onClicked: if (!held) filesPage.openEntry(modelData)
                        }
                    }
                    Text { anchors.centerIn: parent; visible: !systemBackend.filesLoading && systemBackend.fileEntries.length === 0; text: systemBackend.filesError.length ? systemBackend.filesError : "这里还没有内容"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 18 }
                    BusyIndicator { anchors.centerIn: parent; running: systemBackend.filesLoading; visible: running }
                }
            }
            Rectangle {
                z: 600; visible: filesPage.selectedEntry.path || filesPage.clipboardPath.length
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 24; rightMargin: 24; bottomMargin: 18 }
                height: 62; radius: 20; color: "#FCFBFD"; border.color: "#DCD7E1"; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 12; spacing: 10
                    ColumnLayout { Layout.fillWidth: true; spacing: 0; Text { text: filesPage.selectedEntry.path ? filesPage.selectedEntry.name : filesPage.clipboardName; color: window.ink; font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.DemiBold; elide: Text.ElideMiddle; Layout.fillWidth: true } Text { text: filesPage.selectedEntry.path ? "选择操作" : (filesPage.clipboardMove ? "移动到当前目录" : "复制到当前目录"); color: window.secondary; font.family: window.uiFont; font.pixelSize: 12 } }
                    Rectangle { visible: filesPage.selectedEntry.path; Layout.preferredWidth: 76; Layout.preferredHeight: 40; radius: 13; color: "#EAF2FF"; Text { anchors.centerIn: parent; text: "复制"; color: "#3978C5"; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold } MouseArea { anchors.fill: parent; onClicked: filesPage.stageTransfer(false) } }
                    Rectangle { visible: filesPage.selectedEntry.path; Layout.preferredWidth: 76; Layout.preferredHeight: 40; radius: 13; color: "#EAF8F1"; Text { anchors.centerIn: parent; text: "移动"; color: "#238C69"; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold } MouseArea { anchors.fill: parent; onClicked: filesPage.stageTransfer(true) } }
                    Rectangle { visible: filesPage.clipboardPath.length > 0; Layout.preferredWidth: 116; Layout.preferredHeight: 40; radius: 13; color: window.purple; opacity: systemBackend.fileOperationRunning ? 0.5 : 1; Text { anchors.centerIn: parent; text: systemBackend.fileOperationRunning ? systemBackend.fileOperationText : "粘贴到这里"; color: "white"; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold } MouseArea { anchors.fill: parent; enabled: !systemBackend.fileOperationRunning; onClicked: filesPage.pasteHere() } }
                    Rectangle { Layout.preferredWidth: 68; Layout.preferredHeight: 40; radius: 13; color: "#F0EDF3"; Text { anchors.centerIn: parent; text: "取消"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14; font.weight: Font.DemiBold } MouseArea { anchors.fill: parent; onClicked: { filesPage.selectedEntry = ({}); filesPage.clipboardPath = ""; filesPage.clipboardName = "" } } }
                }
            }
            Rectangle {
                z: 1200; anchors.fill: parent; visible: filesPage.previewVisible; color: "#660B0A0D"
                MouseArea { anchors.fill: parent; onClicked: filesPage.previewVisible = false }
                Rectangle {
                    anchors.centerIn: parent; width: parent.width - 150; height: parent.height - 120; radius: 28; color: "#FCFBFD"; border.color: window.separator; border.width: 1; clip: true
                    MouseArea { anchors.fill: parent; onClicked: mouse.accepted = true }
                    RowLayout {
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 22 }
                        ColumnLayout { Layout.fillWidth: true; spacing: 2; Text { text: filesPage.previewEntry.name || "预览"; color: window.ink; font.family: window.uiFont; font.pixelSize: 23; font.weight: Font.Bold; elide: Text.ElideMiddle; Layout.fillWidth: true } Text { text: filesPage.readableSize(filesPage.previewEntry.size || 0) + " · " + (filesPage.previewEntry.modified || ""); color: window.secondary; font.family: window.uiFont; font.pixelSize: 13 } }
                        Rectangle { Layout.preferredWidth: 72; Layout.preferredHeight: 40; radius: 14; color: "#EEEAFE"; Text { anchors.centerIn: parent; text: "完成"; color: window.purple; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold } MouseArea { anchors.fill: parent; onClicked: filesPage.previewVisible = false } }
                    }
                    Image {
                        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 28; topMargin: 86 }
                        visible: filesPage.isImage(filesPage.previewEntry.name || "")
                        source: visible ? "file://" + encodeURI(filesPage.previewEntry.path) : ""
                        fillMode: Image.PreserveAspectFit; asynchronous: true; cache: false
                    }
                    Flickable {
                        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 28; topMargin: 86 }
                        visible: filesPage.isText(filesPage.previewEntry.name || ""); clip: true
                        contentWidth: width; contentHeight: previewText.implicitHeight + 20
                        Text { id: previewText; width: parent.width; text: systemBackend.previewLoading ? "正在读取…" : (systemBackend.previewError.length ? systemBackend.previewError : systemBackend.previewText); color: window.ink; font.family: window.uiFont; font.pixelSize: 15; wrapMode: Text.WrapAnywhere; lineHeight: 1.25 }
                    }
                    Column {
                        anchors.centerIn: parent; spacing: 12
                        visible: !filesPage.isImage(filesPage.previewEntry.name || "") && !filesPage.isText(filesPage.previewEntry.name || "")
                        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 72; height: 72; radius: 22; color: "#7E8794"; Image { anchors.centerIn: parent; width: 38; height: 38; source: "qrc:/assets/icons/file.svg" } }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "此文件暂不支持内容预览"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 17 }
                    }
                }
            }
        }
    }

    Component {
        id: wifiSettings
        Item {
            id: wifiPage
            property string expandedSsid: ""
            property string swipedSsid: ""
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

            SettingsFlickable {
                anchors.fill: parent
                contentHeight: wifiColumn.height + 60
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
                    height: systemBackend.wifiConnected ? 238 : 112
                    radius: 24
                    color: systemBackend.wifiConnected ? "#EAF8F1" : "#F4F2F6"
                    border.color: systemBackend.wifiConnected ? "#BCE8D1" : window.separator

                    MouseArea {
                        anchors.fill: parent; enabled: systemBackend.wifiConnected && !systemBackend.wifiOperating
                        onClicked: wifiPage.expandedSsid = ""
                    }

                    Column {
                        anchors.fill: parent; anchors.margins: 18; spacing: 10
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
                                          ? window.wifiDetailText(wifiPage.currentNetwork)
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
                            width: parent.width; height: 62; spacing: 18
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 4
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
                Column {
                    id: wifiList; width: parent.width; spacing: 8
                        Repeater {
                            model: systemBackend.wifiNetworks
                            delegate: Column {
                                id: networkEntry
                                width: parent.width
                                spacing: 8
                                visible: !modelData.active
                                property real swipeOffset: 0
                                property bool userDragging: false
                                readonly property int actionWidth: 112
                                function openSwipe() { swipeOffset = -actionWidth }
                                function closeSwipe() { swipeOffset = 0 }
                                Connections {
                                    target: wifiPage
                                    function onSwipedSsidChanged() {
                                        if (wifiPage.swipedSsid !== modelData.ssid) networkEntry.closeSwipe()
                                    }
                                }
                                Rectangle {
                                    id: swipeBackdrop
                                    width: parent.width; height: 82; radius: 18
                                    color: "#F9F9FB"; border.color: window.separator; border.width: 1
                                    clip: true
                                    Rectangle {
                                        id: forgetAction
                                        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                                        width: networkEntry.actionWidth
                                        color: forgetActionMouse.pressed ? "#D93645" : "#EB4D5C"
                                        visible: networkEntry.swipeOffset < -1 && modelData.saved
                                                 && !(systemBackend.wifiOperating && systemBackend.wifiOperationSsid === modelData.ssid)
                                        Text { anchors.centerIn: parent; text: "忘记网络"; color: "white"; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold }
                                        MouseArea {
                                            id: forgetActionMouse
                                            anchors.fill: parent
                                            enabled: visible && !systemBackend.wifiOperating
                                            onClicked: {
                                                wifiPage.swipedSsid = ""
                                                networkEntry.closeSwipe()
                                                systemBackend.forgetWifi(modelData.ssid)
                                            }
                                        }
                                    }
                                    Rectangle {
                                        // Keep the moving card's trailing edge square while swiping,
                                        // so its corner does not collide with the rounded red action.
                                        x: networkCard.x + networkCard.width - 20
                                        width: 20; height: networkCard.height
                                        color: networkCard.color
                                        visible: networkEntry.swipeOffset < -1
                                    }
                                    Rectangle {
                                        id: networkCard
                                        width: parent.width; height: 82; radius: 18
                                        color: networkMouse.pressed ? "#EEEAFE" : "#F9F9FB"
                                        border.color: window.separator
                                        border.width: networkEntry.swipeOffset < -1 ? 0 : 1
                                        opacity: systemBackend.wifiOperating ? 0.72 : 1
                                        x: networkEntry.swipeOffset
                                        Behavior on x {
                                            enabled: !networkEntry.userDragging
                                            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                                        }
                                        MouseArea {
                                            id: networkMouse
                                            anchors.fill: parent
                                            enabled: !systemBackend.wifiOperating
                                            property real pressX: 0
                                            property real pressY: 0
                                            property real startOffset: 0
                                            property bool mayDrag: false
                                            property bool hadOpenCard: false
                                            onPressed: {
                                                pressX = mouse.x
                                                pressY = mouse.y
                                                startOffset = networkEntry.swipeOffset
                                                mayDrag = false
                                                hadOpenCard = wifiPage.swipedSsid !== ""
                                                if (hadOpenCard && wifiPage.swipedSsid !== modelData.ssid) wifiPage.swipedSsid = ""
                                            }
                                            onPositionChanged: {
                                                if (!pressed) return
                                                if (!modelData.saved) return
                                                var dx = mouse.x - pressX
                                                var dy = mouse.y - pressY
                                                if (!mayDrag && Math.abs(dx) > 14 && Math.abs(dx) > Math.abs(dy)) {
                                                    mayDrag = true
                                                    networkEntry.userDragging = true
                                                }
                                                if (mayDrag) {
                                                    var w = networkEntry.actionWidth
                                                    var nx = Math.max(-w, Math.min(0, startOffset + (mouse.x - pressX)))
                                                    networkEntry.swipeOffset = nx
                                                }
                                            }
                                            onReleased: {
                                                if (mayDrag) {
                                                    var w = networkEntry.actionWidth
                                                    var open = networkEntry.swipeOffset <= -w / 2
                                                    networkEntry.userDragging = false
                                                    networkEntry.swipeOffset = open ? -w : 0
                                                    wifiPage.swipedSsid = open ? modelData.ssid : ""
                                                } else if (wifiPage.swipedSsid === modelData.ssid) {
                                                    wifiPage.swipedSsid = ""
                                                    networkEntry.closeSwipe()
                                                } else if (hadOpenCard) {
                                                    wifiPage.selectNetwork(modelData)
                                                } else {
                                                    wifiPage.selectNetwork(modelData)
                                                }
                                            }
                                            onCanceled: {
                                                if (mayDrag) {
                                                    var w = networkEntry.actionWidth
                                                    var open = networkEntry.swipeOffset <= -w / 2
                                                    networkEntry.userDragging = false
                                                    networkEntry.swipeOffset = open ? -w : 0
                                                    wifiPage.swipedSsid = open ? modelData.ssid : ""
                                                }
                                            }
                                        }
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
                                                        Layout.preferredWidth: 62; Layout.preferredHeight: 30; radius: 10
                                                        color: manageMouse.pressed ? "#DED8FF" : "#EEEAFE"
                                                        Text { anchors.centerIn: parent; text: "已保存"; color: "#6555D5"; font.family: window.uiFont; font.pixelSize: 13; font.weight: Font.DemiBold }
                                                        MouseArea {
                                                            id: manageMouse
                                                            anchors.fill: parent
                                                            onClicked: wifiPage.expandedSsid = (wifiPage.expandedSsid === modelData.ssid ? "" : modelData.ssid)
                                                        }
                                                    }
                                                }
                                                Text { text: window.wifiDetailText(modelData); color: window.secondary; font.family: window.uiFont; font.pixelSize: 14; elide: Text.ElideRight; Layout.fillWidth: true }
                                            }
                                            ColumnLayout {
                                                spacing: 2
                                                Text { text: modelData.signal + "%"; color: window.wifiSignalColor(modelData.signal); font.family: window.uiFont; font.pixelSize: 18; font.weight: Font.Bold; Layout.alignment: Qt.AlignRight }
                                                Text { text: modelData.rate; color: window.secondary; font.family: window.uiFont; font.pixelSize: 13; Layout.alignment: Qt.AlignRight }
                                            }
                                        }
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
            property bool openedCaptureDialog: false
            function openFirstPortForCapture() {
                if (!openedCaptureDialog && Qt.application.arguments.indexOf("--ethernet-config") >= 0
                        && systemBackend.ethernetPorts.length > 0) {
                    openedCaptureDialog = true
                    ethernetDialog.openFor(systemBackend.ethernetPorts[0])
                }
            }
            Connections {
                target: systemBackend
                function onEthernetChanged() { ethernetPage.openFirstPortForCapture() }
            }
            Component.onCompleted: {
                if (Qt.application.arguments.indexOf("--ethernet-config") >= 0) {
                    openedCaptureDialog = true
                    Qt.callLater(function() {
                        ethernetDialog.openFor(systemBackend.ethernetPorts.length > 0
                                               ? systemBackend.ethernetPorts[0]
                                               : ({ name: "eth0", connected: false, method: "auto" }))
                    })
                }
            }

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
                            onConfigureRequested: ethernetDialog.openFor(modelData)
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
                        color: systemBackend.batteryCharging ? "#E5F6EC" : "#E5E5EA"
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
                                source: systemBackend.batteryCharging
                                        ? "qrc:/assets/icons/zap-green.svg"
                                        : "qrc:/assets/icons/zap-dark.svg"
                                sourceSize.width: 52; sourceSize.height: 52
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: systemBackend.batteryPercent >= 0 ? systemBackend.batteryPercent + "%" : "--"
                                color: systemBackend.batteryCharging ? "#16733F" : "#3A3540"
                                font.family: window.uiFont; font.pixelSize: 36; font.weight: Font.Bold
                            }
                        }
                        Item {
                            visible: !systemBackend.batteryCharging
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
            IosGroup {
                width: parent.width
                IosInfoRow { label: "电量计通信"; value: systemBackend.gaugeCommunication ? "正常" : (systemBackend.gaugeError.length ? systemBackend.gaugeError : "未检测到"); valueColor: systemBackend.gaugeCommunication ? window.mint : "#D94052" }
                IosInfoRow { label: "剩余容量"; value: systemBackend.batteryRemainingMah >= 0 ? systemBackend.batteryRemainingMah + " mAh" : "未导出" }
                IosInfoRow { label: "满充容量"; value: systemBackend.batteryFullChargeMah >= 0 ? systemBackend.batteryFullChargeMah + " mAh" : "未导出" }
                IosInfoRow { label: "设计容量"; value: systemBackend.batteryDesignCapacityMah + " mAh" }
                IosInfoRow { label: "原始电压"; value: systemBackend.batteryRawVoltageMv >= 0 ? systemBackend.batteryRawVoltageMv + " mV" : "--" }
                IosInfoRow { label: "原始电流"; value: systemBackend.batteryRawCurrentMa + " mA"; last: true }
            }
            IosGroup {
                width: parent.width
                IosInfoRow { label: "校准状态"; value: systemBackend.batteryCalibrationStatus; valueColor: systemBackend.batteryCalibrationStatus.indexOf("失败") >= 0 ? "#D94052" : window.mint; last: systemBackend.batteryCalibrationSummary.length === 0 }
                Text { visible: systemBackend.batteryCalibrationSummary.length > 0; width: parent.width; leftPadding: 18; rightPadding: 18; bottomPadding: 12; text: systemBackend.batteryCalibrationSummary; color: window.secondary; font.family: window.uiFont; font.pixelSize: 13; wrapMode: Text.WordWrap }
                RowLayout {
                    width: parent.width; height: 52; spacing: 8
                    TextField { id: calibrationVoltage; Layout.fillWidth: true; placeholderText: "参考电压 mV"; text: systemBackend.batteryVoltageMv >= 0 ? String(systemBackend.batteryVoltageMv) : ""; inputMethodHints: Qt.ImhDigitsOnly }
                    TextField { id: calibrationCurrent; Layout.fillWidth: true; placeholderText: "参考电流 mA"; text: String(systemBackend.batteryCurrentMa); inputMethodHints: Qt.ImhFormattedNumbersOnly }
                    TextField { id: calibrationCapacity; Layout.fillWidth: true; placeholderText: "容量 mAh"; text: "10000"; inputMethodHints: Qt.ImhDigitsOnly }
                }
                RowLayout {
                    width: parent.width; height: 46; spacing: 10
                    CheckBox { id: calibrationStable; text: "已静置稳定"; Layout.fillWidth: true }
                    Button { text: "记录校准参考"; enabled: systemBackend.gaugeCommunication; onClicked: systemBackend.calibrateBattery(Number(calibrationVoltage.text), Number(calibrationCurrent.text), Number(calibrationCapacity.text), calibrationStable.checked) }
                    Button { text: "清除记录"; onClicked: systemBackend.clearBatteryCalibration() }
                }
                Text { width: parent.width; leftPadding: 18; rightPadding: 18; bottomPadding: 14; text: "本操作只保存参考值和偏差，不写入BQ27220未知数据区。确认外部万用表和电流参考稳定后再记录。"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 13; wrapMode: Text.WordWrap }
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
        SettingsFlickable {
            id: aboutFlick
            contentWidth: width
            contentHeight: aboutBody.y + aboutBody.height + 30
            SettingsPageBody {
                id: aboutBody
                title: "关于本机"
                subtitle: systemBackend.boardProfile
                Rectangle {
                    width: parent.width; height: 116; radius: 22
                    color: "#FFF7FA"; border.color: "#F3D5E1"; border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 18; spacing: 18
                        Image { Layout.preferredWidth: 78; Layout.preferredHeight: 78; source: "qrc:/assets/meowkj-avatar-circle.png"; fillMode: Image.PreserveAspectFit; smooth: true }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 4
                            Text { text: "Meow OS"; color: window.ink; font.family: window.uiFont; font.pixelSize: 28; font.weight: Font.Bold }
                            Text { text: systemBackend.boardProfile; color: "#B35A78"; font.family: window.uiFont; font.pixelSize: 16; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }
                }
                IosGroup {
                    width: parent.width
                    IosInfoRow { label: "系统版本"; value: "Meow OS " + systemBackend.version; valueColor: window.pink; emphasize: true }
                    IosInfoRow { label: "主机名"; value: systemBackend.hostname.length ? systemBackend.hostname : "--" }
                    IosInfoRow { label: "Linux 内核"; value: systemBackend.kernel.length ? systemBackend.kernel : "--"; last: true }
                }
                IosGroup {
                    width: parent.width
                    IosInfoRow { label: "显示输出"; value: systemBackend.hardwareCapabilities.display ? "可用" : "未检测到" }
                    IosInfoRow { label: "触摸输入"; value: systemBackend.hardwareCapabilities.touch ? "可用" : "未检测到"; last: true }
                }
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
        Rectangle { anchors.fill: parent; color: passwordDialog.opened ? "#590B0A0D" : "#00000000"; opacity: passwordDialog.opened ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 180 } } MouseArea { anchors.fill: parent; onClicked: passwordDialog.close() } }
        Rectangle {
            id: dialogContent
            width: 840; height: 154
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 78 }
            radius: 24; color: "#FCFBFD"; border.color: "#DEDCE2"; border.width: 1
            opacity: 0; scale: 0.96; layer.enabled: passwordDialog.opened || opacity > 0.01
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

    component NetworkField: Rectangle {
        property string label: ""
        property string value: ""
        property string placeholder: ""
        property bool selected: false
        signal tapped()
        width: parent ? parent.width : 0; height: 62; radius: 14
        color: "white"; border.color: selected ? window.purple : "#D8D5DD"; border.width: selected ? 2 : 1
        Column {
            anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; anchors.topMargin: 8; spacing: 2
            Text { text: label; color: selected ? window.purple : window.secondary; font.family: window.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold }
            Text { text: value.length ? value : placeholder; color: value.length ? window.ink : "#AAA5AE"; font.family: window.uiFont; font.pixelSize: 18; elide: Text.ElideRight; width: parent.width }
        }
        MouseArea { anchors.fill: parent; onClicked: parent.tapped() }
    }

    Item {
        id: ethernetDialog
        parent: scene; anchors.fill: parent; z: 2150; visible: false
        property var port: ({})
        property string interfaceName: ""
        property string connectionName: ""
        property bool connected: false
        property string method: "auto"
        property string addressText: ""
        property string prefixText: "24"
        property string gatewayText: ""
        property string dnsText: ""
        property string activeField: "address"
        function openFor(portInfo) {
            port = portInfo || ({})
            interfaceName = port.name || ""
            connectionName = port.connection || ""
            connected = port.connected === true
            method = port.method === "manual" ? "manual" : "auto"
            var ipv4 = String(port.ipv4 || "")
            var slash = ipv4.lastIndexOf("/")
            addressText = slash >= 0 ? ipv4.slice(0, slash) : ipv4
            prefixText = slash >= 0 ? ipv4.slice(slash + 1) : "24"
            gatewayText = String(port.gateway || "")
            dnsText = String(port.dns || "")
            activeField = "address"
            visible = true
        }
        function close() { visible = false }
        function fieldValue() {
            if (activeField === "address") return addressText
            if (activeField === "prefix") return prefixText
            if (activeField === "gateway") return gatewayText
            return dnsText
        }
        function setFieldValue(value) {
            if (activeField === "address") addressText = value
            else if (activeField === "prefix") prefixText = value
            else if (activeField === "gateway") gatewayText = value
            else dnsText = value
        }
        function typeKey(key) {
            var current = fieldValue()
            if (key === "backspace") setFieldValue(current.slice(0, -1))
            else if (key === "清除") setFieldValue("")
            else if (activeField === "prefix" && (key === "." || key === ",")) return
            else setFieldValue(current + key)
        }
        function nextField() {
            if (activeField === "address") activeField = "prefix"
            else if (activeField === "prefix") activeField = "gateway"
            else if (activeField === "gateway") activeField = "dns"
            else activeField = "address"
        }
        function applyConfiguration() {
            systemBackend.configureEthernet(interfaceName, connectionName, method, addressText,
                                            parseInt(prefixText || "0"), gatewayText, dnsText)
            close()
        }

        Rectangle { anchors.fill: parent; color: "#660B0A0D"; MouseArea { anchors.fill: parent; onClicked: ethernetDialog.close() } }
        Rectangle {
            width: 980; height: 590; anchors.centerIn: parent; radius: 28
            color: "#FCFBFD"; border.color: "#D9D5DE"; border.width: 1
            RowLayout {
                anchors.fill: parent; anchors.margins: 24; spacing: 24
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true; spacing: 14
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 1
                            Text { text: "配置 " + ethernetDialog.interfaceName; color: window.ink; font.family: window.uiFont; font.pixelSize: 27; font.weight: Font.Bold }
                            Text { text: ethernetDialog.connectionName.length ? ethernetDialog.connectionName : "新建有线连接"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14 }
                        }
                        Rectangle {
                            Layout.preferredWidth: 92; Layout.preferredHeight: 38; radius: 13
                            color: ethernetDialog.connected ? "#DDF5E7" : "#E8E8ED"
                            Text { anchors.centerIn: parent; text: ethernetDialog.connected ? "已连接" : "未连接"; color: ethernetDialog.connected ? "#20844A" : "#6F6A74"; font.family: window.uiFont; font.pixelSize: 14; font.weight: Font.DemiBold }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 46; radius: 14
                            color: ethernetDialog.method === "auto" ? window.purple : "#F0EDF3"
                            Text { anchors.centerIn: parent; text: "自动获取 DHCP"; color: ethernetDialog.method === "auto" ? "white" : window.ink; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold }
                            MouseArea { anchors.fill: parent; onClicked: ethernetDialog.method = "auto" }
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 46; radius: 14
                            color: ethernetDialog.method === "manual" ? window.purple : "#F0EDF3"
                            Text { anchors.centerIn: parent; text: "手动 IPv4"; color: ethernetDialog.method === "manual" ? "white" : window.ink; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold }
                            MouseArea { anchors.fill: parent; onClicked: ethernetDialog.method = "manual" }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 9; enabled: ethernetDialog.method === "manual"; opacity: enabled ? 1 : 0.35
                        RowLayout {
                            Layout.fillWidth: true; spacing: 9
                            NetworkField { Layout.fillWidth: true; label: "IPv4 地址"; value: ethernetDialog.addressText; placeholder: "192.168.1.20"; selected: ethernetDialog.activeField === "address"; onTapped: ethernetDialog.activeField = "address" }
                            NetworkField { Layout.preferredWidth: 112; label: "前缀"; value: ethernetDialog.prefixText; placeholder: "24"; selected: ethernetDialog.activeField === "prefix"; onTapped: ethernetDialog.activeField = "prefix" }
                        }
                        NetworkField { Layout.fillWidth: true; label: "默认网关"; value: ethernetDialog.gatewayText; placeholder: "192.168.1.1"; selected: ethernetDialog.activeField === "gateway"; onTapped: ethernetDialog.activeField = "gateway" }
                        NetworkField { Layout.fillWidth: true; label: "DNS 服务器"; value: ethernetDialog.dnsText; placeholder: "1.1.1.1, 8.8.8.8"; selected: ethernetDialog.activeField === "dns"; onTapped: ethernetDialog.activeField = "dns" }
                    }
                    Item { Layout.fillHeight: true }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 9
                        Rectangle {
                            Layout.preferredWidth: 112; Layout.preferredHeight: 46; radius: 14; color: "#F0EDF3"
                            Text { anchors.centerIn: parent; text: "取消"; color: window.ink; font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.DemiBold }
                            MouseArea { anchors.fill: parent; onClicked: ethernetDialog.close() }
                        }
                        Rectangle {
                            Layout.preferredWidth: 132; Layout.preferredHeight: 46; radius: 14
                            color: ethernetDialog.connected ? "#FFF0F1" : "#EAF8F2"
                            Text { anchors.centerIn: parent; text: ethernetDialog.connected ? "断开端口" : "连接端口"; color: ethernetDialog.connected ? "#C93646" : "#238C69"; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold }
                            MouseArea { anchors.fill: parent; onClicked: { systemBackend.setEthernetConnected(ethernetDialog.interfaceName, !ethernetDialog.connected); ethernetDialog.close() } }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            Layout.preferredWidth: 142; Layout.preferredHeight: 46; radius: 14; color: window.purple
                            Text { anchors.centerIn: parent; text: "应用配置"; color: "white"; font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.DemiBold }
                            MouseArea { anchors.fill: parent; onClicked: ethernetDialog.applyConfiguration() }
                        }
                    }
                }
                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: window.separator }
                ColumnLayout {
                    Layout.preferredWidth: 280; Layout.minimumWidth: 280; Layout.maximumWidth: 280
                    Layout.fillHeight: true; spacing: 10
                    Text { text: "数字键盘"; color: window.ink; font.family: window.uiFont; font.pixelSize: 18; font.weight: Font.DemiBold }
                    GridLayout {
                        columns: 3; columnSpacing: 8; rowSpacing: 8
                        Repeater {
                            model: ["1", "2", "3", "4", "5", "6", "7", "8", "9",
                                    ".", "0", "backspace", ",", "清除", "下一项"]
                            delegate: KeyboardKey {
                                label: modelData === "backspace" ? "" : modelData; keyWidth: 88
                                icon: modelData === "backspace" ? "qrc:/assets/icons/delete.svg" : ""
                                destructive: modelData === "清除"
                                accent: modelData === "下一项"
                                onTapped: modelData === "下一项" ? ethernetDialog.nextField()
                                                                       : ethernetDialog.typeKey(modelData)
                            }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 15; color: "#F4F2F6"
                        Column {
                            anchors.centerIn: parent; spacing: 3
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: ethernetDialog.activeField === "address" ? "IPv4 地址" : (ethernetDialog.activeField === "prefix" ? "前缀长度" : (ethernetDialog.activeField === "gateway" ? "默认网关" : "DNS 服务器")); color: window.secondary; font.family: window.uiFont; font.pixelSize: 12 }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: ethernetDialog.fieldValue().length ? ethernetDialog.fieldValue() : "等待输入"; color: window.ink; font.family: window.uiFont; font.pixelSize: 17; font.weight: Font.DemiBold }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }
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

    component SettingsFlickable: Flickable {
        id: settingsFlickRoot
        clip: true
        flickableDirection: Flickable.VerticalFlick
        // Match the iOS-like Wi-Fi list: allow a small elastic overscroll;
        // Flickable returns to its legal range after the release animation.
        boundsBehavior: Flickable.DragAndOvershootBounds
        maximumFlickVelocity: 3200
        flickDeceleration: 3600
        pressDelay: 0
        pixelAligned: true
        onContentHeightChanged: Qt.callLater(function() {
            if (!settingsFlickRoot.dragging && !settingsFlickRoot.flicking)
                settingsFlickRoot.returnToBounds()
        })
    }

    component PerfMetric: Rectangle {
        property string label: ""
        property string value: "--"
        property string note: ""
        property color accent: window.purple
        property color tint: "#F7F5FF"
        Layout.fillWidth: true
        Layout.preferredHeight: 78
        radius: 19; color: tint
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.22); border.width: 1
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
            Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 34; radius: 4; color: accent }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { text: label; color: window.secondary; font.family: window.uiFont; font.pixelSize: 13 }
                Text { text: value; color: window.ink; font.family: window.uiFont; font.pixelSize: 19; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            Text { visible: note.length > 0; text: note; color: accent; font.family: window.uiFont; font.pixelSize: 12; font.weight: Font.DemiBold }
        }
    }

    Component {
        id: performanceSettings
        Item {
            id: performancePage
            function historyValues(key) {
                var values = []
                var history = systemBackend.performanceHistory
                for (var i = 0; i < history.length; ++i) {
                    var value = history[i][key]
                    values.push(value >= 0 ? value : 0)
                }
                return values
            }
            readonly property int logicalCoreCount: Math.max(0, systemBackend.cpuUsage.length - 1)
            function coreUsage(core) {
                return systemBackend.cpuUsage.length > core + 1 ? systemBackend.cpuUsage[core + 1] : 0
            }
            function coreFrequency(core) {
                return systemBackend.cpuFrequencies.length > core ? systemBackend.cpuFrequencies[core] : -1
            }
            SettingsFlickable {
                id: performanceFlick
                anchors.fill: parent
                contentWidth: width
                contentHeight: performanceColumn.height + 52
                onMovementEnded: performanceReturnTimer.restart()
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 4
                    contentItem: Rectangle { radius: 2; color: "#C7C2CD"; opacity: 0.72 }
                    background: Item { }
                }
                Column {
                    id: performanceColumn
                    width: parent.width - 60; x: 30; y: 24; spacing: 14
                    RowLayout {
                        width: parent.width
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 2
                            Text { text: "性能"; color: window.ink; font.family: window.uiFont; font.pixelSize: 34; font.weight: Font.Bold }
                            Text { text: "处理器、图形与内存"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 17 }
                        }
                    }
                    RowLayout {
                        width: parent.width; height: 270; spacing: 14
                        Rectangle {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            Layout.minimumWidth: 500; radius: 26
                            color: "#F3F1FF"; border.color: "#D9D3FA"; border.width: 1
                            Column {
                                anchors.fill: parent; anchors.margins: 20; spacing: 10
                                RowLayout {
                                    width: parent.width
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 0
                                        Text { text: "CPU"; color: "#6558D9"; font.family: window.uiFont; font.pixelSize: 18; font.weight: Font.DemiBold }
                                        Text { text: performancePage.logicalCoreCount > 0 ? performancePage.logicalCoreCount + " 个逻辑核心" : "正在读取"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 13 }
                                    }
                                    Text { text: systemBackend.cpuTotal >= 0 ? systemBackend.cpuTotal + "%" : "--"; color: window.ink; font.family: window.uiFont; font.pixelSize: 46; font.weight: Font.Bold }
                                }
                                Canvas {
                                    id: cpuHistoryCanvas
                                    property var samples: performancePage.historyValues("cpu")
                                    width: parent.width; height: 116
                                    onSamplesChanged: requestPaint()
                                    onWidthChanged: requestPaint()
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)
                                        ctx.strokeStyle = "#E0DCF4"
                                        ctx.lineWidth = 1
                                        for (var grid = 1; grid < 4; ++grid) {
                                            var gy = grid * height / 4
                                            ctx.beginPath(); ctx.moveTo(0, gy); ctx.lineTo(width, gy); ctx.stroke()
                                        }
                                        if (!samples || samples.length === 0) return
                                        var step = width / Math.max(1, samples.length - 1)
                                        ctx.beginPath(); ctx.moveTo(0, height)
                                        for (var i = 0; i < samples.length; ++i) {
                                            var v = Math.max(0, Math.min(100, samples[i]))
                                            ctx.lineTo(i * step, height - v * height / 100)
                                        }
                                        ctx.lineTo((samples.length - 1) * step, height); ctx.closePath()
                                        ctx.fillStyle = "#DCD6FF"; ctx.fill()
                                        ctx.beginPath()
                                        for (var j = 0; j < samples.length; ++j) {
                                            var point = Math.max(0, Math.min(100, samples[j]))
                                            if (j === 0) ctx.moveTo(0, height - point * height / 100)
                                            else ctx.lineTo(j * step, height - point * height / 100)
                                        }
                                        ctx.strokeStyle = "#7367E8"; ctx.lineWidth = 3; ctx.lineJoin = "round"; ctx.lineCap = "round"; ctx.stroke()
                                    }
                                }
                                RowLayout {
                                    width: parent.width
                                    Text { text: "当前 " + (systemBackend.cpuFrequencyMhz > 0 ? systemBackend.cpuFrequencyMhz + " MHz" : "--"); color: window.secondary; font.family: window.uiFont; font.pixelSize: 13; Layout.fillWidth: true }
                                    Text { text: "最高 " + (systemBackend.cpuMaxFrequencyMhz > 0 ? systemBackend.cpuMaxFrequencyMhz + " MHz" : "--"); color: window.secondary; font.family: window.uiFont; font.pixelSize: 13; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                                    Text { text: "温度 " + (systemBackend.cpuTemperatureC > -100 ? systemBackend.cpuTemperatureC.toFixed(0) + "°C" : "--"); color: systemBackend.cpuTemperatureC >= 80 ? "#D94052" : window.secondary; font.family: window.uiFont; font.pixelSize: 13; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.preferredWidth: 286; Layout.minimumWidth: 286; Layout.maximumWidth: 286
                            Layout.fillHeight: true; spacing: 12
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 23
                                color: "#EAF8F2"; border.color: "#C5E9D9"; border.width: 1
                                Column {
                                    anchors.fill: parent; anchors.margins: 17; spacing: 7
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "GPU"; color: "#238C69"; font.family: window.uiFont; font.pixelSize: 17; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                        Text { text: systemBackend.gpuUsage >= 0 ? systemBackend.gpuUsage + "%" : (systemBackend.gpuFrequencyMhz > 0 ? systemBackend.gpuFrequencyMhz + " MHz" : "--"); color: window.ink; font.family: window.uiFont; font.pixelSize: 26; font.weight: Font.Bold }
                                    }
                                    Rectangle {
                                        width: parent.width; height: 8; radius: 4; color: "#CFEBDD"
                                        Rectangle { width: systemBackend.gpuUsage >= 0 ? parent.width * systemBackend.gpuUsage / 100 : 0; height: parent.height; radius: 4; color: "#26A879" }
                                    }
                                    Text { visible: systemBackend.gpuUsage >= 0; text: "图形处理器占用"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 12 }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 23
                                color: "#EAF5FC"; border.color: "#C6E1F1"; border.width: 1
                                Column {
                                    anchors.fill: parent; anchors.margins: 17; spacing: 7
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "内存"; color: "#237EBA"; font.family: window.uiFont; font.pixelSize: 17; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                        Text { text: systemBackend.memoryPercent >= 0 ? systemBackend.memoryPercent + "%" : "--"; color: window.ink; font.family: window.uiFont; font.pixelSize: 26; font.weight: Font.Bold }
                                    }
                                    Rectangle {
                                        width: parent.width; height: 8; radius: 4; color: "#D2E8F5"
                                        Rectangle { width: systemBackend.memoryPercent >= 0 ? parent.width * systemBackend.memoryPercent / 100 : 0; height: parent.height; radius: 4; color: "#268BCB" }
                                    }
                                    Text { text: systemBackend.memoryUsed + " / " + systemBackend.memoryTotal + " · 可用 " + systemBackend.memoryAvailable; color: window.secondary; font.family: window.uiFont; font.pixelSize: 12; elide: Text.ElideRight; width: parent.width }
                                }
                            }
                        }
                    }
                    Text { text: "系统"; color: window.ink; font.family: window.uiFont; font.pixelSize: 19; font.weight: Font.DemiBold }
                    RowLayout {
                        width: parent.width; spacing: 12
                        PerfMetric { label: "系统负载 · 1 / 5 / 15 分钟"; value: systemBackend.loadAverage.length ? systemBackend.loadAverage : "--"; accent: "#E88735"; tint: "#FFF5EA" }
                        PerfMetric { label: "运行时间"; value: systemBackend.uptime.length ? systemBackend.uptime : "--"; accent: "#26A879"; tint: "#ECF9F4" }
                        PerfMetric { label: "当前进程"; value: systemBackend.processCount >= 0 ? systemBackend.processCount + " 个" : "--"; accent: "#E05A86"; tint: "#FFF0F5" }
                    }
                    RowLayout {
                        width: parent.width
                        Text { text: "处理器核心"; color: window.ink; font.family: window.uiFont; font.pixelSize: 19; font.weight: Font.DemiBold; Layout.fillWidth: true }
                        Text { text: performancePage.logicalCoreCount > 0 ? performancePage.logicalCoreCount + " 个逻辑核心" : ""; color: window.secondary; font.family: window.uiFont; font.pixelSize: 13 }
                    }
                    GridLayout {
                        width: parent.width; columns: 4; columnSpacing: 10; rowSpacing: 10
                        Repeater {
                            model: performancePage.logicalCoreCount
                            delegate: Rectangle {
                                readonly property color coreAccent: index % 4 === 0 ? "#7367E8" : (index % 4 === 1 ? "#26A879" : (index % 4 === 2 ? "#268BCB" : "#E88735"))
                                readonly property int usageValue: performancePage.coreUsage(index)
                                readonly property int frequencyValue: performancePage.coreFrequency(index)
                                Layout.fillWidth: true; Layout.preferredHeight: 82; radius: 18
                                color: "#F9F8FB"; border.color: Qt.rgba(coreAccent.r, coreAccent.g, coreAccent.b, 0.22); border.width: 1
                                Column {
                                    anchors.fill: parent; anchors.margins: 12; spacing: 8
                                    RowLayout {
                                        width: parent.width
                                        Text { text: "CPU " + index; color: window.ink; font.family: window.uiFont; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                        Text { text: usageValue + "%"; color: coreAccent; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.Bold }
                                    }
                                    Rectangle {
                                        width: parent.width; height: 7; radius: 4; color: Qt.rgba(coreAccent.r, coreAccent.g, coreAccent.b, 0.13)
                                        Rectangle { width: Math.max(usageValue, 0) / 100 * parent.width; height: parent.height; radius: 4; color: coreAccent }
                                    }
                                    Text { text: frequencyValue > 0 ? frequencyValue + " MHz" : "频率不可用"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 12 }
                                }
                            }
                        }
                    }
                }
            }
            Timer {
                id: performanceReturnTimer
                interval: 120
                repeat: false
                onTriggered: {
                    // Let Flickable's elastic animation finish first. If the
                    // signal arrived at the end of the fling but the rebound
                    // is still active, check again rather than snapping early.
                    if (performanceFlick.dragging || performanceFlick.flicking) {
                        restart()
                        return
                    }
                    performanceFlick.returnToBounds()
                }
            }
            Timer {
                interval: 2000
                running: window.settingsForeground && window.lastSettingsSection === "performance"
                repeat: true
                triggeredOnStart: true
                onTriggered: systemBackend.refreshPerformance()
            }
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
            anchors { left: parent.left; leftMargin: 28; verticalCenter: parent.verticalCenter }
            spacing: 14
            Text { text: window.clockTime; color: window.ink; font.family: window.uiFont; font.pixelSize: 17; font.weight: Font.DemiBold }
            Text { text: window.clockDate; color: window.secondary; font.family: window.uiFont; font.pixelSize: 16 }
        }

        Row {
            anchors { right: parent.right; rightMargin: 28; verticalCenter: parent.verticalCenter }
            spacing: 12

            Rectangle {
                id: powerStatusCard
                width: Math.max(78, powerStatusText.implicitWidth + 30); height: 30; radius: 10
                anchors.verticalCenter: parent.verticalCenter
                color: systemBackend.batteryCharging ? "#EAF8F1"
                                                     : (systemBackend.batteryPowerW >= 3 ? "#FFF3E6" : "#F3F1F4")
                border.color: systemBackend.batteryCharging ? "#BCE8D1"
                                                            : (systemBackend.batteryPowerW >= 3 ? "#F2D2AE" : "#E0DCE3")
                border.width: 1
                Row {
                    anchors.centerIn: parent; spacing: 3
                    Image {
                        width: 14; height: 16; anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/assets/icons/zap-dark.svg"; sourceSize.width: 28; sourceSize.height: 32
                        opacity: systemBackend.batteryAvailable ? 0.9 : 0.35
                    }
                    Text {
                        id: powerStatusText
                        anchors.verticalCenter: parent.verticalCenter
                        text: window.batteryPowerLabel().replace(" W", "W")
                        color: window.batteryPowerColor()
                        font.family: window.uiFont; font.pixelSize: 14; font.weight: Font.DemiBold
                    }
                }
            }

            Image {
                width: 23; height: 23
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:/assets/icons/wifi.svg"
                sourceSize.width: 50; sourceSize.height: 50
                opacity: systemBackend.wifiConnected ? 1 : 0.28
            }

            Row {
                spacing: 5
                anchors.verticalCenter: parent.verticalCenter
                Image { width: 23; height: 23; source: "qrc:/assets/icons/volume-2.svg"; sourceSize.width: 46; sourceSize.height: 46; opacity: systemBackend.volumePercent >= 0 ? 1 : 0.28 }
                Text { anchors.verticalCenter: parent.verticalCenter; text: systemBackend.volumePercent >= 0 ? systemBackend.volumePercent + "%" : "--"; color: window.ink; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.Medium }
            }

            Item {
                id: statusBattery
                width: 64; height: 30
                anchors.verticalCenter: parent.verticalCenter
                property color trackColor: systemBackend.batteryCharging ? "#DDF4E6" : "#E5E5EA"
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
                            source: systemBackend.batteryCharging
                                    ? "qrc:/assets/icons/zap-green.svg"
                                    : "qrc:/assets/icons/zap-dark.svg"
                            sourceSize.width: 22; sourceSize.height: 28
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: systemBackend.batteryPercent >= 0 ? systemBackend.batteryPercent : "--"
                            color: systemBackend.batteryCharging ? "#16733F" : "#3A3540"
                            font.family: window.uiFont
                            font.pixelSize: 14
                            font.weight: Font.Bold
                        }
                    }

                    Item {
                        visible: !systemBackend.batteryCharging
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

    component AppHeader: Rectangle {
        id: appHeader
        property string title: ""
        property string subtitle: ""
        property string trailingText: ""
        property bool compact: false
        property bool trailingEnabled: false
        signal backRequested()
        signal trailingRequested()
        z: 700
        width: parent ? parent.width : 0
        height: 66
        color: "#FCFBFD"
        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: window.separator }
        RowLayout {
            anchors { fill: parent; leftMargin: appHeader.compact ? 0 : 18; rightMargin: appHeader.compact ? 0 : 22 }
            spacing: 10
            CompactBackButton { Layout.preferredWidth: 52; Layout.preferredHeight: 52; onClicked: appHeader.backRequested() }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                Text { text: appHeader.title; color: window.ink; font.family: window.uiFont; font.pixelSize: appHeader.compact ? 28 : 30; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { visible: !appHeader.compact && appHeader.subtitle.length > 0; text: appHeader.subtitle; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14; Layout.fillWidth: true; elide: Text.ElideRight }
            }
            Rectangle {
                visible: appHeader.trailingText.length > 0
                Layout.preferredWidth: Math.max(68, trailingLabel.implicitWidth + 28)
                Layout.preferredHeight: 38; radius: 13
                color: appHeader.trailingEnabled && trailingMouse.pressed ? "#E2DDFB" : "#EEEAFE"
                Text { id: trailingLabel; anchors.centerIn: parent; text: appHeader.trailingText; color: window.purple; font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.DemiBold }
                MouseArea { id: trailingMouse; anchors.fill: parent; enabled: appHeader.trailingEnabled; onClicked: appHeader.trailingRequested() }
            }
        }
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
        property url icon: ""
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
            visible: icon.toString().length === 0
            anchors.centerIn: parent
            text: label
            color: accent || destructive ? "white" : window.ink
            font.family: window.uiFont; font.pixelSize: 17; font.weight: Font.Medium
        }
        Image {
            visible: icon.toString().length > 0
            anchors.centerIn: parent; width: 24; height: 24
            source: icon; sourceSize.width: 48; sourceSize.height: 48; smooth: true
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
        signal configureRequested()
        height: 206
        radius: 22
        color: tint
        border.color: outline
        border.width: 1

        RowLayout {
            id: ethernetHeader
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
            height: 62; spacing: 14
            Rectangle {
                Layout.preferredWidth: 52; Layout.preferredHeight: 52; radius: 16
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
                          ? ((port.connection || "").length > 0
                             ? port.connection
                             : ((port.ipv4 || "").length > 0 ? "已接入局域网" : "网线已连接，正在获取地址"))
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
            Rectangle {
                Layout.preferredWidth: 76; Layout.preferredHeight: 38; radius: 13
                color: ethernetConfigMouse.pressed ? Qt.darker(accent, 1.12) : accent
                opacity: systemBackend.ethernetOperating ? 0.55 : 1
                Text { anchors.centerIn: parent; text: "配置"; color: "white"; font.family: window.uiFont; font.pixelSize: 15; font.weight: Font.DemiBold }
                MouseArea { id: ethernetConfigMouse; anchors.fill: parent; enabled: !systemBackend.ethernetOperating; onClicked: configureRequested() }
            }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: ethernetHeader.bottom; leftMargin: 18; rightMargin: 18; topMargin: 14 }
            height: 1; color: outline
        }

        RowLayout {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 20; rightMargin: 20; bottomMargin: 20 }
            height: 70; spacing: 16
            ColumnLayout {
                Layout.preferredWidth: 188; spacing: 5
                Text { text: "IPv4 地址"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14 }
                Text {
                    text: connected ? ((port.ipv4 || "").length > 0 ? port.ipv4 : "正在获取…") : "--"
                    color: window.ink; font.family: window.uiFont; font.pixelSize: 17; font.weight: Font.DemiBold
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 44; color: outline }
            ColumnLayout {
                Layout.preferredWidth: 154; spacing: 5
                Text { text: "默认网关"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14 }
                Text {
                    text: connected && (port.gateway || "").length > 0 ? port.gateway : "--"
                    color: window.ink; font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.DemiBold
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 44; color: outline }
            ColumnLayout {
                Layout.preferredWidth: 166; spacing: 5
                Text { text: "连接速率"; color: window.secondary; font.family: window.uiFont; font.pixelSize: 14 }
                Text {
                    text: connected && port.speed > 0
                          ? port.speed + " Mb/s · " + window.ethernetDuplexText(port.duplex)
                          : "未协商"
                    color: window.ink; font.family: window.uiFont; font.pixelSize: 16; font.weight: Font.DemiBold
                }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 44; color: outline }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 5
                Text {
                    text: port && port.mtu > 0 ? "MAC · MTU " + port.mtu : "MAC 地址"
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
