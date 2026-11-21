import QtQuick

// A key cap for keyboard hints.
Item {
    property alias text: label.text

    implicitWidth: face.width + 2
    implicitHeight: face.height + 2

    Rectangle {
        x: 2
        y: 2
        width: face.width
        height: face.height
        color: Neo.line
    }
    Rectangle {
        id: face
        width: Math.max(height, label.implicitWidth + 12)
        height: label.implicitHeight + 4
        color: Neo.card
        border.width: 2
        border.color: Neo.line

        Text {
            id: label
            anchors.centerIn: parent
            font.family: Neo.mono
            font.pixelSize: 12
            font.bold: true
            color: Neo.ink
        }
    }
}
