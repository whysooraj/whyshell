import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings
import "Pages.js" as Pages
import "PagesContent.js" as Content

ApplicationWindow {
    id: root

    width: 715
    height: 700
    visible: true
    title: "System Settings"
    color: Theme.windowBg

    property string selectedId: "general"
    property bool hasBattery: true

    // --test-pages: cycle through every page and print QML errors, then exit
    readonly property bool testMode: Qt.application.arguments.join(" ").indexOf("--test-pages") >= 0
    property var testList: []
    property int testIdx: 0

    Component.onCompleted: {
        if (!testMode) {
            var args = Qt.application.arguments
            for (var a = 1; a < args.length; a++) {
                var arg = args[a]
                if (arg.indexOf("--page=") === 0) {
                    root.selectedId = arg.substring(7)
                    return
                }
                if (arg === "shortcuts") {
                    root.selectedId = "keyboard.shortcuts"
                    return
                }
                if (Pages.info[arg] || Content.content[arg]) {
                    root.selectedId = arg
                    return
                }
            }
            return
        }
        var all = Pages.roots.slice()
        for (var k in Content.content)
            if (all.indexOf(k) < 0)
                all.push(k)
        testList = all
        testTimer.start()
    }

    Timer {
        id: testTimer
        interval: 650
        repeat: true
        onTriggered: {
            if (root.testIdx >= root.testList.length) {
                console.log("TEST_PAGES_DONE", root.testList.length)
                Qt.quit()
                return
            }
            var id = root.testList[root.testIdx++]
            console.log("TEST_PAGE_BEGIN", id)
            root.selectedId = id
        }
    }

    readonly property string systemUser: (typeof Shell !== "undefined" && Shell) ? Shell.execOut("whoami", 500).trim() : "User"
    readonly property string systemHost: (typeof Shell !== "undefined" && Shell) ? Shell.execOut("hostname", 500).trim() : "Linux"

    Settings {
        id: accountStore
        category: "account"
        property string email: root.systemUser + "@" + root.systemHost
        property string name: root.systemUser
    }

    font.family: Theme.fontText
    font.pixelSize: 13


    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 0

        Sidebar {
            id: sidebar
            Layout.preferredWidth: Theme.sidebarWidth
            Layout.fillHeight: true
            selectedId: root.selectedId
            hasBattery: root.hasBattery
            signedIn: true
            accountName: accountStore.name.length > 0 ? accountStore.name : root.systemUser
            accountSub: accountStore.email.length > 0 ? accountStore.email : (root.systemUser + "@" + root.systemHost)
            onSelect: (id) => root.selectedId = id
            onSignIn: root.selectedId = "appleId"
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: Theme.hairline
        }

        DetailPane {
            id: detailPane
            Layout.fillWidth: true
            Layout.fillHeight: true
            selectedId: root.selectedId
            accountName: accountStore.name
            accountEmail: accountStore.email
            onSignedIn: (email, name) => {
                accountStore.email = email
                accountStore.name = name
            }
            onSignedOut: {
                accountStore.email = ""
                accountStore.name = ""
            }
        }
    }

    // macOS traffic lights
    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 13
        anchors.topMargin: 9
        spacing: 8

        Repeater {
            model: [
                { c: "#FF5F57", ring: "#E14640" },
                { c: "#FEBC2E", ring: "#DF9F1F" },
                { c: "#28C840", ring: "#1DAD33" }
            ]

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: 12
                height: 12
                radius: 6
                color: modelData.c
                border.color: modelData.ring
                border.width: 0.5

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (index === 0)
                            Qt.quit()
                    }
                }
            }
        }
    }
}
