pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import qs.config

// State of the lock screen and the PAM conversation that unlocks it.
Singleton {
	id: root

	property bool locked: false
	// what the user has typed so far; shared by every screen's surface
	property string buffer: ""
	property bool busy: false
	property string error: ""
	// bumped on every wrong password, so the UI can shake
	property int failures: 0

	readonly property string user: Quickshell.env("USER")
	property string fullName: user

	property string pending: ""

	function lock() {
		if (locked)
			return;
		buffer = "";
		error = "";
		busy = false;
		locked = true;
	}

	function submit() {
		if (busy || buffer === "")
			return;
		error = "";
		pending = buffer;
		busy = true;
		if (!pam.start()) {
			busy = false;
			error = "Could not start authentication";
		}
	}

	PamContext {
		id: pam
		config: Settings.lockPam
		configDirectory: Settings.lockPamDir !== "" ? Settings.lockPamDir : "/etc/pam.d"
		user: root.user

		onPamMessage: {
			if (responseRequired)
				respond(root.pending);
		}
		onCompleted: result => {
			root.busy = false;
			root.pending = "";
			root.buffer = "";
			if (result === PamResult.Success) {
				root.error = "";
				root.locked = false;
			} else {
				root.failures++;
				root.error = result === PamResult.MaxTries ? "Too many attempts. Try again in a moment." : "Wrong password";
			}
		}
		onError: err => {
			root.busy = false;
			root.pending = "";
			root.buffer = "";
			root.error = "Authentication service \"" + Settings.lockPam + "\" is not usable (" + PamError.toString(err) + ")";
		}
	}

	// real name for the greeting
	Process {
		running: true
		command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1"]
		stdout: StdioCollector {
			onStreamFinished: {
				const n = text.trim();
				if (n !== "")
					root.fullName = n;
			}
		}
	}
}
