import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: ethernetCard
    property var port: ({})
    property int portNumber: 1
    property color accent: "#438DE5"
    property color tint: "#F0F7FF"
    property color outline: "#C9E1FA"
    readonly property bool connected: port && port.connected === true
    readonly property string interfaceName: port && port.name ? port.name : "--"
    signal configureRequested()
    height: 206
    radius: 22
    color: tint
    border.color: outline
    border.width: 1

    RowLayout {
        id: ethernetHeader
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
        height: 62; spacing: 14
        Rectangle {
            Layout.preferredWidth: 52; Layout.preferredHeight: 52; radius: 16
            color: accent
            Image {
                anchors.centerIn: parent; width: 31; height: 31
                source: "qrc:/assets/icons/ethernet-port.svg"
                sourceSize.width: 62; sourceSize.height: 62; smooth: true
            }
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            Text {
                text: "网口 " + portNumber + "  ·  " + interfaceName
                color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 21; font.weight: Font.Bold
            }
            Text {
                text: connected ? (port.carrier ? "链路正常 · " + (port.speedMbit > 0 ? port.speedMbit + " Mbps" : "协商中") + " " + (port.duplex === "full" ? "全双工" : "半双工") : "等待网线插入")
                                : "端口已停用"
                color: connected ? (port.carrier ? "#217F5E" : "#8A8490") : "#8A8490"
                font.family: "Noto Sans CJK SC"; font.pixelSize: 14
            }
        }
        Rectangle {
            Layout.preferredWidth: 92; Layout.preferredHeight: 40; radius: 14
            color: connected ? (port.carrier ? "#EAF8F2" : "#FFF8E6") : "#F0EDF3"
            border.color: connected ? (port.carrier ? "#B8EAD4" : "#F6DC9F") : "#DDD8E2"; border.width: 1
            Text {
                anchors.centerIn: parent
                text: connected ? (port.carrier ? "已连通" : "无载波") : "未启用"
                color: connected ? (port.carrier ? "#238C69" : "#B27100") : "#77717D"
                font.family: "Noto Sans CJK SC"; font.pixelSize: 14; font.weight: Font.DemiBold
            }
        }
        Rectangle {
            Layout.preferredWidth: 92; Layout.preferredHeight: 40; radius: 14
            color: "#FFFFFF"; border.color: "#DDD8E2"; border.width: 1
            Text { anchors.centerIn: parent; text: "配置"; color: "#7B6DF0"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; font.weight: Font.DemiBold }
            MouseArea { anchors.fill: parent; onClicked: configureRequested() }
        }
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: ethernetHeader.bottom; bottom: parent.bottom; margins: 18; topMargin: 10 }
        radius: 16; color: "#FFFFFF"; border.color: outline; border.width: 1
        RowLayout {
            anchors.fill: parent; anchors.margins: 14; spacing: 12
            ColumnLayout {
                Layout.fillWidth: true; spacing: 3
                Text { text: "IPv4 地址"; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 12 }
                Text { text: port.ipv4 && port.ipv4.length ? port.ipv4 : (connected ? "获取中…" : "--"); color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 16; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#E7E3EA" }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 3
                Text { text: "默认网关"; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 12 }
                Text { text: port.gateway && port.gateway.length ? port.gateway : "--"; color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 16; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#E7E3EA" }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 3
                Text { text: "MAC 地址 / MTU"; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 12 }
                Text { text: (port.mac && port.mac.length ? port.mac : "--") + " · " + (port.mtu > 0 ? port.mtu : "--"); color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
            }
        }
    }
}
