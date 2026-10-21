import QtQuick
import qs.components

Item {
	property var cfg: ({})
	property bool editing: false

	ProfileSwitch {
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		height: Math.min(parent.height, 48)
		enabled: !parent.editing
	}
}
