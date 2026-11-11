import QtQuick
import QtQuick.Controls
import ".."

Column {
    id: page

    property string pageId: "gen.softwareUpdate"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    property bool checking: true
    property int updateCount: 0
    property string kernelVer: ""
    property string osVer: ""

    width: parent ? parent.width : 700
    spacing: 12

    function refresh() {
        checking = true
        checkTimer.restart()
    }

    Timer {
        id: checkTimer
        interval: 100
        repeat: false
        onTriggered: {
            page.kernelVer = Shell.execOut("uname -r", 1000).trim()
            page.osVer = Shell.execOut("sed -n 's/^PRETTY_NAME=//p' /etc/os-release | tr -d '\"'", 1000).trim()
            var cntStr = Shell.execOut("checkupdates 2>/dev/null | wc -l", 6000).trim()
            var cnt = parseInt(cntStr)
            if (isNaN(cnt)) {
                cntStr = Shell.execOut("pacman -Qu 2>/dev/null | wc -l", 3000).trim()
                cnt = parseInt(cntStr)
            }
            page.updateCount = isNaN(cnt) ? 0 : cnt
            page.checking = false
        }
    }

    Component.onCompleted: refresh()

    Placard {
        iconFile: "dt_software-update"
        title: "Software Update"
        subtitle: "Check and install system packages, security patches, and kernel updates."
    }

    GroupCard {
        // Status Row
        DetailRow {
            visible: page.checking
            title: "Checking for updates…"
            subtitle: "Querying package repositories"
            dimmed: true
        }

        DetailRow {
            visible: !page.checking && page.updateCount > 0
            title: page.updateCount + (page.updateCount === 1 ? " Update Available" : " Updates Available")
            subtitle: "Kernel " + page.kernelVer + " • Ready to install"
            value: page.updateCount + " pkgs"
        }

        DetailRow {
            visible: !page.checking && page.updateCount > 0
            separator: true
            title: "Update Now"
            subtitle: "Launch terminal to run full system upgrade (paru / yay / pacman)"
            chevron: true
            onClicked: {
                Shell.run("kitty -e sh -c 'paru || yay || sudo pacman -Syu'")
            }
        }

        DetailRow {
            visible: !page.checking && page.updateCount === 0
            title: "Your system is up to date"
            subtitle: (page.osVer.length > 0 ? page.osVer : "Linux") + " • Kernel " + page.kernelVer
            value: "Up to date"
        }

        DetailRow {
            separator: true
            title: "Check Again"
            subtitle: "Query package mirrors for latest versions"
            chevron: true
            onClicked: page.refresh()
        }
    }

    SectionHeader {
        text: "System Information"
    }

    GroupCard {
        DetailRow {
            title: "Kernel Version"
            subtitle: "Currently running Linux kernel"
            value: page.kernelVer.length > 0 ? page.kernelVer : Shell.execOut("uname -r", 500).trim()
        }
        DetailRow {
            separator: true
            title: "Operating System"
            subtitle: "Distribution release"
            value: page.osVer.length > 0 ? page.osVer : Shell.execOut("sed -n 's/^PRETTY_NAME=//p' /etc/os-release | tr -d '\"'", 500).trim()
        }
        DetailRow {
            separator: true
            title: "Package Manager"
            subtitle: "Default AUR / Pacman helper"
            value: Shell.execOut("which paru yay pacman 2>/dev/null | head -1 | xargs basename", 500).trim()
        }
    }

    Text {
        x: 28
        width: parent.width - 56
        wrapMode: Text.WordWrap
        text: "Updates ensure your system has the latest security fixes, package features, and kernel drivers."
        font { family: Theme.fontText; pixelSize: 12 }
        color: Theme.textSecondary
    }
}
