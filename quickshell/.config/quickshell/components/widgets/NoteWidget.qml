import QtQuick
import qs.config
import qs.services
import qs.components

Rectangle {
	id: root

	property var cfg: ({})
	property bool editing: false

	readonly property var c: WidgetTypes.resolve("note", cfg)

	radius: Theme.radiusMedium
	color: Theme.surfaceContainer

	Column {
		anchors.fill: parent
		anchors.margins: 12
		spacing: 4
		Txt {
			visible: root.c.title !== ""
			width: parent.width
			text: root.c.title
			font.pixelSize: 12
			font.weight: Font.Bold
			color: Theme.primary
		}
		Txt {
			width: parent.width
			height: parent.height - (root.c.title !== "" ? 20 : 0)
			text: root.c.text
			wrapMode: Text.Wrap
			elide: Text.ElideRight
			color: Theme.surfaceFg
		}
	}
}
