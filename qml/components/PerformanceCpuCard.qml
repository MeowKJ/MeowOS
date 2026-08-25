import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: cpuCardRoot
    property int cpuTotal: 0
    property int logicalCoreCount: 8
    property var cpuSamples: []
    property int frequencyMhz: 0
    property int maxFrequencyMhz: 0
    property real temperatureC: 0

    implicitWidth: 400
    implicitHeight: 236
    height: 236
    radius: 22
    color: "#F8F7FF"
    border.color: "#E0DBFC"
    border.width: 1

    Column {
        width: parent.width - 36
        x: 18
        y: 18
        spacing: 10

        // Header Row: Icon + Title + CPU %
        RowLayout {
            width: parent.width
            Row {
                Layout.fillWidth: true
                spacing: 10
                Rectangle {
                    width: 40; height: 40; radius: 12
                    color: "#6366F1"
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        anchors.centerIn: parent; width: 22; height: 22
                        source: "qrc:/assets/icons/cpu.svg"
                        sourceSize.width: 44; sourceSize.height: 44
                    }
                }
                ColumnLayout {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    Text {
                        text: "中央处理器 (CPU)"
                        color: "#1E1B4B"
                        font.family: "Noto Sans CJK SC"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }
                    Text {
                        text: cpuCardRoot.logicalCoreCount > 0 ? cpuCardRoot.logicalCoreCount + " 逻辑核心 · 动态负载" : "读取中…"
                        color: "#6B7280"
                        font.family: "Noto Sans CJK SC"
                        font.pixelSize: 12
                    }
                }
            }
            Text {
                text: cpuCardRoot.cpuTotal >= 0 ? cpuCardRoot.cpuTotal + "%" : "--"
                color: "#4F46E5"
                font.family: "Noto Sans CJK SC"
                font.pixelSize: 38
                font.weight: Font.Bold
            }
        }

        // Hardware-Cached 2D Gradient Area Sparkline
        Canvas {
            id: sparklineCanvas
            width: parent.width
            height: 86
            renderTarget: Canvas.Image
            renderStrategy: Canvas.Cooperative
            antialiasing: true

            property var samples: cpuCardRoot.cpuSamples
            onSamplesChanged: requestPaint()
            onWidthChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                
                // 1. Grid lines
                ctx.strokeStyle = "#EAE5FD"
                ctx.lineWidth = 1
                for (var grid = 1; grid < 3; ++grid) {
                    var gy = grid * height / 3
                    ctx.beginPath()
                    ctx.moveTo(0, gy)
                    ctx.lineTo(width, gy)
                    ctx.stroke()
                }

                if (!samples || samples.length === 0) return
                var step = width / Math.max(1, samples.length - 1)

                // 2. Gradient filled area
                ctx.beginPath()
                ctx.moveTo(0, height)
                for (var i = 0; i < samples.length; ++i) {
                    var v = Math.max(0, Math.min(100, samples[i]))
                    ctx.lineTo(i * step, height - v * height / 100)
                }
                ctx.lineTo((samples.length - 1) * step, height)
                ctx.closePath()

                var grad = ctx.createLinearGradient(0, 0, 0, height)
                grad.addColorStop(0, "rgba(99, 102, 241, 0.32)")
                grad.addColorStop(1, "rgba(99, 102, 241, 0.02)")
                ctx.fillStyle = grad
                ctx.fill()

                // 3. Crisp stroke line
                ctx.beginPath()
                for (var j = 0; j < samples.length; ++j) {
                    var point = Math.max(0, Math.min(100, samples[j]))
                    if (j === 0) ctx.moveTo(0, height - point * height / 100)
                    else ctx.lineTo(j * step, height - point * height / 100)
                }
                ctx.strokeStyle = "#6366F1"
                ctx.lineWidth = 2.5
                ctx.lineJoin = "round"
                ctx.lineCap = "round"
                ctx.stroke()
            }
        }

        // Telemetry Footer
        RowLayout {
            width: parent.width
            Text {
                text: "当前频率: " + (cpuCardRoot.frequencyMhz > 0 ? cpuCardRoot.frequencyMhz + " MHz" : "--")
                color: "#6B7280"
                font.family: "Noto Sans CJK SC"
                font.pixelSize: 12
                Layout.fillWidth: true
            }
            Text {
                text: "最高: " + (cpuCardRoot.maxFrequencyMhz > 0 ? cpuCardRoot.maxFrequencyMhz + " MHz" : "--")
                color: "#6B7280"
                font.family: "Noto Sans CJK SC"
                font.pixelSize: 12
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                text: "温度: " + (cpuCardRoot.temperatureC > -100 ? cpuCardRoot.temperatureC.toFixed(0) + "°C" : "--")
                color: cpuCardRoot.temperatureC >= 80 ? "#EF4444" : "#10B981"
                font.family: "Noto Sans CJK SC"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
