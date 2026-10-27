import QtQuick
import qs.components

Item {
	property var cfg: ({})
	property bool editing: false

	TrayPill {
		anchors.fill: parent
		editing: parent.editing
	}
}
