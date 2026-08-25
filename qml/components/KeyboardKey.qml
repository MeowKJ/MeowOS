import QtQuick 2.15

Rectangle {
    id: keyboardKey
    property string label: ""
    property url icon: ""
    property real keyWidth: 65
    property bool active: false
    property bool accent: false
    property bool destructive: false
    signal tapped()
    width: keyWidth; height: 50; radius: 13
    scale: keyMouse.pressed ? 0.94 : 1.0
    Behavior on scale { NumberAnimation { duration: 70; easing.type: Easing.OutCubic } }
    color: keyMouse.pressed
           ? (accent ? "#6558D9" : (destructive ? "#C82333" : "#E2DFE8"))
           : (accent ? "#7B6DF0" : (destructive ? "#EB4D5C" : (active ? "#DED8FF" : "#F2EFF5")))
    border.color: active ? "#7B6DF0" : (accent ? "#9488F7" : "#DDD9E3")
    border.width: active ? 2 : 1
    Text {
        visible: icon.toString().length === 0
        anchors.centerIn: parent
        anchors.verticalCenterOffset: keyMouse.pressed ? 1 : 0
        text: label
        color: accent || destructive ? "white" : "#27222D"
        font.family: "Noto Sans CJK SC"
        font.pixelSize: 17
        font.weight: Font.DemiBold
    }
    Image {
        visible: icon.toString().length > 0
        anchors.centerIn: parent; width: 24; height: 24
        source: icon; sourceSize.width: 48; sourceSize.height: 48; smooth: true
    }
    MouseArea { id: keyMouse; anchors.fill: parent; onClicked: keyboardKey.tapped() }
}
