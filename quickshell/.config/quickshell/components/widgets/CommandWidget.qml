import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.components

// Shows the (trimmed) output of a shell command, re-run every few seconds.
Rectangle {
	id: root

	property var cfg: ({})
	property bool editing: false

	readonly property var c: WidgetTypes.resolve("command", cfg)
	property string output: ""

	radius: Theme.radiusMedium
	color: Theme.surfaceContainer

	Process {
		id: proc
		command: ["sh", "-c", root.c.command]
		stdout: StdioCollector {
			onStreamFinished: root.output = text.trim()
		}
	}

	Timer {
		interval: Math.max(1, root.c.interval) * 1000
		running: root.visible && root.c.command !== ""
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			if (!proc.running)
				proc.running = true;
		}
	}

	Row {
		anchors.fill: parent
		anchors.margins: 12
		spacing: 10
		Icon {
			visible: root.c.icon !== ""
			name: root.c.icon
			size: Math.max(20, Math.min(root.height * 0.4, 32))
			color: Theme.primary
			anchors.verticalCenter: parent.verticalCenter
		}
		Column {
			width: parent.width - (root.c.icon !== "" ? 42 : 0)
			anchors.verticalCenter: parent.verticalCenter
			spacing: 0
			Txt {
				visible: root.c.label !== ""
				width: parent.width
				text: root.c.label
				font.pixelSize: 11
				color: Theme.surfaceVariantFg
			}
			Txt {
				width: parent.width
				text: root.c.command === "" ? "Set a command" : root.output === "" ? "…" : root.output
				font.pixelSize: Math.max(13, Math.min(root.height * 0.3, 22))
				font.weight: Font.Bold
				wrapMode: Text.Wrap
				maximumLineCount: Math.max(1, Math.floor(root.height / 24))
				elide: Text.ElideRight
			}
		}
	}

	MouseArea {
		anchors.fill: parent
		enabled: !root.editing && root.c.clickCommand !== ""
		cursorShape: Qt.PointingHandCursor
		onClicked: Quickshell.execDetached(["sh", "-c", root.c.clickCommand])
	}
}
