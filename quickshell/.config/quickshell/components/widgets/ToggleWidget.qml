import QtQuick
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.config
import qs.services
import qs.components

// One quick toggle; which one is a setting.
Item {
	id: root

	property var cfg: ({})
	property bool editing: false

	readonly property var c: WidgetTypes.resolve("toggle", cfg)
	readonly property var adapter: Bluetooth.defaultAdapter
	readonly property string kind: c.kind

	readonly property bool on: kind === "wifi" ? Networking.wifiEnabled : kind === "bluetooth" ? (adapter ? adapter.enabled : false) : kind === "caffeine" ? Caffeine.active : kind === "mic" ? !Mic.muted : Settings.dnd
	readonly property string iconName: {
		switch (kind) {
		case "wifi":
			return on ? "wifi" : "wifi_off";
		case "bluetooth":
			return on ? "bluetooth" : "bluetooth_disabled";
		case "caffeine":
			return "coffee";
		case "mic":
			return on ? "mic" : "mic_off";
		default:
			return Settings.dnd ? "notifications_off" : "notifications_active";
		}
	}
	readonly property string defaultLabel: ({ wifi: "Wi-Fi", bluetooth: "Bluetooth", caffeine: "Caffeine", mic: "Mic", dnd: "Silent" })[kind]

	function toggle() {
		if (kind === "wifi")
			Networking.wifiEnabled = !Networking.wifiEnabled;
		else if (kind === "bluetooth" && adapter)
			adapter.enabled = !adapter.enabled;
		else if (kind === "caffeine")
			Caffeine.toggle();
		else if (kind === "mic")
			Mic.toggle();
		else
			Settings.dnd = !Settings.dnd;
	}

	Btn {
		anchors.fill: parent
		vertical: true
		toggleable: true
		toggledRadius: 18
		idleRadius: 30
		iconSize: Math.max(20, Math.min(34, Math.min(parent.width, parent.height) * 0.36))
		icon: root.iconName
		label: root.c.label !== "" ? root.c.label : root.defaultLabel
		toggled: root.on
		enabled: !root.editing
		onClicked: root.toggle()
	}
}
