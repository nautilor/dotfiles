import QtQuick
import qs.config

// Little equalizer bars shown while music plays.
Row {
	id: root

	property bool active: false
	property color color: Theme.primary

	spacing: 2
	height: 16

	Repeater {
		model: 4
		Rectangle {
			required property int index
			width: 3
			radius: 1.5
			color: root.color
			anchors.verticalCenter: parent.verticalCenter
			height: 4

			Behavior on height {
				NumberAnimation {
					duration: 160
					easing.type: Easing.OutQuad
				}
			}

			Timer {
				interval: 140 + index * 30
				running: root.active && root.visible
				repeat: true
				onTriggered: parent.height = 4 + Math.random() * 12
			}
		}
	}
}
