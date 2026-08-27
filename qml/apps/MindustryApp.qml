import QtQuick 2.15
import QtQuick.Controls 2.15
import "../components"

Rectangle {
    id: page
    objectName: "mindustry"
    color: "#F5F4F8"
    signal exitRequested()
    signal backRequested()
    property bool launching: false

    AppHeader {
        title: "像素工厂"
        subtitle: "Mindustry · ARM64"
        showBack: false
        onExitRequested: page.exitRequested()
    }

    Column {
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 118 }
        spacing: 22
        leftPadding: 32; rightPadding: 32
        Rectangle {
            width: parent.width - 64; height: 210; radius: 28
            color: "#242038"
            Text { anchors.centerIn: parent; text: "像素工厂"; color: "#FFFFFF"; font.pixelSize: 36; font.weight: Font.Bold }
            Text {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 24 }
                text: "Mindustry"; color: "#BDB6E8"; font.pixelSize: 16
            }
        }
        Text {
            width: parent.width - 64; wrapMode: Text.WordWrap
            text: page.launching ? "正在启动游戏…" : "已安装 ARM64 版本。启动后将进入游戏窗口，退出游戏即可返回 MeowOS。"
            color: "#5E5868"; font.family: "Noto Sans CJK SC"; font.pixelSize: 18
        }
        Button {
            width: parent.width - 64; height: 58; enabled: !page.launching
            text: page.launching ? "启动中…" : "启动像素工厂"
            font.pixelSize: 20; font.weight: Font.DemiBold
            contentItem: Text { text: parent.text; color: parent.enabled ? "white" : "#AAA5AC"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
            background: Rectangle { radius: 18; color: parent.enabled ? "#7B6DF0" : "#E5E2E7" }
            onClicked: { page.launching = true; systemBackend.launchMindustry() }
        }
        Text { width: parent.width - 64; text: "图形后端由系统 GPU/SDL2 配置决定"; color: "#898391"; font.pixelSize: 14 }
    }
}
