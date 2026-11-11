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
        apps: []
    })

    function refresh() {
        try {
            var raw = Shell.execOut("revo-screentime summary", 1200).trim()
            if (raw.length > 0 && raw.charAt(0) === "{") {
                summary = JSON.parse(raw)
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

    // Daily Summary Card with Hourly Bar Chart
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
                            width: 130
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
                                text: appRow.modelData.category || "General"
                                font.family: Theme.fontText
                                font.pixelSize: 11
                                color: Theme.textSecondary
                            }
                        }

                        // Progress bar representation
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 220
                            height: 6
                            radius: 3
                            color: Qt.rgba(1, 1, 1, 0.1)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.max(4, parent.width * ((appRow.modelData.percent || 1) / 100))
                                radius: 3
                                color: {
                                    var cat = appRow.modelData.category
                                    if (cat === "Browsing") return "#34C759"
                                    if (cat === "Developer") return "#0A84FF"
                                    if (cat === "Entertainment") return "#FF375F"
                                    if (cat === "Social") return "#FF9F0A"
                                    return "#BF5AF2"
                                }
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
        text: "Options"
    }

    GroupCard {
        DetailRow {
            title: "Clear Today's History"
            subtitle: "Reset active window usage stats for today"
            dimmed: false
            titleColor: Theme.red
            onClicked: {
                Shell.run("rm -f ~/.local/share/screentime/daily.json")
                page.refresh()
            }
        }
    }

    Item {
        width: 1
        height: 12
    }
}
