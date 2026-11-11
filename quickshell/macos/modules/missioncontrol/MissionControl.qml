import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../services"
import "../common"

PanelWindow {
    id: root

    screen: (Quickshell.screens && Quickshell.screens.length > 0) ? Quickshell.screens[0] : null
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: ShellController.missionControlOpen && !ShellController.locked
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "macos:missioncontrol"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var windowList: {
        var all = ToplevelManager.toplevels.values || [];
        return all.filter(function(t) {
            if (!t) return false;
            var id = String(t.appId || "").toLowerCase();
            if (id === "org.quickshell" || id === "quickshell" || id === "") return false;
            return true;
        });
    }

    // Backdrop
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.04, 0.05, 0.08, 0.78)

        MouseArea {
            anchors.fill: parent
            onClicked: ShellController.missionControlOpen = false
        }
    }

    // Keyboard handler
    Item {
        focus: root.visible
        Keys.onEscapePressed: ShellController.missionControlOpen = false
    }

    // Main layout
    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 24
        anchors.bottomMargin: 32
        anchors.leftMargin: 40
        anchors.rightMargin: 40
        spacing: 24

        // ── Top Spaces / Workspaces Bar ──
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            Repeater {
                model: 6
                delegate: Rectangle {
                    required property int index
                    readonly property int wsId: index + 1
                    readonly property bool isActive: (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId)

                    width: 110
                    height: 64
                    radius: 10
                    color: isActive ? Qt.rgba(255, 255, 255, 0.22) : Qt.rgba(255, 255, 255, 0.08)
                    border.color: isActive ? "#ffffff" : Qt.rgba(255, 255, 255, 0.18)
                    border.width: isActive ? 2 : 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\u25A2"
                            font.pixelSize: 16
                            color: isActive ? "#ffffff" : Qt.rgba(255, 255, 255, 0.6)
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Desktop " + wsId
                            font {
                                family: Appearance.fontFamily
                                pixelSize: 11
                                weight: isActive ? Font.Bold : Font.Normal
                            }
                            color: isActive ? "#ffffff" : Qt.rgba(255, 255, 255, 0.75)
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch("workspace " + wsId);
                        }
                    }
                }
            }
        }

        // ── Center Windows Grid / Exposé ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty state
            Column {
                anchors.centerIn: parent
                visible: root.windowList.length === 0
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No Windows Open"
                    font { family: Appearance.fontFamily; pixelSize: 20; bold: true }
                    color: Qt.rgba(255, 255, 255, 0.7)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Open applications will appear here in Mission Control"
                    font { family: Appearance.fontFamily; pixelSize: 13 }
                    color: Qt.rgba(255, 255, 255, 0.4)
                }
            }

            // Window Cards Grid
            Flow {
                id: windowGrid
                anchors.centerIn: parent
                width: Math.min(parent.width, Math.ceil(root.windowList.length / 2) * 330)
                spacing: 20

                Repeater {
                    model: root.windowList

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        required property int index

                        width: 310
                        height: 190
                        radius: 14
                        color: cardMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.18) : Qt.rgba(255, 255, 255, 0.10)
                        border.color: cardMouse.containsMouse ? Appearance.accent : Qt.rgba(255, 255, 255, 0.20)
                        border.width: cardMouse.containsMouse ? 1.5 : 1
                        clip: true

                        scale: cardMouse.containsMouse ? 1.03 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        // Window Titlebar Header
                        Rectangle {
                            id: cardHeader
                            z: 5
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 32
                            color: Qt.rgba(0, 0, 0, 0.25)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                // Close Button
                                Rectangle {
                                    width: 14
                                    height: 14
                                    radius: 7
                                    color: closeMouse.containsMouse ? "#ff453a" : Qt.rgba(1, 0.3, 0.3, 0.8)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\u00D7"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: "#ffffff"
                                        visible: closeMouse.containsMouse
                                    }

                                    MouseArea {
                                        id: closeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        z: 10
                                        onClicked: {
                                            if (card.modelData && typeof card.modelData.close === "function") {
                                                card.modelData.close();
                                            }
                                        }
                                    }
                                }

                                // App Icon
                                Image {
                                    width: 16
                                    height: 16
                                    source: DockApps.iconSource(DockApps.iconFor(card.modelData.appId))
                                    fillMode: Image.PreserveAspectCrop
                                }

                                // Window Title
                                Text {
                                    Layout.fillWidth: true
                                    text: card.modelData.title || card.modelData.appId || "Window"
                                    elide: Text.ElideRight
                                    font {
                                        family: Appearance.fontFamily
                                        pixelSize: 12
                                        weight: Font.DemiBold
                                    }
                                    color: "#ffffff"
                                }
                            }
                        }

                        // Window Body Preview
                        Item {
                            anchors.top: cardHeader.bottom
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Image {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 52
                                    height: 52
                                    source: DockApps.iconSource(DockApps.iconFor(card.modelData.appId))
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: card.modelData.appId || ""
                                    font { family: Appearance.fontFamily; pixelSize: 11 }
                                    color: Qt.rgba(255, 255, 255, 0.6)
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (card.modelData && typeof card.modelData.activate === "function") {
                                    card.modelData.activate();
                                }
                                ShellController.missionControlOpen = false;
                            }
                        }
                    }
                }
            }
        }

        // ── Bottom Dismiss Hint ──
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Press Esc or click background to exit Mission Control"
            font { family: Appearance.fontFamily; pixelSize: 12 }
            color: Qt.rgba(255, 255, 255, 0.40)
        }
    }
}
