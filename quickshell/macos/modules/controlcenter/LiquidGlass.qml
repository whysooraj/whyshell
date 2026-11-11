import QtQuick
import QtQuick.Effects

Item {
    id: root

    property real radius: 28
    property color glassColor: Qt.rgba(1, 1, 1, 0.015) // Subtle glass background
    property color strokeHighlight: Qt.rgba(1, 1, 1, 0.25) // Top glass highlight
    property color strokeShadow: Qt.rgba(0, 0, 0, 0.2)     // Bottom refraction shadow

    default property alias content: containerLayout.children

    // 1. Primary glass body
    Rectangle {
        id: glassBody
        anchors.fill: parent
        radius: root.radius
        color: root.glassColor
        opacity: 0.9

        // 2. Backdrop blur effect
        MultiEffect {
            anchors.fill: parent
            source: glassBody
            blurEnabled: true
            blur: 0.15
            blurMax: 12
        }

        // 3. Glow and refraction border (Liquid Stroke & Inset Shadows)
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)

            // Inner gradient for 3D curvature
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"

                gradient: Gradient {
                    orientation: Gradient.TopLeftToBottomRight
                    GradientStop { position: 0.0; color: root.strokeHighlight }
                    GradientStop { position: 0.5; color: "transparent" }
                    GradientStop { position: 1.0; color: root.strokeShadow }
                }
            }
        }

        // Inner items container
        Item {
            id: containerLayout
            anchors.fill: parent
            anchors.margins: 12
        }
    }
}
