import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: infoRow
    property string label: ""
    property string value: ""
    property color valueColor: "#77717D"
    property bool emphasize: false
    property bool last: false
    width: parent ? parent.width : 0; height: 62
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 18
        Text { text: infoRow.label; color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 18; Layout.fillWidth: true }
        Text { text: infoRow.value; color: infoRow.valueColor; font.family: "Noto Sans CJK SC"; font.pixelSize: 17; font.weight: infoRow.emphasize ? Font.DemiBold : Font.Normal }
    }
    Rectangle { visible: !infoRow.last; anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 18 } height: 1; color: "#E7E3EA" }
}
