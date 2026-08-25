import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: perfMetricRoot
    property string label: ""
    property string value: "--"
    property string note: ""
    property color accent: "#7B6DF0"
    property color tint: "#F7F5FF"
    Layout.fillWidth: true
    Layout.preferredHeight: 78
    radius: 19; color: tint
    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.22); border.width: 1
    RowLayout {
        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
        Rectangle { Layout.preferredWidth: 8; Layout.preferredHeight: 34; radius: 4; color: accent }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            Text { text: label; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 13 }
            Text { text: value; color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 19; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
        }
        Text { visible: note.length > 0; text: note; color: accent; font.family: "Noto Sans CJK SC"; font.pixelSize: 12; font.weight: Font.DemiBold }
    }
}
