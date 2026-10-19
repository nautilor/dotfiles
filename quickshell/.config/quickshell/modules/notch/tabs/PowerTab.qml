import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// Power menu. Destructive actions need a second tap within 3 seconds.
Item {
	id: root

	property string armed: ""

	Timer {
		id: disarm
		interval: 3000
		onTriggered: root.armed = ""
	}

	function activate(id, action, needsConfirm) {
		if (needsConfirm && armed !== id) {
			armed = id;
			disarm.restart();
			return;
		}
		armed = "";
		NotchCtl.close();
		action();
	}

	RowLayout {
		anchors.fill: parent
		spacing: 10

		Repeater {
			model: [
				{ id: "lock", icon: "lock", label: "Lock", danger: false, confirm: false },
				{ id: "logout", icon: "logout", label: "Log out", danger: false, confirm: true },
				{ id: "reboot", icon: "restart_alt", label: "Reboot", danger: false, confirm: true },
				{ id: "poweroff", icon: "power_settings_new", label: "Power off", danger: true, confirm: true }
			]

			Item {
				id: cell
				required property var modelData
				readonly property bool armedNow: root.armed === modelData.id

				Layout.fillWidth: true
				Layout.fillHeight: true

				Rectangle {
					anchors.fill: parent
					radius: cell.armedNow ? 20 : 48
					color: cell.armedNow ? Theme.error : cell.modelData.danger ? Theme.errorContainer : Theme.surfaceContainerHigh
					scale: area.pressed ? 0.95 : 1

					Behavior on radius {
						SpringAnimation {
							spring: Theme.springBouncy
							damping: Theme.dampBouncy
							epsilon: 0.25
						}
					}
					Behavior on color {
						ColorAnimation {
							duration: Theme.durShort
						}
					}
					Behavior on scale {
						SpringAnimation {
							spring: 5
							damping: 0.4
							epsilon: 0.002
						}
					}

					Rectangle {
						anchors.fill: parent
						radius: parent.radius
						color: Theme.surfaceFg
						opacity: area.containsMouse ? 0.08 : 0
					}

					Column {
						anchors.centerIn: parent
						spacing: 8
						Icon {
							name: cell.modelData.icon
							size: 36
							fill: 1
							color: cell.armedNow ? Theme.errorFg : cell.modelData.danger ? Theme.errorContainerFg : Theme.surfaceFg
							anchors.horizontalCenter: parent.horizontalCenter
						}
						Txt {
							text: cell.armedNow ? "Tap to confirm" : cell.modelData.label
							font.weight: Font.Medium
							color: cell.armedNow ? Theme.errorFg : cell.modelData.danger ? Theme.errorContainerFg : Theme.surfaceFg
							anchors.horizontalCenter: parent.horizontalCenter
						}
					}

					MouseArea {
						id: area
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							const m = cell.modelData;
							const fn = {
								lock: PowerActions.lock,
								logout: PowerActions.logout,
								reboot: PowerActions.reboot,
								poweroff: PowerActions.poweroff
							}[m.id];
							root.activate(m.id, fn, m.confirm);
						}
					}
				}
			}
		}
	}
}
