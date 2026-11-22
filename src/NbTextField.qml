import QtQuick
import QtQuick.Controls.Basic

// A boxy text field. The hard shadow turns yellow while typing and red when
// the text is invalid.
TextField {
    id: control

    property bool invalid: false

    implicitHeight: 48
    leftPadding: 14
    rightPadding: 14
    font.family: Neo.mono
    font.pixelSize: 16
    font.bold: true
    color: Neo.ink
    placeholderTextColor: Neo.muted
    selectionColor: Neo.yellow
    selectedTextColor: "#000000"
    selectByMouse: true

    background: Item {
        Rectangle {
            x: 4
            y: 4
            width: parent.width
            height: parent.height
            color: control.invalid ? Neo.red : control.activeFocus ? Neo.yellow : Neo.line
        }
        Rectangle {
            anchors.fill: parent
            color: Neo.card
            border.width: 3
            border.color: control.invalid ? Neo.red : Neo.line
        }
    }
}
