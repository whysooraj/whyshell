import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../Pages.js" as Pages

Column {
    id: page

    property string pageId: "gemini"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var meta: Pages.info[pageId] || ({ title: "Gemini Intelligence", icon: "sb_apple-intelligence" })

    width: parent ? parent.width : 700
    spacing: 12

    property string selectedModel: {
        var m = Shell.uget("gemini.model", "gemini-flash-latest")
        return m.length > 0 ? m : "gemini-flash-latest"
    }

    property string lastPrompt: ""
    property string lastResponse: ""
    property bool querying: false
    property string statusText: "Ready"

    function askGemini(prompt) {
        if (!prompt || prompt.trim().length === 0) return
        querying = true
        statusText = "Thinking…"
        lastPrompt = prompt
        lastResponse = ""

        // Escape prompt for shell argument
        var safePrompt = prompt.replace(/'/g, "'\\''")
        var cmd = "revo-gemini-query '" + safePrompt + "' " + selectedModel
        
        // Execute detached or via Shell.execOut with timer
        queryTimer.command = cmd
        queryTimer.start()
    }

    Timer {
        id: queryTimer
        interval: 100
        repeat: false
        property string command: ""
        onTriggered: {
            try {
                var out = Shell.execOut(command, 15000).trim()
                if (out.length > 0 && out.charAt(0) === "{") {
                    var data = JSON.parse(out)
                    if (data.response) {
                        page.lastResponse = data.response
                        page.statusText = "Completed"
                    } else if (data.error) {
                        page.lastResponse = "Error: " + data.error
                        page.statusText = "Failed"
                    }
                } else {
                    page.lastResponse = out.length > 0 ? out : "No response returned"
                    page.statusText = "Completed"
                }
            } catch (e) {
                page.lastResponse = "Execution error: " + e
                page.statusText = "Error"
            }
            page.querying = false
        }
    }

    Placard {
        iconFile: page.meta.icon
        title: page.meta.title
        subtitle: "On-device and cloud AI capabilities powered by Google Gemini."
    }

    GroupCard {
        DetailRow {
            title: "Gemini Intelligence"
            subtitle: "Enable AI assistant features across the desktop"
            showSwitch: true
            switchOn: Shell.uget("gemini.enabled", true)
            onToggled: (checked) => Shell.uset("gemini.enabled", checked)
        }
        DetailRow {
            separator: true
            title: "Model"
            subtitle: "Select the Gemini generative model"
            value: page.selectedModel
            pickerOptions: ["gemini-flash-latest", "gemini-flash-lite-latest", "gemini-pro-latest"]
            onPicked: (v) => {
                page.selectedModel = v
                Shell.uset("gemini.model", v)
            }
        }
        DetailRow {
            separator: true
            title: "API Key"
            subtitle: "Loaded securely from ~/.env"
            value: "Configured"
            dimmed: true
        }
    }

    SectionHeader {
        text: "Interactive Prompt"
    }

    GroupCard {
        Column {
            width: parent.width
            padding: 14
            spacing: 12

            RowLayout {
                width: parent.width - 28
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.2)
                    border.color: promptInput.activeFocus ? Theme.accent : Theme.separator
                    border.width: 1

                    TextInput {
                        id: promptInput
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontText
                        font.pixelSize: 13
                        color: Theme.textPrimary
                        clip: true

                        Text {
                            visible: !promptInput.text && !promptInput.activeFocus
                            text: "Ask Gemini anything…"
                            font.family: Theme.fontText
                            font.pixelSize: 13
                            color: Theme.placeholder
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Keys.onReturnPressed: {
                            page.askGemini(promptInput.text)
                            promptInput.text = ""
                        }
                    }
                }

                MacButton {
                    text: page.querying ? "Thinking…" : "Ask"
                    primary: true
                    btnEnabled: !page.querying
                    onClicked: {
                        page.askGemini(promptInput.text)
                        promptInput.text = ""
                    }
                }
            }

            // Response Box
            Rectangle {
                visible: page.lastResponse.length > 0 || page.querying
                width: parent.width - 28
                implicitHeight: respText.implicitHeight + 20
                radius: 8
                color: Qt.rgba(0, 0, 0, 0.15)
                border.color: Theme.separator
                border.width: 1

                Text {
                    id: respText
                    anchors.fill: parent
                    anchors.margins: 10
                    wrapMode: Text.WordWrap
                    text: page.querying ? "Waiting for Gemini response…" : page.lastResponse
                    font.family: Theme.fontText
                    font.pixelSize: 12
                    color: page.querying ? Theme.textSecondary : Theme.textPrimary
                }
            }
        }
    }

    SectionHeader {
        text: "Desktop Integration"
    }

    GroupCard {
        DetailRow {
            title: "Quick Chat Terminal"
            subtitle: "Launch full interactive AI terminal session"
            chevron: true
            onClicked: Shell.run("kitty --title 'Gemini AI' -e python3 -q")
        }
        DetailRow {
            separator: true
            title: "Environment Configuration"
            subtitle: "Edit API keys and tokens in ~/.env"
            chevron: true
            onClicked: Shell.run("kitty --title 'Environment Keys' -e nvim ~/.env")
        }
    }

    Item {
        width: 1
        height: 12
    }
}
