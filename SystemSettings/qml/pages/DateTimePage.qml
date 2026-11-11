import QtQuick
import QtQuick.Controls
import ".."

Column {
    id: page

    property string pageId: "gen.dateAndTime"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    property int rev: 0

    property bool autoNtp: false
    property string timeZone: ""
    property bool clock24h: false
    property string nowFormatted: ""

    readonly property var commonTimezones: [
        "Asia/Kolkata",
        "UTC",
        "America/New_York",
        "America/Chicago",
        "America/Denver",
        "America/Los_Angeles",
        "Europe/London",
        "Europe/Paris",
        "Europe/Berlin",
        "Asia/Dubai",
        "Asia/Singapore",
        "Asia/Tokyo",
        "Australia/Sydney"
    ]

    property var tzOptions: []

    width: parent ? parent.width : 700
    spacing: 12

    function refresh() {
        bumpU
        var ntpVal = Shell.execOut("timedatectl show -p NTP --value", 1000).trim()
        autoNtp = (ntpVal === "yes")

        var tz = Shell.execOut("timedatectl show -p Timezone --value", 1000).trim()
        if (tz.length === 0)
            tz = "UTC"
        timeZone = tz

        var opts = commonTimezones.slice()
        if (opts.indexOf(tz) < 0)
            opts.unshift(tz)
        tzOptions = opts

        clock24h = Shell.uget("clock24h", false) === true
        updateTime()
    }

    function updateTime() {
        var d = new Date()
        nowFormatted = Qt.formatDateTime(d, clock24h ? "dddd, MMMM d, yyyy  HH:mm:ss" : "dddd, MMMM d, yyyy  h:mm:ss AP")
    }

    Timer {
        id: liveClock
        interval: 1000
        running: true
        repeat: true
        onTriggered: page.updateTime()
    }

    Component.onCompleted: refresh()

    Placard {
        iconFile: "dt_date-and-time"
        title: "Date & Time"
        subtitle: "Set the system clock, time zone, and time display preferences."
    }

    GroupCard {
        DetailRow {
            title: "Set date and time automatically"
            subtitle: "Synchronize system time with network time servers (NTP)"
            showSwitch: true
            switchOn: page.autoNtp
            onToggled: (checked) => {
                page.autoNtp = checked
                Shell.run("timedatectl set-ntp " + (checked ? "true" : "false"))
                page.rev++
            }
        }

        DetailRow {
            separator: true
            title: "Current Time"
            subtitle: "System clock reading"
            value: page.nowFormatted
        }
    }

    SectionHeader {
        text: "Time Zone"
    }

    GroupCard {
        DetailRow {
            title: "Time Zone"
            subtitle: "Local region and daylight saving rule"
            value: page.timeZone
            pickerOptions: page.tzOptions
            onPicked: (val) => {
                if (val && val !== page.timeZone) {
                    page.timeZone = val
                    Shell.run("timedatectl set-timezone '" + val + "'")
                    page.refresh()
                }
            }
        }
    }

    SectionHeader {
        text: "Clock Format"
    }

    GroupCard {
        DetailRow {
            title: "24-Hour Time"
            subtitle: "Display time using a 24-hour military clock (e.g. 14:00 vs 2:00 PM)"
            showSwitch: true
            switchOn: page.clock24h
            onToggled: (checked) => {
                page.clock24h = checked
                Shell.uset("clock24h", checked)
                page.updateTime()
                page.rev++
            }
        }
    }

    Text {
        x: 28
        width: parent.width - 56
        wrapMode: Text.WordWrap
        text: "Date & time configurations are backed by systemd-timedated and synced with Desktop and Status Bar clocks."
        font { family: Theme.fontText; pixelSize: 12 }
        color: Theme.textSecondary
    }
}
