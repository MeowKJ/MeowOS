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
    // Press feedback belongs only to the switch under the finger. Avoid
    // animating through the previous grey state after the value changes.
    color: checked
           ? (switchMouse.pressed ? Qt.darker(activeColor, 1.12) : activeColor)
           : (switchMouse.pressed ? Qt.darker(inactiveColor, 1.08) : inactiveColor)

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
        id: switchMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onClicked: {
            // The owner is the source of truth. Emitting the requested value
            // preserves its binding and prevents a one-frame stale state.
            switchRoot.toggled(!switchRoot.checked)
        }
    }
}
