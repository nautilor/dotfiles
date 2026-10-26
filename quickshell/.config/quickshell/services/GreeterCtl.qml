pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import qs.config

// State and greetd conversation of the login screen (greeter.qml).
Singleton {
	id: root

	// ---- configuration: /etc/quickshell-notch/greeter.json, or the file named by $QS_GREETER_CONFIG ----
	readonly property string configPath: Quickshell.env("QS_GREETER_CONFIG") || "/etc/quickshell-notch/greeter.json"
	readonly property string statePath: Quickshell.env("QS_GREETER_STATE") || "/var/cache/quickshell-notch/state.json"
	property var config: ({})
	readonly property string wallpaper: config.wallpaper || ""

	// ---- users and sessions ----
	// [{name, full}]
	property var users: []
	// [{name, command}]
	property var sessions: [{ name: "Hyprland", command: "start-hyprland" }]
	property string user: ""
	property int sessionIndex: 0
	readonly property var session: sessions[Math.min(sessionIndex, sessions.length - 1)]
	readonly property string fullName: {
		const u = users.find(x => x.name === user);
		return u && u.full ? u.full : user;
	}
	readonly property string avatar: {
		const a = config.avatars || {};
		return a[user] || "/var/lib/AccountsService/icons/" + user;
	}

	// ---- authentication ----
	property string buffer: ""
	property bool busy: false
	property string error: ""
	property string prompt: "Password"
	property int failures: 0
	property bool awaiting: false
	property string pending: ""
	property bool hasPending: false

	function selectUser(name) {
		if (busy)
			return;
		user = name;
		reset();
	}

	function nextSession() {
		sessionIndex = (sessionIndex + 1) % sessions.length;
	}

	function reset() {
		buffer = "";
		error = "";
		prompt = "Password";
		awaiting = false;
		hasPending = false;
		if (Greetd.state !== GreetdState.Inactive)
			Greetd.cancelSession();
	}

	function submit() {
		if (busy || user === "" || !Greetd.available)
			return;
		error = "";
		if (awaiting) {
			awaiting = false;
			busy = true;
			Greetd.respond(buffer);
			buffer = "";
		} else if (buffer !== "") {
			pending = buffer;
			hasPending = true;
			buffer = "";
			busy = true;
			Greetd.createSession(user);
		}
	}

	Connections {
		target: Greetd

		function onAuthMessage(message, isError, responseRequired, echoResponse) {
			if (!responseRequired) {
				// informational ("Place your finger"): show it, keep going
				if (isError)
					root.error = message;
				return;
			}
			if (root.hasPending) {
				root.hasPending = false;
				Greetd.respond(root.pending);
				root.pending = "";
			} else {
				// a further question (one-time code...): ask the user
				root.prompt = message.replace(/:\s*$/, "");
				root.busy = false;
				root.awaiting = true;
			}
		}
		function onAuthFailure(message) {
			root.busy = false;
			root.pending = "";
			root.hasPending = false;
			root.buffer = "";
			root.failures++;
			root.error = message !== "" ? message : "Wrong password";
			root.prompt = "Password";
			root.awaiting = false;
			Greetd.cancelSession();
		}
		function onReadyToLaunch() {
			root.saveState();
			const env = (root.config.env || ["XDG_SESSION_TYPE=wayland"]).slice();
			// greetd joins the argument list with spaces and runs it as `/bin/sh -c "<profile>; exec <args>"`,
			// so the whole command goes in as ONE argument that is already shell syntax. Its output is
			// written to a file in the user's home so a failing session can be diagnosed.
			const inner = "mkdir -p \"$HOME/.cache\"; exec " + root.session.command + " >\"$HOME/.cache/quickshell-notch-session.log\" 2>&1";
			Greetd.launch(["sh -c '" + inner.replace(/'/g, "'\\''") + "'"], env, true);
		}
		function onError(message) {
			root.busy = false;
			root.hasPending = false;
			root.pending = "";
			root.buffer = "";
			root.error = message;
			if (Greetd.state !== GreetdState.Inactive)
				Greetd.cancelSession();
		}
	}

	// ---- remembering the last user and session ----
	function saveState() {
		const json = JSON.stringify({ user: user, session: session.name });
		Quickshell.execDetached(["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "sh", statePath, json]);
	}

	function applyDefaults() {
		const st = state || {};
		const wantUser = st.user || config.user || "";
		if (user === "") {
			if (users.find(u => u.name === wantUser))
				user = wantUser;
			else if (users.length > 0)
				user = users[0].name;
			else if (wantUser !== "")
				user = wantUser;
		}
		const wantSession = st.session || config.session || "";
		const i = sessions.findIndex(s => s.name === wantSession);
		if (i >= 0)
			sessionIndex = i;
	}

	property var state: ({})

	FileView {
		path: root.configPath
		onLoaded: {
			try {
				root.config = JSON.parse(text());
			} catch (e) {
				console.warn("greeter.json: " + e);
			}
			if (root.config.hue !== undefined)
				Settings.hue = root.config.hue;
			if (root.config.colorscheme !== undefined)
				Settings.colorscheme = root.config.colorscheme;
			if (root.config.use24h !== undefined)
				Settings.use24h = root.config.use24h;
			if (Array.isArray(root.config.sessions) && root.config.sessions.length > 0)
				root.sessions = root.config.sessions;
			root.applyDefaults();
		}
	}

	FileView {
		path: root.statePath
		onLoaded: {
			try {
				root.state = JSON.parse(text());
			} catch (e) {}
			root.applyDefaults();
		}
	}

	// real users: uid 1000-59999 with a login shell
	Process {
		running: true
		command: ["sh", "-c", "getent passwd | awk -F: '$3>=1000 && $3<60000 && $7 !~ /(nologin|false)$/ {split($5,a,\",\"); print $1 \"|\" a[1]}'"]
		stdout: StdioCollector {
			onStreamFinished: {
				root.users = text.trim().split("\n").filter(l => l !== "").map(l => {
					const p = l.split("|");
					return { name: p[0], full: p[1] || "" };
				});
				root.applyDefaults();
			}
		}
	}

	// installed Wayland sessions
	Process {
		running: true
		command: ["sh", "-c", "for d in $(echo \"$XDG_DATA_DIRS\" | tr ':' ' ') /run/current-system/sw/share /usr/local/share /usr/share; do for f in \"$d\"/wayland-sessions/*.desktop; do [ -f \"$f\" ] || continue; n=$(sed -n 's/^Name=//p' \"$f\" | head -1); e=$(sed -n 's/^Exec=//p' \"$f\" | head -1); echo \"$n|$e\"; done; done | awk '!seen[$0]++'"]
		stdout: StdioCollector {
			onStreamFinished: {
				const list = text.trim().split("\n").filter(l => l.includes("|")).map(l => {
					const i = l.indexOf("|");
					return { name: l.slice(0, i), command: l.slice(i + 1) };
				});
				if (list.length > 0 && !(Array.isArray(root.config.sessions) && root.config.sessions.length > 0))
					root.sessions = list;
				root.applyDefaults();
			}
		}
	}
}
