import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import qs
import qs.config
import qs.ui.controls.advanced
import qs.ui.controls.auxiliary
import qs.ui.controls.providers
import qs.ui.controls.primitives
import qs.ui.controls.windows

Item {
    id: root
    signal actionClicked()
    function keyPressed(event: var) {
        if (loader && loader.item && typeof loader.item.keyPressed === "function") {
            loader.item.keyPressed(event)
        }
    }
    property string text: ""
    required property string selectedAction
    required property string textColor
    property bool shown: false
    function collectAnswers() {
        return DesktopEntries.applications.values
                    .filter(a => a.name.toLowerCase().includes(root.text.toLowerCase()))
                    .map(a => root.answer(a));
    }
    function answer(entry) {
        return {
            title: entry.name,
            description: "Application",
            icon: entry.icon,
            clicked: () => {
                entry.execute()
                root.actionClicked()
            }
        }
    }

    property list<var> answers: collectAnswers()
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: false

    height: root.shown ? Math.min(400, (loader.item.customHeight ? loader.item.customHeight : loader.item.contentHeight)+20) : 0

    Behavior on height {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutBack
            easing.overshoot: 1
        }
    }

    Rectangle {
        anchors {
            top: parent.top
            topMargin: -10
            left: parent.left; leftMargin: 12
            right: parent.right; rightMargin: 12
        }
        height: 2
        radius: 2
        color: "#40555555"
        visible: false
    }
    CFClippingRect {
        id: clippingRect
        anchors.fill: parent
        radius: 20
        Loader {
            id: loader
            anchors.fill: parent
            active: true
            property Component contentGlobal: ContentGlobal {
                id: contentGlobal
                anchors.fill: parent
                textColor: root.textColor
                text: root.text
                answers: root.answers
            }
            property Component contentClipboard: ContentClipboard {
                id: contentClipboard
                anchors.fill: parent
                textColor: root.textColor
                text: root.text
                answers: root.answers
                onActionClicked: () => {
                    root.actionClicked()
                }
                
            }
            sourceComponent: root.selectedAction == "clipboard" ? contentClipboard : contentGlobal
        }
    }
}