import QtQuick 2.15

Rectangle {
    id: pill
    property string state: "info"
    property string label: "状态"
    readonly property color accent: state === "ok" ? "#168A5A"
                                      : (state === "warning" ? "#B86B00"
                                      : (state === "error" ? "#C93646" : "#5367C9"))
    readonly property color tint: state === "ok" ? "#E8F8F0"
                                    : (state === "warning" ? "#FFF5DF"
                                    : (state === "error" ? "#FFF0F1" : "#EEF1FF"))
    implicitWidth: statusText.implicitWidth + 28
    implicitHeight: 28
    radius: 14
    color: tint
    border.color: Qt.lighter(accent, 1.65)
    border.width: 1
    Rectangle { width: 7; height: 7; radius: 3.5; anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; color: pill.accent }
    Text {
        id: statusText
        anchors.left: parent.left; anchors.leftMargin: 22
        anchors.right: parent.right; anchors.rightMargin: 9
        anchors.verticalCenter: parent.verticalCenter
        text: pill.label; color: pill.accent
        font.family: "Noto Sans CJK SC"; font.pixelSize: 12; font.weight: Font.DemiBold
    }
}
