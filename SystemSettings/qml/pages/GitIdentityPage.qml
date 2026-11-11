import QtQuick
import QtQuick.Controls
import ".."

Column {
    id: page

    property string pageId: "acct.gitIdentity"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    property string gitName: ""
    property string gitEmail: ""
    property string gitBranch: ""
    property string gitGpgSign: ""

    width: parent ? parent.width : 700
    spacing: 12

    function refresh() {
        gitName = Shell.execOut("git config user.name", 500).trim()
        gitEmail = Shell.execOut("git config user.email", 500).trim()
        gitBranch = Shell.execOut("git config init.defaultBranch", 500).trim()
        if (gitBranch.length === 0)
            gitBranch = "main"
        gitGpgSign = Shell.execOut("git config commit.gpgsign", 500).trim()
    }

    Component.onCompleted: refresh()

    Placard {
        iconFile: "dt_personal-info"
        title: "Git Identity"
        subtitle: "Global author name and email used for Git commits and repository contributions."
    }

    SectionHeader {
        text: "Global Author Identity"
    }

    GroupCard {
        DetailRow {
            title: "Author Name (user.name)"
            subtitle: "Name embedded into commit metadata"
            value: page.gitName.length > 0 ? page.gitName : "Not configured"
        }

        DetailRow {
            separator: true
            title: "Author Email (user.email)"
            subtitle: "Email linked to commit author and GitHub profile"
            value: page.gitEmail.length > 0 ? page.gitEmail : "Not configured"
        }

        DetailRow {
            separator: true
            title: "Default Initial Branch"
            subtitle: "Default branch name for 'git init'"
            value: page.gitBranch
        }

        DetailRow {
            separator: true
            title: "Commit Signing"
            subtitle: "GPG / SSH cryptographic signature verification"
            value: page.gitGpgSign === "true" ? "Enabled" : "Disabled"
        }
    }

    SectionHeader {
        text: "Configuration Actions"
    }

    GroupCard {
        DetailRow {
            title: "Configure Git Identity in Terminal…"
            subtitle: "Interactive prompt to set global user.name and user.email"
            chevron: true
            onClicked: {
                Shell.run("kitty --title 'Configure Git Identity' -e sh -c 'echo \"=== Git Global Identity ===\"; git config --list --show-origin | grep -E \"user\\.\"; echo \"\"; read -p \"New user.name (press Enter to keep \\\"" + page.gitName + "\\\"): \" n; [ -n \"$n\" ] && git config --global user.name \"$n\"; read -p \"New user.email (press Enter to keep \\\"" + page.gitEmail + "\\\"): \" e; [ -n \"$e\" ] && git config --global user.email \"$e\"; echo \"\"; echo \"Saved:\"; git config user.name; git config user.email; sleep 1'")
                refreshTimer.restart()
            }
        }

        DetailRow {
            separator: true
            title: "View All Git Configuration…"
            subtitle: "Display origin and values for system, global, and local configs"
            chevron: true
            onClicked: {
                Shell.run("kitty --title 'Git Config' -e sh -c 'git config --list --show-origin; echo \"\"; echo \"Press Enter to close...\"; read -r'")
            }
        }

        DetailRow {
            separator: true
            title: "Open ~/.gitconfig"
            subtitle: "Edit global git configuration file directly"
            chevron: true
            onClicked: {
                Shell.run("xdg-open '" + HOME_DIR + "/.gitconfig'")
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
        text: "Git configurations are saved to ~/.gitconfig and used by all local Git operations and GUI clients."
        font { family: Theme.fontText; pixelSize: 12 }
        color: Theme.textSecondary
    }
}
