pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Colour schemes: JSON files from the bundled colorschemes/ folder and from
// ~/.config/quickshell-notch/colorschemes/ (user files win on the same file name).
// A scheme needs "background", "foreground" and "primary"; "secondary", "tertiary",
// "error", "name" and any Theme role (e.g. "surfaceContainer") are optional.
Singleton {
	id: root

	readonly property string bundledDir: Quickshell.shellDir + "/colorschemes"
	readonly property string userDir: Settings.configDir + "/colorschemes"

	// [{id, name, preview: [color x4], palette: {role: color}}]
	property var schemes: []
	readonly property var current: schemes.find(s => s.id === Settings.colorscheme) ?? null
	readonly property var palette: current ? current.palette : null

	function reload() {
		if (!loader.running)
			loader.running = true;
	}

	function mix(a, b, t) {
		return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
	}

	function luminance(c) {
		return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
	}

	function build(id, json) {
		const bg = Qt.color(json.background);
		const fg = Qt.color(json.foreground);
		const primary = Qt.color(json.primary);
		const secondary = json.secondary ? Qt.color(json.secondary) : mix(primary, fg, 0.5);
		const tertiary = json.tertiary ? Qt.color(json.tertiary) : mix(primary, secondary, 0.5);
		const error = json.error ? Qt.color(json.error) : Qt.color("#f2b8b5");
		const on = c => luminance(c) > 0.5 ? bg : fg;
		const p = {
			notch: bg,
			surfaceContainerLow: mix(bg, fg, 0.04),
			surfaceContainer: mix(bg, fg, 0.07),
			surfaceContainerHigh: mix(bg, fg, 0.11),
			surfaceContainerHighest: mix(bg, fg, 0.15),
			primary: primary,
			primaryFg: on(primary),
			primaryContainer: mix(bg, primary, 0.3),
			primaryContainerFg: mix(primary, fg, 0.75),
			secondaryContainer: mix(bg, secondary, 0.22),
			secondaryContainerFg: mix(secondary, fg, 0.75),
			tertiary: tertiary,
			tertiaryFg: on(tertiary),
			tertiaryContainer: mix(bg, tertiary, 0.28),
			tertiaryContainerFg: mix(tertiary, fg, 0.75),
			error: error,
			errorFg: on(error),
			errorContainer: mix(bg, error, 0.35),
			errorContainerFg: mix(error, fg, 0.75),
			surfaceFg: fg,
			surfaceVariantFg: mix(fg, bg, 0.25),
			outline: mix(bg, fg, 0.4),
			outlineVariant: mix(bg, fg, 0.18)
		};
		for (const k in p) {
			if (typeof json[k] === "string")
				p[k] = Qt.color(json[k]);
		}
		return {
			id: id,
			name: json.name || id,
			preview: [p.surfaceContainerHigh, primary, secondary, tertiary],
			palette: p
		};
	}

	Process {
		id: loader
		running: true
		command: ["sh", "-c", "mkdir -p \"$2\"; for f in \"$1\"/*.json \"$2\"/*.json; do [ -f \"$f\" ] || continue; printf '%s\\t' \"$f\"; tr '\\n' ' ' < \"$f\"; echo; done", "sh", root.bundledDir, root.userDir]
		stdout: StdioCollector {
			onStreamFinished: {
				const byId = {};
				for (const line of text.split("\n")) {
					const tab = line.indexOf("\t");
					if (tab < 0)
						continue;
					const file = line.slice(0, tab);
					const id = file.slice(file.lastIndexOf("/") + 1).replace(/\.json$/, "");
					try {
						byId[id] = root.build(id, JSON.parse(line.slice(tab + 1)));
					} catch (e) {
						console.warn("colorscheme " + file + ": " + e);
					}
				}
				root.schemes = Object.values(byId).sort((a, b) => a.name.localeCompare(b.name));
			}
		}
	}
}
