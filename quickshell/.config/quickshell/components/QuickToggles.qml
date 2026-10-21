import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Networking
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
			Layout.preferredWidth: 10
			Layout.minimumWidth: 10
			Layout.maximumWidth: 1000
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
			Layout.preferredWidth: 10
			Layout.minimumWidth: 10
			Layout.maximumWidth: 1000
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
			Layout.preferredWidth: 10
			Layout.minimumWidth: 10
			Layout.maximumWidth: 1000
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
			Layout.preferredWidth: 10
			Layout.minimumWidth: 10
			Layout.maximumWidth: 1000
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
			Layout.preferredWidth: 10
			Layout.minimumWidth: 10
			Layout.maximumWidth: 1000
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

	ProfileSwitch {
		Layout.fillWidth: true
	}
}
