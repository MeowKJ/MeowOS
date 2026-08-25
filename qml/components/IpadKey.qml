import QtQuick 2.15

Rectangle {
    id: ipadKey
    property string label: ""
    property string subLabel: ""
    property url icon: ""
    property real keyWidth: 108
    property real keyHeight: 52
    property bool functionKey: false
    property bool returnKey: false
    property bool destructive: false
    property bool active: false
    signal tapped()

    width: keyWidth
    height: keyHeight
    radius: 12

    scale: ipadKeyMouse.pressed ? 0.95 : 1.0
    Behavior on scale { NumberAnimation { duration: 70; easing.type: Easing.OutQuad } }
    Behavior on color { ColorAnimation { duration: 70 } }

    color: ipadKeyMouse.pressed
           ? (returnKey ? "#6352E8" : (destructive ? "#E11D48" : (active ? "#6352E8" : (functionKey ? "#4A416E" : "#3B355A"))))
           : (returnKey ? "#7B6DF0"
              : (active ? "#7B6DF0"
                 : (functionKey ? "#342E4E" : "#25203A")))

    border.color: returnKey || active
                  ? "#9487FF"
                  : (functionKey ? "#453D66" : "#373053")
    border.width: returnKey || active ? 1.5 : 1

    Column {
        anchors.centerIn: parent
        spacing: 1

        Text {
            visible: subLabel.length > 0 && icon.toString().length === 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: subLabel
            color: returnKey || active ? "#DED8FF" : "#8E86A8"
            font.family: "Noto Sans CJK SC"
            font.pixelSize: 11
            font.weight: Font.Normal
        }

        Text {
            id: keyText
            visible: icon.toString().length === 0 || keyImage.status !== Image.Ready
            anchors.horizontalCenter: parent.horizontalCenter
            text: label.length > 0 ? label : (destructive ? "⌫" : "")
            color: returnKey || active || destructive ? "#FFFFFF" : "#F4F1FA"
            font.family: "Noto Sans CJK SC"
            font.pixelSize: label.length > 4 ? 15 : (label.length > 2 ? 16 : 20)
            font.weight: returnKey || functionKey || active ? Font.Bold : Font.DemiBold
        }
    }

    Image {
        id: keyImage
        visible: icon.toString().length > 0 && status === Image.Ready
        anchors.centerIn: parent
        width: 26
        height: 26
        source: icon
        sourceSize.width: 52
        sourceSize.height: 52
        smooth: true
    }

    MouseArea {
        id: ipadKeyMouse
        anchors.fill: parent
        onClicked: ipadKey.tapped()
    }
}
