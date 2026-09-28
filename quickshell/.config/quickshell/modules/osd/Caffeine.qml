import Quickshell
import QtQuick
import Quickshell.Io
import qs.modules.osd

Item {
	id: root

	property bool active: false
	property string state: "inactive"
	implicitWidth: message.implicitWidth
	implicitHeight: message.implicitHeight

	opacity: active ? 1 : 0
	visible: active || opacity > 0

	Behavior on opacity {
		NumberAnimation {
			duration: active ? 150 : 250
			easing.type: active ? Easing.OutCubic : Easing.InCubic
		}
	}

	function showCaffeine() {
		if (!stateReader.running)
			stateReader.running = true
	}

	readonly property string iconName: root.state === "active" ? "caffeine" : "caffeine-off"
	readonly property string iconGlyph: root.state === "active"? "󰅶" : "󰾪"

	Process {
		id: stateReader
		command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/caffeine.sh" state 2>/dev/null || true']
		stdout: StdioCollector {
			onStreamFinished: {
				const next = (this.text || "").trim()
				if (next === "active" || next === "inactive")
					root.state = next

				root.active = true
				hideTimer.restart()
			}
		}
	}

	Timer {
		id: hideTimer
		interval: 1200
		onTriggered: root.active = false
	}

	Osd {
		id: message
		anchors.fill: parent
		mode: "message"
		iconName: root.iconName
		iconGlyph: root.iconGlyph
		title: "Caffeine"
		subtitle: root.state === "active" ? "On" : "Off"
		accentBackgroundColor: root.state === "active" ? colors.primary : colors.error
	}
}
