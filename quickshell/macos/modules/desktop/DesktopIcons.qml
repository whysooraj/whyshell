import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell

Scope {
    id: root

    PanelWindow {
        id: desktopWindow
        
        // Bind screen to eDP-1 if present, otherwise primary screen
        screen: Quickshell.screens.find(function(s) { return s.name === "eDP-1"; }) || Quickshell.screens[0]
        
        anchors.fill: parent
        
        // Layer settings for stable background presence
        WlrLayershell.exclusionMode: WlrLayershell.ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayershell.Layer.Background
        WlrLayershell.namespace: "desktop_icons"
        
        color: "transparent" // Transparent to show wallpaper

        GridView {
            id: grid
            anchors.fill: parent
            anchors.topMargin: 80     // Avoid TopBar overlap
            anchors.bottomMargin: 120  // Avoid Dock overlap
            anchors.leftMargin: 50
            anchors.rightMargin: 50
            cellWidth: 120
            cellHeight: 120
            flow: GridView.FlowTopToBottom // Vertical column layout

            model: FolderListModel {
                id: folderModel
                // Direct desktop folder path
                folder: "file://" + Quickshell.env("HOME") + "/Desktop"
                showDotAndDotDot: false
            }

            delegate: Item {
                width: grid.cellWidth
                height: grid.cellHeight

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    // Icon placeholder
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 55
                        height: 55
                        color: fileIsDir ? "#4c566a" : "#81a1c1"
                        radius: 10
                        opacity: 0.85
                    }

                    // File or folder name
                    Text {
                        Layout.fillWidth: true
                        text: fileName
                        color: "white"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        // Drop shadow for legibility over any wallpaper
                        style: Text.Outline
                        styleColor: "black"
                    }
                }

                // Open on double click
                MouseArea {
                    anchors.fill: parent
                    onDoubleClicked: {
                        Quickshell.exec(["xdg-open", filePath])
                    }
                }
            }
        }
    }
}
