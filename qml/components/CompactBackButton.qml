import QtQuick 2.15

Item {
    signal clicked()
    width: 52; height: 52
    Rectangle {
        anchors.centerIn: parent
        width: 42; height: 42; radius: 21
        color: backMouse.pressed ? "#E5E1E9" : "#F0EDF3"
        Image { anchors.centerIn: parent; width: 24; height: 24; source: "qrc:/assets/icons/chevron-left.svg"; sourceSize.width: 48; sourceSize.height: 48 }
    }
    MouseArea { id: backMouse; anchors.fill: parent; onClicked: parent.clicked() }
}
