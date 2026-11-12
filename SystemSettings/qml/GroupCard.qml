import QtQuick

Rectangle {
    id: card

    default property alias rows: rowCol.data

    x: 12
    width: parent ? parent.width - 24 : 400
    radius: 10
    color: Theme.cardBg
    border.width: 1
    border.color: Theme.hairline
    clip: true

    implicitHeight: rowCol.implicitHeight

    Column {
        id: rowCol
        width: parent.width
    }
}
