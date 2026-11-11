import QtQuick
import Quickshell
import "./guide" // Relative path import

Shell {
    PanelWindow {
        active: true
        wantsFocus: true
        
        // Fullscreen configuration in Quickshell
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        GuidePopup {
            anchors.fill: parent
        }
    }
}
