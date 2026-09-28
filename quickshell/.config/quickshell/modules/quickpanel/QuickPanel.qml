import Quickshell
import QtQuick
import Quickshell.Widgets
import QtQuick.Effects
import qs.modules.colors

Item {
	id: quickPanel
	signal closeRequested()
	property string time: Qt.formatDateTime(new Date(), "h:mm")
	property string date: Qt.formatDateTime(new Date(), "ddd, MMM d")
	property var barWindow: null

Colors {
	id: colors
}

Timer {
	interval: 1000
	repeat: true
	running: true
	onTriggered: {
		quickPanel.time = Qt.formatDateTime(new Date(), "h:mm")
		quickPanel.date = Qt.formatDateTime(new Date(), "ddd, MMM d")
	}
}

Rectangle {
	id: quickPanelBackground
	anchors.fill: parent
	anchors.margins: 15
	color: colors.background
	radius: 24

	Item {
		id: content
		anchors.fill: parent

		Column {
			anchors.fill: parent
			spacing: 20

			Item {
				width: parent.width
				height: 52

				Column {
					anchors.left: parent.left
					anchors.top: parent.top

					Text {
						text: quickPanel.time
						color: colors.windowForeground
						font.pixelSize: 38
						font.weight: Font.Medium
					}

					Text {
						text: quickPanel.date
						color: colors.windowForeground
						font.pixelSize: 13
						opacity: 0.85
					}
				}
				Tray {}
			}

			Grid {
				id: quickPanelGrid
				columns: 3
				columnSpacing: 10
				rowSpacing: 10

				Bluetooth {
					width: 180
					height: 64
				}

				Wifi {
					width: 180
					height: 64
				}

				Microphone {
					width: 180
					height: 64
				}

				PowerProfiles {
					width: 180
					height: 64
				}

				Battery {
					width: 180
					height: 64
				}

				Caffeine {
					width: 180
					height: 64
				}
			}
		}
	}
}
}
