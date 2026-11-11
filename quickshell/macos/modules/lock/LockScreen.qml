import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../../services"
import "../common"

PanelWindow {
    id: root

    screen: Quickshell.screens[0]
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    visible: ShellController.locked
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "macos:lock"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property bool authenticating: false
    property bool failed: false
    property string statusText: ""
    property string password: ""
    property string pendingPassword: ""

    // Customizable configuration helpers
    readonly property var lockCfg: (Appearance.userCfg && Appearance.userCfg.lockScreen) ? Appearance.userCfg.lockScreen : ({})
    readonly property string clockFormat: (lockCfg && lockCfg.clockFormat) ? lockCfg.clockFormat : "12h"
    readonly property bool showDate: (lockCfg && typeof lockCfg.showDate !== "undefined") ? lockCfg.showDate : true
    readonly property bool showPowerButton: (lockCfg && typeof lockCfg.showPowerButton !== "undefined") ? lockCfg.showPowerButton : true
    readonly property real dimOpacity: {
        if (lockCfg && typeof lockCfg.dimOpacity !== "undefined") {
            var v = Number(lockCfg.dimOpacity);
            if (!isNaN(v)) return Math.max(0.0, Math.min(1.0, v));
        }
        return 0.12; // Authentic vibrant macOS Sonoma look
    }

    readonly property string customWallpaper: (lockCfg && lockCfg.wallpaper) ? lockCfg.wallpaper : ""
    readonly property string systemWallpaper: (Appearance.userCfg && Appearance.userCfg.wallpaperPath) ? Appearance.userCfg.wallpaperPath : ""
    readonly property string wallpaperSource: {
        var wp = customWallpaper;
        if (!wp || wp === "system" || wp === "desktop") {
            wp = systemWallpaper !== "" ? systemWallpaper : (Quickshell.shellDir + "/assets/wall.jpg");
        }
        return wp.startsWith("file://") ? wp : ("file://" + wp);
    }

    readonly property string customAvatar: (lockCfg && lockCfg.avatar) ? lockCfg.avatar : ""
    readonly property string systemAvatar: (Appearance.userCfg && Appearance.userCfg.avatarPath) ? Appearance.userCfg.avatarPath : ""
    readonly property string avatarSource: {
        var av = customAvatar;
        if (!av || av === "system" || av === "default") {
            av = systemAvatar !== "" ? systemAvatar : (Quickshell.shellDir + "/assets/user.jpg");
        }
        return av.startsWith("file://") ? av : ("file://" + av);
    }

    readonly property string displayDate: {
        return (typeof Time !== "undefined" && Time.dateLong && Time.dateLong !== "")
            ? Time.dateLong
            : Qt.formatDate(new Date(), "dddd, MMMM d");
    }

    readonly property string displayTime: {
        if (clockFormat === "24h") {
            var d = new Date();
            var h = String(d.getHours()).padStart(2, "0");
            var m = String(d.getMinutes()).padStart(2, "0");
            return h + ":" + m;
        }
        return (typeof Time !== "undefined" && Time.timeHourMin && Time.timeHourMin !== "")
            ? Time.timeHourMin
            : Qt.formatTime(new Date(), "h:mm");
    }

    onVisibleChanged: {
        if (root.visible) {
            root.password = "";
            root.pendingPassword = "";
            root.failed = false;
            root.statusText = "";
            root.authenticating = false;
            passwordBoxContainer.horizontalOffset = 0;
            Qt.callLater(() => {
                if (passwordField) passwordField.forceActiveFocus();
            });
        }
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellDir + "/ui/components/lockscreen/pam"
        config: "password.conf"

        onPamMessage: {
            if (this.responseRequired && root.pendingPassword !== "") {
                this.respond(root.pendingPassword);
                root.pendingPassword = "";
            }
        }

        onCompleted: (result) => {
            root.authenticating = false;
            if (result === PamResult.Success) {
                root.password = "";
                root.pendingPassword = "";
                ShellController.unlock();
            } else {
                root.failed = true;
                root.statusText = "Incorrect Password";
                root.password = "";
                root.pendingPassword = "";
                shakeAnim.restart();
                if (passwordField) passwordField.forceActiveFocus();
            }
        }

        onError: (error) => {
            root.authenticating = false;
            root.statusText = "Authentication failed";
            root.password = "";
            root.pendingPassword = "";
            shakeAnim.restart();
            if (passwordField) passwordField.forceActiveFocus();
        }
    }

    // Wallpaper
    Image {
        anchors.fill: parent
        source: root.wallpaperSource
        fillMode: Image.PreserveAspectCrop
        smooth: true
        mipmap: true
    }

    // Subtle dark vignette/dimming
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, root.dimOpacity)
    }

    // Dismiss focus / click background handler
    MouseArea {
        anchors.fill: parent
        z: 1
        onClicked: {
            if (passwordField) passwordField.forceActiveFocus();
        }
    }

    // Main lock screen content
    Item {
        anchors.fill: parent
        z: 2

        // Top Clock & Date Area
        Item {
            id: clockArea
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 56
            width: Math.max(timeWrapper.width, dateWrapper.width)
            height: (root.showDate ? dateWrapper.height + 4 : 0) + timeWrapper.height

            // Date (macOS style: top center)
            Item {
                id: dateWrapper
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: dateText.paintedWidth
                height: dateText.paintedHeight
                visible: root.showDate

                // Soft shadow for legibility over vibrant wallpapers
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 1.5
                    text: root.displayDate
                    font {
                        family: Appearance.fontFamily
                        pixelSize: 22
                        weight: Font.DemiBold
                    }
                    color: Qt.rgba(0, 0, 0, 0.40)
                }

                Text {
                    id: dateText
                    anchors.centerIn: parent
                    text: root.displayDate
                    font {
                        family: Appearance.fontFamily
                        pixelSize: 22
                        weight: Font.DemiBold
                    }
                    color: "#ffffff"
                }
            }

            // Time (macOS Sonoma / Sequoia bold clock)
            Item {
                id: timeWrapper
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: root.showDate ? dateWrapper.bottom : parent.top
                anchors.topMargin: 4
                width: timeText.paintedWidth
                height: timeText.paintedHeight

                // Drop shadow
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 3
                    text: root.displayTime
                    font {
                        family: Appearance.fontFamily
                        pixelSize: 104
                        weight: Font.Bold
                    }
                    color: Qt.rgba(0, 0, 0, 0.35)
                }

                Text {
                    id: timeText
                    anchors.centerIn: parent
                    text: root.displayTime
                    font {
                        family: Appearance.fontFamily
                        pixelSize: 104
                        weight: Font.Bold
                    }
                    color: "#ffffff"
                }
            }
        }

        // User Avatar (compact circle)
        Item {
            id: avatarWrapper
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: passwordBoxContainer.top
            anchors.bottomMargin: 14
            width: 56
            height: 56

            // Subtle drop shadow behind avatar
            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: width / 2
                color: Qt.rgba(0, 0, 0, 0.30)
            }

            Rectangle {
                id: avatarCircle
                anchors.fill: parent
                radius: width / 2
                color: Qt.rgba(255, 255, 255, 0.15)
                border.color: Qt.rgba(255, 255, 255, 0.35)
                border.width: 1.5
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.avatarSource
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    mipmap: true
                    cache: false
                }
            }
        }

        // Password pill container
        Item {
            id: passwordBoxContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: horizontalOffset
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 105
            width: 204
            height: 34

            property real horizontalOffset: 0

            // Shake animation on error
            SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: passwordBoxContainer; property: "horizontalOffset"; to: -12; duration: 40; easing.type: Easing.InOutQuad }
                NumberAnimation { target: passwordBoxContainer; property: "horizontalOffset"; to: 12; duration: 40; easing.type: Easing.InOutQuad }
                NumberAnimation { target: passwordBoxContainer; property: "horizontalOffset"; to: -8; duration: 35; easing.type: Easing.InOutQuad }
                NumberAnimation { target: passwordBoxContainer; property: "horizontalOffset"; to: 8; duration: 35; easing.type: Easing.InOutQuad }
                NumberAnimation { target: passwordBoxContainer; property: "horizontalOffset"; to: -4; duration: 30; easing.type: Easing.InOutQuad }
                NumberAnimation { target: passwordBoxContainer; property: "horizontalOffset"; to: 4; duration: 30; easing.type: Easing.InOutQuad }
                NumberAnimation { target: passwordBoxContainer; property: "horizontalOffset"; to: 0; duration: 25; easing.type: Easing.InOutQuad }
            }

            // Frosted glass pill background
            Rectangle {
                id: passwordBox
                anchors.fill: parent
                radius: 17
                color: Qt.rgba(255, 255, 255, 0.22)
                border.color: root.failed ? "#ff5c5c" : Qt.rgba(255, 255, 255, 0.32)
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (passwordField) passwordField.forceActiveFocus();
                    }
                }

                // Placeholder text
                Text {
                    anchors.centerIn: parent
                    visible: passwordField.text.length === 0 && !root.authenticating
                    text: "Enter Password"
                    font {
                        family: Appearance.fontFamily
                        pixelSize: 13
                        weight: Font.Normal
                    }
                    color: Qt.rgba(255, 255, 255, 0.65)
                }

                // Unlocking state text
                Text {
                    anchors.centerIn: parent
                    visible: root.authenticating
                    text: "Unlocking\u2026"
                    font {
                        family: Appearance.fontFamily
                        pixelSize: 13
                        weight: Font.Normal
                    }
                    color: Qt.rgba(255, 255, 255, 0.85)
                }

                TextInput {
                    id: passwordField
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: (passwordField.text.length > 0) ? 34 : 16
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    visible: !root.authenticating
                    focus: root.visible
                    echoMode: TextInput.Password
                    passwordCharacter: "\u2022"
                    font {
                        family: Appearance.fontFamily
                        pixelSize: 15
                        letterSpacing: 2
                    }
                    color: "#ffffff"
                    selectionColor: Appearance.accent
                    text: root.password
                    onTextChanged: {
                        root.password = text;
                        if (root.failed) root.failed = false;
                        if (root.statusText !== "") root.statusText = "";
                    }
                    onAccepted: root.authenticate()
                }

                // Submit arrow button (visible when user types)
                Rectangle {
                    id: submitBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24
                    radius: 12
                    visible: passwordField.text.length > 0 && !root.authenticating
                    color: submitMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.50) : Qt.rgba(255, 255, 255, 0.30)

                    Text {
                        anchors.centerIn: parent
                        text: "\u2192"
                        font {
                            family: Appearance.fontFamily
                            pixelSize: 13
                            bold: true
                        }
                        color: "#ffffff"
                    }

                    MouseArea {
                        id: submitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.authenticate()
                    }
                }
            }
        }

        // Status text / Incorrect password notice
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: passwordBoxContainer.bottom
            anchors.topMargin: 10
            visible: root.statusText !== ""
            text: root.statusText
            font {
                family: Appearance.fontFamily
                pixelSize: 12
                weight: Font.Normal
            }
            color: root.failed ? "#ff8080" : Qt.rgba(255, 255, 255, 0.85)
        }
    }

    // Power button (bottom right)
    Rectangle {
        id: powerBtn
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        width: 36
        height: 36
        radius: 18
        visible: root.showPowerButton
        color: powerMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.28) : Qt.rgba(255, 255, 255, 0.15)
        border.color: Qt.rgba(255, 255, 255, 0.25)
        border.width: 1
        z: 3

        Text {
            anchors.centerIn: parent
            text: "\u23FB"
            font { family: Appearance.fontFamily; pixelSize: 16 }
            color: "#ffffff"
        }

        MouseArea {
            id: powerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellController.toggle("session")
        }
    }

    function authenticate() {
        if (root.authenticating) return;
        if (root.password === "") {
            shakeAnim.restart();
            return;
        }
        root.authenticating = true;
        root.failed = false;
        root.statusText = "";
        root.pendingPassword = root.password;
        pam.start();
    }
}
