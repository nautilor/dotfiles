import QtQuick
import qs.components

Item {
	property var cfg: ({})
	property bool editing: false

	WorkspaceRow {
		anchors.verticalCenter: parent.verticalCenter
		anchors.horizontalCenter: parent.horizontalCenter
		maxWidth: parent.width
	}
}
