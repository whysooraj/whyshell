import QtQuick
import Quickshell
import "guide"

Quickshell.Shell {
    PanelWindow {
        active: true
        wantsFocus: true
        
        // Fullscreen configuration in Quickshell
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        GuidePopup {
            anchors.fill: parent
        }
    }
}
