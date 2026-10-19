import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.config

// StatusNotifier tray icons. Left click activates, middle click secondary-activates, right click asks for the menu.
Row {
	id: root

	signal menuRequested(var trayItem)

	spacing: 4

	Repeater {
		model: SystemTray.items

		Rectangle {
			id: cell
			required property var modelData

			width: 34
			height: 34
			radius: mouse.pressed ? 8 : 17
			color: mouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"
			Behavior on radius {
				NumberAnimation {
					duration: Theme.durShort
				}
			}

			Image {
				anchors.centerIn: parent
				width: 20
				height: 20
				sourceSize: Qt.size(40, 40)
				source: cell.modelData.icon
				fillMode: Image.PreserveAspectFit
			}

			MouseArea {
				id: mouse
				anchors.fill: parent
				hoverEnabled: true
				acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
				cursorShape: Qt.PointingHandCursor
				onClicked: event => {
					if (event.button === Qt.MiddleButton)
						cell.modelData.secondaryActivate();
					else if (event.button === Qt.RightButton || cell.modelData.onlyMenu) {
						if (cell.modelData.hasMenu)
							root.menuRequested(cell.modelData);
					} else {
						cell.modelData.activate();
					}
				}
			}
		}
	}
}
