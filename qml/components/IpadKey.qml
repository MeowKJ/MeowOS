import QtQuick 2.15

Rectangle {
    id: ipadKey
    property string label: ""
    property url icon: ""
    property real keyWidth: 108
    property bool functionKey: false
    property bool returnKey: false
    property bool destructive: false
    property bool active: false
    signal tapped()
    width: keyWidth; height: 54; radius: 11
    scale: ipadKeyMouse.pressed ? 0.94 : 1.0
    Behavior on scale { NumberAnimation { duration: 70; easing.type: Easing.OutCubic } }

    color: ipadKeyMouse.pressed
           ? (returnKey ? "#6B58F2" : (destructive ? "#C22838" : (functionKey ? "#4E4575" : "#443D68")))
           : (returnKey ? "#7B6DF0"
              : (destructive ? "#EB4D5C"
                 : (active ? "#8B5CF6"
                    : (functionKey ? "#332D50" : "#292440"))))

    border.color: returnKey ? "#9D90FF" : (active ? "#A78BFA" : (functionKey ? "#443C6B" : "#3D365F"))
    border.width: active || returnKey ? 1.5 : 1

    Rectangle {
        visible: !ipadKeyMouse.pressed
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 3; radius: 2
        color: returnKey ? "#5243DB" : (destructive ? "#A11E2D" : (active ? "#6739D6" : (functionKey ? "#211D36" : "#1B172C")))
        opacity: 0.8
    }
    Image {
        visible: icon.toString().length > 0
        anchors.centerIn: parent
        anchors.verticalCenterOffset: ipadKeyMouse.pressed ? 1 : -1
        width: 32; height: 32
        source: icon
        sourceSize.width: 64; sourceSize.height: 64
        smooth: true
    }
    Text {
        visible: icon.toString().length === 0
        anchors.centerIn: parent
        anchors.verticalCenterOffset: ipadKeyMouse.pressed ? 1 : -1
        text: label
        color: returnKey || active || destructive ? "#FFFFFF" : "#F4F1FA"
        font.family: "Noto Sans CJK SC"
        font.pixelSize: label.length > 4 ? 15 : (label.length > 2 ? 17 : 21)
        font.weight: returnKey || functionKey || active ? Font.Bold : Font.Medium
    }
    MouseArea { id: ipadKeyMouse; anchors.fill: parent; onClicked: ipadKey.tapped() }
}
