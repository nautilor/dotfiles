import QtQuick
import qs.config
import qs.services
import qs.components

Item {
	id: root

	property var cfg: ({})
	property bool editing: false

	TrayRow {
		id: tray
		anchors.centerIn: parent
		onMenuRequested: item => HomeLayout.trayItem = item
	}

	Txt {
		visible: root.editing && tray.children.length <= 1
		anchors.centerIn: parent
		text: "tray"
		color: Theme.outline
		font.pixelSize: 12
	}
}
