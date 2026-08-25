import QtQuick 2.15

Rectangle {
    id: networkField
    property string label: ""
    property string value: ""
    property string placeholder: ""
    property bool selected: false
    signal tapped()
    width: parent ? parent.width : 0; height: 62; radius: 14
    color: "white"; border.color: selected ? "#7B6DF0" : "#D8D5DD"; border.width: selected ? 2 : 1
    Column {
        anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; anchors.topMargin: 8; spacing: 2
        Text { text: label; color: selected ? "#7B6DF0" : "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 12; font.weight: Font.DemiBold }
        Text { text: value.length ? value : placeholder; color: value.length ? "#27222D" : "#AAA5AE"; font.family: "Noto Sans CJK SC"; font.pixelSize: 18; elide: Text.ElideRight; width: parent.width }
    }
    MouseArea { anchors.fill: parent; onClicked: networkField.tapped() }
}
