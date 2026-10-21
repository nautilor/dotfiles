pragma Singleton

import QtQuick
import Quickshell

// Catalog of Home dashboard widgets: size limits, default size and the settings each one offers.
// schema kinds: text | bool | choice (options) | number (min, max) | icon
Singleton {
	id: root

	function src(name) {
		return Qt.resolvedUrl("../components/widgets/" + name + ".qml");
	}

	readonly property var types: ({
			"media": {
				title: "Media player",
				icon: "music_note",
				desc: "Now playing with controls (any MPRIS player)",
				source: src("MediaWidget"),
				w: 4, h: 4, minW: 3, minH: 3, maxW: 8, maxH: 6,
				schema: []
			},
			"workspaces": {
				title: "Workspaces",
				icon: "apps",
				desc: "Hyprland workspace switcher",
				source: src("WorkspacesWidget"),
				w: 3, h: 1, minW: 2, minH: 1, maxW: 8, maxH: 1,
				schema: []
			},
			"tray": {
				title: "System tray",
				icon: "tray",
				desc: "Tray icons; right click for the app menu",
				source: src("TrayWidget"),
				w: 1, h: 1, minW: 1, minH: 1, maxW: 4, maxH: 1,
				schema: []
			},
			"toggle": {
				title: "Quick toggle",
				icon: "tune",
				desc: "Wi-Fi, Bluetooth, caffeine, microphone or do not disturb",
				source: src("ToggleWidget"),
				w: 1, h: 1, minW: 1, minH: 1, maxW: 3, maxH: 3,
				schema: [
					{ key: "kind", label: "Toggle", kind: "choice", options: ["wifi", "bluetooth", "caffeine", "mic", "dnd"], def: "wifi" },
					{ key: "label", label: "Label", kind: "text", def: "", placeholder: "Default label" }
				]
			},
			"profile": {
				title: "Power profile",
				icon: "bolt",
				desc: "Saver, Balanced, Performance",
				source: src("ProfileWidget"),
				w: 3, h: 1, minW: 3, minH: 1, maxW: 8, maxH: 1,
				schema: []
			},
			"event": {
				title: "Next event",
				icon: "event",
				desc: "Your next Google Calendar event",
				source: src("EventWidget"),
				w: 4, h: 1, minW: 2, minH: 1, maxW: 8, maxH: 2,
				schema: []
			},
			"clock": {
				title: "Clock",
				icon: "schedule",
				desc: "Time and date",
				source: src("ClockWidget"),
				w: 2, h: 1, minW: 1, minH: 1, maxW: 8, maxH: 3,
				schema: [
					{ key: "showTime", label: "Show time", kind: "bool", def: true },
					{ key: "showSeconds", label: "Show seconds", kind: "bool", def: false },
					{ key: "showDate", label: "Show date", kind: "bool", def: true },
					{ key: "dateFormat", label: "Date format", kind: "text", def: "dddd d MMMM", placeholder: "dddd d MMMM" }
				]
			},
			"battery": {
				title: "Battery",
				icon: "battery_full",
				desc: "Charge level and state",
				source: src("BatteryWidget"),
				w: 2, h: 1, minW: 1, minH: 1, maxW: 4, maxH: 2,
				schema: []
			},
			"slider": {
				title: "Slider",
				icon: "volume_up",
				desc: "Volume or brightness slider",
				source: src("SliderWidget"),
				w: 3, h: 1, minW: 1, minH: 1, maxW: 8, maxH: 4,
				schema: [
					{ key: "kind", label: "Controls", kind: "choice", options: ["volume", "brightness"], def: "volume" }
				]
			},
			"note": {
				title: "Note",
				icon: "notes",
				desc: "A piece of text of your own",
				source: src("NoteWidget"),
				w: 3, h: 2, minW: 1, minH: 1, maxW: 8, maxH: 6,
				schema: [
					{ key: "title", label: "Title", kind: "text", def: "Note" },
					{ key: "text", label: "Text", kind: "text", def: "Write something…" }
				]
			},
			"button": {
				title: "Command button",
				icon: "touch_app",
				desc: "Runs a shell command when pressed",
				source: src("ButtonWidget"),
				w: 1, h: 1, minW: 1, minH: 1, maxW: 4, maxH: 3,
				schema: [
					{ key: "icon", label: "Icon", kind: "icon", def: "rocket" },
					{ key: "label", label: "Label", kind: "text", def: "Run" },
					{ key: "command", label: "Command", kind: "text", def: "", placeholder: "notify-send hello" },
					{ key: "closeOnClick", label: "Close the notch after", kind: "bool", def: false }
				]
			},
			"command": {
				title: "Command output",
				icon: "terminal",
				desc: "Shows the output of a shell command, refreshed on a timer",
				source: src("CommandWidget"),
				w: 2, h: 1, minW: 1, minH: 1, maxW: 8, maxH: 4,
				schema: [
					{ key: "icon", label: "Icon", kind: "icon", def: "terminal" },
					{ key: "label", label: "Label", kind: "text", def: "", placeholder: "Caption" },
					{ key: "command", label: "Command", kind: "text", def: "", placeholder: "uptime -p" },
					{ key: "interval", label: "Refresh (seconds)", kind: "number", def: 10, min: 1, max: 3600, step: 1 },
					{ key: "clickCommand", label: "Command on click", kind: "text", def: "", placeholder: "optional" }
				]
			},
			"qml": {
				title: "QML file",
				icon: "extension",
				desc: "Your own QML widget from ~/.config/quickshell-notch/widgets/",
				source: src("QmlWidget"),
				w: 3, h: 2, minW: 1, minH: 1, maxW: 8, maxH: 6,
				schema: [
					{ key: "file", label: "File name", kind: "text", def: "", placeholder: "Hello.qml" }
				]
			}
		})

	// icons offered when a widget has an icon setting
	readonly property var iconChoices: ["rocket", "terminal", "folder", "language", "link", "mail", "star", "favorite", "photo_camera", "settings", "memory", "ram", "speed", "thermostat", "lightbulb", "headphones", "monitor", "download", "upload", "cloud", "sunny", "timer", "check_circle", "gamepad", "music_note", "lock", "power_settings_new", "restart_alt", "bedtime", "wifi", "bluetooth", "coffee", "home", "search", "refresh", "notes", "event", "dashboard", "widgets", "touch_app"]

	readonly property var order: ["media", "workspaces", "tray", "toggle", "profile", "event", "clock", "battery", "slider", "note", "button", "command", "qml"]

	// config with schema defaults filled in
	function resolve(type, cfg) {
		const out = {};
		const t = types[type];
		if (t)
			for (const f of t.schema)
				out[f.key] = f.def;
		return Object.assign(out, cfg || {});
	}
}
