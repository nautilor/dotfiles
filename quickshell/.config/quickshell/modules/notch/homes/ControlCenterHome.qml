import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.components

// Home layout "Control Center": sliders on top, pill tiles below, the player and the next event on the right.
Item {
	id: root

	readonly property var profiles: [
		{ p: PowerProfile.PowerSaver, icon: "eco", label: "Saver" },
		{ p: PowerProfile.Balanced, icon: "balance", label: "Balanced" },
		{ p: PowerProfile.Performance, icon: "bolt", label: "Performance" }
	].filter(o => o.p !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)
	readonly property int profileIndex: Math.max(0, profiles.findIndex(o => o.p === PowerProfiles.profile))

	RowLayout {
		anchors.fill: parent
		spacing: 12

		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.preferredWidth: 1
			spacing: 8

			SliderBar {
				Layout.fillWidth: true
				Layout.preferredHeight: 46
				kind: "brightness"
			}
			SliderBar {
				Layout.fillWidth: true
				Layout.preferredHeight: 46
				kind: "volume"
			}

			GridLayout {
				Layout.fillWidth: true
				Layout.fillHeight: true
				Layout.topMargin: 4
				columns: 2
				rowSpacing: 8
				columnSpacing: 8

				Repeater {
					model: Toggles.kinds

					QuickTile {
						required property string modelData
						Layout.fillWidth: true
						Layout.fillHeight: true
						Layout.preferredWidth: 1
						icon: Toggles.icon(modelData)
						title: Toggles.label(modelData)
						subtitle: Toggles.on(modelData) ? "On" : "Off"
						toggled: Toggles.on(modelData)
						onClicked: Toggles.toggle(modelData)
					}
				}
				QuickTile {
					Layout.fillWidth: true
					Layout.fillHeight: true
					Layout.preferredWidth: 1
					icon: root.profiles[root.profileIndex].icon
					title: "Power"
					subtitle: root.profiles[root.profileIndex].label
					toggled: root.profiles[root.profileIndex].p === PowerProfile.Performance
					onClicked: PowerProfiles.profile = root.profiles[(root.profileIndex + 1) % root.profiles.length].p
				}
			}
		}

		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.preferredWidth: 1
			spacing: 8

			MediaCard {
				Layout.fillWidth: true
				Layout.fillHeight: true
			}
			TrayPill {
				Layout.fillWidth: true
				Layout.preferredHeight: 44
				visible: SystemTray.items.values.length > 0
			}
			EventCard {
				Layout.fillWidth: true
				Layout.preferredHeight: 64
			}
		}
	}
}
