import QtQuick
import Quickshell.Hyprland
import qs.config
import qs.components

// Hyprland workspaces; the active one is a wide pill.
Row {
	id: root

	spacing: 4
	// shrink inactive pills so the row never exceeds this width
	property real maxWidth: 100000
	readonly property real inactiveW: Math.max(14, Math.min(26, (maxWidth - 44 - spacing * (count - 1)) / Math.max(1, count - 1)))
	readonly property int count: {
		let m = 5;
		for (const w of Hyprland.workspaces.values)
			m = Math.max(m, w.id);
		return Math.min(m, 10);
	}
	readonly property int activeId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1

	Repeater {
		model: root.count

		Rectangle {
			id: pill
			required property int index
			readonly property int wsId: index + 1
			readonly property bool active: root.activeId === wsId
			readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId)

			height: 28
			width: active ? 44 : root.inactiveW
			radius: active ? 12 : 13
			color: active ? Theme.primary : occupied ? Theme.secondaryContainer : Theme.surfaceContainerHigh

			Behavior on width {
				SpringAnimation {
					spring: Theme.springBouncy
					damping: Theme.dampBouncy
					epsilon: 0.5
				}
			}
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

			Txt {
				anchors.centerIn: parent
				text: pill.wsId
				font.pixelSize: 13
				font.weight: pill.active ? Font.Bold : Font.Medium
				color: pill.active ? Theme.primaryFg : pill.occupied ? Theme.secondaryContainerFg : Theme.surfaceVariantFg
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: Hyprland.dispatch("workspace " + pill.wsId)
			}
		}
	}
}
