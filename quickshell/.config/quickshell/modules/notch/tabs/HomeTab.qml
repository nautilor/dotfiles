import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.config
import qs.services
import qs.components

Item {
	id: root

	RowLayout {
		anchors.fill: parent
		spacing: 12

		MediaCard {
			Layout.preferredWidth: 330
			Layout.minimumWidth: 330
			Layout.maximumWidth: 330
			Layout.fillHeight: true
		}

		ColumnLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
			Layout.preferredWidth: 100
			spacing: 10

			RowLayout {
				id: wsRow
				Layout.fillWidth: true
				Layout.minimumWidth: 0
				WorkspaceRow {
					maxWidth: wsRow.width - (tray.visible ? tray.width + 8 : 0) - 8
				}
				Item {
					Layout.fillWidth: true
				}
				TrayRow {
					id: tray
					visible: SystemTray.items.values.length > 0
					onMenuRequested: item => menu.trayItem = item
				}
			}
			QuickToggles {
				Layout.fillWidth: true
				Layout.fillHeight: true
			}
			EventCard {
				Layout.fillWidth: true
				Layout.preferredHeight: 62
			}
		}
	}

	TrayMenu {
		id: menu
		visible: trayItem !== null && trayItem !== undefined
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		anchors.right: parent.right
		width: parent.width - 342
		trayItem: null
		onClosed: trayItem = null
	}
}
