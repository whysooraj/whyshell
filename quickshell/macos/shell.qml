import QtQuick
import Quickshell
import qs.config
import "./services"
import "./modules/topbar"
import "./modules/spotlight"
import "./modules/dock"
import "./modules/genie"
import "./modules/about"
import "./modules/notification"
import "./modules/session"
import "./modules/controlcenter"
import "./modules/desktop"
import "./modules/settings"
import "./modules/launcher"
import "./modules/lock"
import "./modules/missioncontrol"

ShellRoot {
    id: root

    TopBar { id: topBar }
    Loader { active: Config.spotlight.enable; sourceComponent: Spotlight {} }
    Loader { active: Config.launchpad.enable; sourceComponent: Launcher {} }
    Loader { active: Config.dock.enable; sourceComponent: Dock {} }
    Genie {}
    AboutWindow { parentWindow: topBar }
    NotificationPopup {}
    Session {}
    ConfirmDialog {}
    ForceQuit {}
    ControlCenter {}
    Settings {}
    LockScreen {}
    MissionControl {}

    // eqsh Spotlight reads Runtime.spotlightOpen; macos uses ShellController.spotlightOpen
    Connections {
        target: Runtime
        function onSpotlightOpenChanged() {
            if (ShellController.spotlightOpen !== Runtime.spotlightOpen)
                ShellController.spotlightOpen = Runtime.spotlightOpen;
        }
    }
    Connections {
        target: ShellController
        function onSpotlightOpenChanged() {
            if (Runtime.spotlightOpen !== ShellController.spotlightOpen)
                Runtime.spotlightOpen = ShellController.spotlightOpen;
        }
    }

    Component.onCompleted: { void Apps.ready; }
}
