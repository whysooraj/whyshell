import QtQuick
import QtQuick.Controls
import ".."

Column {
    id: page

    property string pageId: "acct.sshKeys"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    property var keys: []

    width: parent ? parent.width : 700
    spacing: 12

    function refresh() {
        var sshDir = HOME_DIR + "/.ssh"
        var fileList = Shell.listFiles(sshDir, "*.pub")
        var list = []
        for (var i = 0; i < fileList.length; i++) {
            var f = fileList[i]
            var content = Shell.readFile(f).trim()
            var parts = content.split(/\s+/)
            var filename = f.split("/").pop()
            var keyType = parts.length > 0 ? parts[0] : "ssh-key"
            var comment = parts.length > 2 ? parts[2] : ""
            var fpOut = Shell.execOut("ssh-keygen -lf '" + f + "' 2>/dev/null", 1000).trim()
            var fp = fpOut.length > 0 ? fpOut : content.substring(0, 32) + "…"

            list.push({
                path: f,
                filename: filename,
                type: keyType,
                comment: comment,
                fingerprint: fp,
                content: content
            })
        }
        keys = list
    }

    Component.onCompleted: refresh()

    Placard {
        iconFile: "dt_passkey"
        title: "SSH Keys"
        subtitle: "Manage cryptographic public keys stored in ~/.ssh for remote servers and Git."
    }

    SectionHeader {
        text: "Configured Public Keys"
    }

    GroupCard {
        DetailRow {
            visible: page.keys.length === 0
            title: "No Public Keys"
            subtitle: "No .pub keys found in ~/.ssh"
            dimmed: true
        }

        Repeater {
            model: page.keys

            delegate: Column {
                id: keyBlock
                required property var modelData
                required property int index
                width: parent.width

                DetailRow {
                    separator: keyBlock.index > 0
                    title: keyBlock.modelData.filename
                    subtitle: keyBlock.modelData.type + (keyBlock.modelData.comment.length > 0 ? (" • " + keyBlock.modelData.comment) : "")
                    value: keyBlock.modelData.type
                }

                DetailRow {
                    separator: true
                    title: "Fingerprint"
                    subtitle: keyBlock.modelData.fingerprint
                    dimmed: true
                }

                DetailRow {
                    separator: true
                    title: "Copy Public Key"
                    subtitle: "Copy to clipboard for GitHub, GitLab, or server authorized_keys"
                    chevron: true
                    onClicked: {
                        Shell.run("wl-copy < '" + keyBlock.modelData.path + "' 2>/dev/null || xclip -selection clipboard < '" + keyBlock.modelData.path + "'")
                        Shell.run("notify-send 'SSH Keys' 'Public key " + keyBlock.modelData.filename + " copied to clipboard'")
                    }
                }
            }
        }
    }

    SectionHeader {
        text: "Key Operations"
    }

    GroupCard {
        DetailRow {
            title: "Generate New SSH Key…"
            subtitle: "Generate an Ed25519 keypair (ssh-keygen -t ed25519) in terminal"
            chevron: true
            onClicked: {
                Shell.run("kitty --title 'Generate SSH Key' -e sh -c 'ssh-keygen -t ed25519; echo \"\"; echo \"Press Enter to close...\"; read -r'")
                refreshTimer.restart()
            }
        }

        DetailRow {
            separator: true
            title: "Open ~/.ssh in File Manager"
            subtitle: "Open directory to inspect keys and known_hosts"
            chevron: true
            onClicked: {
                Shell.run("xdg-open '" + HOME_DIR + "/.ssh'")
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 1000
        repeat: false
        onTriggered: page.refresh()
    }

    Text {
        x: 28
        width: parent.width - 56
        wrapMode: Text.WordWrap
        text: "Public keys (~/.ssh/*.pub) are safe to share and authorize your machine across GitHub, GitLab, and SSH servers."
        font { family: Theme.fontText; pixelSize: 12 }
        color: Theme.textSecondary
    }
}
