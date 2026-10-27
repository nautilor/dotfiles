import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// Home layout "Glance": a big clock, the player and the next event on the left; tiles, power profile and tray on the right.
Item {
	id: root

	property date now: new Date()

	Timer {
		interval: 10000
		running: root.visible
		repeat: true
		triggeredOnStart: true
		onTriggered: root.now = new Date()
	}

	RowLayout {
		anchors.fill: parent
		spacing: 12

		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.preferredWidth: 1
			spacing: 8

			Rectangle {
				Layout.fillWidth: true
				Layout.fillHeight: true
				radius: Theme.radiusLarge
				color: Theme.surfaceContainer
				Column {
					anchors.centerIn: parent
					spacing: 0
					Txt {
						anchors.horizontalCenter: parent.horizontalCenter
						text: Qt.formatTime(root.now, Settings.use24h ? "HH:mm" : "h:mm AP")
						font.pixelSize: 52
						font.weight: Font.Bold
						elide: Text.ElideNone
					}
					Txt {
						anchors.horizontalCenter: parent.horizontalCenter
						text: Qt.formatDate(root.now, "dddd d MMMM")
						font.pixelSize: 14
						color: Theme.surfaceVariantFg
						elide: Text.ElideNone
					}
				}
			}
			MiniPlayer {
				Layout.fillWidth: true
				Layout.preferredHeight: 56
			}
			EventCard {
				Layout.fillWidth: true
				Layout.preferredHeight: 60
			}
		}

		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.preferredWidth: 1
			spacing: 8

			GridLayout {
				Layout.fillWidth: true
				Layout.fillHeight: true
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
				TrayPill {
					Layout.fillWidth: true
					Layout.fillHeight: true
					Layout.preferredWidth: 1
				}
			}
			ProfileSwitch {
				Layout.fillWidth: true
				Layout.preferredHeight: 46
			}
		}
	}
}
