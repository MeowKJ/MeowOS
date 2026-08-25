import QtQuick 2.15
import QtQuick.Controls 2.15
import "../components"

Rectangle {
    id: reactionPage
    objectName: "reaction-game"
    property string appId: "reaction-game"
    color: "#F5F4F8"
    signal exitRequested()
    signal backRequested()

    property bool running: false
    property int remaining: 30
    property int score: 0
    property int streak: 0
    property int best: 0
    property int targetSize: 112

    function placeTarget() {
        var margin = 28
        var minX = margin
        var maxX = Math.max(minX, gameBoard.width - targetSize - margin)
        var minY = margin
        var maxY = Math.max(minY, gameBoard.height - targetSize - margin)
        target.x = minX + Math.floor(Math.random() * (maxX - minX + 1))
        target.y = minY + Math.floor(Math.random() * (maxY - minY + 1))
    }
    function startGame() {
        score = 0
        streak = 0
        remaining = 30
        running = true
        placeTarget()
        gameTimer.restart()
    }
    function finishGame() {
        running = false
        gameTimer.stop()
        if (score > best) best = score
    }

    Component.onCompleted: placeTarget()

    AppHeader {
        title: "喵喵反应"
        subtitle: "30 秒触摸挑战"
        showBack: false
        trailingText: "最佳 " + reactionPage.best
        onExitRequested: reactionPage.exitRequested()
    }

    Row {
        anchors { top: parent.top; topMargin: 82; horizontalCenter: parent.horizontalCenter }
        spacing: 34
        Text { text: "得分 " + reactionPage.score; color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 22; font.weight: Font.DemiBold }
        Text { text: "连击 " + reactionPage.streak; color: "#FF7FA7"; font.family: "Noto Sans CJK SC"; font.pixelSize: 22; font.weight: Font.DemiBold }
        Text { text: "时间 " + reactionPage.remaining + "s"; color: reactionPage.remaining <= 5 ? "#FF3B30" : "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 22; font.weight: Font.DemiBold }
    }

    Rectangle {
        id: gameBoard
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 24; topMargin: 122 }
        radius: 28; color: "#FFF8FA"; border.color: "#EFDCE5"; border.width: 2
        Text {
            anchors.centerIn: parent
            visible: !reactionPage.running
            text: reactionPage.remaining === 0 ? "本轮结束\n得分 " + reactionPage.score : "点击开始，然后尽快点中绿色喵爪"
            horizontalAlignment: Text.AlignHCenter
            color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 26; lineHeight: 1.25
        }
        Rectangle {
            id: target
            width: reactionPage.targetSize; height: reactionPage.targetSize; radius: width / 2
            color: "#49B990"; border.color: "#FFFFFF"; border.width: 6
            visible: reactionPage.running
            Text { anchors.centerIn: parent; text: "喵"; color: "white"; font.family: "Noto Sans CJK SC"; font.pixelSize: 36; font.weight: Font.Bold }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    reactionPage.score += 1
                    reactionPage.streak += 1
                    reactionPage.placeTarget()
                }
            }
        }
    }

    Button {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 34 }
        text: reactionPage.running ? "进行中…" : (reactionPage.remaining === 0 ? "再来一局" : "开始游戏")
        enabled: !reactionPage.running
        font.family: "Noto Sans CJK SC"; font.pixelSize: 19; font.weight: Font.DemiBold
        contentItem: Text { text: parent.text; color: parent.enabled ? "white" : "#AAA5AC"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
        background: Rectangle { radius: 18; color: parent.enabled ? "#7B6DF0" : "#E5E2E7" }
        onClicked: reactionPage.startGame()
    }

    Text {
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 40; bottomMargin: 48 }
        text: "最佳 " + reactionPage.best
        color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 16
    }

    Timer {
        id: gameTimer
        interval: 1000; repeat: true
        onTriggered: {
            reactionPage.remaining -= 1
            if (reactionPage.remaining <= 0) reactionPage.finishGame()
        }
    }
}
