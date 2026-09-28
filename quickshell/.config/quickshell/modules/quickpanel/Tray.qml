import Quickshell
import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets


Item {
	id: tray
	width: parent.width
	height: 24
	readonly property var trayItems: {
		const items = SystemTray.items.values || [];
		return items.filter(item => item && item.status !== Status.Passive);
	}
	function trayItemClick(item, point, alternate) {
		if (!item)
		return;

		if (item.hasMenu) {
			item.display(barWindow, point.x, point.y);
			return;
		}

		if (alternate)
		item.secondaryActivate();
		else
		item.activate();
	}

	Row {
		id: trayRow
		anchors.right: parent.right
		spacing: 8

		Repeater {
			model: tray.trayItems

			delegate: Item {
				required property var modelData

				implicitWidth: 24
				implicitHeight: 24

				Rectangle {
					anchors.fill: parent
					radius: width / 2
					color: trayMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
				}

				MouseArea {
					id: trayMouse
					anchors.fill: parent
					acceptedButtons: Qt.LeftButton | Qt.RightButton
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: function(mouse) {
						const point = mapToItem(content, 0, height);
						tray.trayItemClick(modelData, point, mouse.button === Qt.RightButton);
					}
				}

				IconImage {
					anchors.centerIn: parent
					implicitSize: 18
					source: modelData.icon
				}
			}
		}
	}
}
