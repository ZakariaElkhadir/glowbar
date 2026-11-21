pragma Singleton
import QtQuick

// Neobrutalist palette. Light and dark follow the Omarchy theme's mode.
QtObject {
    readonly property bool dark: theme.dark

    readonly property color background: dark ? "#161616" : "#FFF4E0"
    readonly property color card: dark ? "#232323" : "#FFFFFF"
    readonly property color ink: dark ? "#F2F2F2" : "#000000"
    // Borders and hard shadows.
    readonly property color line: ink
    readonly property color muted: dark ? "#C4C4C4" : "#3D3D3D"
    readonly property color subtle: dark ? "#3A3A3A" : "#F3E6CC"

    // Bright fills always carry black ink, in both modes.
    readonly property color yellow: "#FFD23F"
    readonly property color pink: "#FF6B9D"
    readonly property color green: "#7CF29C"
    readonly property color red: "#FF6B6B"
    readonly property color unlit: "#2A2A2A"

    readonly property string display: "Archivo Black"
    readonly property string body: "Space Grotesk"
    readonly property string mono: "Space Mono"

    // Black text on light colors, white on dark ones (WCAG luminance).
    function textOn(c) {
        const linear = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
        const luminance = 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b)
        return luminance > 0.18 ? "#000000" : "#FFFFFF"
    }
}
