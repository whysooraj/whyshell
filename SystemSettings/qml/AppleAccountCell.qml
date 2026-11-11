import QtQuick
import QtQuick.Window

Item {
    id: cell

    property bool signedIn: true
    property string accountName: ""
    property string accountSub: ""
    property bool selected: false
    readonly property bool highlighted: selected && cell.Window.window && cell.Window.window.active

    signal clicked

    width: parent ? parent.width : 200
    height: 48

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        radius: 8
        color: cell.selected ? (cell.highlighted ? Theme.accent : Theme.selectedBg) : "transparent"
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 16
        spacing: 10

        Avatar {
            size: 34
            avatarPath: { var m = Shell.userCfg; return String(Shell.uget("avatarPath", "")) }
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: cell.accountName.length > 0 ? cell.accountName : "User"
                font.family: Theme.fontText
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: cell.highlighted ? "white" : Theme.textPrimary
                width: 150
                elide: Text.ElideRight
            }

            Text {
                text: cell.accountSub.length > 0 ? cell.accountSub : "Local Account"
                font.family: Theme.fontText
                font.pixelSize: 11
                color: cell.highlighted ? Qt.rgba(1, 1, 1, 0.85) : Theme.textSecondary
                width: 150
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: cell.clicked()
    }
}
