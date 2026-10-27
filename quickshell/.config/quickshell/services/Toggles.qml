pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import qs.config
import qs.services

// State and actions of the quick toggles (Wi-Fi, Bluetooth, caffeine, microphone, do not disturb),
// shared by the Home widgets and the Control Center layout.
Singleton {
	id: root

	readonly property var adapter: Bluetooth.defaultAdapter
	readonly property var kinds: ["wifi", "bluetooth", "caffeine", "mic", "dnd"]

	function on(kind) {
		switch (kind) {
		case "wifi":
			return Networking.wifiEnabled;
		case "bluetooth":
			return adapter ? adapter.enabled : false;
		case "caffeine":
			return Caffeine.active;
		case "mic":
			return !Mic.muted;
		default:
			return Settings.dnd;
		}
	}

	function icon(kind) {
		const o = on(kind);
		switch (kind) {
		case "wifi":
			return o ? "wifi" : "wifi_off";
		case "bluetooth":
			return o ? "bluetooth" : "bluetooth_disabled";
		case "caffeine":
			return "coffee";
		case "mic":
			return o ? "mic" : "mic_off";
		default:
			return o ? "notifications_off" : "notifications_active";
		}
	}

	function label(kind) {
		return ({ wifi: "Wi-Fi", bluetooth: "Bluetooth", caffeine: "Caffeine", mic: "Mic", dnd: "Silent" })[kind];
	}

	function toggle(kind) {
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
}
