import QtQuick
import QtQuick.Window

Item {
    id: row

    property string rowId
    property string title
    property string iconFile
    property bool selected: false
    property bool show: true
    readonly property bool highlighted: selected && row.Window.window && row.Window.window.active

    signal clicked(string rowId)

    width: parent ? parent.width : 100
    height: show ? Theme.rowHeight : 0
    visible: show

    Rectangle {
        id: highlight
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        radius: 8
        color: row.selected ? (row.highlighted ? Theme.accent : Theme.selectedBg) : (mouse.containsMouse ? Qt.rgba(0, 0, 0, 0.05) : "transparent")

        Behavior on color {
            ColorAnimation { duration: 60 }
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: highlight.left
        anchors.leftMargin: 8
        anchors.right: highlight.right
        anchors.rightMargin: 8
        spacing: 10

        Image {
            source: Theme.icon(row.iconFile, Theme.sidebarIconSize)
            width: Theme.sidebarIconSize
            height: Theme.sidebarIconSize
            anchors.verticalCenter: parent.verticalCenter
            asynchronous: true
            mipmap: true
        }

        Text {
            text: row.title
            font.family: Theme.fontText
            font.pixelSize: 13
            color: row.highlighted ? "white" : Theme.textPrimary
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            width: parent.width - Theme.sidebarIconSize - parent.spacing
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked(row.rowId)
    }
}
