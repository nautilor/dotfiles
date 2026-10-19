import QtQuick
import qs.config
import qs.services
import qs.components

// Transient message (caffeine / mic toggles etc.) with custom text.
Item {
	id: root

	implicitWidth: Hud.value >= 0 ? 320 : row.implicitWidth + 24
	implicitHeight: 56

	Row {
		id: row
		anchors.centerIn: parent
		spacing: 12

		Rectangle {
			width: 36
			height: 36
			radius: Hud.warn ? 12 : 18
			color: Hud.warn ? Theme.errorContainer : Theme.primaryContainer
			anchors.verticalCenter: parent.verticalCenter
			Behavior on radius {
				SpringAnimation {
					spring: Theme.springBouncy
					damping: Theme.dampBouncy
					epsilon: 0.25
				}
			}
			Icon {
				anchors.centerIn: parent
				name: Hud.icon
				size: 22
				fill: 1
				color: Hud.warn ? Theme.errorContainerFg : Theme.primaryContainerFg
			}
		}

		// OSD slider (volume / brightness)
		Item {
			visible: Hud.value >= 0
			width: 150
			height: 36
			anchors.verticalCenter: parent.verticalCenter
			Rectangle {
				anchors.verticalCenter: parent.verticalCenter
				width: parent.width
				height: 12
				radius: 6
				color: Theme.surfaceContainerHighest
				Rectangle {
					width: Math.max(parent.height, parent.width * Math.min(1, Hud.value))
					height: parent.height
					radius: 6
					color: Hud.warn ? Theme.error : Theme.primary
					Behavior on width {
						NumberAnimation {
							duration: 120
							easing.type: Easing.OutCubic
						}
					}
				}
			}
		}

		Txt {
			text: Hud.text
			font.pixelSize: 15
			font.weight: Font.Medium
			elide: Text.ElideNone
			anchors.verticalCenter: parent.verticalCenter
		}
	}
}
