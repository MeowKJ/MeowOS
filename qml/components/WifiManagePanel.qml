import QtQuick 2.15

Rectangle {
    id: wifiPanelRoot
    property bool expanded: false
    signal forget()
    signal reenter()
    signal connect()
    width: parent ? parent.width : 0
    height: 0
    clip: true
    radius: 18
    color: "#F5F3FF"
    border.color: "#D8D0F5"; border.width: 1
    Column {
        id: panelContent
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 12
        Text { text: "已保存此网络的连接信息，密码变化时请重新输入"; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 14; wrapMode: Text.WordWrap; width: parent.width; leftPadding: 16; rightPadding: 16; topPadding: 14 }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
            Rectangle {
                width: 140; height: 44; radius: 12
                color: reenterBtnMouse.pressed ? "#6558D9" : "#7B6DF0"
                Text { anchors.centerIn: parent; text: "重新输入密码"; color: "white"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; font.weight: Font.DemiBold }
                MouseArea { id: reenterBtnMouse; anchors.fill: parent; onClicked: wifiPanelRoot.reenter() }
            }
            Rectangle {
                width: 140; height: 44; radius: 12
                color: connectBtnMouse.pressed ? "#3DA47E" : "#49B990"
                Text { anchors.centerIn: parent; text: "连接"; color: "white"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; font.weight: Font.DemiBold }
                MouseArea { id: connectBtnMouse; anchors.fill: parent; onClicked: wifiPanelRoot.connect() }
            }
            Rectangle {
                width: 140; height: 44; radius: 12
                color: forgetBtnMouse.pressed ? "#D93645" : "#EB4D5C"
                Text { anchors.centerIn: parent; text: "忘记网络"; color: "white"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; font.weight: Font.DemiBold }
                MouseArea { id: forgetBtnMouse; anchors.fill: parent; onClicked: wifiPanelRoot.forget() }
            }
        }
    }
    states: [
        State { name: "collapsed"; when: !wifiPanelRoot.expanded; PropertyChanges { target: wifiPanelRoot; height: 0; opacity: 0 } },
        State { name: "expanded"; when: wifiPanelRoot.expanded; PropertyChanges { target: wifiPanelRoot; height: panelContent.height + 28; opacity: 1 } }
    ]
    transitions: Transition { NumberAnimation { properties: "height,opacity"; duration: 240; easing.type: Easing.OutCubic } }
    visible: expanded || height > 1
    enabled: expanded
}
