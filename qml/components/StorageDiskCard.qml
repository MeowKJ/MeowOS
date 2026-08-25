import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: storageDiskCardRoot
    property string title: ""
    property string detail: ""
    property int percent: 0
    property color accent: "#7B6DF0"
    property color accent2: accent
    property bool available: true
    property bool mounted: true
    height: available && mounted ? 170 : 104
    radius: 20
    color: "#F9F9FB"
    border.color: "#E7E3EA"
    border.width: 1

    RowLayout {
        id: diskHeader
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        height: 54
        spacing: 14
        Rectangle {
            Layout.preferredWidth: 50; Layout.preferredHeight: 50
            radius: 14
            color: available ? accent : "#B9B5BE"
            Image {
                anchors.centerIn: parent
                width: 28; height: 28
                source: "qrc:/assets/icons/hard-drive.svg"
                sourceSize.width: 56; sourceSize.height: 56
            }
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            Text { text: title; color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 20; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
            Text { text: detail; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; elide: Text.ElideRight; Layout.fillWidth: true }
        }
        Text {
            text: !available ? "未检测到" : (mounted ? percent + "%" : "未挂载")
            color: available ? "#77717D" : "#8E8993"
            font.family: "Noto Sans CJK SC"; font.pixelSize: 17; font.weight: Font.DemiBold
        }
    }

    Rectangle {
        id: storageTrack
        visible: available && mounted
        anchors { left: parent.left; right: parent.right; top: diskHeader.bottom; leftMargin: 18; rightMargin: 18; topMargin: 15 }
        height: 14; radius: 7
        color: "#E7E5EA"
        clip: true
        Rectangle {
            width: percent > 0 ? Math.max(height, parent.width * Math.max(0, Math.min(100, percent)) / 100) : 0
            height: parent.height; radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: accent }
                GradientStop { position: 1.0; color: accent2 }
            }
        }
    }

    RowLayout {
        visible: available && mounted
        anchors { left: parent.left; right: parent.right; top: storageTrack.bottom; leftMargin: 18; rightMargin: 18; topMargin: 12 }
        spacing: 22
        Row {
            spacing: 7
            Rectangle { width: 10; height: 10; radius: 5; color: accent; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "已使用"; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 14 }
        }
        Row {
            spacing: 7
            Rectangle { width: 10; height: 10; radius: 5; color: "#D2CFD7"; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "可用空间"; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 14 }
        }
        Item { Layout.fillWidth: true }
    }
}
