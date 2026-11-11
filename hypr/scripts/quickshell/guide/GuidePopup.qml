import QtQuick
import Quickshell

Shell {
    PanelWindow {
        active: true
        wantsFocus: true
        
        anchors.fill: parent

        // Import local component directly
        GuidePopup {
            anchors.fill: parent
        }
    }
}
