import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config

// dbusmenu of a tray item, with nested submenus.
Rectangle {
	id: root

	property var trayItem
	property var current
	property var stack: []
	property string title: ""

	signal closed

	radius: Theme.radiusLarge
	color: Theme.surfaceContainerHigh

	onTrayItemChanged: {
		stack = [];
		current = trayItem ? trayItem.menu : null;
		title = trayItem ? (trayItem.tooltipTitle || trayItem.title || trayItem.id) : "";
	}

	function back() {
		if (stack.length === 0) {
			closed();
			return;
		}
		const s = stack.slice();
		current = s.pop();
		stack = s;
	}

	QsMenuOpener {
		id: opener
		menu: root.current
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 8
		spacing: 4

		RowLayout {
			Layout.fillWidth: true
			Btn {
				icon: root.stack.length === 0 ? "close" : "arrow_back"
				variant: 2
				iconSize: 18
				implicitWidth: 34
				implicitHeight: 34
				onClicked: root.back()
			}
			Txt {
				Layout.fillWidth: true
				text: root.title
				font.weight: Font.Bold
			}
		}

		ListView {
			Layout.fillWidth: true
			Layout.fillHeight: true
			clip: true
			boundsBehavior: Flickable.StopAtBounds
			model: opener.children

			delegate: Item {
				id: entry
				required property var modelData
				width: ListView.view.width
				height: modelData.isSeparator ? 9 : 38

				Rectangle {
					visible: entry.modelData.isSeparator
					anchors.verticalCenter: parent.verticalCenter
					x: 12
					width: parent.width - 24
					height: 1
					color: Theme.outlineVariant
				}

				Rectangle {
					visible: !entry.modelData.isSeparator
					anchors.fill: parent
					radius: 19
					color: Theme.surfaceFg
					opacity: area.containsMouse && entry.modelData.enabled ? 0.1 : 0
				}

				Row {
					visible: !entry.modelData.isSeparator
					anchors.left: parent.left
					anchors.leftMargin: 12
					anchors.right: parent.right
					anchors.rightMargin: 12
					anchors.verticalCenter: parent.verticalCenter
					spacing: 10
					opacity: entry.modelData.enabled ? 1 : 0.4

					Icon {
						visible: entry.modelData.checkState === Qt.Checked
						name: "check"
						size: 18
						anchors.verticalCenter: parent.verticalCenter
					}
					Image {
						visible: entry.modelData.icon !== ""
						width: 18
						height: 18
						source: entry.modelData.icon
						sourceSize: Qt.size(36, 36)
						anchors.verticalCenter: parent.verticalCenter
					}
					Txt {
						width: parent.width - (entry.modelData.hasChildren ? 28 : 0) - (entry.modelData.icon !== "" ? 28 : 0) - (entry.modelData.checkState === Qt.Checked ? 28 : 0)
						text: entry.modelData.text
						anchors.verticalCenter: parent.verticalCenter
					}
					Icon {
						visible: entry.modelData.hasChildren
						name: "chevron_right"
						size: 18
						anchors.verticalCenter: parent.verticalCenter
					}
				}

				MouseArea {
					id: area
					anchors.fill: parent
					hoverEnabled: true
					enabled: !entry.modelData.isSeparator && entry.modelData.enabled
					onClicked: {
						if (entry.modelData.hasChildren) {
							root.stack = root.stack.concat([root.current]);
							root.current = entry.modelData;
						} else {
							entry.modelData.triggered();
							root.closed();
						}
					}
				}
			}
		}
	}
}
