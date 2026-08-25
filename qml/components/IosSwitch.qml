import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: switchRoot
    property bool checked: false
    property color activeColor: "#7B6DF0"
    property color inactiveColor: "#D5D1DF"
    property color thumbColor: "#FFFFFF"
    signal toggled(bool isChecked)

    implicitWidth: 44
    implicitHeight: 26
    radius: height / 2
    color: checked ? activeColor : inactiveColor
    Behavior on color { ColorAnimation { duration: 160 } }

    Rectangle {
        id: thumb
        x: switchRoot.checked ? switchRoot.width - width - 2 : 2
        y: 2
        width: switchRoot.height - 4
        height: switchRoot.height - 4
        radius: height / 2
        color: switchRoot.thumbColor
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            switchRoot.checked = !switchRoot.checked
            switchRoot.toggled(switchRoot.checked)
        }
    }
}
