import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: navRowRoot
    property string label: ""
    property string detail: ""
    property url iconSource: ""
    property bool hasChevron: true
    property bool last: false
    signal clicked()

    width: parent ? parent.width : 0
    height: 56

    Rectangle {
        id: bgHighlight
        anchors.fill: parent
        color: navMouse.pressed ? "#EFECE7" : "transparent"
        radius: 12
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        Image {
            visible: navRowRoot.iconSource != ""
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            source: navRowRoot.iconSource
            sourceSize.width: 44
            sourceSize.height: 44
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: navRowRoot.label
            color: "#27222D"
            font.family: "Noto Sans CJK SC"
            font.pixelSize: 17
            Layout.fillWidth: true
        }

        Text {
            visible: navRowRoot.detail.length > 0
            text: navRowRoot.detail
            color: "#8E8896"
            font.family: "Noto Sans CJK SC"
            font.pixelSize: 15
        }

        Image {
            visible: navRowRoot.hasChevron
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            source: "qrc:/assets/icons/chevron-left.svg"
            rotation: 180
            sourceSize.width: 32
            sourceSize.height: 32
            opacity: 0.4
        }
    }

    Rectangle {
        visible: !navRowRoot.last
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 16 }
        height: 1
        color: "#E7E3EA"
    }

    MouseArea {
        id: navMouse
        anchors.fill: parent
        onClicked: navRowRoot.clicked()
    }
}
