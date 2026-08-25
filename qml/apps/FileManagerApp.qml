import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../components"

Rectangle {
    id: filesPage
    objectName: "files"
    property string appId: "files"
    color: "#F5F4F8"
    signal exitRequested()
    signal backRequested()

    property string currentFolder: "/home/radxa"
    property string currentLabel: "用户目录"
    property var folderHistory: []
    property var previewEntry: ({})
    property bool previewVisible: false
    property var selectedEntry: ({})
    readonly property bool hasSelection: selectedEntry && typeof selectedEntry.path === "string" && selectedEntry.path.length > 0
    property string clipboardPath: ""
    property string clipboardName: ""
    property bool clipboardMove: false
    property bool pastePending: false

    function enterFolder(url, label) {
        folderHistory.push({ url: currentFolder, label: currentLabel })
        currentFolder = url
        currentLabel = label
        systemBackend.browseDirectory(url)
    }
    function goBackFolder() {
        if (folderHistory.length === 0) return
        var previous = folderHistory.pop()
        currentFolder = previous.url
        currentLabel = previous.label
        systemBackend.browseDirectory(currentFolder)
    }
    function parentFolder() {
        if (currentFolder === "/") return "/"
        var slash = currentFolder.lastIndexOf("/")
        return slash <= 0 ? "/" : currentFolder.slice(0, slash)
    }
    function handleBack() {
        if (folderHistory.length > 0) goBackFolder()
        else if (currentFolder !== "/") {
            currentFolder = parentFolder()
            currentLabel = currentFolder === "/" ? "系统盘" : currentFolder.slice(currentFolder.lastIndexOf("/") + 1)
            systemBackend.browseDirectory(currentFolder)
        } else filesPage.exitRequested()
    }
    function isCurrentFavorite() {
        for (var i = 0; i < systemBackend.favoriteLocations.length; ++i)
            if (systemBackend.favoriteLocations[i].path === currentFolder) return true
        return false
    }
    function readableSize(bytes) {
        if (bytes < 1024) return bytes + " B"
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB"
        if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB"
        return (bytes / 1073741824).toFixed(1) + " GB"
    }
    function suffix(name) {
        var dot = name.lastIndexOf(".")
        return dot > 0 ? name.slice(dot + 1).toLowerCase() : ""
    }
    function isImage(name) { return ["png", "jpg", "jpeg", "webp", "bmp", "gif"].indexOf(suffix(name)) >= 0 }
    function isText(name) { return ["txt", "md", "json", "csv", "log", "ini", "conf", "qml", "js", "cpp", "c", "h", "py", "sh", "xml", "yaml", "yml"].indexOf(suffix(name)) >= 0 }
    function entryIcon(entry) {
        if (entry.directory) return "qrc:/assets/icons/folder.svg"
        if (isImage(entry.name)) return "qrc:/assets/icons/image.svg"
        if (isText(entry.name)) return "qrc:/assets/icons/file-text.svg"
        return "qrc:/assets/icons/file.svg"
    }
    function entryColor(entry) {
        if (entry.directory) return "#4A90E2"
        if (isImage(entry.name)) return "#E76D9B"
        if (isText(entry.name)) return "#8B68E8"
        return "#7E8794"
    }
    function pathParts() {
        var result = [{ label: "系统盘", path: "/" }]
        if (currentFolder === "/") return result
        var names = currentFolder.split("/")
        var accumulated = ""
        for (var i = 0; i < names.length; ++i) {
            if (!names[i].length) continue
            accumulated += "/" + names[i]
            result.push({ label: names[i], path: accumulated })
        }
        return result
    }
    function openEntry(entry) {
        if (entry.directory) {
            enterFolder(entry.path, entry.name)
            return
        }
        previewEntry = entry
        previewVisible = true
        if (isText(entry.name)) systemBackend.previewDocument(entry.path)
    }
    function canTransfer(path) {
        return (path.indexOf("/home/radxa/") === 0 || path.indexOf("/data/") === 0)
    }
    function stageTransfer(move) {
        if (!hasSelection) return
        clipboardPath = selectedEntry.path
        clipboardName = selectedEntry.name
        clipboardMove = move
        selectedEntry = ({})
    }
    function pasteHere() {
        if (!clipboardPath.length || systemBackend.fileOperationRunning) return
        pastePending = true
        systemBackend.transferFile(clipboardPath, currentFolder, clipboardMove)
        Qt.callLater(function() {
            if (!systemBackend.fileOperationRunning) filesPage.pastePending = false
        })
    }

    Connections {
        target: systemBackend
        function onFileOperationChanged() {
            if (filesPage.pastePending && !systemBackend.fileOperationRunning) {
                filesPage.pastePending = false
                filesPage.clipboardPath = ""
                filesPage.clipboardName = ""
            }
        }
    }

    Component.onCompleted: {
        systemBackend.browseDirectory(currentFolder)
        if (window.qaFileCopy)
            Qt.callLater(function() { systemBackend.transferFile("/home/radxa/meow-qa/source-copy.txt", "/home/radxa/meow-qa/dest", false) })
        else if (window.qaFileMove)
            Qt.callLater(function() { systemBackend.transferFile("/home/radxa/meow-qa/source-move.txt", "/home/radxa/meow-qa/dest", true) })
    }

    AppHeader {
        title: "文件"
        subtitle: filesPage.currentLabel
        showBack: filesPage.folderHistory.length > 0 || filesPage.currentFolder !== "/"
        trailingText: systemBackend.fileEntries.length + " 项"
        onBackRequested: filesPage.handleBack()
        onExitRequested: filesPage.exitRequested()
    }

    Flickable {
        anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 24; rightMargin: 24; topMargin: 74 }
        height: 52; contentWidth: Math.max(width, favoriteRow.width); clip: true; flickableDirection: Flickable.HorizontalFlick
        Row {
            id: favoriteRow; height: parent.height; spacing: 10
            Text { visible: systemBackend.favoriteLocations.length === 0; anchors.verticalCenter: parent.verticalCenter; text: "暂无收藏 · 进入目录后点击底部“收藏”"; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 16 }
            Repeater {
                model: systemBackend.favoriteLocations
                delegate: Rectangle {
                    width: favoriteLabel.implicitWidth + 28; height: 44; radius: 15
                    color: filesPage.currentFolder === modelData.path ? "#7B6DF0" : "#FFFFFF"
                    border.color: filesPage.currentFolder === modelData.path ? "#7B6DF0" : "#DCD7E1"; border.width: 1
                    Text { id: favoriteLabel; anchors.centerIn: parent; text: modelData.label; color: filesPage.currentFolder === modelData.path ? "white" : "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 16; font.weight: Font.DemiBold }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: { filesPage.folderHistory = []; filesPage.currentFolder = modelData.path; filesPage.currentLabel = modelData.label; systemBackend.browseDirectory(modelData.path) }
                        onPressAndHold: systemBackend.removeFavoriteLocation(modelData.path)
                    }
                }
            }
        }
    }

    Flickable {
        anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 30; rightMargin: 30; topMargin: 130 }
        height: 38; contentWidth: breadcrumbRow.width; clip: true; flickableDirection: Flickable.HorizontalFlick
        Row {
            id: breadcrumbRow; spacing: 6
            Repeater {
                model: filesPage.pathParts()
                delegate: Row {
                    spacing: 6
                    Text { visible: index > 0; text: "›"; color: "#AAA5AE"; font.pixelSize: 22; anchors.verticalCenter: parent.verticalCenter }
                    Rectangle {
                        width: crumbText.implicitWidth + 22; height: 34; radius: 11
                        color: index === filesPage.pathParts().length - 1 ? "#EDEAFF" : "transparent"
                        Text { id: crumbText; anchors.centerIn: parent; text: modelData.label; color: index === filesPage.pathParts().length - 1 ? "#7B6DF0" : "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; font.weight: index === filesPage.pathParts().length - 1 ? Font.DemiBold : Font.Normal }
                        MouseArea { anchors.fill: parent; onClicked: filesPage.enterFolder(modelData.path, modelData.label) }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; leftMargin: 24; rightMargin: 24; topMargin: 172; bottomMargin: 92 }
        radius: 22; color: "#FFFFFF"; border.color: "#E7E3EA"; border.width: 1; clip: true
        ListView {
            anchors.fill: parent; anchors.margins: 10; clip: true
            model: systemBackend.fileEntries
            boundsBehavior: Flickable.DragAndOvershootBounds
            maximumFlickVelocity: 3200
            delegate: Rectangle {
                width: ListView.view.width; height: 60; radius: 14
                color: filesPage.selectedEntry.path === modelData.path ? "#EEEAFE" : (fileMouse.pressed ? "#F0EDF3" : "#FFFFFF")
                border.color: filesPage.selectedEntry.path === modelData.path ? "#BEB3F5" : "transparent"; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 14
                    Rectangle { Layout.preferredWidth: 40; Layout.preferredHeight: 40; radius: 12; color: filesPage.entryColor(modelData); Image { anchors.centerIn: parent; width: 23; height: 23; source: filesPage.entryIcon(modelData); sourceSize.width: 46; sourceSize.height: 46 } }
                    Text { Layout.fillWidth: true; text: modelData.name; color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 17; elide: Text.ElideRight }
                    ColumnLayout { spacing: 1; Text { Layout.alignment: Qt.AlignRight; text: modelData.directory ? "文件夹" : filesPage.readableSize(modelData.size); color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 14 } Text { Layout.alignment: Qt.AlignRight; visible: !modelData.directory; text: modelData.modified; color: "#AAA5AE"; font.family: "Noto Sans CJK SC"; font.pixelSize: 11 } }
                }
                MouseArea {
                    id: fileMouse; anchors.fill: parent
                    property bool held: false
                    onPressed: held = false
                    onPressAndHold: {
                        held = true
                        if (filesPage.canTransfer(modelData.path)) filesPage.selectedEntry = modelData
                        else systemBackend.operationMessage("系统位置为只读，不能复制或移动", false)
                    }
                    onClicked: if (!held) filesPage.openEntry(modelData)
                }
            }
            Text { anchors.centerIn: parent; visible: !systemBackend.filesLoading && systemBackend.fileEntries.length === 0; text: systemBackend.filesError.length ? systemBackend.filesError : "这里还没有内容"; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 18 }
            BusyIndicator { anchors.centerIn: parent; running: systemBackend.filesLoading; visible: running }
        }
    }

    Rectangle {
        z: 600; visible: true
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 24; rightMargin: 24; bottomMargin: 18 }
        height: 62; radius: 20; color: "#FCFBFD"; border.color: "#DCD7E1"; border.width: 1
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 12; spacing: 10
            ColumnLayout { Layout.fillWidth: true; spacing: 0; Text { text: filesPage.hasSelection ? filesPage.selectedEntry.name : (filesPage.clipboardPath.length ? filesPage.clipboardName : filesPage.currentLabel); color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 16; font.weight: Font.DemiBold; elide: Text.ElideMiddle; Layout.fillWidth: true } Text { text: filesPage.hasSelection ? "选择操作" : (filesPage.clipboardPath.length ? (filesPage.clipboardMove ? "移动到当前目录" : "复制到当前目录") : filesPage.currentFolder); color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 12; elide: Text.ElideMiddle; Layout.fillWidth: true } }
            Rectangle { visible: !filesPage.hasSelection && filesPage.clipboardPath.length === 0; Layout.preferredWidth: 94; Layout.preferredHeight: 40; radius: 13; color: filesPage.isCurrentFavorite() ? "#EAF8F1" : "#EEEAFE"; Text { anchors.centerIn: parent; text: filesPage.isCurrentFavorite() ? "已收藏" : "收藏"; color: filesPage.isCurrentFavorite() ? "#238C69" : "#7B6DF0"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; font.weight: Font.DemiBold } MouseArea { anchors.fill: parent; enabled: !filesPage.isCurrentFavorite(); onClicked: systemBackend.addFavoriteLocation(filesPage.currentFolder, filesPage.currentLabel) } }
            Rectangle { visible: filesPage.hasSelection; Layout.preferredWidth: 76; Layout.preferredHeight: 40; radius: 13; color: "#EAF2FF"; Text { anchors.centerIn: parent; text: "复制"; color: "#3978C5"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; font.weight: Font.DemiBold } MouseArea { anchors.fill: parent; onClicked: filesPage.stageTransfer(false) } }
            Rectangle { visible: filesPage.hasSelection; Layout.preferredWidth: 76; Layout.preferredHeight: 40; radius: 13; color: "#EAF8F1"; Text { anchors.centerIn: parent; text: "移动"; color: "#238C69"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; font.weight: Font.DemiBold } MouseArea { anchors.fill: parent; onClicked: filesPage.stageTransfer(true) } }
            Rectangle { visible: filesPage.clipboardPath.length > 0; Layout.preferredWidth: 116; Layout.preferredHeight: 40; radius: 13; color: "#7B6DF0"; opacity: systemBackend.fileOperationRunning ? 0.5 : 1; Text { anchors.centerIn: parent; text: systemBackend.fileOperationRunning ? systemBackend.fileOperationText : "粘贴到这里"; color: "white"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; font.weight: Font.DemiBold } MouseArea { anchors.fill: parent; enabled: !systemBackend.fileOperationRunning; onClicked: filesPage.pasteHere() } }
            Rectangle { visible: filesPage.hasSelection || filesPage.clipboardPath.length > 0; Layout.preferredWidth: 68; Layout.preferredHeight: 40; radius: 13; color: "#F0EDF3"; Text { anchors.centerIn: parent; text: "取消"; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 14; font.weight: Font.DemiBold } MouseArea { anchors.fill: parent; onClicked: { filesPage.selectedEntry = ({}); filesPage.clipboardPath = ""; filesPage.clipboardName = "" } } }
        }
    }

    Rectangle {
        z: 1200; anchors.fill: parent; visible: filesPage.previewVisible; color: "#660B0A0D"
        MouseArea { anchors.fill: parent; onClicked: filesPage.previewVisible = false }
        Rectangle {
            anchors.centerIn: parent; width: parent.width - 150; height: parent.height - 120; radius: 28; color: "#FCFBFD"; border.color: "#E7E3EA"; border.width: 1; clip: true
            MouseArea { anchors.fill: parent; onClicked: mouse.accepted = true }
            RowLayout {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 22 }
                ColumnLayout { Layout.fillWidth: true; spacing: 2; Text { text: filesPage.previewEntry.name || "预览"; color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 23; font.weight: Font.Bold; elide: Text.ElideMiddle; Layout.fillWidth: true } Text { text: filesPage.readableSize(filesPage.previewEntry.size || 0) + " · " + (filesPage.previewEntry.modified || ""); color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 13 } }
                Rectangle { Layout.preferredWidth: 72; Layout.preferredHeight: 40; radius: 14; color: "#EEEAFE"; Text { anchors.centerIn: parent; text: "完成"; color: "#7B6DF0"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; font.weight: Font.DemiBold } MouseArea { anchors.fill: parent; onClicked: filesPage.previewVisible = false } }
            }
            Image {
                anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 28; topMargin: 86 }
                visible: filesPage.isImage(filesPage.previewEntry.name || "")
                source: visible ? "file://" + encodeURI(filesPage.previewEntry.path) : ""
                fillMode: Image.PreserveAspectFit; asynchronous: true; cache: false
            }
            Flickable {
                anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom; margins: 28; topMargin: 86 }
                visible: filesPage.isText(filesPage.previewEntry.name || ""); clip: true
                contentWidth: width; contentHeight: previewText.implicitHeight + 20
                Text { id: previewText; width: parent.width; text: systemBackend.previewLoading ? "正在读取…" : (systemBackend.previewError.length ? systemBackend.previewError : systemBackend.previewText); color: "#27222D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 15; wrapMode: Text.WrapAnywhere; lineHeight: 1.25 }
            }
            Column {
                anchors.centerIn: parent; spacing: 12
                visible: !filesPage.isImage(filesPage.previewEntry.name || "") && !filesPage.isText(filesPage.previewEntry.name || "")
                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 72; height: 72; radius: 22; color: "#7E8794"; Image { anchors.centerIn: parent; width: 38; height: 38; source: "qrc:/assets/icons/file.svg" } }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "此文件暂不支持内容预览"; color: "#77717D"; font.family: "Noto Sans CJK SC"; font.pixelSize: 17 }
            }
        }
    }
}
