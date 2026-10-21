import QtQuick
import qs.config
import qs.services
import qs.components

Rectangle {
	id: root

	property var cfg: ({})
	property bool editing: false

	radius: Theme.radiusMedium
	color: Theme.surfaceContainer

	Txt {
		visible: !Battery.present
		anchors.centerIn: parent
		text: "No battery"
		color: Theme.surfaceVariantFg
	}

	Row {
		visible: Battery.present
		anchors.centerIn: parent
		spacing: 10
		Icon {
			name: Battery.icon
			size: Math.max(22, Math.min(root.height * 0.5, 40))
			fill: 1
			color: Battery.color
			anchors.verticalCenter: parent.verticalCenter
		}
		Column {
			anchors.verticalCenter: parent.verticalCenter
			Txt {
				text: Battery.percent + "%"
				font.pixelSize: Math.max(15, Math.min(root.height * 0.36, 26))
				font.weight: Font.Bold
				color: Battery.color
				elide: Text.ElideNone
			}
			Txt {
				visible: root.height >= 60
				text: Battery.full ? "Full" : Battery.charging ? "Charging" : Battery.low ? "Low" : "On battery"
				font.pixelSize: 11
				color: Theme.surfaceVariantFg
				elide: Text.ElideNone
			}
		}
	}
}
