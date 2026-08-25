import QtQuick 2.15
import "../components"

Rectangle {
    id: touchPage
    objectName: "touch-test"
    property string appId: "touch-test"
    color: "#F5F4F8"
    signal exitRequested()
    signal backRequested()

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
                    color: index % 2 ? "#7B6DF0" : "#FF7FA7"
                    opacity: 0.78; border.color: "white"; border.width: 5
                    Text { anchors.centerIn: parent; text: index + 1; color: "white"; font.pixelSize: 18; font.weight: Font.DemiBold }
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 10
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: touchPad.activeTouches === 0 ? "请触摸或拖动" : (touchPad.activeTouches === 1 ? "单指位置正确" : touchPad.activeTouches + " 个触点")
                color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 36; font.weight: Font.DemiBold
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "逻辑坐标 1280 × 800 · 累计 " + window.tapCount + " 次"
                color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 18
            }
        }
    }

    AppHeader {
        title: "点击测试"
        subtitle: "触摸与坐标验证"
        showBack: false
        trailingText: "清除"
        trailingEnabled: true
        onExitRequested: touchPage.exitRequested()
        onTrailingRequested: window.tapCount = 0
    }
}
