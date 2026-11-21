import QtQuick
import QtQuick.Controls.Basic

// A flat neobrutalist panel with a thick border and hard shadow.
Pane {
    id: card

    property color fill: Neo.card
    property color line: Neo.line
    property int depth: 6

    padding: 24

    background: Item {
        Rectangle {
            x: card.depth
            y: card.depth
            width: parent.width
            height: parent.height
            color: card.line
        }
        Rectangle {
            anchors.fill: parent
            color: card.fill
            border.width: 3
            border.color: card.line
        }
    }
}
