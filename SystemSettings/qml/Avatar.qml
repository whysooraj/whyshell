import QtQuick

Item {
    id: root

    property int size: 84
    property string avatarPath: ""
    property bool editable: false

    signal editClicked

    property bool loadFailed: false
    readonly property string effectiveAvatar: {
        if (!loadFailed && avatarPath && avatarPath.length > 0) return avatarPath;
        var face = (typeof HOME_DIR !== "undefined" ? HOME_DIR : "") + "/.face";
        return face;
    }

    readonly property bool customReady: effectiveAvatar.length > 0 && customImg.status === Image.Ready

    width: size
    height: size

    Rectangle {
        id: disc
        anchors.centerIn: parent
        width: root.size
        height: root.size
        radius: width / 2
        color: Theme.dark ? "#3a3a3c" : "#e9e9eb"
        clip: true
        visible: root.customReady

        Image {
            id: customImg
            anchors.fill: parent
            source: root.effectiveAvatar.length > 0 ? "file://" + root.effectiveAvatar : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            sourceSize.width: root.size * 2
            sourceSize.height: root.size * 2
            onStatusChanged: {
                if (status === Image.Error && root.avatarPath.length > 0 && !root.loadFailed) {
                    root.loadFailed = true;
                }
            }
        }
    }

    Image {
        id: fallback
        anchors.centerIn: parent
        width: root.size
        height: root.size
        source: Theme.icon("sb_signin", root.size)
        fillMode: Image.PreserveAspectFit
        visible: !root.customReady
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: root.editable
        cursorShape: root.editable ? Qt.PointingHandCursor : Qt.ArrowCursor
        visible: root.editable
        onClicked: root.editClicked()
    }

    Rectangle {
        id: overlay
        anchors.centerIn: parent
        width: root.size
        height: root.size
        radius: width / 2
        color: Qt.rgba(0, 0, 0, 0.45)
        visible: root.editable && ma.containsMouse

        Column {
            anchors.centerIn: parent
            spacing: 1

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "\u270E"
                font.pixelSize: Math.max(14, Math.round(root.size * 0.30))
                color: "#ffffff"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Edit"
                font { family: Theme.fontText; pixelSize: Math.max(9, Math.round(root.size * 0.17)) }
                color: "#ffffff"
                visible: root.size >= 56
            }
        }
    }
}
