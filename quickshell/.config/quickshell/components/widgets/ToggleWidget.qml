import QtQuick
import qs.config
import qs.services
import qs.components

// One quick toggle; which one is a setting.
Item {
	id: root

	property var cfg: ({})
	property bool editing: false

	readonly property var c: WidgetTypes.resolve("toggle", cfg)
	readonly property string kind: c.kind

	Btn {
		anchors.fill: parent
		vertical: true
		toggleable: true
		toggledRadius: 18
		idleRadius: 30
		iconSize: Math.max(20, Math.min(34, Math.min(parent.width, parent.height) * 0.36))
		icon: Toggles.icon(root.kind)
		label: root.c.label !== "" ? root.c.label : Toggles.label(root.kind)
		toggled: Toggles.on(root.kind)
		enabled: !root.editing
		onClicked: Toggles.toggle(root.kind)
	}
}
