pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Caffeine = logind inhibitor for idle+sleep while the process runs.
Singleton {
	id: root

	property bool active: false

	function set(value) {
		active = value;
		Hud.show("caffeine", value ? "coffee" : "bedtime", value ? Settings.caffeineOnMessage : Settings.caffeineOffMessage, false);
	}

	function toggle() {
		set(!active);
	}

	Process {
		running: root.active
		command: ["systemd-inhibit", "--what=idle:sleep", "--who=Notch", "--why=Caffeine mode", "--mode=block", "sleep", "infinity"]
	}
}
