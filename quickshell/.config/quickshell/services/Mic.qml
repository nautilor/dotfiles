pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.config

// Default microphone mute state. Also reacts to mute changes made elsewhere (hardware key, wpctl...).
Singleton {
	id: root

	readonly property var node: Pipewire.defaultAudioSource
	readonly property bool available: node !== null && node.audio !== null
	readonly property bool muted: available ? node.audio.muted : false
	property bool armed: false

	PwObjectTracker {
		objects: root.node ? [root.node] : []
	}

	function toggle() {
		if (available)
			node.audio.muted = !node.audio.muted;
	}

	onMutedChanged: {
		if (armed)
			Hud.show("mic", muted ? "mic_off" : "mic", muted ? Settings.micOffMessage : Settings.micOnMessage, muted);
	}

	Timer {
		interval: 2000
		running: true
		onTriggered: root.armed = true
	}
}
