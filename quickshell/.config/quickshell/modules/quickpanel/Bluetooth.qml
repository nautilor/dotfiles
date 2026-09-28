import Quickshell
import QtQuick
import Quickshell.Bluetooth

Item {
	id: root

	// ─────────────────────────────────────────────
	// Adapter
	// ─────────────────────────────────────────────

	readonly property var adapter: Bluetooth.defaultAdapter

	// ─────────────────────────────────────────────
	// State
	// ─────────────────────────────────────────────

	readonly property bool available:
	root.adapter !== null

	readonly property bool powered:
	root.adapter?.enabled ?? false

	readonly property bool connected:
	root.adapter?.connected ?? false

	// ─────────────────────────────────────────────
	// Connected device
	// ─────────────────────────────────────────────

	readonly property var connectedDevice: {
		if (!root.adapter)
		return null

		const devices = root.adapter.devices.values || []

		return devices.find(
			device => device && device.connected
		) || null
	}

	readonly property string deviceName:
	root.connectedDevice
	? root.connectedDevice.name
	: ""

	// ─────────────────────────────────────────────
	// Glyph
	// ─────────────────────────────────────────────

	readonly property string icon:
	root.powered
	? root.connected
	? "󰂯"
	: "󰂯"
	: "󰂲"

	// ─────────────────────────────────────────────
	// Toggle
	// ─────────────────────────────────────────────

	QuickToggle {
		id: toggle

		anchors.fill: parent

		enabled: root.available

		checked: root.powered

		activeIcon: "󰂯"
		inactiveIcon: "󰂲"

		label: "Bluetooth"

		subLabel: {
			if (!root.available)
			return "Unavailable"

			if (!root.powered)
			return "Off"

			if (root.connected)
			return root.deviceName

			return "On"
		}

		onToggled: {
			if (root.adapter)
			root.adapter.enabled = !root.adapter.enabled
		}
	}
}
