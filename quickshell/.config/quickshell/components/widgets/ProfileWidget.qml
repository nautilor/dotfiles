import QtQuick
import qs.components

Item {
	property var cfg: ({})
	property bool editing: false

	ProfileSwitch {
		anchors.fill: parent
		enabled: !parent.editing
	}
}
