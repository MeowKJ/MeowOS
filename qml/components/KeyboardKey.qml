import QtQuick 2.15

Rectangle {
    id: keyboardKey
    property string label: ""
    property url icon: ""
    property real keyWidth: 65
    property real keyHeight: 50
    property bool active: false
    property bool accent: false
    property bool destructive: false
    signal tapped()

    width: keyWidth
    height: keyHeight
    radius: 13

    scale: keyMouse.pressed ? 0.95 : 1.0
    Behavior on scale { NumberAnimation { duration: 70; easing.type: Easing.OutQuad } }
    Behavior on color { ColorAnimation { duration: 70 } }

    color: keyMouse.pressed
           ? (accent ? "#6352E8" : (destructive ? "#DC2626" : "#E2DFE8"))
           : (accent ? "#7B6DF0" : (destructive ? "#EF4444" : (active ? "#EDE8FF" : "#F6F5F9")))

    border.color: active || accent
                  ? "#7B6DF0"
                  : (destructive ? "#F87171" : "#E0DCE6")
    border.width: active || accent ? 1.5 : 1

    Text {
        visible: icon.toString().length === 0 || keyImg.status !== Image.Ready
        anchors.centerIn: parent
        text: label.length > 0 ? label : (destructive ? "⌫" : "")
        color: accent || destructive ? "#FFFFFF" : "#1E1B2E"
        font.family: "Noto Sans CJK SC"
        font.pixelSize: label.length > 2 ? 14 : 18
        font.weight: accent || destructive ? Font.Bold : Font.DemiBold
    }

    Image {
        id: keyImg
        visible: icon.toString().length > 0 && status === Image.Ready
        anchors.centerIn: parent
        width: 22
        height: 22
        source: icon
        sourceSize.width: 44
        sourceSize.height: 44
        smooth: true
    }

    MouseArea {
        id: keyMouse
        anchors.fill: parent
        onClicked: keyboardKey.tapped()
    }
}
