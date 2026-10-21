import QtQuick
import qs.config
import qs.services
import qs.components

// Volume or brightness as a chunky Material slider.
Item {
	id: root

	property var cfg: ({})
	property bool editing: false

	readonly property var c: WidgetTypes.resolve("slider", cfg)
	readonly property bool isVolume: c.kind === "volume"
	readonly property bool vertical: height > width * 1.2
	readonly property real value: isVolume ? (Audio.muted ? 0 : Audio.volume) : Brightness.value
	property real dragValue: -1
	readonly property real shown: dragValue >= 0 ? dragValue : value
	readonly property string iconName: isVolume ? (Audio.muted ? "volume_off" : shown < 0.34 ? "volume_mute" : shown < 0.67 ? "volume_down" : "volume_up") : (shown < 0.5 ? "brightness_5" : "brightness_7")

	function apply(v) {
		dragValue = v;
		if (isVolume)
			Audio.setVolume(v);
		else
			Brightness.setPercent(v * 100);
	}

	Rectangle {
		id: track
		anchors.fill: parent
		radius: Math.min(width, height) / 2 > 22 ? 22 : Math.min(width, height) / 2
		color: Theme.surfaceContainerHigh
		clip: true

		Rectangle {
			color: Theme.primary
			radius: track.radius
			x: 0
			y: root.vertical ? parent.height * (1 - root.shown) : 0
			width: root.vertical ? parent.width : Math.max(radius * 2, parent.width * root.shown)
			height: root.vertical ? Math.max(radius * 2, parent.height * root.shown) : parent.height
			anchors.bottom: root.vertical ? parent.bottom : undefined
		}

		Icon {
			name: root.iconName
			size: 22
			color: root.shown > 0.12 ? Theme.primaryFg : Theme.surfaceVariantFg
			x: root.vertical ? (parent.width - width) / 2 : 14
			y: root.vertical ? parent.height - height - 14 : (parent.height - height) / 2
		}
		Txt {
			visible: !root.vertical && parent.width > 110
			anchors.right: parent.right
			anchors.rightMargin: 14
			anchors.verticalCenter: parent.verticalCenter
			text: Math.round(root.shown * 100) + "%"
			font.weight: Font.Bold
			color: root.shown > 0.88 ? Theme.primaryFg : Theme.surfaceVariantFg
			elide: Text.ElideNone
		}
	}

	MouseArea {
		anchors.fill: parent
		enabled: !root.editing
		cursorShape: Qt.PointingHandCursor
		function at(m) {
			return Math.max(0, Math.min(1, root.vertical ? 1 - m.y / height : m.x / width));
		}
		onPressed: m => root.apply(at(m))
		onPositionChanged: m => root.apply(at(m))
		onReleased: root.dragValue = -1
	}
}
