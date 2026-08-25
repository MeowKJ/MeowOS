import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: actionRowRoot
    property string label: ""
    property string actionText: ""
    property color actionColor: "#7B6DF0"
    property bool last: false
    signal clicked()

    width: parent ? parent.width : 0
    height: 56

    Rectangle {
        id: bgHighlight
        anchors.fill: parent
        color: actionMouse.pressed ? "#EFECE7" : "transparent"
        radius: 12
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        Text {
            text: actionRowRoot.label
            color: "#27222D"
            font.family: "Noto Sans CJK SC"
            font.pixelSize: 17
            Layout.fillWidth: true
        }

        Text {
            text: actionRowRoot.actionText
            color: actionRowRoot.actionColor
            font.family: "Noto Sans CJK SC"
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }
    }

    Rectangle {
        visible: !actionRowRoot.last
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 16 }
        height: 1
        color: "#E7E3EA"
    }

    MouseArea {
        id: actionMouse
        anchors.fill: parent
        onClicked: actionRowRoot.clicked()
    }
}
