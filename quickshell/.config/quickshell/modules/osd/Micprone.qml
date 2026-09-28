import Quickshell
import QtQuick
import Quickshell.Io
import qs.modules.osd

Item {
	id: root

	property bool active: false
	property string state: "unmuted"
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

	function showMicrophone() {
		if (!stateReader.running)
			stateReader.running = true
	}

	readonly property string iconName: root.state === "muted" ? "microphone-sensitivity-muted" : "microphone-sensitivity-high"
	readonly property string iconGlyph: root.state === "muted" ? "󰍭" : "󰍬"

	Process {
		id: stateReader
		command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/mic_toggle.sh" state 2>/dev/null || true']
		stdout: StdioCollector {
			onStreamFinished: {
				const next = (this.text || "").trim()
				if (next === "muted" || next === "unmuted")
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
		title: "Microphone"
		subtitle: root.state === "muted" ? "Muted" : "On"
		accentBackgroundColor: root.state === "muted" ? colors.error : colors.primary
	}
}
