import QtQuick
import qs.config
import qs.services
import qs.components

// System tray icons in a pill; right click asks Home to show the app menu.
// Too many icons to fit: scroll sideways (drag or mouse wheel).
Rectangle {
	id: root

	property bool editing: false
	// size of one icon button
	property real cell: 34
	readonly property alias tray: tray

	radius: Math.min(height / 2, 26)
	color: Theme.surfaceContainerHigh
	clip: true

	Flickable {
		id: flick
		anchors.fill: parent
		anchors.leftMargin: 6
		anchors.rightMargin: 6
		contentWidth: Math.max(width, tray.width)
		contentHeight: height
		flickableDirection: Flickable.HorizontalFlick
		boundsBehavior: Flickable.StopAtBounds
		interactive: tray.width > width

		TrayRow {
			id: tray
			cell: root.cell
			x: Math.max(0, (flick.width - width) / 2)
			anchors.verticalCenter: parent.verticalCenter
			onMenuRequested: item => HomeLayout.trayItem = item
		}

		WheelHandler {
			enabled: flick.interactive
			acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
			onWheel: event => {
				const d = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
				flick.contentX = Math.max(0, Math.min(flick.contentWidth - flick.width, flick.contentX - d / 2));
			}
		}
	}

	Txt {
		visible: root.editing && tray.children.length <= 1
		anchors.centerIn: parent
		text: "tray"
		color: Theme.outline
		font.pixelSize: 12
	}
}
