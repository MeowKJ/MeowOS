import QtQuick 2.15

Column {
    id: bodyRoot
    property string title: ""
    property string subtitle: ""
    default property alias content: bodyContent.data
    anchors { left: parent ? parent.left : undefined; right: parent ? parent.right : undefined; top: parent ? parent.top : undefined; margins: 30 }
    spacing: 16
    Text { text: bodyRoot.title; color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 34; font.weight: Font.Bold }
    Text { width: parent.width; text: bodyRoot.subtitle; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 18; wrapMode: Text.WordWrap }
    Column { id: bodyContent; width: parent.width; spacing: 18 }
}
