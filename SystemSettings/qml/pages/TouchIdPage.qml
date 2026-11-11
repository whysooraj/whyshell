import QtQuick
import QtQuick.Controls
import ".."

Column {
    id: page

    property string pageId: "touchIDPassword"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property string currentUser: (typeof Shell !== "undefined" && Shell) ? Shell.execOut("id -un", 500).trim() : "user"

    property bool hasDevice: false
    property string deviceName: "Fingerprint Reader"
    property string enrolledStatus: "Checking…"
    property var enrolledFingers: []

    width: parent ? parent.width : 700
    spacing: 12

    function refresh() {
        var u = currentUser
        var out = Shell.execOut("fprintd-list " + u + " 2>&1", 3000)
        var devFound = out.indexOf("found 1 devices") >= 0 || out.indexOf("Device at") >= 0 || (out.indexOf("found") >= 0 && out.indexOf("found 0 devices") < 0)
        hasDevice = devFound

        if (!devFound) {
            deviceName = "Fingerprint Sensor"
            enrolledStatus = "No fingerprint reader hardware detected"
            enrolledFingers = []
            return
        }

        // Extract device name if present
        var m = out.match(/(?:for|on)\s+([^.\n]+)/i)
        if (m && m[1]) {
            deviceName = m[1].trim()
        } else {
            deviceName = "Biometric Sensor"
        }

        if (out.indexOf("no fingers enrolled") >= 0) {
            enrolledStatus = "No fingers enrolled"
            enrolledFingers = []
        } else {
            var lines = out.split("\n")
            var fingers = []
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (line.indexOf("- #") === 0) {
                    var parts = line.split(":")
                    if (parts.length > 1)
                        fingers.push(parts[1].trim())
                }
            }
            enrolledFingers = fingers
            enrolledStatus = fingers.length > 0 ? (fingers.length + " enrolled (" + fingers.join(", ") + ")") : "Ready"
        }
    }

    Component.onCompleted: refresh()

    Placard {
        iconFile: "sb_touch-id"
        title: "Touch ID & Password"
        subtitle: "Use fingerprint reader or UNIX password to log in and authorize administration."
    }

    SectionHeader {
        text: "Biometrics (Fingerprint)"
    }

    GroupCard {
        DetailRow {
            title: page.deviceName
            subtitle: page.enrolledStatus
            value: page.hasDevice ? "Detected" : "Unavailable"
        }

        DetailRow {
            visible: page.hasDevice
            separator: true
            title: "Add Fingerprint…"
            subtitle: "Enroll a new fingerprint using fprintd in terminal"
            chevron: true
            onClicked: {
                Shell.run("kitty --title 'Enroll Fingerprint' -e fprintd-enroll " + page.currentUser)
            }
        }
    }

    SectionHeader {
        text: "Password"
    }

    GroupCard {
        DetailRow {
            title: "Change Password…"
            subtitle: "Change UNIX login password for " + page.currentUser
            chevron: true
            onClicked: {
                Shell.run("kitty --title 'Change Password' -e passwd")
            }
        }
    }

    SectionHeader {
        text: "Authentication Options"
    }

    GroupCard {
        DetailRow {
            title: "Use Fingerprint for PAM authentication"
            subtitle: "Allow sudo and login authentication via fprintd"
            showSwitch: true
            switchOn: Shell.uget("auth.useFingerprint", true) === true
            onToggled: (checked) => Shell.uset("auth.useFingerprint", checked)
        }

        DetailRow {
            separator: true
            title: "Require password after sleep"
            subtitle: "Lock screen and demand credentials immediately upon wake"
            showSwitch: true
            switchOn: Shell.uget("lockScreen.requirePassword", true) === true
            onToggled: (checked) => Shell.uset("lockScreen.requirePassword", checked)
        }
    }

    Text {
        x: 28
        width: parent.width - 56
        wrapMode: Text.WordWrap
        text: "Touch ID hardware interacts directly with fprintd daemon and PAM module (pam_fprintd.so) for hardware-level authentication."
        font { family: Theme.fontText; pixelSize: 12 }
        color: Theme.textSecondary
    }
}
