pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default output volume. Any change (our IPC, wpctl, hardware keys) shows the OSD slider.
Singleton {
	id: root

	readonly property var sink: Pipewire.defaultAudioSink
	readonly property bool available: sink !== null && sink.audio !== null
	readonly property real volume: available ? sink.audio.volume : 0
	readonly property bool muted: available ? sink.audio.muted : false
	property bool armed: false

	PwObjectTracker {
		objects: root.sink ? [root.sink] : []
	}

	function step(delta) {
		if (!available)
			return;
		sink.audio.muted = false;
		sink.audio.volume = Math.max(0, Math.min(1, volume + delta));
	}

	function setVolume(v) {
		if (!available)
			return;
		sink.audio.muted = false;
		sink.audio.volume = Math.max(0, Math.min(1, v));
	}

	function toggleMute() {
		if (available)
			sink.audio.muted = !sink.audio.muted;
	}

	function icon() {
		if (muted || volume <= 0)
			return "volume_off";
		return volume < 0.34 ? "volume_mute" : volume < 0.67 ? "volume_down" : "volume_up";
	}

	function osd() {
		if (armed)
			Hud.show("volume", icon(), muted ? "Muted" : Math.round(volume * 100) + "%", muted, 1600, muted ? 0 : volume);
	}

	onVolumeChanged: osd()
	onMutedChanged: osd()

	Timer {
		interval: 2000
		running: true
		onTriggered: root.armed = true
	}
}
