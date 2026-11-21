import QtQml
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 1100
    height: 900
    minimumWidth: 420
    minimumHeight: 560
    visible: true
    title: "Glowbar"
    color: Neo.background

    font.family: Neo.body
    font.pixelSize: 14
    palette.windowText: Neo.ink
    palette.text: Neo.ink

    property bool helpVisible: false
    property string colorTab: "presets"
    // Remembered separately so white (which has no hue) keeps the slider put.
    property real customHue: 0

    readonly property bool wide: width >= 920
    readonly property bool compact: main.width < 640

    // Values are tuned for the strip's LEDs rather than the screen.
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

    // A scene is a color and a brightness, applied together.
    readonly property var scenes: [
        { name: QT_TR_NOOP("Focus"), preset: 8, brightness: 100 },
        { name: QT_TR_NOOP("Relax"), preset: 9, brightness: 40 },
        { name: QT_TR_NOOP("Movie"), preset: 5, brightness: 20 },
        { name: QT_TR_NOOP("Night"), preset: 0, brightness: 10 }
    ]

    readonly property bool problem: ["noAdapter", "bluetoothOff", "notFound", "error"].indexOf(backend.state) >= 0
    readonly property bool busy: ["searching", "connecting"].indexOf(backend.state) >= 0
                                 || (backend.state === "reconnecting" && slowReconnect)
    readonly property bool connected: backend.state === "ready"
                                      || (backend.state === "reconnecting" && !slowReconnect)

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

    function percent(value) {
        return qsTr("%1%").arg(Number(value).toLocaleString(Qt.locale(), 'f', 0))
    }

    function deviceStatus() {
        if (win.connected) return qsTr("● Connected")
        switch (backend.state) {
        case "searching": return qsTr("● Searching…")
        case "connecting": return qsTr("● Connecting…")
        case "reconnecting": return qsTr("● Reconnecting…")
        default: return qsTr("● Not connected")
        }
    }

    function problemTitle() {
        switch (backend.state) {
        case "noAdapter": return qsTr("No Bluetooth adapter found.")
        case "bluetoothOff": return qsTr("Bluetooth is turned off.")
        case "notFound": return qsTr("Can't find your strip")
        default: return qsTr("Something went wrong")
        }
    }

    function sceneSelected(scene) {
        return backend.power && backend.brightness === scene.brightness
               && Qt.colorEqual(backend.color, win.presets[scene.preset].color)
    }

    // What the strip is showing, in words: a scene, a preset, or the hex value.
    function currentName() {
        for (const scene of win.scenes)
            if (win.sceneSelected(scene)) return qsTr(scene.name)
        for (const preset of win.presets)
            if (Qt.colorEqual(backend.color, preset.color)) return qsTr(preset.label)
        return win.hex(backend.color)
    }

    function hex(c) {
        return c.toString().toUpperCase()
    }

    function setHueAndSaturation(hue, saturation) {
        backend.setColor(Qt.hsva(hue / 359, saturation / 100, 1, 1))
    }

    function shiftHue(degrees) {
        const c = backend.color
        const hue = c.hsvHue < 0 ? 0 : c.hsvHue * 360
        const saturation = c.hsvSaturation > 0 ? c.hsvSaturation : 1
        backend.setColor(Qt.hsva(((hue + degrees + 360) % 360) / 360, saturation, 1, 1))
    }

    function rememberHue() {
        if (backend.color.hsvSaturation > 0.01)
            win.customHue = backend.color.hsvHue * 359
    }
    Component.onCompleted: rememberHue()
    Connections {
        target: backend
        function onLightChanged() { win.rememberHue() }
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
        font.family: Neo.mono
        font.pixelSize: 12
        font.bold: true
        font.letterSpacing: 1
        font.capitalization: Font.AllUppercase
        color: Neo.muted
    }

    component Muted: Label {
        font.pixelSize: 13
        color: Neo.muted
    }

    component Display: Label {
        font.family: Neo.display
        font.capitalization: Font.AllUppercase
        lineHeight: 0.95
    }

    component PowerIcon: Canvas {
        property color ink
        implicitWidth: 30
        implicitHeight: 30
        onInkChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.scale(width / 24, height / 24)
            ctx.strokeStyle = ink
            ctx.lineWidth = 3
            ctx.lineCap = "square"
            ctx.beginPath()
            ctx.moveTo(12, 3)
            ctx.lineTo(12, 11)
            ctx.stroke()
            ctx.beginPath()
            ctx.arc(12, 12.4, 8, -2.36, -0.78, true)
            ctx.stroke()
        }
    }

    // Right-to-left languages mirror the window; the Translator sets the
    // application's layout direction.
    Item {
        anchors.fill: parent
        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

        Flickable {
            id: flick
            anchors.fill: parent
            contentWidth: width
            contentHeight: page.implicitHeight + 64
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}

            GridLayout {
                id: page
                width: Math.min(flick.width - 56, 1200)
                x: (flick.width - width) / 2
                y: 28
                columns: win.wide ? 2 : 1
                columnSpacing: 28
                rowSpacing: 28

                // ── Sidebar: the device and scenes ──────────────────────────
                // On narrow windows it moves below the controls.
                NbCard {
                    Layout.row: win.wide ? 0 : 1
                    Layout.column: 0
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 270
                    Layout.fillWidth: !win.wide
                    padding: 20

                    ColumnLayout {
                        width: parent.width
                        spacing: 24

                        Display {
                            Layout.fillWidth: true
                            text: "Glowbar"
                            font.pixelSize: 26
                            wrapMode: Text.Wrap
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            SectionLabel { text: qsTr("Device") }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: device.implicitHeight + 20
                                color: win.problem ? Neo.red : win.connected ? Neo.green : Neo.yellow
                                border.width: 3
                                border.color: Neo.line
                                Behavior on color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    id: device
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Label {
                                            Layout.fillWidth: true
                                            text: backend.deviceName || qsTr("Your strip")
                                            elide: Text.ElideRight
                                            font.pixelSize: 15
                                            font.bold: true
                                            color: "#000000"
                                        }
                                        Label {
                                            id: deviceStatusLabel
                                            Layout.fillWidth: true
                                            text: (translator.language, win.deviceStatus())
                                            font.family: Neo.mono
                                            font.pixelSize: 12
                                            font.capitalization: Font.AllUppercase
                                            color: "#000000"
                                            SequentialAnimation on opacity {
                                                running: win.busy
                                                loops: Animation.Infinite
                                                onRunningChanged: if (!running) deviceStatusLabel.opacity = 1
                                                NumberAnimation { to: 0.35; duration: 600 }
                                                NumberAnimation { to: 1; duration: 600 }
                                            }
                                        }
                                    }
                                    Rectangle {
                                        implicitWidth: 20
                                        implicitHeight: 20
                                        color: backend.power ? backend.output : Neo.unlit
                                        border.width: 2
                                        border.color: "#000000"
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            SectionLabel { text: qsTr("Scenes") }

                            Repeater {
                                model: win.scenes
                                delegate: NbButton {
                                    id: sceneButton
                                    required property var modelData
                                    readonly property bool current: win.sceneSelected(modelData)
                                    Layout.fillWidth: true
                                    Layout.rightMargin: 4
                                    implicitHeight: 56
                                    padding: 10
                                    latched: current
                                    fill: current ? Neo.pink : Neo.card
                                    ink: current ? "#000000" : Neo.ink
                                    text: qsTr(modelData.name)
                                    onClicked: {
                                        backend.setColor(win.presets[modelData.preset].color)
                                        backend.setBrightness(modelData.brightness)
                                    }

                                    contentItem: RowLayout {
                                        spacing: 12
                                        Rectangle {
                                            implicitWidth: 30
                                            implicitHeight: 30
                                            color: win.presets[sceneButton.modelData.preset].color
                                            border.width: 2
                                            border.color: "#000000"
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0
                                            Label {
                                                Layout.fillWidth: true
                                                text: sceneButton.text
                                                font.pixelSize: 15
                                                font.bold: true
                                                color: sceneButton.ink
                                                elide: Text.ElideRight
                                            }
                                            Label {
                                                Layout.fillWidth: true
                                                text: (translator.language, qsTr("%1 · %2")
                                                       .arg(qsTr(win.presets[sceneButton.modelData.preset].label))
                                                       .arg(win.percent(sceneButton.modelData.brightness)))
                                                font.family: Neo.mono
                                                font.pixelSize: 11
                                                font.capitalization: Font.AllUppercase
                                                color: sceneButton.ink
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Main column ────────────────────────────────────────────
                ColumnLayout {
                    id: main
                    Layout.row: 0
                    Layout.column: win.wide ? 1 : 0
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true
                    spacing: 28

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Display {
                                Layout.fillWidth: true
                                text: backend.deviceName || qsTr("Your strip")
                                font.pixelSize: win.compact ? 32 : 44
                                elide: Text.ElideRight
                            }
                            Label {
                                Layout.fillWidth: true
                                text: (translator.language, backend.power
                                       ? qsTr("%1 / %2 brightness").arg(win.currentName()).arg(win.percent(backend.brightness))
                                       : qsTr("Off"))
                                font.family: Neo.mono
                                font.pixelSize: 14
                                font.capitalization: Font.AllUppercase
                                color: Neo.muted
                                wrapMode: Text.Wrap
                            }
                        }

                        AbstractButton {
                            Layout.alignment: Qt.AlignBottom
                            focusPolicy: Qt.NoFocus
                            hoverEnabled: true
                            text: qsTr("Shortcuts")
                            onClicked: win.helpVisible = true
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            contentItem: RowLayout {
                                spacing: 8
                                Kbd { text: "?" }
                                Muted { text: qsTr("Shortcuts") }
                            }
                        }
                    }

                    // ── Connection problem ──
                    NbCard {
                        visible: win.problem
                        Layout.fillWidth: true
                        Layout.rightMargin: 6
                        fill: Neo.red
                        padding: 20

                        GridLayout {
                            width: parent.width
                            columns: win.compact ? 1 : 2
                            columnSpacing: 20
                            rowSpacing: 16

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Display {
                                    Layout.fillWidth: true
                                    text: (translator.language, win.problemTitle())
                                    font.pixelSize: 18
                                    color: "#000000"
                                    wrapMode: Text.Wrap
                                }
                                Repeater {
                                    model: backend.state === "notFound" ? [
                                        QT_TR_NOOP("Check the strip is plugged in and its controller light is on."),
                                        QT_TR_NOOP("Close the strip's phone app or turn off your phone's Bluetooth: it can keep the strip busy."),
                                        QT_TR_NOOP("Keep this computer close to the strip.")
                                    ] : []
                                    delegate: RowLayout {
                                        required property string modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        spacing: 8
                                        Label {
                                            Layout.alignment: Qt.AlignTop
                                            text: (translator.language, Number(index + 1).toLocaleString(Qt.locale(), 'f', 0) + ".")
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            color: "#000000"
                                        }
                                        Label {
                                            Layout.fillWidth: true
                                            text: (translator.language, qsTr(modelData))
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            color: "#000000"
                                            wrapMode: Text.Wrap
                                        }
                                    }
                                }
                                Label {
                                    visible: backend.state === "error"
                                    Layout.fillWidth: true
                                    text: backend.error
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: "#000000"
                                    wrapMode: Text.Wrap
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: qsTr("Your changes are kept and sent as soon as it connects.")
                                    font.family: Neo.mono
                                    font.pixelSize: 12
                                    color: "#000000"
                                    wrapMode: Text.Wrap
                                }
                            }

                            NbButton {
                                Layout.alignment: Qt.AlignTop
                                implicitHeight: 48
                                leftPadding: 22
                                rightPadding: 22
                                fill: "#FFFFFF"
                                ink: "#000000"
                                line: "#000000"
                                text: qsTr("Try again")
                                onClicked: backend.connectToStrip()
                            }
                        }
                    }

                    // ── The light: preview, power and brightness ──
                    Item {
                        Layout.fillWidth: true
                        Layout.rightMargin: 6
                        Layout.topMargin: 10
                        implicitHeight: hero.implicitHeight

                        NbCard {
                            id: hero
                            width: parent.width
                            padding: 28

                            ColumnLayout {
                                width: parent.width
                                spacing: 28

                                // What the strip shows right now.
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 22 + 16 + 6
                                    color: "#000000"
                                    border.width: 3
                                    border.color: Neo.line

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 6
                                        Repeater {
                                            model: win.compact ? 12 : 20
                                            delegate: Rectangle {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                color: backend.power ? backend.output : Neo.unlit
                                                border.width: 1
                                                border.color: "#333333"
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }
                                        }
                                    }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: win.compact ? 1 : 2
                                    columnSpacing: 36
                                    rowSpacing: 24

                                    NbButton {
                                        id: powerButton
                                        Layout.alignment: Qt.AlignVCenter
                                        implicitWidth: 128
                                        implicitHeight: 128
                                        latched: backend.power
                                        fill: backend.power ? backend.color : Neo.card
                                        ink: backend.power ? Neo.textOn(backend.color) : Neo.ink
                                        text: backend.power ? qsTr("On") : qsTr("Off")
                                        Accessible.name: qsTr("Turn on or off")
                                        onClicked: backend.togglePower()

                                        contentItem: ColumnLayout {
                                            spacing: 6
                                            PowerIcon {
                                                Layout.alignment: Qt.AlignHCenter
                                                ink: powerButton.ink
                                            }
                                            Display {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: powerButton.text
                                                font.pixelSize: 22
                                                color: powerButton.ink
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        RowLayout {
                                            Layout.fillWidth: true
                                            SectionLabel { text: qsTr("Brightness"); Layout.alignment: Qt.AlignBottom; Layout.bottomMargin: 6 }
                                            Item { Layout.fillWidth: true }
                                            Display {
                                                text: (translator.language, win.percent(backend.brightness))
                                                font.pixelSize: 52
                                            }
                                        }
                                        NbSlider {
                                            Layout.fillWidth: true
                                            from: 5
                                            to: 100
                                            stepSize: 5
                                            value: backend.brightness
                                            fillColor: backend.power ? backend.color : "#888888"
                                            onMoved: backend.setBrightness(value)
                                        }
                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: 6
                                            Kbd { text: qsTr("Space") }
                                            Muted { text: qsTr("power") }
                                            Muted { text: "·"; leftPadding: 4; rightPadding: 4 }
                                            Kbd { text: "↑" }
                                            Kbd { text: "↓" }
                                            Muted { text: qsTr("brightness") }
                                        }
                                    }
                                }
                            }
                        }

                        // The sticker on the corner of the card.
                        Rectangle {
                            id: sticker
                            anchors.right: parent.right
                            anchors.rightMargin: 24
                            y: -18
                            rotation: 4
                            antialiasing: true
                            width: stickerText.implicitWidth + 28
                            height: stickerText.implicitHeight + 12
                            color: Neo.yellow
                            border.width: 3
                            border.color: "#000000"

                            Rectangle {
                                z: -1
                                x: 3
                                y: 3
                                width: parent.width
                                height: parent.height
                                color: Neo.line
                                antialiasing: true
                            }
                            Display {
                                id: stickerText
                                anchors.centerIn: parent
                                text: backend.power ? qsTr("Lights on") : qsTr("Lights off")
                                font.pixelSize: 14
                                color: "#000000"
                            }
                        }
                    }

                    // ── Color ──
                    NbCard {
                        Layout.fillWidth: true
                        Layout.rightMargin: 6

                        ColumnLayout {
                            width: parent.width
                            spacing: 20

                            GridLayout {
                                Layout.fillWidth: true
                                columns: win.compact ? 1 : 2
                                rowSpacing: 16

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    Repeater {
                                        model: [
                                            { id: "presets", label: QT_TR_NOOP("Presets") },
                                            { id: "custom", label: QT_TR_NOOP("Custom") },
                                            { id: "theme", label: QT_TR_NOOP("Theme") }
                                        ]
                                        delegate: NbButton {
                                            required property var modelData
                                            readonly property bool current: win.colorTab === modelData.id
                                            leftPadding: 18
                                            rightPadding: 18
                                            latched: current
                                            fill: current ? Neo.yellow : Neo.card
                                            ink: current ? "#000000" : Neo.ink
                                            text: (translator.language, qsTr(modelData.label))
                                            onClicked: win.colorTab = modelData.id
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                RowLayout {
                                    Layout.alignment: win.compact ? Qt.AlignLeft : Qt.AlignRight
                                    spacing: 8
                                    Rectangle {
                                        implicitWidth: 18
                                        implicitHeight: 18
                                        color: backend.color
                                        border.width: 2
                                        border.color: Neo.line
                                    }
                                    Label {
                                        text: win.hex(backend.color)
                                        font.family: Neo.mono
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }
                            }

                            GridLayout {
                                visible: win.colorTab === "presets"
                                Layout.fillWidth: true
                                columns: 5
                                rowSpacing: 14
                                columnSpacing: 14

                                Repeater {
                                    model: win.presets
                                    delegate: NbButton {
                                        id: swatch
                                        required property var modelData
                                        required property int index
                                        readonly property bool current: backend.power && Qt.colorEqual(backend.color, modelData.color)
                                        Layout.fillWidth: true
                                        Layout.rightMargin: 4
                                        implicitHeight: 60
                                        padding: 6
                                        latched: current
                                        fill: modelData.color
                                        text: (translator.language, qsTr(modelData.label))
                                        onClicked: backend.setColor(modelData.color)
                                        ToolTip.visible: hovered
                                        ToolTip.delay: 400
                                        ToolTip.text: text

                                        contentItem: Item {
                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                width: Math.max(22, key.implicitWidth + 8)
                                                height: 22
                                                color: swatch.current ? "#000000" : "#FFFFFF"
                                                border.width: 2
                                                border.color: "#000000"
                                                Label {
                                                    id: key
                                                    anchors.centerIn: parent
                                                    text: swatch.current ? "✓" : (swatch.index + 1) % 10
                                                    font.family: Neo.mono
                                                    font.pixelSize: 12
                                                    font.bold: true
                                                    color: swatch.current ? "#FFFFFF" : "#000000"
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            GridLayout {
                                visible: win.colorTab === "custom"
                                Layout.fillWidth: true
                                columns: win.compact ? 1 : 2
                                columnSpacing: 28
                                rowSpacing: 16

                                Item {
                                    implicitWidth: 104
                                    implicitHeight: 104
                                    Rectangle { x: 4; y: 4; width: 100; height: 100; color: Neo.line }
                                    Rectangle {
                                        width: 100
                                        height: 100
                                        color: backend.color
                                        border.width: 3
                                        border.color: Neo.line
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    SectionLabel { text: qsTr("Hue") }
                                    NbSlider {
                                        id: hueSlider
                                        Layout.fillWidth: true
                                        track: "hue"
                                        from: 0
                                        to: 359
                                        stepSize: 1
                                        value: win.customHue
                                        onMoved: {
                                            win.customHue = value
                                            win.setHueAndSaturation(value, Math.max(saturationSlider.value, 1))
                                        }
                                    }
                                    SectionLabel { text: qsTr("Saturation") }
                                    NbSlider {
                                        id: saturationSlider
                                        Layout.fillWidth: true
                                        track: "gradient"
                                        from: 0
                                        to: 100
                                        stepSize: 1
                                        value: Math.max(0, backend.color.hsvSaturation) * 100
                                        fromColor: "#FFFFFF"
                                        toColor: Qt.hsva(win.customHue / 359, 1, 1, 1)
                                        onMoved: win.setHueAndSaturation(win.customHue, value)
                                    }
                                }
                            }

                            Rectangle {
                                visible: win.colorTab === "theme"
                                Layout.fillWidth: true
                                implicitHeight: themeRow.implicitHeight + 36
                                color: Neo.yellow
                                border.width: 3
                                border.color: Neo.line

                                GridLayout {
                                    id: themeRow
                                    anchors.fill: parent
                                    anchors.margins: 18
                                    columns: win.compact ? 1 : 3
                                    columnSpacing: 16
                                    rowSpacing: 14

                                    Rectangle {
                                        // Re-read whenever the Omarchy theme changes.
                                        readonly property color themeColor: (theme.accent, backend.themeLightColor())
                                        implicitWidth: 44
                                        implicitHeight: 44
                                        color: themeColor
                                        border.width: 3
                                        border.color: "#000000"
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        Label {
                                            Layout.fillWidth: true
                                            text: qsTr("Match your desktop theme")
                                            font.pixelSize: 16
                                            font.bold: true
                                            color: "#000000"
                                            wrapMode: Text.Wrap
                                        }
                                        Label {
                                            Layout.fillWidth: true
                                            text: qsTr("Sets the strip to your Omarchy theme's lighting color. Press T any time.")
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            color: "#000000"
                                            wrapMode: Text.Wrap
                                        }
                                    }
                                    NbButton {
                                        implicitHeight: 48
                                        leftPadding: 20
                                        rightPadding: 20
                                        fill: "#000000"
                                        ink: Neo.yellow
                                        line: "#000000"
                                        text: qsTr("Use theme color")
                                        onClicked: backend.useThemeColor()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Keyboard shortcuts ─────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            visible: win.helpVisible
            color: Neo.dark ? "#CC000000" : "#99000000"

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => {
                    if (!help.contains(mapToItem(help, mouse.x, mouse.y)))
                        win.helpVisible = false
                }
            }

            NbCard {
                id: help
                anchors.centerIn: parent
                width: Math.min(parent.width - 48, 400)
                padding: 24

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    Display {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 4
                        text: qsTr("Keyboard shortcuts")
                        font.pixelSize: 20
                        wrapMode: Text.Wrap
                    }

                    Repeater {
                        model: [
                            [QT_TR_NOOP("Space"), QT_TR_NOOP("Turn on or off")],
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
                            Item {
                                Layout.preferredWidth: 72
                                implicitHeight: cap.implicitHeight
                                Kbd { id: cap; text: (translator.language, qsTr(modelData[0])) }
                            }
                            Label {
                                Layout.fillWidth: true
                                text: (translator.language, qsTr(modelData[1]))
                                font.pixelSize: 15
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }
    }
}
