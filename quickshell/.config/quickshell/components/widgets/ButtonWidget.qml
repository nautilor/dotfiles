import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.components

// Runs a user-defined shell command.
Item {
	id: root

	property var cfg: ({})
	property bool editing: false

	readonly property var c: WidgetTypes.resolve("button", cfg)

	Btn {
		anchors.fill: parent
		vertical: true
		idleRadius: 30
		iconSize: Math.max(20, Math.min(34, Math.min(parent.width, parent.height) * 0.36))
		icon: root.c.icon
		label: root.c.label
		enabled: !root.editing
		onClicked: {
			if (root.c.command !== "")
				Quickshell.execDetached(["sh", "-c", root.c.command]);
			if (root.c.closeOnClick)
				NotchCtl.close();
		}
	}
}
