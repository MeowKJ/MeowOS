import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: ramGpuRoot
    property int memoryPercent: 0
    property string memoryUsed: ""
    property string memoryAvailable: ""
    property int gpuFrequencyMhz: 0
    property string gpuName: "ARM Mali-G310 · 图形加速就绪"

    implicitWidth: 350
    implicitHeight: 236
    height: 236
    radius: 22
    color: "#F8FAFC"
    border.color: "#E2E8F0"
    border.width: 1

    Column {
        width: parent.width - 36
        x: 18
        y: 18
        spacing: 14

        // Top Section: RAM
        Column {
            width: parent.width
            spacing: 6

            RowLayout {
                width: parent.width
                Row {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle {
                        width: 32; height: 32; radius: 10
                        color: "#3B82F6"
                        anchors.verticalCenter: parent.verticalCenter
                        Image {
                            anchors.centerIn: parent
                            width: 18; height: 18
                            source: "qrc:/assets/icons/ram-stick-white.svg"
                            sourceSize.width: 36; sourceSize.height: 36
                        }
                    }
                    Text {
                        text: "运行内存"
                        color: "#0F172A"
                        font.family: "Noto Sans CJK SC"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                Text {
                    text: ramGpuRoot.memoryPercent >= 0 ? ramGpuRoot.memoryPercent + "%" : "--"
                    color: "#2563EB"
                    font.family: "Noto Sans CJK SC"
                    font.pixelSize: 24
                    font.weight: Font.Bold
                }
            }

            Rectangle {
                width: parent.width
                height: 7
                radius: 3.5
                color: "#DBEAFE"
                Rectangle {
                    width: ramGpuRoot.memoryPercent >= 0 ? Math.min(parent.width, parent.width * ramGpuRoot.memoryPercent / 100) : 0
                    height: parent.height
                    radius: parent.radius
                    color: "#2563EB"
                }
            }

            Text {
                text: (ramGpuRoot.memoryUsed.length > 0 ? ramGpuRoot.memoryUsed + " 已用" : "--") + (ramGpuRoot.memoryAvailable.length > 0 ? " · 可用 " + ramGpuRoot.memoryAvailable : "")
                color: "#64748B"
                font.family: "Noto Sans CJK SC"
                font.pixelSize: 12
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#E2E8F0"
        }

        // Bottom Section: GPU
        Column {
            width: parent.width
            spacing: 4

            RowLayout {
                width: parent.width
                Row {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle {
                        width: 32; height: 32; radius: 10
                        color: "#10B981"
                        anchors.verticalCenter: parent.verticalCenter
                        Image {
                            anchors.centerIn: parent
                            width: 18; height: 18
                            source: "qrc:/assets/icons/monitor.svg"
                            sourceSize.width: 36; sourceSize.height: 36
                        }
                    }
                    Text {
                        text: "图形处理器 (GPU)"
                        color: "#0F172A"
                        font.family: "Noto Sans CJK SC"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                Text {
                    text: ramGpuRoot.gpuFrequencyMhz > 0 ? (ramGpuRoot.gpuFrequencyMhz + " MHz") : "Mali GPU"
                    color: "#059669"
                    font.family: "Noto Sans CJK SC"
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }
            }

            Text {
                text: ramGpuRoot.gpuName
                color: "#64748B"
                font.family: "Noto Sans CJK SC"
                font.pixelSize: 12
            }
        }
    }
}
