import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: dialogRoot
    property bool opened: false
    property int referenceVoltage: systemBackend.batteryRawVoltageMv > 0 ? systemBackend.batteryRawVoltageMv : 4000
    property int referenceCurrent: 0
    property int designCapacity: systemBackend.batteryDesignCapacityMah > 0 ? systemBackend.batteryDesignCapacityMah : 10000
    property bool stableConfirmed: false
    signal closed()

    anchors.fill: parent
    z: 5000
    visible: opened || opacity > 0.01
    opacity: opened ? 1 : 0
    color: "#77000000"
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    // Consume touch events to prevent background clicks
    MouseArea { anchors.fill: parent; onClicked: {} }

    Rectangle {
        id: dialogCard
        width: Math.min(parent.width - 48, 640)
        height: Math.min(parent.height - 48, 540)
        anchors.centerIn: parent
        radius: 24
        color: "#FFFFFF"
        border.color: "#E2DFF0"
        border.width: 1
        clip: true

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            RowLayout {
                width: parent.width
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Text {
                        text: "电量计安全两点校准"
                        color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 22; font.weight: Font.Bold
                    }
                    Text {
                        text: "针对 1S 4.2V (10000 mAh) 电池进行实测电压与电流标定"
                        color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 13
                    }
                }
                Rectangle {
                    width: 36; height: 36; radius: 18; color: closeMouse.pressed ? "#EAE6F4" : "#F5F3FF"
                    Text { anchors.centerIn: parent; text: "✕"; color: "#6558D9"; font.pixelSize: 16; font.weight: Font.Bold }
                    MouseArea { id: closeMouse; anchors.fill: parent; onClicked: dialogRoot.opened = false }
                }
            }

            // Realtime Gauge Readout Card
            Rectangle {
                width: parent.width; height: 72; radius: 14
                color: "#F6F5FC"; border.color: "#E5E1F8"; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 14
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: "BQ27220 原始采样"; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 12 }
                        Text {
                            text: (systemBackend.batteryRawVoltageMv > 0 ? systemBackend.batteryRawVoltageMv + " mV" : "--")
                                  + "  ·  " + systemBackend.batteryRawCurrentMa + " mA"
                            color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 16; font.weight: Font.DemiBold
                        }
                    }
                    Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#DCD7F0" }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: "当前校准状态"; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 12 }
                        Text {
                            text: systemBackend.batteryCalibrationStatus
                            color: systemBackend.batteryCalibrationStatus.indexOf("已") >= 0 ? "#10B981" : "#F59E0B"
                            font.family: "Noto Sans CJK SC"; font.pixelSize: 14; font.weight: Font.DemiBold
                            elide: Text.ElideRight; Layout.fillWidth: true
                        }
                    }
                }
            }

            // Warning if charging
            Rectangle {
                visible: systemBackend.batteryCharging
                width: parent.width; height: 38; radius: 10
                color: "#FFF4F2"; border.color: "#FFD0C7"; border.width: 1
                Row {
                    anchors.centerIn: parent; spacing: 8
                    Text { text: "⚠️ 正在充电中：安全规则要求拔掉电源静置后校准电流"; color: "#D93829"; font.family: "Noto Sans CJK SC"; font.pixelSize: 12; font.weight: Font.DemiBold }
                }
            }

            // Voltage Reference Input
            RowLayout {
                width: parent.width; height: 44
                Text { text: "实测参考电压 (mV)"; color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.preferredWidth: 160 }
                Rectangle {
                    Layout.fillWidth: true; height: 38; radius: 10; color: "#F8F7FF"; border.color: "#D8D0F5"; border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 4; spacing: 4
                        Rectangle {
                            width: 32; height: 30; radius: 6; color: vMinus.pressed ? "#DDD7F5" : "#EBE6FC"
                            Text { anchors.centerIn: parent; text: "−10"; color: "#5648C8"; font.pixelSize: 11; font.weight: Font.Bold }
                            MouseArea { id: vMinus; anchors.fill: parent; onClicked: dialogRoot.referenceVoltage = Math.max(3000, dialogRoot.referenceVoltage - 10) }
                        }
                        Text {
                            text: dialogRoot.referenceVoltage + " mV"
                            color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 16; font.weight: Font.Bold
                            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                        }
                        Rectangle {
                            width: 32; height: 30; radius: 6; color: vPlus.pressed ? "#DDD7F5" : "#EBE6FC"
                            Text { anchors.centerIn: parent; text: "+10"; color: "#5648C8"; font.pixelSize: 11; font.weight: Font.Bold }
                            MouseArea { id: vPlus; anchors.fill: parent; onClicked: dialogRoot.referenceVoltage = Math.min(4350, dialogRoot.referenceVoltage + 10) }
                        }
                    }
                }
            }

            // Current Reference Input
            RowLayout {
                width: parent.width; height: 44
                Text { text: "实测参考电流 (mA)"; color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.preferredWidth: 160 }
                Rectangle {
                    Layout.fillWidth: true; height: 38; radius: 10; color: "#F8F7FF"; border.color: "#D8D0F5"; border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 4; spacing: 4
                        Rectangle {
                            width: 32; height: 30; radius: 6; color: iMinus.pressed ? "#DDD7F5" : "#EBE6FC"
                            Text { anchors.centerIn: parent; text: "−50"; color: "#5648C8"; font.pixelSize: 11; font.weight: Font.Bold }
                            MouseArea { id: iMinus; anchors.fill: parent; onClicked: dialogRoot.referenceCurrent -= 50 }
                        }
                        Text {
                            text: dialogRoot.referenceCurrent + " mA"
                            color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 16; font.weight: Font.Bold
                            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter
                        }
                        Rectangle {
                            width: 32; height: 30; radius: 6; color: iPlus.pressed ? "#DDD7F5" : "#EBE6FC"
                            Text { anchors.centerIn: parent; text: "+50"; color: "#5648C8"; font.pixelSize: 11; font.weight: Font.Bold }
                            MouseArea { id: iPlus; anchors.fill: parent; onClicked: dialogRoot.referenceCurrent += 50 }
                        }
                    }
                }
            }

            // Capacity Input
            RowLayout {
                width: parent.width; height: 44
                Text { text: "电池额定容量 (mAh)"; color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.preferredWidth: 160 }
                Rectangle {
                    Layout.fillWidth: true; height: 38; radius: 10; color: "#F8F7FF"; border.color: "#D8D0F5"; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: dialogRoot.designCapacity + " mAh (1S 4.2V)"
                        color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; font.weight: Font.Bold
                    }
                }
            }

            // Stable Settle Checkbox
            Rectangle {
                width: parent.width; height: 42; radius: 10
                color: dialogRoot.stableConfirmed ? "#EEF9F4" : "#FAF8FF"
                border.color: dialogRoot.stableConfirmed ? "#A3E4C8" : "#D8D0F5"; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 10
                    Rectangle {
                        width: 22; height: 22; radius: 6
                        color: dialogRoot.stableConfirmed ? "#10B981" : "#FFFFFF"
                        border.color: dialogRoot.stableConfirmed ? "#10B981" : "#B4A8D8"; border.width: 2
                        Text { visible: dialogRoot.stableConfirmed; anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 14; font.weight: Font.Bold }
                    }
                    Text {
                        text: "已确认万用表读数准确且电池已静置稳定"
                        color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 13; font.weight: Font.DemiBold
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: dialogRoot.stableConfirmed = !dialogRoot.stableConfirmed }
            }

            // Action Buttons
            RowLayout {
                width: parent.width; spacing: 10
                Rectangle {
                    visible: systemBackend.batteryCalibrationRollbackAvailable
                    Layout.preferredWidth: 110; height: 44; radius: 12
                    color: rollbackMouse.pressed ? "#E2DFED" : "#ECE9F7"
                    Text { anchors.centerIn: parent; text: "回滚上一次"; color: "#5648C8"; font.family: "Noto Sans CJK SC"; font.pixelSize: 13; font.weight: Font.DemiBold }
                    MouseArea {
                        id: rollbackMouse; anchors.fill: parent
                        onClicked: { systemBackend.rollbackBatteryCalibration(); dialogRoot.opened = false }
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 90; height: 44; radius: 12
                    color: resetMouse.pressed ? "#F8D4D7" : "#FEE8EB"
                    Text { anchors.centerIn: parent; text: "重置默认"; color: "#D93829"; font.family: "Noto Sans CJK SC"; font.pixelSize: 13; font.weight: Font.DemiBold }
                    MouseArea {
                        id: resetMouse; anchors.fill: parent
                        onClicked: { systemBackend.clearBatteryCalibration(); dialogRoot.opened = false }
                    }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredWidth: 140; height: 44; radius: 12
                    enabled: dialogRoot.stableConfirmed && (!systemBackend.batteryCharging || dialogRoot.referenceCurrent === 0)
                    opacity: enabled ? 1 : 0.45
                    color: calBtnMouse.pressed ? "#5345C5" : "#6555D5"
                    Text { anchors.centerIn: parent; text: "执行安全标定"; color: "white"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; font.weight: Font.DemiBold }
                    MouseArea {
                        id: calBtnMouse; anchors.fill: parent
                        onClicked: {
                            var ok = systemBackend.calibrateBattery(dialogRoot.referenceVoltage,
                                                                    dialogRoot.referenceCurrent,
                                                                    dialogRoot.designCapacity,
                                                                    dialogRoot.stableConfirmed)
                            if (ok) dialogRoot.opened = false
                        }
                    }
                }
            }
        }
    }
}
