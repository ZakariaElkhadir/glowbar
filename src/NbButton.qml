import QtQuick
import QtQuick.Controls.Basic

// A raised neobrutalist button: thick border and a hard offset shadow. It
// lifts on hover and sinks into its shadow while pressed or latched.
AbstractButton {
    id: control

    property color fill: Neo.card
    property color ink: Neo.ink
    property color line: Neo.line
    // Stays sunk, for selected items and toggles that are on.
    property bool latched: false
    property int depth: 4

    readonly property real lift: down || latched ? depth : hovered ? -2 : 0

    focusPolicy: Qt.NoFocus
    hoverEnabled: true
    padding: 12
    font.family: Neo.body
    font.pixelSize: 15
    font.weight: Font.Bold

    implicitWidth: Math.max(44, implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(44, implicitContentHeight + topPadding + bottomPadding)

    transform: Translate {
        id: shift
        x: control.lift
        y: control.lift
        Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
        Behavior on y { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }

    contentItem: Text {
        text: control.text
        font: control.font
        color: control.ink
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Item {
        // The shadow stays put while the face moves over it.
        Rectangle {
            x: control.depth - shift.x
            y: control.depth - shift.y
            width: parent.width
            height: parent.height
            color: control.line
        }
        Rectangle {
            anchors.fill: parent
            color: control.fill
            border.width: 3
            border.color: control.line
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }
}
