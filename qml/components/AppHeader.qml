import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: appHeader
    property string title: ""
    property string subtitle: ""
    property string trailingText: ""
    property bool compact: false
    property bool trailingEnabled: false
    property bool showBack: false
    signal backRequested()
    signal exitRequested()
    signal trailingRequested()
    z: 700
    width: parent ? parent.width : 0
    height: 66
    color: "#FCFBFD"
    Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: "#ECE8EE" }
    RowLayout {
        anchors { fill: parent; leftMargin: appHeader.compact ? 0 : 18; rightMargin: appHeader.compact ? 0 : 22 }
        spacing: 10
        CompactBackButton { visible: appHeader.showBack; Layout.preferredWidth: visible ? 52 : 0; Layout.preferredHeight: 52; onClicked: appHeader.backRequested() }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 0
            Text { text: appHeader.title; color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: appHeader.compact ? 28 : 30; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
            Text { visible: !appHeader.compact && appHeader.subtitle.length > 0; text: appHeader.subtitle; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 14; Layout.fillWidth: true; elide: Text.ElideRight }
        }
        Rectangle {
            visible: appHeader.trailingText.length > 0
            Layout.preferredWidth: Math.max(68, trailingLabel.implicitWidth + 28)
            Layout.preferredHeight: 38; radius: 13
            color: appHeader.trailingEnabled && trailingMouse.pressed ? "#E2DDFB" : "#EEEAFE"
            Text { id: trailingLabel; anchors.centerIn: parent; text: appHeader.trailingText; color: "#7B6DF0"; font.family: "Noto Sans CJK SC"; font.pixelSize: 16; font.weight: Font.DemiBold }
            MouseArea { id: trailingMouse; anchors.fill: parent; enabled: appHeader.trailingEnabled; onClicked: appHeader.trailingRequested() }
        }
    }
}
