import QtQuick 2.15

Item {
    id: root
    property string title: ""
    property url icon: ""
    property color accentColor: "#7B6DF0"
    signal clicked()

    width: 110
    height: 124

    Rectangle {
        id: squircle
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 4 }
        width: 86
        height: 86
        radius: 22
        color: accentColor
        scale: mouseArea.pressed ? 0.88 : 1.0
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

        // Subtle top light sheen for classic 3D glass look
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: parent.height / 2
            radius: 22
            color: "#FFFFFF"
            opacity: 0.15
        }

        // Subtle dark bottom rim
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 4
            radius: 2
            color: "#000000"
            opacity: 0.12
        }

        Image {
            anchors.centerIn: parent
            width: 46
            height: 46
            source: root.icon
            sourceSize.width: 92
            sourceSize.height: 92
            smooth: true
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onClicked: root.clicked()
        }
    }

    Text {
        anchors { horizontalCenter: parent.horizontalCenter; top: squircle.bottom; topMargin: 8 }
        text: root.title
        color: "#FFFFFF"
        font.family: "Noto Sans CJK SC"
        font.pixelSize: 15
        font.weight: Font.DemiBold
        style: Text.Outline
        styleColor: "#66000000"
    }
}
