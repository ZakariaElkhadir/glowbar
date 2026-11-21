import QtQuick
import QtQuick.Controls.Basic

// A boxy slider. The track is either filled up to the handle ("fill"), a hue
// rainbow ("hue"), or a gradient between two colors ("gradient").
Slider {
    id: control

    property string track: "fill"
    property color fillColor: Neo.yellow
    property color fromColor: "#FFFFFF"
    property color toColor: "#FF0000"

    focusPolicy: Qt.NoFocus
    implicitHeight: 48

    HoverHandler { cursorShape: Qt.PointingHandCursor }

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.availableWidth
        height: 24
        color: Neo.subtle
        border.width: 3
        border.color: Neo.line

        Rectangle {
            visible: control.track === "fill"
            readonly property real span: parent.width - 6
            x: control.mirrored ? 3 + span - width : 3
            y: 3
            width: span * control.position
            height: parent.height - 6
            color: control.fillColor
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Rectangle {
            visible: control.track !== "fill"
            x: 3
            y: 3
            width: parent.width - 6
            height: parent.height - 6
            // Values run right to left when the layout is mirrored.
            transform: Scale { xScale: control.mirrored ? -1 : 1; origin.x: (control.availableWidth - 6) / 2 }
            gradient: control.track === "hue" ? hueGradient : twoColorGradient

            Gradient {
                id: hueGradient
                orientation: Gradient.Horizontal
                GradientStop { position: 0.000; color: "#ff0000" }
                GradientStop { position: 0.167; color: "#ffff00" }
                GradientStop { position: 0.333; color: "#00ff00" }
                GradientStop { position: 0.500; color: "#00ffff" }
                GradientStop { position: 0.667; color: "#0000ff" }
                GradientStop { position: 0.833; color: "#ff00ff" }
                GradientStop { position: 1.000; color: "#ff0000" }
            }
            Gradient {
                id: twoColorGradient
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: control.fromColor }
                GradientStop { position: 1; color: control.toColor }
            }
        }
    }

    handle: Item {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 22
        implicitHeight: 36

        Rectangle {
            x: 3
            y: 3
            width: parent.width
            height: parent.height
            color: Neo.line
        }
        Rectangle {
            anchors.fill: parent
            color: control.pressed ? Neo.yellow : Neo.card
            border.width: 3
            border.color: Neo.line
        }
    }
}
