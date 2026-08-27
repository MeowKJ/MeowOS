import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: navRow
    property string title: ""
    property url icon: ""
    property color accent: "#6366F1"
    property bool selected: false
    signal clicked()

    width: parent ? parent.width : 0
    height: 56
    radius: 14
    color: selected ? "#EEF2FF" : (navMouse.pressed ? "#F8FAFC" : "transparent")
    border.color: selected ? "#C7D2FE" : "transparent"
    border.width: selected ? 1 : 0

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        spacing: 12

        // Colorful App Squircle Badge
        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: 10
            color: navRow.accent
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.centerIn: parent
                width: 20
                height: 20
                source: navRow.icon
                sourceSize.width: 40
                sourceSize.height: 40
            }
        }

        Text {
            text: navRow.title
            color: navRow.selected ? "#3730A3" : "#1F2937"
            font.family: "Noto Sans CJK SC"
            font.pixelSize: 17
            font.weight: navRow.selected ? Font.Bold : Font.Normal
            Layout.fillWidth: true
        }

        Text {
            visible: navRow.selected
            text: "›"
            color: navRow.accent
            font.pixelSize: 22
            font.weight: Font.Bold
        }
    }

    MouseArea {
        id: navMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: navRow.clicked()
    }
}
