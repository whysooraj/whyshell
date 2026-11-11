import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import ".."
import "../Pages.js" as Pages

Column {
    id: page

    property string pageId: "lockScreen"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0
    property bool locking: false

    function eget(k, d) { bumpU; bumpE; return Shell.eget(k, d) }
    function uget(k, d) { bumpU; bumpE; return Shell.uget(k, d) }

    width: parent ? parent.width : 640
    spacing: 12

    readonly property string idlePath: HOME_DIR + "/.config/hypr/hypridle.conf"
    readonly property string lockPath: HOME_DIR + "/.config/hypr/hyprlock.conf"

    readonly property var wallpaperPresets: ({
        "macOS Sonoma (Light)": HOME_DIR + "/Pictures/Wallpapers/14-Sonoma-Light.jpg",
        "macOS Sonoma (Dark)": HOME_DIR + "/Pictures/Wallpapers/14-Sonoma-Dark.jpg",
        "macOS Sequoia": HOME_DIR + "/Pictures/Wallpapers/Sequoia-Sunrise-wallpaper-macos.jpg",
        "MacBook Pro M3": HOME_DIR + "/Pictures/Wallpapers/M3-MacBook-Pro-Wallpaper-8K.png",
        "Lake Tahoe": HOME_DIR + "/.config/revo/quickshell/macos/assets/wall.jpg",
        "Match Desktop": "system"
    })

    readonly property string currentWallpaper: {
        bumpU; rev;
        return String(Shell.uget("lockScreen.wallpaper", ""));
    }

    readonly property string currentPresetName: {
        var wp = currentWallpaper;
        if (!wp || wp === "system" || wp === "") return "Match Desktop";
        for (var k in wallpaperPresets) {
            if (wallpaperPresets[k] === wp) return k;
        }
        return "Custom Image";
    }

    readonly property string effectivePreviewWallpaper: {
        var wp = currentWallpaper;
        if (!wp || wp === "system" || wp === "") {
            wp = String(Shell.uget("wallpaperPath", ""));
        }
        if (!wp || wp === "") {
            wp = HOME_DIR + "/Pictures/Wallpapers/14-Sonoma-Light.jpg";
        }
        return wp.startsWith("file://") ? wp : ("file://" + wp);
    }

    readonly property string currentAvatar: {
        bumpU; rev;
        var a = String(Shell.uget("lockScreen.avatar", ""));
        if (!a || a === "system" || a === "default" || a === "") {
            a = String(Shell.uget("avatarPath", ""));
        }
        if (!a || a === "") {
            a = HOME_DIR + "/.config/revo/quickshell/macos/assets/user.jpg";
        }
        return a.startsWith("file://") ? a : ("file://" + a);
    }

    readonly property string clockFormat: {
        bumpU; rev;
        return String(Shell.uget("lockScreen.clockFormat", "12h"));
    }

    readonly property real dimOpacity: {
        bumpU; rev;
        var v = Number(Shell.uget("lockScreen.dimOpacity", 0.12));
        if (isNaN(v)) return 0.12;
        return Math.max(0.0, Math.min(0.50, v));
    }

    readonly property bool showDate: {
        bumpU; rev;
        return Shell.uget("lockScreen.showDate", true) === true;
    }

    readonly property bool showPowerButton: {
        bumpU; rev;
        return Shell.uget("lockScreen.showPowerButton", true) === true;
    }

    function resetDefaults() {
        Shell.uset("lockScreen.wallpaper", HOME_DIR + "/Pictures/Wallpapers/14-Sonoma-Light.jpg");
        Shell.uset("lockScreen.avatar", "system");
        Shell.uset("lockScreen.clockFormat", "12h");
        Shell.uset("lockScreen.showDate", true);
        Shell.uset("lockScreen.showPowerButton", true);
        Shell.uset("lockScreen.dimOpacity", 0.12);
        rev++;
    }

    function secs(v) {
        var m = { "Never": 0, "Immediately": 0, "5 seconds": 5, "1 minute": 60,
                  "2 minutes": 120, "5 minutes": 300, "10 minutes": 600,
                  "15 minutes": 900, "20 minutes": 1200, "1 hour": 3600 };
        return m[v] !== undefined ? m[v] : 0;
    }

    function backup(path) {
        if (Shell.readFile(path + ".settings-backup").length === 0) {
            var t = Shell.readFile(path);
            if (t.length > 0)
                Shell.writeFile(path + ".settings-backup", t);
        }
    }

    function applySystem() {
        backup(idlePath);
        backup(lockPath);

        var enabled = eget("lockScreen.enable", true) === true;
        var ss = enabled ? secs(String(eget("lockScreen.startAfter", "Never"))) : 0;
        var off = secs(String(eget("lockScreen.displayOffAfter", "10 minutes")));

        var L = [];
        L.push("general {");
        L.push("    lock_cmd = bash ~/.config/hypr/scripts/macos_lock.sh 'pidof hyprlock || hyprlock'");
        L.push("    before_sleep_cmd = bash ~/.config/hypr/scripts/macos_lock.sh 'loginctl lock-session'");
        L.push("    after_sleep_cmd = hyprctl dispatch dpms on");
        L.push("}");
        if (ss > 0) {
            L.push("");
            L.push("listener {");
            L.push("    timeout = " + ss);
            L.push("    on-timeout = pidof hyprlock >/dev/null || hyprlock");
            L.push("}");
        }
        if (off > 0 && off !== ss) {
            L.push("");
            L.push("listener {");
            L.push("    timeout = " + off);
            L.push("    on-timeout = hyprctl dispatch dpms off");
            L.push("    on-resume = hyprctl dispatch dpms on");
            L.push("}");
        }
        Shell.writeFile(idlePath, L.join("\n") + "\n");

        Shell.run("pkill hypridle; sleep 0.2; hypridle >/dev/null 2>&1 &");
        rev++;
    }

    Timer {
        id: idleApply
        interval: 350
        onTriggered: page.applySystem()
    }
    function scheduleApply() { idleApply.restart() }

    Timer {
        id: unlockTimer
        interval: 1400
        onTriggered: page.locking = false
    }

    // File Dialogs
    FileDialog {
        id: wallpaperDialog
        title: "Choose Lock Screen Wallpaper"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.jpg *.jpeg *.png *.webp *.bmp *.JPG *.PNG)", "All files (*)"]
        onAccepted: {
            var p = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""));
            Shell.uset("lockScreen.wallpaper", p);
            rev++;
        }
    }

    FileDialog {
        id: avatarDialog
        title: "Choose Lock Screen Avatar"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.jpg *.jpeg *.png *.webp *.bmp *.svg *.JPG *.PNG)", "All files (*)"]
        onAccepted: {
            var p = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""));
            Shell.uset("lockScreen.avatar", p);
            rev++;
        }
    }

    Placard {
        iconFile: "sb_lockscreen"
        title: "Lock Screen"
    }

    // Interactive macOS Sonoma Live Preview
    GroupCard {
        height: previewBox.height + 20

        Rectangle {
            id: previewBox
            x: 12
            y: 10
            width: parent.width - 24
            height: Math.round(width * 0.44)
            radius: 12
            clip: true
            color: Theme.dark ? "#0c0c10" : "#1b1b1f"

            // Wallpaper Image
            Image {
                anchors.fill: parent
                source: page.effectivePreviewWallpaper
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                mipmap: true
            }

            // Dark vignette overlay
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: page.dimOpacity
            }

            // Top Center Clock & Date
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 18
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(new Date(), "dddd, MMMM d")
                    visible: page.showDate
                    font { family: Theme.fontText; pixelSize: 12; weight: Font.DemiBold }
                    color: "#ffffff"
                    style: Text.Outline
                    styleColor: Qt.rgba(0, 0, 0, 0.40)
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: page.clockFormat === "24h"
                          ? Qt.formatTime(new Date(), "HH:mm")
                          : Qt.formatTime(new Date(), "h:mm")
                    font { family: Theme.fontText; pixelSize: 42; bold: true }
                    color: "#ffffff"
                    style: Text.Outline
                    styleColor: Qt.rgba(0, 0, 0, 0.35)

                    Timer {
                        interval: 1000
                        running: page.visible
                        repeat: true
                        onTriggered: parent.text = (page.clockFormat === "24h"
                            ? Qt.formatTime(new Date(), "HH:mm")
                            : Qt.formatTime(new Date(), "h:mm"))
                    }
                }
            }

            // Bottom Center Avatar & Password Pill
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                spacing: 6

                // Avatar circle
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 32
                    height: 32
                    radius: 16
                    color: Qt.rgba(255, 255, 255, 0.20)
                    border.color: Qt.rgba(255, 255, 255, 0.40)
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: page.currentAvatar
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        mipmap: true
                    }
                }

                // Password pill
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 110
                    height: 20
                    radius: 10
                    color: Qt.rgba(255, 255, 255, 0.22)
                    border.color: Qt.rgba(255, 255, 255, 0.35)
                    border.width: 0.8

                    Text {
                        anchors.centerIn: parent
                        text: "Enter Password"
                        font { family: Theme.fontText; pixelSize: 9 }
                        color: Qt.rgba(255, 255, 255, 0.70)
                    }
                }
            }

            // Bottom right power button
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                visible: page.showPowerButton
                text: "\u23FB"
                font { family: Theme.fontText; pixelSize: 12 }
                color: Qt.rgba(255, 255, 255, 0.85)
            }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Lock Screen Wallpaper" }

    GroupCard {
        DetailRow {
            title: "Wallpaper"
            subtitle: "Select preset background or match your desktop."
            pickerOptions: [
                "macOS Sonoma (Light)",
                "macOS Sonoma (Dark)",
                "macOS Sequoia",
                "MacBook Pro M3",
                "Lake Tahoe",
                "Match Desktop",
                "Custom Image"
            ]
            value: page.currentPresetName
            onPicked: (v) => {
                if (v === "Custom Image") {
                    wallpaperDialog.open();
                } else if (page.wallpaperPresets[v] !== undefined) {
                    Shell.uset("lockScreen.wallpaper", page.wallpaperPresets[v]);
                    rev++;
                }
            }
        }
        DetailRow {
            separator: true
            title: "Browse Wallpaper File..."
            subtitle: page.currentWallpaper.length > 0 ? page.currentWallpaper : "Using preset/desktop"
            chevron: true
            onClicked: wallpaperDialog.open()
        }
        DetailRow {
            separator: true
            title: "Backdrop Dimming"
            subtitle: Math.round(page.dimOpacity * 100) + "% darkening"
            isSlider: true
            sliderValue: Math.max(0, Math.min(1, page.dimOpacity / 0.50))
            onMoved: (r) => {
                var val = Math.round(r * 50) / 100;
                Shell.uset("lockScreen.dimOpacity", val);
                rev++;
            }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Avatar & User" }

    GroupCard {
        DetailRow {
            title: "Choose Custom Avatar..."
            subtitle: "Set custom picture for lock screen avatar."
            chevron: true
            onClicked: avatarDialog.open()
        }
        DetailRow {
            separator: true
            title: "Match System Profile Picture"
            subtitle: "Reset avatar to your user account picture."
            chevron: true
            onClicked: {
                Shell.uset("lockScreen.avatar", "system");
                rev++;
            }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Clock & Display" }

    GroupCard {
        DetailRow {
            title: "Clock Format"
            pickerOptions: ["12-hour", "24-hour"]
            value: page.clockFormat === "24h" ? "24-hour" : "12-hour"
            onPicked: (v) => {
                Shell.uset("lockScreen.clockFormat", v === "24-hour" ? "24h" : "12h");
                rev++;
            }
        }
        DetailRow {
            separator: true
            title: "Show date above clock"
            showSwitch: true
            switchOn: page.showDate
            onToggled: (c) => {
                Shell.uset("lockScreen.showDate", c);
                rev++;
            }
        }
        DetailRow {
            separator: true
            title: "Show power button"
            subtitle: "Displays sleep/power button in bottom right corner."
            showSwitch: true
            switchOn: page.showPowerButton
            onToggled: (c) => {
                Shell.uset("lockScreen.showPowerButton", c);
                rev++;
            }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Inactivity & Sleep" }

    GroupCard {
        DetailRow {
            title: "Start Screen Saver when inactive"
            subtitle: "Locks the screen after this amount of time."
            pickerOptions: ["Never", "1 minute", "2 minutes", "5 minutes", "10 minutes", "20 minutes", "1 hour"]
            value: String(eget("lockScreen.startAfter", "Never"))
            onPicked: (v) => { Shell.eset("lockScreen.startAfter", v); page.scheduleApply() }
        }
        DetailRow {
            separator: true
            title: "Turn display off when inactive"
            pickerOptions: ["Never", "1 minute", "2 minutes", "5 minutes", "10 minutes", "20 minutes", "1 hour"]
            value: String(eget("lockScreen.displayOffAfter", "10 minutes"))
            onPicked: (v) => { Shell.eset("lockScreen.displayOffAfter", v); page.scheduleApply() }
        }
        DetailRow {
            separator: true
            title: "Require password after screen saver begins"
            showSwitch: true
            switchOn: eget("lockScreen.requirePassword", true) === true
            onToggled: (c) => { Shell.eset("lockScreen.requirePassword", c); page.scheduleApply() }
        }
        DetailRow {
            visible: eget("lockScreen.requirePassword", true) === true
            title: "Delay"
            pickerOptions: ["Immediately", "5 seconds", "1 minute", "5 minutes", "15 minutes", "1 hour"]
            value: String(eget("lockScreen.passwordDelay", "Immediately"))
            onPicked: (v) => { Shell.eset("lockScreen.passwordDelay", v); page.scheduleApply() }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Actions" }

    GroupCard {
        DetailRow {
            title: "Lock Screen Now"
            subtitle: "Test your lock screen settings immediately."
            chevron: true
            onClicked: {
                page.locking = true;
                unlockTimer.restart();
                Shell.run("bash -c 'echo lock > /tmp/macos_cmd'");
            }
        }
        DetailRow {
            separator: true
            title: "Reset to Sonoma Defaults"
            subtitle: "Restore macOS Sonoma Light graphic, 12h clock, and defaults."
            chevron: true
            onClicked: page.resetDefaults()
        }
    }

    Item { width: 1; height: 6 }

    Component.onCompleted: scheduleApply()
}
