import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../Pages.js" as Pages

Column {
    id: page

    property string pageId: "screenTime"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var meta: Pages.info[pageId] || ({ title: "Screen Time", icon: "sb_screen-time" })

    width: parent ? parent.width : 700
    spacing: 12

    property var summary: ({
        date: "",
        total_seconds: 0,
        total_formatted: "0m",
        hourly: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
        categories: [],
        limits: {},
        apps: []
    })

    property var appLimitsList: []

    readonly property var limitPresets: [
        { label: "1 min", seconds: 60 },
        { label: "2 min", seconds: 120 },
        { label: "5 min", seconds: 300 },
        { label: "15 min", seconds: 900 },
        { label: "30 min", seconds: 1800 },
        { label: "1 hour", seconds: 3600 },
        { label: "2 hours", seconds: 7200 },
        { label: "3 hours", seconds: 10800 }
    ]

    readonly property var pickerDurations: [
        "1 min",
        "2 min",
        "5 min",
        "15 min",
        "30 min",
        "1 hour",
        "2 hours",
        "3 hours"
    ]

    function labelForLimit(secs) {
        if (!secs || secs <= 0) return "Off"
        for (var i = 0; i < limitPresets.length; i++) {
            if (limitPresets[i].seconds === secs) return limitPresets[i].label
        }
        if (secs >= 3600) {
            var h = Math.floor(secs / 3600)
            var m = Math.floor((secs % 3600) / 60)
            return m > 0 ? (h + "h " + m + "m") : (h + " hour" + (h > 1 ? "s" : ""))
        }
        if (secs >= 60) {
            return Math.floor(secs / 60) + " min"
        }
        return secs + "s"
    }

    function secondsForLabel(label) {
        for (var i = 0; i < limitPresets.length; i++) {
            if (limitPresets[i].label === label) return limitPresets[i].seconds
        }
        return 3600
    }

    function categoryColor(cat) {
        if (cat === "Development") return "#0A84FF"
        if (cat === "Browsing") return "#34C759"
        if (cat === "Communication") return "#FF9F0A"
        if (cat === "Media") return "#FF375F"
        if (cat === "Gaming") return "#AF52DE"
        if (cat === "Productivity") return "#5E5CE6"
        return "#8E8E93"
    }

    function setAppLimit(appKey, seconds) {
        Shell.execOut("revo-screentime set-limit \"" + appKey + "\" " + seconds)
        page.refresh()
    }

    function removeAppLimit(appKey) {
        Shell.execOut("revo-screentime remove-limit \"" + appKey + "\"")
        page.refresh()
    }

    function updateAppLimitsList() {
        var list = []
        var seen = {}
        var curLimits = page.summary.limits || {}

        // 1. Configured limits from limits.json
        for (var lk in curLimits) {
            var lval = curLimits[lk]
            var low = lk.toLowerCase()
            seen[low] = true
            var displayName = lk
            if (lk === "dev.zed.Zed") displayName = "Zed"
            else if (lk === "google-chrome") displayName = "Google Chrome"
            else if (lk.indexOf(".") >= 0) displayName = lk.split(".").pop()

            list.push({
                appKey: lk,
                appName: displayName,
                limitSeconds: parseInt(lval) || 0,
                category: "Configured Limit"
            })
        }

        // 2. Tracked apps from summary.apps
        if (page.summary.apps) {
            for (var i = 0; i < page.summary.apps.length; i++) {
                var app = page.summary.apps[i]
                var appCls = app["class"] || app.id || ""
                var lowCls = appCls.toLowerCase()
                var existing = null
                for (var j = 0; j < list.length; j++) {
                    if (list[j].appKey.toLowerCase() === lowCls || list[j].appKey.toLowerCase() === app.id.toLowerCase()) {
                        existing = list[j]
                        break
                    }
                }
                if (existing) {
                    existing.appName = app.name || existing.appName
                    existing.category = app.category || existing.category
                } else {
                    seen[lowCls] = true
                    list.push({
                        appKey: appCls,
                        appName: app.name || appCls,
                        limitSeconds: app.limit || 0,
                        category: app.category || "General"
                    })
                }
            }
        }

        // 3. Recommended apps
        var defaults = [
            { key: "dev.zed.Zed", name: "Zed", cat: "Development" },
            { key: "google-chrome", name: "Google Chrome", cat: "Browsing" },
            { key: "kitty", name: "Kitty", cat: "Development" },
            { key: "zen", name: "Zen Browser", cat: "Browsing" },
            { key: "org.telegram.desktop", name: "Telegram", cat: "Communication" },
            { key: "discord", name: "Discord", cat: "Communication" },
            { key: "spotify", name: "Spotify", cat: "Media" },
            { key: "md.obsidian.obsidian", name: "Obsidian", cat: "Productivity" },
            { key: "steam", name: "Steam", cat: "Gaming" }
        ]
        for (var k = 0; k < defaults.length; k++) {
            var def = defaults[k]
            if (!seen[def.key.toLowerCase()]) {
                seen[def.key.toLowerCase()] = true
                list.push({
                    appKey: def.key,
                    appName: def.name,
                    limitSeconds: 0,
                    category: def.cat
                })
            }
        }

        page.appLimitsList = list
    }

    function refresh() {
        try {
            var raw = Shell.execOut("revo-screentime summary", 1200).trim()
            if (raw.length > 0 && raw.charAt(0) === "{") {
                summary = JSON.parse(raw)
                updateAppLimitsList()
            }
        } catch (e) {
            console.log("SCREENTIME_PARSE_ERROR", e)
        }
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: page.refresh()
    }

    Placard {
        iconFile: page.meta.icon
        title: page.meta.title
        subtitle: "See how much time you spend using apps and websites."
    }

    // Daily Summary Card with Hourly Bar Chart and Category Breakdown
    GroupCard {
        Column {
            width: parent.width
            padding: 16
            spacing: 14

            Row {
                width: parent.width - 32
                spacing: 12

                Column {
                    spacing: 2
                    Text {
                        text: "Daily Average"
                        font.family: Theme.fontText
                        font.pixelSize: 12
                        color: Theme.textSecondary
                    }
                    Text {
                        text: page.summary.total_formatted || "0m"
                        font.family: Theme.fontDisplay
                        font.pixelSize: 28
                        font.weight: Font.Bold
                        color: Theme.textPrimary
                    }
                }
            }

            // 24-hour visual bar chart
            Rectangle {
                width: parent.width - 32
                height: 90
                color: Qt.rgba(0, 0, 0, 0.15)
                radius: 8

                Row {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: Math.max(2, (width - (24 * 6)) / 23)

                    Repeater {
                        model: 24

                        delegate: Item {
                            required property int index
                            width: 6
                            height: parent.height

                            readonly property real maxSec: {
                                var m = 60
                                for (var i = 0; i < page.summary.hourly.length; i++) {
                                    if (page.summary.hourly[i] > m) m = page.summary.hourly[i]
                                }
                                return m
                            }
                            readonly property real barHeight: {
                                var val = (page.summary.hourly && page.summary.hourly[index]) ? page.summary.hourly[index] : 0
                                return Math.max(3, (val / maxSec) * (height - 14))
                            }

                            Rectangle {
                                anchors.bottom: hourLabel.top
                                anchors.bottomMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 5
                                height: barHeight
                                radius: 2.5
                                color: (page.summary.hourly && page.summary.hourly[index] > 0) ? Theme.accent : Qt.rgba(1, 1, 1, 0.1)
                            }

                            Text {
                                id: hourLabel
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                visible: index % 6 === 0
                                text: index === 0 ? "12A" : (index === 6 ? "6A" : (index === 12 ? "12P" : (index === 18 ? "6P" : "")))
                                font.family: Theme.fontText
                                font.pixelSize: 8
                                color: Theme.textSecondary
                            }
                        }
                    }
                }
            }

            // Category colored segmented bar
            Column {
                width: parent.width - 32
                spacing: 8
                visible: page.summary.total_seconds > 0

                Text {
                    text: "Usage by Category"
                    font.family: Theme.fontText
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: Theme.textSecondary
                }

                Rectangle {
                    width: parent.width
                    height: 12
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.2)
                    clip: true

                    Row {
                        anchors.fill: parent
                        spacing: 1

                        Repeater {
                            model: page.summary.categories || []

                            delegate: Rectangle {
                                required property var modelData
                                width: {
                                    if (!page.summary.total_seconds || page.summary.total_seconds <= 0) return 0
                                    var segW = (modelData.seconds / page.summary.total_seconds) * parent.width
                                    return Math.max(0, segW)
                                }
                                height: parent.height
                                color: modelData.color || Theme.accent
                                visible: width > 0.5
                            }
                        }
                    }
                }

                // Category breakdown list
                Flow {
                    width: parent.width
                    spacing: 12

                    Repeater {
                        model: (page.summary.categories || []).filter(function(c) { return c.seconds > 0 })

                        delegate: Row {
                            required property var modelData
                            spacing: 6

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8
                                height: 8
                                radius: 4
                                color: modelData.color || Theme.accent
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.name + " (" + modelData.formatted + " • " + modelData.percent + "%)"
                                font.family: Theme.fontText
                                font.pixelSize: 11
                                color: Theme.textSecondary
                            }
                        }
                    }
                }
            }
        }
    }

    SectionHeader {
        text: "Most Used Apps"
        visible: page.summary.apps && page.summary.apps.length > 0
    }

    GroupCard {
        visible: page.summary.apps && page.summary.apps.length > 0

        Repeater {
            model: page.summary.apps

            delegate: Column {
                id: appRow
                required property var modelData
                required property int index
                width: parent.width

                Item {
                    width: parent.width
                    height: 44

                    Rectangle {
                        visible: appRow.index > 0
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.right: parent.right
                        height: 1
                        color: Theme.separator
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        spacing: 12

                        Column {
                            width: 140
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: appRow.modelData.name || "App"
                                font.family: Theme.fontText
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                color: Theme.textPrimary
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: {
                                    var txt = appRow.modelData.category || "General"
                                    if (appRow.modelData.limit_formatted) {
                                        txt += " • Limit: " + appRow.modelData.limit_formatted
                                    }
                                    return txt
                                }
                                font.family: Theme.fontText
                                font.pixelSize: 11
                                color: Theme.textSecondary
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Progress bar representation
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 230
                            height: 6
                            radius: 3
                            color: Qt.rgba(1, 1, 1, 0.1)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.max(4, parent.width * ((appRow.modelData.percent || 1) / 100))
                                radius: 3
                                color: page.categoryColor(appRow.modelData.category)
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: appRow.modelData.formatted || "0s"
                            font.family: Theme.fontText
                            font.pixelSize: 13
                            color: Theme.textPrimary
                            width: 50
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
    }

    SectionHeader {
        text: "App Limits"
    }

    GroupCard {
        Column {
            width: parent.width

            Repeater {
                model: page.appLimitsList

                delegate: Column {
                    id: limitItem
                    required property var modelData
                    required property int index
                    width: parent.width

                    Item {
                        width: parent.width
                        height: 48

                        Rectangle {
                            visible: limitItem.index > 0
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.right: parent.right
                            height: 1
                            color: Theme.separator
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            spacing: 12

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 230
                                spacing: 2

                                Text {
                                    text: limitItem.modelData.appName
                                    font.family: Theme.fontText
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                    color: Theme.textPrimary
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: limitItem.modelData.limitSeconds > 0
                                        ? ("Daily Limit: " + page.labelForLimit(limitItem.modelData.limitSeconds))
                                        : (limitItem.modelData.category + " • No limit")
                                    font.family: Theme.fontText
                                    font.pixelSize: 11
                                    color: limitItem.modelData.limitSeconds > 0 ? Theme.accent : Theme.textSecondary
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                spacing: 8

                                MacPicker {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: limitItem.modelData.limitSeconds > 0
                                    options: page.pickerDurations
                                    value: page.labelForLimit(limitItem.modelData.limitSeconds)
                                    pill: true
                                    onAccepted: (v) => {
                                        var s = page.secondsForLabel(v)
                                        page.setAppLimit(limitItem.modelData.appKey, s)
                                    }
                                }

                                MacToggle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    checked: limitItem.modelData.limitSeconds > 0
                                    onToggled: (isChecked) => {
                                        if (isChecked) {
                                            page.setAppLimit(limitItem.modelData.appKey, 3600)
                                        } else {
                                            page.removeAppLimit(limitItem.modelData.appKey)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    SectionHeader {
        text: "Options"
    }

    GroupCard {
        DetailRow {
            title: "Clear Today's History"
            subtitle: "Reset active window usage stats for today"
            dimmed: false
            titleColor: Theme.red
            onClicked: {
                Shell.execOut("revo-screentime clear")
                Shell.run("rm -f ~/.local/share/revo-screentime/data.json ~/.local/share/screentime/daily.json")
                page.refresh()
            }
        }
    }

    Item {
        width: 1
        height: 12
    }
}
