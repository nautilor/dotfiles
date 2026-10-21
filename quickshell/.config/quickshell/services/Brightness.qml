pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Backlight via brightnessctl. A udev monitor catches changes made by anything (keybinds calling brightnessctl directly).
Singleton {
	id: root

	property real value: 1
	property bool available: false
	property bool armed: false

	function step(percent) {
		setProc.command = ["brightnessctl", "-m", "set", Math.abs(percent) + "%" + (percent > 0 ? "+" : "-")];
		setProc.running = true;
	}

	function setPercent(p) {
		setProc.command = ["brightnessctl", "-m", "set", Math.round(Math.max(1, Math.min(100, p))) + "%"];
		setProc.running = true;
	}

	function parse(text) {
		const f = text.trim().split("\n").pop().split(",");
		if (f.length < 5)
			return false;
		root.available = true;
		root.value = parseInt(f[3]) / 100;
		return true;
	}

	function osd() {
		if (armed)
			Hud.show("brightness", value < 0.5 ? "brightness_5" : "brightness_7", Math.round(value * 100) + "%", false, 1600, value);
	}

	Process {
		id: readProc
		running: true
		command: ["brightnessctl", "-m"]
		stdout: StdioCollector {
			onStreamFinished: {
				const before = root.value;
				if (root.parse(text) && Math.abs(root.value - before) > 0.001)
					root.osd();
			}
		}
	}

	Process {
		id: setProc
		stdout: StdioCollector {
			onStreamFinished: {
				if (root.parse(text))
					root.osd();
			}
		}
	}

	Process {
		running: root.available
		command: ["udevadm", "monitor", "--udev", "--subsystem-match=backlight"]
		stdout: SplitParser {
			onRead: line => {
				if (line.includes("change"))
					readProc.running = true;
			}
		}
	}

	Timer {
		interval: 1500
		running: true
		onTriggered: root.armed = true
	}
}
