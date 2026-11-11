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
        var hlWins = (Hyprland.toplevels && Hyprland.toplevels.values) ? Hyprland.toplevels.values : [];
        var list = [];
        for (var i = 0; i < hlWins.length; i++) {
            var w = hlWins[i];
            if (!w) continue;
            var ipc = w.lastIpcObject || {};
            var cls = String(ipc["class"] || "").toLowerCase();
            if (cls === "org.quickshell" || cls === "quickshell" || cls === "") continue;

            var wsId = (w.workspace && w.workspace.id !== undefined) ? w.workspace.id : (ipc.workspace ? ipc.workspace.id : 1);
            var addr = String(ipc.address || w.address || "");
            if (addr && !addr.startsWith("0x")) addr = "0x" + addr;

            list.push({
                title: ipc.title || w.title || "Window",
                appId: ipc["class"] || ipc.initialClass || "app",
                workspaceId: wsId,
                address: addr,
                wayland: w.wayland,
                raw: w
            });
        }
        if (list.length > 0) return list;

        // Fallback to ToplevelManager if Hyprland.toplevels is empty
        var tops = (ToplevelManager.toplevels && ToplevelManager.toplevels.values) ? ToplevelManager.toplevels.values : [];
        return (tops || []).filter(function(t) {
            if (!t) return false;
            var id = String(t.appId || "").toLowerCase();
            return (id !== "org.quickshell" && id !== "quickshell" && id !== "");
        }).map(function(t) {
            return {
                title: t.title || t.appId || "Window",
                appId: t.appId || "app",
                workspaceId: 1,
                address: "",
                wayland: t,
                raw: t
            };
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
                            Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })");
                            ShellController.missionControlOpen = false;
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
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: closeMouse.containsMouse ? "#ff5f56" : Qt.rgba(255, 95, 86, 0.7)

                                    MouseArea {
                                        id: closeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        z: 10
                                        onClicked: {
                                            if (card.modelData && card.modelData.address) {
                                                Hyprland.dispatch("hl.dsp.window.close({ window = \"address:" + card.modelData.address + "\" })");
                                            } else if (card.modelData && card.modelData.raw && typeof card.modelData.raw.close === "function") {
                                                card.modelData.raw.close();
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

                                // Workspace Badge
                                Text {
                                    visible: !!card.modelData.workspaceId && card.modelData.workspaceId > 0
                                    text: "Desktop " + card.modelData.workspaceId
                                    font {
                                        family: Appearance.fontFamily
                                        pixelSize: 10
                                    }
                                    color: Qt.rgba(255, 255, 255, 0.45)
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
                                var item = card.modelData;
                                if (!item) return;

                                if (item.workspaceId !== undefined && item.workspaceId > 0) {
                                    Hyprland.dispatch("hl.dsp.focus({ workspace = " + item.workspaceId + " })");
                                }

                                if (item.address) {
                                    Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + item.address + "\" })");
                                    Hyprland.dispatch("hl.dsp.window.alter_zorder({ mode = \"top\" })");
                                }

                                if (item.wayland && typeof item.wayland.activate === "function") {
                                    item.wayland.activate();
                                } else if (item.raw && typeof item.raw.activate === "function") {
                                    item.raw.activate();
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
