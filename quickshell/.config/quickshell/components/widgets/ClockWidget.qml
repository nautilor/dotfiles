import QtQuick
import qs.config
import qs.services
import qs.components

Rectangle {
	id: root

	property var cfg: ({})
	property bool editing: false

	readonly property var c: WidgetTypes.resolve("clock", cfg)
	property date now: new Date()

	radius: Theme.radiusMedium
	color: Theme.surfaceContainer

	Timer {
		interval: root.c.showSeconds ? 1000 : 10000
		running: root.visible
		repeat: true
		triggeredOnStart: true
		onTriggered: root.now = new Date()
	}

	Column {
		anchors.centerIn: parent
		width: parent.width - 16
		spacing: 0
		Txt {
			visible: root.c.showTime
			width: parent.width
			horizontalAlignment: Text.AlignHCenter
			text: Qt.formatTime(root.now, Settings.use24h ? (root.c.showSeconds ? "HH:mm:ss" : "HH:mm") : (root.c.showSeconds ? "h:mm:ss AP" : "h:mm AP"))
			font.pixelSize: Math.max(14, Math.min(root.height * (root.c.showDate ? 0.42 : 0.55), root.width / 4.2))
			font.weight: Font.Bold
		}
		Txt {
			visible: root.c.showDate
			width: parent.width
			horizontalAlignment: Text.AlignHCenter
			text: Qt.formatDate(root.now, root.c.dateFormat)
			font.pixelSize: Math.max(10, Math.min(root.height * 0.22, 15))
			fontSizeMode: Text.HorizontalFit
			minimumPixelSize: 8
			color: Theme.surfaceVariantFg
		}
	}
}
