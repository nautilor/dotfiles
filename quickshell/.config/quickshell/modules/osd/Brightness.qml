import Quickshell
import QtQuick
import Quickshell.Io
import qs.modules.osd

Item {
	id: root

	property bool active: false
	property int percent: 0
	property real level: 0
	property bool ready: false
	implicitWidth: meter.implicitWidth
	implicitHeight: meter.implicitHeight

	opacity: active ? 1 : 0
	visible: active || opacity > 0

	Behavior on opacity {
		NumberAnimation {
			duration: active ? 150 : 250
			easing.type: active ? Easing.OutCubic : Easing.InCubic
		}
	}

	function clampPercent(value) {
		return Math.max(0, Math.min(100, value))
	}

	function showBrightness(nextPercent) {
		const next = clampPercent(nextPercent)
		percent = next
		level = next / 100
		active = true
		hideTimer.restart()
	}

	function refreshBrightness() {
		if (!brightnessPokeReader.running)
			brightnessPokeReader.running = true
	}

	readonly property string iconName: {
		if (percent <= 0)
			return "display-brightness-off-symbolic"
		if (percent < 34)
			return "display-brightness-low-symbolic"
		if (percent < 67)
			return "display-brightness-medium-symbolic"
		return "display-brightness-high-symbolic"
	}

	readonly property string iconGlyph: {
		if (percent <= 0)
			return "󰃞"
		if (percent < 34)
			return "󰃞"
		if (percent < 67)
			return "󰃟"
		return "󰃠"
	}

	Process {
		id: brightnessReader
		command: [
			"bash",
			"-lc",
			"brightnessctl -m 2>/dev/null | awk -F, 'NR == 1 { gsub(/%/, \"\", $4); print int($4); found = 1 } END { if (!found) print \"0\" }'"
		]
		stdout: StdioCollector {
			onStreamFinished: {
				const text = this.text.trim()
				if (text === "")
					return

				const next = parseInt(text)
				if (Number.isNaN(next))
					return

				if (!root.ready) {
					root.ready = true
					root.percent = next
					root.level = next / 100
					return
				}

				if (next !== root.percent)
					root.showBrightness(next)
			}
		}
	}

	Process {
		id: brightnessPokeReader
		command: [
			"bash",
			"-lc",
			"brightnessctl -m 2>/dev/null | awk -F, 'NR == 1 { gsub(/%/, \"\", $4); print int($4); found = 1 } END { if (!found) print \"0\" }'"
		]
		stdout: StdioCollector {
			onStreamFinished: {
				const text = this.text.trim()
				if (text === "")
					return

				const next = parseInt(text)
				if (Number.isNaN(next))
					return

				root.ready = true
				root.showBrightness(next)
			}
		}
	}

	Timer {
		interval: 250
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			if (!brightnessReader.running)
				brightnessReader.running = true
		}
	}

	Timer {
		id: hideTimer
		interval: 1200
		onTriggered: root.active = false
	}

	Osd {
		id: meter
		anchors.fill: parent
		mode: "meter"
		iconName: root.iconName
		iconGlyph: root.iconGlyph
		level: root.level
		percent: root.percent
	}
}
