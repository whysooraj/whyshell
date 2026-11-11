import QtQuick
import QtQuick.Controls
import ".."

Column {
    id: page

    property string pageId: "gen.loginItems"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    property var items: []
    property string newName: ""
    property string newExec: ""

    width: parent ? parent.width : 700
    spacing: 12

    function parseDesktop(path, content) {
        var lines = content.split("\n")
        var name = ""
        var exec = ""
        var hidden = false
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.indexOf("Name=") === 0 && name.length === 0)
                name = line.substring(5).trim()
            else if (line.indexOf("Exec=") === 0 && exec.length === 0)
                exec = line.substring(5).trim()
            else if (line.indexOf("Hidden=true") === 0 || line.indexOf("X-GNOME-Autostart-enabled=false") === 0)
                hidden = true
        }
        if (name.length === 0) {
            var parts = path.split("/")
            name = parts[parts.length - 1].replace(".desktop", "")
        }
        return {
            path: path,
            name: name,
            exec: exec,
            enabled: !hidden
        }
    }

    function refresh() {
        var autostartDir = HOME_DIR + "/.config/autostart"
        Shell.run("mkdir -p '" + autostartDir + "'")
        var fileList = Shell.listFiles(autostartDir, "*.desktop")
        var list = []
        for (var i = 0; i < fileList.length; i++) {
            var f = fileList[i]
            var content = Shell.readFile(f)
            if (content && content.length > 0)
                list.push(parseDesktop(f, content))
        }
        items = list
    }

    function setEnabled(item, enabled) {
        var c = Shell.readFile(item.path)
        if (!c || c.length === 0) return
        var lines = c.split("\n")
        var hasHidden = false
        var hasAutostart = false
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].indexOf("Hidden=") === 0) {
                lines[i] = "Hidden=" + (enabled ? "false" : "true")
                hasHidden = true
            } else if (lines[i].indexOf("X-GNOME-Autostart-enabled=") === 0) {
                lines[i] = "X-GNOME-Autostart-enabled=" + (enabled ? "true" : "false")
                hasAutostart = true
            }
        }
        if (!hasHidden)
            lines.push("Hidden=" + (enabled ? "false" : "true"))
        if (!hasAutostart)
            lines.push("X-GNOME-Autostart-enabled=" + (enabled ? "true" : "false"))
        Shell.writeFile(item.path, lines.join("\n"))
        refresh()
    }

    function removeItem(item) {
        Shell.run("rm -f '" + item.path + "'")
        refreshTimer.restart()
    }

    function addCustom() {
        if (!newName || !newExec) return
        var autostartDir = HOME_DIR + "/.config/autostart"
        var slug = newName.toLowerCase().replace(/[^a-z0-9_-]/g, "_") + ".desktop"
        var filePath = autostartDir + "/" + slug
        var content = "[Desktop Entry]\nType=Application\nName=" + newName + "\nExec=" + newExec + "\nHidden=false\nX-GNOME-Autostart-enabled=true\n"
        Shell.writeFile(filePath, content)
        newName = ""
        newExec = ""
        nameInput.text = ""
        execInput.text = ""
        refreshTimer.restart()
    }

    Timer {
        id: refreshTimer
        interval: 150
        repeat: false
        onTriggered: page.refresh()
    }

    Component.onCompleted: refresh()

    Placard {
        iconFile: "dt_login-items"
        title: "Login Items"
        subtitle: "Applications and helper tools that open automatically when you log in."
    }

    SectionHeader {
        text: "Open at Login"
    }

    GroupCard {
        // Empty state
        DetailRow {
            visible: page.items.length === 0
            title: "No Login Items"
            subtitle: "No autostart applications found in ~/.config/autostart"
            dimmed: true
        }

        Repeater {
            model: page.items

            delegate: Item {
                id: itemRow
                required property var modelData
                required property int index

                width: parent ? parent.width : 400
                height: 54

                Rectangle {
                    visible: itemRow.index > 0
                    anchors.top: parent.top
                    x: 16
                    width: parent.width - 32
                    height: 1
                    color: Theme.separator
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 180
                    spacing: 2

                    Text {
                        text: itemRow.modelData.name
                        font.family: Theme.fontText
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: itemRow.modelData.exec.length > 0 ? itemRow.modelData.exec : itemRow.modelData.path
                        font.family: Theme.fontText
                        font.pixelSize: 11
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    MacToggle {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: itemRow.modelData.enabled
                        onToggled: (checked) => page.setEnabled(itemRow.modelData, checked)
                    }

                    MacButton {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Remove"
                        onClicked: page.removeItem(itemRow.modelData)
                    }
                }
            }
        }
    }

    SectionHeader {
        text: "Add Custom Login Item"
    }

    GroupCard {
        Item {
            width: parent.width
            height: 48

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "Application Name"
                font.family: Theme.fontText
                font.pixelSize: 13
                color: Theme.textPrimary
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: 240
                height: 26
                radius: 6
                color: Theme.checkBg
                border.width: 1
                border.color: Theme.checkBorder

                TextInput {
                    id: nameInput
                    anchors.fill: parent
                    anchors.margins: 4
                    anchors.leftMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.fontText
                    font.pixelSize: 12
                    color: Theme.textPrimary
                    selectByMouse: true
                    onTextChanged: page.newName = text.trim()

                    Text {
                        visible: !nameInput.text && !nameInput.activeFocus
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "e.g. Discord"
                        font.family: Theme.fontText
                        font.pixelSize: 12
                        color: Theme.placeholder
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 48

            Rectangle {
                anchors.top: parent.top
                x: 16
                width: parent.width - 32
                height: 1
                color: Theme.separator
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "Command / Exec"
                font.family: Theme.fontText
                font.pixelSize: 13
                color: Theme.textPrimary
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: 240
                height: 26
                radius: 6
                color: Theme.checkBg
                border.width: 1
                border.color: Theme.checkBorder

                TextInput {
                    id: execInput
                    anchors.fill: parent
                    anchors.margins: 4
                    anchors.leftMargin: 8
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.fontText
                    font.pixelSize: 12
                    color: Theme.textPrimary
                    selectByMouse: true
                    onTextChanged: page.newExec = text.trim()

                    Text {
                        visible: !execInput.text && !execInput.activeFocus
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "e.g. discord --start-minimized"
                        font.family: Theme.fontText
                        font.pixelSize: 12
                        color: Theme.placeholder
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 44

            Rectangle {
                anchors.top: parent.top
                x: 16
                width: parent.width - 32
                height: 1
                color: Theme.separator
            }

            MacButton {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "Add Entry"
                primary: true
                btnEnabled: page.newName.length > 0 && page.newExec.length > 0
                onClicked: page.addCustom()
            }
        }
    }

    Text {
        x: 28
        width: parent.width - 56
        wrapMode: Text.WordWrap
        text: "Autostart entries conform to the XDG Autostart desktop specification in ~/.config/autostart."
        font { family: Theme.fontText; pixelSize: 12 }
        color: Theme.textSecondary
    }
}
