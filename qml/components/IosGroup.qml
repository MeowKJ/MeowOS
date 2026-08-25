import QtQuick 2.15

Rectangle {
    id: groupRoot
    default property alias content: groupColumn.data
    radius: 18
    color: "#F9F9FB"
    border.color: "#E7E3EA"
    border.width: 1
    implicitHeight: groupColumn.height
    height: groupColumn.height
    width: parent ? parent.width : 0

    Column {
        id: groupColumn
        width: parent.width
    }
}
