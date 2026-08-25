import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: statusBar
    height: window.statusBarHeight
    color: "#FCFBFD"
    border.color: window.separator
    border.width: 1

    property int appDepth: stack ? stack.depth : 1
    signal exitRequested()

    // Left Section: Brand & Telemetry Status Indicators
    Row {
        anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
        spacing: 12

        // Brand Pill
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            Image {
                width: 24; height: 24
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:/assets/meowkj-avatar-circle.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Meow OS"
                color: window.ink
                font.family: window.uiFont
                font.pixelSize: 15
                font.weight: Font.Bold
            }
        }

        Rectangle {
            width: 1; height: 20
            color: window.separator
            anchors.verticalCenter: parent.verticalCenter
        }

        // 1. 电量 (Battery) - Mini Battery Capsule with dynamic fill level + Percentage
        Rectangle {
            id: batteryStatusCard
            width: Math.max(76, batteryRow.implicitWidth + 20); height: 30; radius: 10
            anchors.verticalCenter: parent.verticalCenter
            color: systemBackend.batteryCharging ? "#ECFDF5"
                                                 : (systemBackend.batteryPercent <= 20 && systemBackend.batteryPercent >= 0 ? "#FEF2F2" : "#F8FAFC")
            border.color: systemBackend.batteryCharging ? "#A7F3D0"
                                                        : (systemBackend.batteryPercent <= 20 && systemBackend.batteryPercent >= 0 ? "#FECACA" : "#E2E8F0")
            border.width: 1

            Row {
                id: batteryRow
                anchors.centerIn: parent
                spacing: 6

                // Mini Battery Capsule Graphic
                Item {
                    width: 22
                    height: 12
                    anchors.verticalCenter: parent.verticalCenter

                    // Battery Body Outline
                    Rectangle {
                        id: miniBatteryBody
                        width: 19
                        height: 12
                        radius: 3.5
                        color: "transparent"
                        border.color: systemBackend.batteryCharging ? "#059669"
                                                                    : (systemBackend.batteryPercent <= 20 && systemBackend.batteryPercent >= 0 ? "#DC2626" : "#475569")
                        border.width: 1.5

                        // Battery Fill
                        Rectangle {
                            x: 2; y: 2
                            height: parent.height - 4
                            width: systemBackend.batteryPercent >= 0 ? Math.max(2, (parent.width - 4) * Math.min(100, systemBackend.batteryPercent) / 100) : 0
                            radius: 1.5
                            color: systemBackend.batteryCharging ? "#10B981"
                                                                 : (systemBackend.batteryPercent <= 20 ? "#EF4444" : "#1F2937")
                        }
                    }

                    // Battery Terminal Cap
                    Rectangle {
                        anchors.left: miniBatteryBody.right
                        anchors.leftMargin: 1
                        anchors.verticalCenter: miniBatteryBody.verticalCenter
                        width: 2
                        height: 5
                        radius: 1
                        color: miniBatteryBody.border.color
                    }
                }

                Text {
                    id: batteryStatusText
                    anchors.verticalCenter: parent.verticalCenter
                    text: systemBackend.batteryPercent >= 0 ? (systemBackend.batteryPercent + "%") : "--"
                    color: systemBackend.batteryCharging ? "#059669"
                                                         : (systemBackend.batteryPercent <= 20 && systemBackend.batteryPercent >= 0 ? "#DC2626" : "#0F172A")
                    font.family: window.uiFont
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }
            }
        }

        // 2. RAM Usage Telemetry Badge (内存使用率 - 图标清晰，无 RAM 字样，统一设计语言)
        Rectangle {
            id: ramStatusCard
            width: Math.max(68, ramStatusText.implicitWidth + 34); height: 30; radius: 10
            anchors.verticalCenter: parent.verticalCenter
            color: systemBackend.memoryPercent >= 80 ? "#FFF0F2" : "#EDF5FE"
            border.color: systemBackend.memoryPercent >= 80 ? "#F8C6CE" : "#C7DEF8"
            border.width: 1
            Row {
                anchors.centerIn: parent; spacing: 4
                Image {
                    width: 14; height: 14; anchors.verticalCenter: parent.verticalCenter
                    source: "qrc:/assets/icons/ram-chip.svg"; sourceSize.width: 28; sourceSize.height: 28
                    opacity: 0.9
                }
                Text {
                    id: ramStatusText
                    anchors.verticalCenter: parent.verticalCenter
                    text: systemBackend.memoryPercent >= 0 ? (systemBackend.memoryPercent + "%") : "--"
                    color: systemBackend.memoryPercent >= 80 ? "#EB4D5C" : "#2072D4"
                    font.family: window.uiFont; font.pixelSize: 13; font.weight: Font.DemiBold
                }
            }
        }

        // 3. Power Telemetry Badge (功率 - Energy Zap Icon + Wattage)
        Rectangle {
            id: powerStatusCard
            width: Math.max(76, powerRow.implicitWidth + 20); height: 30; radius: 10
            anchors.verticalCenter: parent.verticalCenter
            color: systemBackend.batteryCharging ? "#ECFDF5"
                                                 : (systemBackend.batteryPowerW >= 3 ? "#FFFBEB" : "#F8FAFC")
            border.color: systemBackend.batteryCharging ? "#A7F3D0"
                                                        : (systemBackend.batteryPowerW >= 3 ? "#FDE68A" : "#E2E8F0")
            border.width: 1
            Row {
                id: powerRow
                anchors.centerIn: parent; spacing: 5
                Image {
                    width: 12; height: 14; anchors.verticalCenter: parent.verticalCenter
                    source: systemBackend.batteryCharging ? "qrc:/assets/icons/zap-green.svg" : "qrc:/assets/icons/zap-dark.svg"
                    sourceSize.width: 24; sourceSize.height: 28
                    opacity: systemBackend.batteryAvailable ? 0.9 : 0.4
                }
                Text {
                    id: powerStatusText
                    anchors.verticalCenter: parent.verticalCenter
                    text: window.batteryPowerLabel().replace(" W", "W")
                    color: systemBackend.batteryCharging ? "#059669"
                                                         : (systemBackend.batteryPowerW >= 3 ? "#D97706" : "#0F172A")
                    font.family: window.uiFont; font.pixelSize: 13; font.weight: Font.Bold
                }
            }
        }

        // 4. Volume Badge (音量 - 位于 Wi-Fi 前，色彩优化: 珊瑚粉主调，静音/不可用时浅灰)
        Rectangle {
            id: volumeStatusCard
            readonly property bool volActive: systemBackend.volumePercent > 0
            readonly property bool volMuted: systemBackend.volumePercent === 0
            width: Math.max(68, volumeRow.implicitWidth + 20); height: 30; radius: 10
            anchors.verticalCenter: parent.verticalCenter
            color: volActive ? "#FDF2F8" : "#F8FAFC"
            border.color: volActive ? "#FCE7F3" : "#E2E8F0"
            border.width: 1

            Row {
                id: volumeRow
                anchors.centerIn: parent
                spacing: 5
                Image {
                    width: 14; height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    source: volumeStatusCard.volActive ? "qrc:/assets/icons/volume-pink.svg" : "qrc:/assets/icons/volume-2.svg"
                    sourceSize.width: 28; sourceSize.height: 28
                    opacity: volumeStatusCard.volActive ? 0.95 : (volumeStatusCard.volMuted ? 0.45 : 0.28)
                }
                Text {
                    id: volumeStatusText
                    anchors.verticalCenter: parent.verticalCenter
                    text: systemBackend.volumePercent >= 0 ? (systemBackend.volumePercent + "%") : "--"
                    color: volumeStatusCard.volActive ? "#DB2777" : "#94A3B8"
                    font.family: window.uiFont
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }
            }
        }

        // 5. Wi-Fi Badge (通过色彩表达信号质量: ≥70% 翡翠绿, 40-69% 太阳橙, <40% 警戒红, 未连接 灰色)
        Rectangle {
            id: wifiStatusCard
            readonly property int sig: systemBackend.wifiConnected ? (systemBackend.wifiSignal > 0 ? systemBackend.wifiSignal : 100) : 0
            readonly property color sigColor: !systemBackend.wifiConnected ? "#94A3B8" : (sig >= 70 ? "#10B981" : (sig >= 40 ? "#F59E0B" : "#EF4444"))
            readonly property color sigBg: !systemBackend.wifiConnected ? "#F8FAFC" : (sig >= 70 ? "#ECFDF5" : (sig >= 40 ? "#FFFBEB" : "#FEF2F2"))
            readonly property color sigBorder: !systemBackend.wifiConnected ? "#E2E8F0" : (sig >= 70 ? "#A7F3D0" : (sig >= 40 ? "#FDE68A" : "#FECACA"))

            width: 36; height: 30; radius: 10
            anchors.verticalCenter: parent.verticalCenter
            color: sigBg
            border.color: sigBorder
            border.width: 1

            Item {
                anchors.centerIn: parent
                width: 16; height: 16
                Image {
                    anchors.centerIn: parent
                    width: 16; height: 16
                    source: "qrc:/assets/icons/wifi.svg"
                    sourceSize.width: 32; sourceSize.height: 32
                    opacity: systemBackend.wifiConnected ? 0.9 : 0.3
                }
            }

            // Signal Quality Indicator Dot
            Rectangle {
                visible: systemBackend.wifiConnected
                width: 6; height: 6; radius: 3
                anchors { right: parent.right; bottom: parent.bottom; margins: 3 }
                color: wifiStatusCard.sigColor
                border.color: "white"; border.width: 1
            }
        }
    }

    // Right Section: Unified Super-Advanced App Exit Button
    Rectangle {
        id: exitAppCapsule
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        readonly property bool active: statusBar.appDepth > 1
        width: active ? 112 : 0
        height: 36
        radius: 18
        color: exitMouse.pressed ? "#D93645" : "#EB4D5C"
        border.color: "#FF7382"
        border.width: 1
        clip: true
        opacity: active ? 1 : 0
        scale: exitMouse.pressed ? 0.92 : (active ? 1.0 : 0.8)

        Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        Row {
            anchors.centerIn: parent
            spacing: 6
            Rectangle {
                width: 18; height: 18; radius: 9
                color: "#FFFFFF"
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: "#EB4D5C"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "退出应用"
                color: "white"
                font.family: window.uiFont
                font.pixelSize: 14
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: exitMouse
            anchors.fill: parent
            enabled: exitAppCapsule.active
            onClicked: statusBar.exitRequested()
        }
    }
}
