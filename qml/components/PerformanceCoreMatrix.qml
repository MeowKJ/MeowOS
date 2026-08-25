import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: coreMatrixRoot
    property int logicalCoreCount: 8
    property var cpuUsageList: []
    property var cpuFrequenciesList: []

    function coreUsage(core) {
        return cpuUsageList.length > core + 1 ? cpuUsageList[core + 1] : 0
    }
    function coreFrequency(core) {
        return cpuFrequenciesList.length > core ? cpuFrequenciesList[core] : -1
    }

    implicitWidth: 800
    implicitHeight: 200
    height: 200
    radius: 22
    color: "#FAFAFD"
    border.color: "#E6E5EC"
    border.width: 1

    Column {
        width: parent.width - 32
        x: 16
        y: 16
        spacing: 12

        // Header Row
        RowLayout {
            width: parent.width
            Text {
                text: "多核负载分布"
                color: "#1E1B4B"
                font.family: "Noto Sans CJK SC"
                font.pixelSize: 18
                font.weight: Font.Bold
                Layout.fillWidth: true
            }
            Text {
                text: coreMatrixRoot.logicalCoreCount + " 个核心全动态调频"
                color: "#6B7280"
                font.family: "Noto Sans CJK SC"
                font.pixelSize: 13
            }
        }

        // 4 x 2 Grid
        GridLayout {
            width: parent.width
            columns: 4
            columnSpacing: 10
            rowSpacing: 10

            Repeater {
                model: coreMatrixRoot.logicalCoreCount
                delegate: Rectangle {
                    readonly property int usageValue: coreMatrixRoot.coreUsage(index)
                    readonly property int frequencyValue: coreMatrixRoot.coreFrequency(index)
                    readonly property color accentColor: usageValue >= 75 ? "#EF4444" : (usageValue >= 50 ? "#F59E0B" : "#6366F1")
                    readonly property color bgColor: usageValue >= 75 ? "#FEF2F2" : (usageValue >= 50 ? "#FFFBEB" : "#F5F3FF")
                    readonly property color borderColor: usageValue >= 75 ? "#FECACA" : (usageValue >= 50 ? "#FDE68A" : "#DDD6FE")

                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: 14
                    color: bgColor
                    border.color: borderColor
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        RowLayout {
                            width: parent.width
                            Text {
                                text: "Core " + index
                                color: "#1F2937"
                                font.family: "Noto Sans CJK SC"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                            }
                            Text {
                                text: usageValue + "%"
                                color: accentColor
                                font.family: "Noto Sans CJK SC"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 5
                            radius: 2.5
                            color: "#E5E7EB"
                            Rectangle {
                                width: Math.max(0, Math.min(parent.width, usageValue / 100 * parent.width))
                                height: parent.height
                                radius: parent.radius
                                color: accentColor
                            }
                        }

                        Text {
                            text: frequencyValue > 0 ? frequencyValue + " MHz" : "--"
                            color: "#6B7280"
                            font.family: "Noto Sans CJK SC"
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
