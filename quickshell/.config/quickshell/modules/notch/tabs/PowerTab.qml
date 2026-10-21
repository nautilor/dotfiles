import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// Power menu. Destructive actions need a second tap within 3 seconds.
FocusScope {
	id: root

	property string armed: ""
	// keyboard / hover selection, -1 = none
	property int current: -1
	readonly property var actions: [
		{ id: "lock", fn: PowerActions.lock, confirm: false },
		{ id: "logout", fn: PowerActions.logout, confirm: true },
		{ id: "reboot", fn: PowerActions.reboot, confirm: true },
		{ id: "poweroff", fn: PowerActions.poweroff, confirm: true }
	]

	function focusInput() {
		forceActiveFocus();
		if (current < 0)
			current = 0;
	}

	function move(delta) {
		current = (Math.max(0, current) + delta + actions.length) % actions.length;
		armed = "";
	}

	Keys.onLeftPressed: move(-1)
	Keys.onRightPressed: move(1)
	Keys.onTabPressed: move(1)
	Keys.onBacktabPressed: move(-1)
	Keys.onReturnPressed: trigger(current)
	Keys.onEnterPressed: trigger(current)
	Keys.onSpacePressed: trigger(current)
	Keys.onPressed: event => {
		const n = event.key - Qt.Key_1;
		if (n >= 0 && n < actions.length) {
			current = n;
			trigger(n);
		}
	}

	function trigger(i) {
		if (i < 0 || i >= actions.length)
			return;
		const a = actions[i];
		activate(a.id, a.fn, a.confirm);
	}

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
				required property int index
				readonly property bool focused: root.current === index
				readonly property bool armedNow: root.armed === modelData.id

				Layout.fillWidth: true
				Layout.fillHeight: true

				Rectangle {
					anchors.fill: parent
					radius: cell.armedNow ? 20 : 48
					color: cell.armedNow ? Theme.error : cell.modelData.danger ? Theme.errorContainer : Theme.surfaceContainerHigh
					scale: area.pressed ? 0.95 : 1
					border.width: cell.focused ? 3 : 0
					border.color: Theme.primary

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
						opacity: area.containsMouse || cell.focused ? 0.08 : 0
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
						onEntered: root.current = cell.index
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
