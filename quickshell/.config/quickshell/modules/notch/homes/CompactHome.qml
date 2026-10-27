import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// Home layout "Compact": three slim rows.
// Toggles and tray, power profile and a mini player, next event.
Item {
	id: root

	ColumnLayout {
		anchors.fill: parent
		spacing: 8

		RowLayout {
			Layout.fillWidth: true
			Layout.preferredHeight: 52
			spacing: 6

			Repeater {
				model: Toggles.kinds
				Btn {
					required property string modelData
					Layout.preferredWidth: 52
					Layout.preferredHeight: 52
					icon: Toggles.icon(modelData)
					iconSize: 24
					toggleable: true
					toggled: Toggles.on(modelData)
					toggledRadius: 18
					onClicked: Toggles.toggle(modelData)
				}
			}
			TrayPill {
				Layout.fillWidth: true
				Layout.preferredHeight: 52
				cell: 44
			}
		}

		RowLayout {
			Layout.fillWidth: true
			Layout.preferredHeight: 52
			spacing: 8

			ProfileSwitch {
				Layout.preferredWidth: 270
				Layout.preferredHeight: 52
			}
			MiniPlayer {
				Layout.fillWidth: true
				Layout.preferredHeight: 52
			}
		}

		EventCard {
			Layout.fillWidth: true
			Layout.fillHeight: true
		}
	}
}
