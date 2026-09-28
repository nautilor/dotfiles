import Quickshell
import QtQuick
import Quickshell.Services.UPower

Item {
    id: root

    // ─────────────────────────────────────────────
    // Battery
    // ─────────────────────────────────────────────

    readonly property var battery:
        UPower.displayDevice

    // ─────────────────────────────────────────────
    // State
    // ─────────────────────────────────────────────

    readonly property real percentage:
        root.battery?.percentage ?? 0

    readonly property bool charging:
        root.battery?.state === UPowerDeviceState.Charging

    readonly property bool fullyCharged:
        root.battery?.state === UPowerDeviceState.FullyCharged

    readonly property bool pluggedIn:
        root.battery?.state === UPowerDeviceState.Charging
        || root.battery?.state === UPowerDeviceState.FullyCharged

    // ─────────────────────────────────────────────
    // Battery icon
    // ─────────────────────────────────────────────

    readonly property string batteryIcon: {
        if (root.charging)
            return "󰂄"

        if (root.percentage >= 0.9)
            return "󰁹"

        if (root.percentage >= 0.8)
            return "󰂂"

        if (root.percentage >= 0.7)
            return "󰂁"

        if (root.percentage >= 0.6)
            return "󰂀"

        if (root.percentage >= 0.5)
            return "󰁿"

        if (root.percentage >= 0.4)
            return "󰁾"

        if (root.percentage >= 0.3)
            return "󰁽"

        if (root.percentage >= 0.2)
            return "󰁼"

        if (root.percentage >= 0.1)
            return "󰁻"

        return "󰁺"
    }

    // ─────────────────────────────────────────────
    // Quick Toggle
    // ─────────────────────────────────────────────

    QuickToggle {
        id: toggle

        anchors.fill: parent

        // Battery is informational, not a toggle.
        enabled: false
		
        activeIcon: root.batteryIcon
        inactiveIcon: root.batteryIcon

        label: "Battery"

        subLabel: {
            if (root.charging)
                return `${Math.round(root.percentage * 100)}% · Charging`

            if (root.fullyCharged)
                return "100% · Full"

            return `${Math.round(root.percentage * 100)}%`
        }
    }
}
