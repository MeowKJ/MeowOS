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
        scale: mouseArea.pressed ? 0.90 : 1.0
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

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
    }
}
