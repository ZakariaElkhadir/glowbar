import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 460
    height: 700
    minimumWidth: 380
    minimumHeight: 640
    visible: true
    title: qsTr("LED Strip")
    color: "#0e0e10"

    Material.theme: Material.Dark
    Material.accent: theme.accent
    Material.roundedScale: theme.radius

    property bool helpVisible: false

    readonly property var presets: [
        { label: QT_TR_NOOP("Red"), color: "#ff0000" },
        { label: QT_TR_NOOP("Orange"), color: "#ff5000" },
        { label: QT_TR_NOOP("Yellow"), color: "#ffc800" },
        { label: QT_TR_NOOP("Green"), color: "#00ff00" },
        { label: QT_TR_NOOP("Cyan"), color: "#00ffff" },
        { label: QT_TR_NOOP("Blue"), color: "#0000ff" },
        { label: QT_TR_NOOP("Purple"), color: "#a000ff" },
        { label: QT_TR_NOOP("Pink"), color: "#ff2878" },
        { label: QT_TR_NOOP("White"), color: "#ffffff" },
        { label: QT_TR_NOOP("Warm"), color: "#ff9632" }
    ]

    readonly property bool problem: ["noAdapter", "bluetoothOff", "notFound", "error"].indexOf(backend.state) >= 0
    readonly property bool busy: ["searching", "connecting"].indexOf(backend.state) >= 0
                                 || (backend.state === "reconnecting" && slowReconnect)

    // The strip drops its connection every few seconds and the backend
    // re-opens it within a second, so only a reconnect that takes a while is
    // worth showing.
    property bool slowReconnect: false
    Timer {
        interval: 2500
        running: backend.state === "reconnecting"
        onRunningChanged: if (!running) win.slowReconnect = false
        onTriggered: win.slowReconnect = true
    }

    function statusText() {
        switch (backend.state) {
        case "ready": return qsTr("Connected to %1").arg(backend.deviceName)
        case "searching": return qsTr("Searching for the strip…")
        case "connecting": return qsTr("Connecting…")
        case "reconnecting": return win.slowReconnect ? qsTr("Reconnecting…") : qsTr("Connected to %1").arg(backend.deviceName)
        case "noAdapter": return qsTr("No Bluetooth adapter found.")
        case "bluetoothOff": return qsTr("Bluetooth is turned off.")
        case "notFound": return qsTr("Strip not found. Make sure it's plugged in and your phone's Bluetooth is off.")
        default: return backend.error
        }
    }

    // Dark text on light colors, white on dark ones.
    function textOn(c) {
        return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) > 0.6 ? "#111111" : "#ffffff"
    }

    function shiftHue(degrees) {
        const c = backend.color
        const hue = c.hsvHue < 0 ? 0 : c.hsvHue * 360
        const saturation = c.hsvSaturation > 0 ? c.hsvSaturation : 1
        backend.setColor(Qt.hsva(((hue + degrees + 360) % 360) / 360, saturation, 1, 1))
    }

    Shortcut { sequence: "?"; context: Qt.ApplicationShortcut; onActivated: win.helpVisible = !win.helpVisible }
    Shortcut { sequence: "Esc"; context: Qt.ApplicationShortcut; enabled: win.helpVisible; onActivated: win.helpVisible = false }
    Shortcut { sequence: "Q"; context: Qt.ApplicationShortcut; onActivated: Qt.quit() }
    Shortcut { sequence: "Space"; context: Qt.ApplicationShortcut; onActivated: backend.togglePower() }
    Shortcut { sequence: "T"; context: Qt.ApplicationShortcut; onActivated: backend.useThemeColor() }
    Shortcut { sequence: "R"; context: Qt.ApplicationShortcut; onActivated: backend.connectToStrip() }
    Shortcut { sequences: ["Up", "+", "="]; context: Qt.ApplicationShortcut; onActivated: backend.setBrightness(backend.brightness + 10) }
    Shortcut { sequences: ["Down", "-"]; context: Qt.ApplicationShortcut; onActivated: backend.setBrightness(backend.brightness - 10) }
    Shortcut { sequence: "Right"; context: Qt.ApplicationShortcut; onActivated: win.shiftHue(15) }
    Shortcut { sequence: "Left"; context: Qt.ApplicationShortcut; onActivated: win.shiftHue(-15) }

    // 1 to 9 and 0 pick the presets in order.
    Instantiator {
        model: win.presets.length
        delegate: Shortcut {
            required property int index
            sequence: String((index + 1) % 10)
            context: Qt.ApplicationShortcut
            onActivated: backend.setColor(win.presets[index].color)
        }
    }

    component SectionLabel: Label {
        font.pixelSize: 12
        font.letterSpacing: 1
        font.capitalization: Font.AllUppercase
        color: "#8a8a92"
    }

    // Right-to-left languages mirror the window; the Translator sets the
    // application's layout direction.
    Item {
        anchors.fill: parent
        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

        ColumnLayout {
            width: Math.min(parent.width - 48, 440)
            anchors.centerIn: parent
            spacing: 16

            Label {
                text: qsTr("LED Strip")
                font.pixelSize: 26
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    id: statusDot
                    Layout.alignment: Qt.AlignVCenter
                    width: 10
                    height: 10
                    radius: 5
                    color: win.problem ? "#ef5350" : win.busy ? "#ffb74d" : theme.accent
                    SequentialAnimation on opacity {
                        running: win.busy
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) statusDot.opacity = 1
                        NumberAnimation { to: 0.3; duration: 600 }
                        NumberAnimation { to: 1; duration: 600 }
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: (translator.language, win.statusText())
                    wrapMode: Text.Wrap
                    font.pixelSize: 13
                    color: win.problem ? "#ef9a9a" : "#b0b0b8"
                }
                Button {
                    visible: win.problem
                    text: qsTr("Retry")
                    flat: true
                    focusPolicy: Qt.NoFocus
                    onClicked: backend.connectToStrip()
                }
            }

            // The light itself: shows what the strip shows, and switches it.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                radius: theme.radius
                color: backend.power ? backend.output : "#18181b"
                border.color: "#2a2a2e"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: backend.power ? qsTr("On") : qsTr("Off")
                        font.pixelSize: 30
                        font.bold: true
                        color: backend.power ? win.textOn(backend.output) : "#77777f"
                    }
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: backend.power ? qsTr("Click or press Space to turn off") : qsTr("Click or press Space to turn on")
                        font.pixelSize: 12
                        opacity: 0.75
                        color: backend.power ? win.textOn(backend.output) : "#77777f"
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.togglePower()
                }
            }

            SectionLabel { text: qsTr("Presets") }

            GridLayout {
                Layout.fillWidth: true
                columns: 5
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: win.presets
                    delegate: Rectangle {
                        id: swatch
                        required property var modelData
                        required property int index
                        readonly property bool current: backend.power && Qt.colorEqual(backend.color, modelData.color)
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: Math.min(4, theme.radius)
                        color: modelData.color
                        border.width: current ? 3 : 0
                        border.color: "#ffffff"

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            visible: swatch.current
                            color: "transparent"
                            border.color: "#0e0e10"
                            border.width: 2
                            radius: Math.min(3, theme.radius)
                        }
                        Label {
                            anchors.centerIn: parent
                            text: (swatch.index + 1) % 10
                            font.pixelSize: 12
                            opacity: 0.7
                            color: win.textOn(swatch.color)
                        }
                        MouseArea {
                            id: swatchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.setColor(swatch.modelData.color)
                        }
                        ToolTip.visible: swatchMouse.containsMouse
                        ToolTip.delay: 400
                        ToolTip.text: qsTr(swatch.modelData.label)
                    }
                }
            }

            Button {
                id: themeButton
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                focusPolicy: Qt.NoFocus
                text: qsTr("Use theme color")
                onClicked: backend.useThemeColor()
                contentItem: Label {
                    text: themeButton.text
                    font.bold: true
                    color: theme.accentForeground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: Math.min(4, theme.radius)
                    color: themeButton.down ? Qt.darker(theme.accent, 1.25)
                         : themeButton.hovered ? Qt.lighter(theme.accent, 1.1) : theme.accent
                }
            }

            SectionLabel { text: qsTr("Color") }

            Slider {
                id: hue
                Layout.fillWidth: true
                focusPolicy: Qt.NoFocus
                from: 0
                to: 359
                stepSize: 1
                value: backend.color.hsvHue < 0 ? 0 : backend.color.hsvHue * 359
                onMoved: backend.setColor(Qt.hsva(value / 359, 1, 1, 1))
                background: Rectangle {
                    x: hue.leftPadding
                    y: hue.topPadding + hue.availableHeight / 2 - height / 2
                    width: hue.availableWidth
                    height: 10
                    radius: 5
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.000; color: "#ff0000" }
                        GradientStop { position: 0.167; color: "#ffff00" }
                        GradientStop { position: 0.333; color: "#00ff00" }
                        GradientStop { position: 0.500; color: "#00ffff" }
                        GradientStop { position: 0.667; color: "#0000ff" }
                        GradientStop { position: 0.833; color: "#ff00ff" }
                        GradientStop { position: 1.000; color: "#ff0000" }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                SectionLabel { text: qsTr("Brightness") }
                Item { Layout.fillWidth: true }
                Label {
                    text: (translator.language, qsTr("%1%").arg(Number(backend.brightness).toLocaleString(Qt.locale(), 'f', 0)))
                    color: "#b0b0b8"
                }
            }

            Slider {
                Layout.fillWidth: true
                focusPolicy: Qt.NoFocus
                from: 5
                to: 100
                stepSize: 5
                value: backend.brightness
                onMoved: backend.setBrightness(value)
            }

            Label {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                text: qsTr("Press ? for keyboard shortcuts")
                font.pixelSize: 12
                color: "#66666e"
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: win.helpVisible
            color: "#cc000000"

            MouseArea {
                anchors.fill: parent
                onClicked: win.helpVisible = false
            }

            Pane {
                anchors.centerIn: parent
                width: Math.min(parent.width - 48, 380)
                padding: 20
                background: Rectangle {
                    color: "#18181b"
                    radius: theme.radius
                    border.color: "#2a2a2e"
                    border.width: 1
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    Label {
                        text: qsTr("Keyboard shortcuts")
                        font.pixelSize: 16
                        font.bold: true
                        Layout.bottomMargin: 4
                    }

                    Repeater {
                        model: [
                            ["Space", QT_TR_NOOP("Turn on or off")],
                            ["1 – 0", QT_TR_NOOP("Color presets")],
                            ["← →", QT_TR_NOOP("Change color")],
                            ["↑ ↓", QT_TR_NOOP("Brightness")],
                            ["T", QT_TR_NOOP("Use theme color")],
                            ["R", QT_TR_NOOP("Search for the strip again")],
                            ["?", QT_TR_NOOP("Show or hide this help")],
                            ["Q", QT_TR_NOOP("Quit")]
                        ]
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 12
                            Label {
                                Layout.preferredWidth: 64
                                text: modelData[0]
                                font.family: "monospace"
                                color: theme.accent
                            }
                            Label {
                                Layout.fillWidth: true
                                text: (translator.language, qsTr(modelData[1]))
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }
    }
}
