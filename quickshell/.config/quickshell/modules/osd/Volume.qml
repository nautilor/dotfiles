import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.modules.osd

Item {
	id: root

	property bool active: false
	property int percent: 0
	property real level: 0
	property bool muted: false
	implicitWidth: meter.implicitWidth
	implicitHeight: meter.implicitHeight

	readonly property bool available: !!(Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio)

	opacity: active ? 1 : 0
	visible: active || opacity > 0

	Behavior on opacity {
		NumberAnimation {
			duration: active ? 150 : 250
			easing.type: active ? Easing.OutCubic : Easing.InCubic
		}
	}

	function clamp01(value) {
		return Math.max(0, Math.min(1, value))
	}

	function showVolume() {
		const sink = Pipewire.defaultAudioSink
		const audio = sink ? sink.audio : null
		if (!audio)
			return

		const raw = audio.volume !== undefined && audio.volume !== null ? audio.volume : 0
		const isMuted = audio.muted !== undefined && audio.muted !== null ? audio.muted : false

		muted = isMuted
		percent = Math.round(raw * 100)
		level = clamp01(raw)
		active = true
		hideTimer.restart()
	}

	readonly property string iconName: {
		if (!available || muted || percent <= 0)
			return "audio-volume-muted-symbolic"
		if (percent < 34)
			return "audio-volume-low-symbolic"
		if (percent < 67)
			return "audio-volume-medium-symbolic"
		return "audio-volume-high-symbolic"
	}

	readonly property string iconGlyph: {
		if (!available || muted || percent <= 0)
			return "󰖁"
		if (percent < 34)
			return "󰕿"
		if (percent < 67)
			return "󰖀"
		return "󰕾"
	}

	PwObjectTracker {
		objects: [Pipewire.defaultAudioSink]
	}

	Connections {
		target: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio : null

		function onVolumeChanged() {
			root.showVolume()
		}

		function onMutedChanged() {
			root.showVolume()
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
		level: root.muted ? 0 : root.level
		percent: root.percent
		accentBackgroundColor: root.muted ? colors.error : colors.primary
	}
}
