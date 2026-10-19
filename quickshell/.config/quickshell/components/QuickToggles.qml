import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// Wi-Fi, Bluetooth, caffeine, microphone, DND and the power profile (PPD).
ColumnLayout {
	id: root

	spacing: 8

	readonly property var adapter: Bluetooth.defaultAdapter

	RowLayout {
		Layout.fillWidth: true
		Layout.fillHeight: true
		spacing: 8

		Btn {
			Layout.fillWidth: true
			Layout.fillHeight: true
			vertical: true
			toggleable: true
			toggledRadius: 18
			idleRadius: 30
			implicitHeight: 76
			icon: Networking.wifiEnabled ? "wifi" : "wifi_off"
			label: "Wi‑Fi"
			toggled: Networking.wifiEnabled
			onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
		}
		Btn {
			Layout.fillWidth: true
			Layout.fillHeight: true
			vertical: true
			toggleable: true
			toggledRadius: 18
			idleRadius: 30
			enabled: root.adapter !== null
			icon: root.adapter && root.adapter.enabled ? "bluetooth" : "bluetooth_disabled"
			label: "Bluetooth"
			toggled: root.adapter ? root.adapter.enabled : false
			onClicked: root.adapter.enabled = !root.adapter.enabled
		}
		Btn {
			Layout.fillWidth: true
			Layout.fillHeight: true
			vertical: true
			toggleable: true
			toggledRadius: 18
			idleRadius: 30
			icon: "coffee"
			label: "Caffeine"
			toggled: Caffeine.active
			onClicked: Caffeine.toggle()
		}
		Btn {
			Layout.fillWidth: true
			Layout.fillHeight: true
			vertical: true
			toggleable: true
			toggledRadius: 18
			idleRadius: 30
			enabled: Mic.available
			icon: Mic.muted ? "mic_off" : "mic"
			label: "Mic"
			toggled: !Mic.muted
			onClicked: Mic.toggle()
		}
		Btn {
			Layout.fillWidth: true
			Layout.fillHeight: true
			vertical: true
			toggleable: true
			toggledRadius: 18
			idleRadius: 30
			icon: Settings.dnd ? "notifications_off" : "notifications_active"
			label: "Silent"
			toggled: Settings.dnd
			onClicked: Settings.dnd = !Settings.dnd
		}
	}

	// power-profiles-daemon, as a connected button group
	RowLayout {
		Layout.fillWidth: true
		spacing: 3

		Repeater {
			model: [
				{ p: PowerProfile.PowerSaver, icon: "eco", label: "Saver" },
				{ p: PowerProfile.Balanced, icon: "balance", label: "Balanced" },
				{ p: PowerProfile.Performance, icon: "bolt", label: "Boost" }
			]

			Btn {
				required property var modelData
				required property int index
				visible: modelData.p !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
				Layout.fillWidth: true
				implicitHeight: 44
				toggleable: true
				toggled: PowerProfiles.profile === modelData.p
				toggledRadius: 22
				icon: modelData.icon
				label: modelData.label
				iconSize: 20
				onClicked: PowerProfiles.profile = modelData.p
			}
		}
	}
}
