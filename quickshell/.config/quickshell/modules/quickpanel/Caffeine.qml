import Quickshell
import QtQuick
import Quickshell.Io

Item {
	id: root

	readonly property bool active:
	caffeineState === "active"

	property string caffeineState: "inactive"

	// ─────────────────────────────────────────────
	// Status
	// ─────────────────────────────────────────────

	Process {
		id: statusProcess

		command: [
			"bash",
			"-lc",
			'bash "$HOME/.config/quickshell/bin/caffeine.sh" state'
		]

		stdout: StdioCollector {
			onStreamFinished: {
				const state = this.text.trim()

				if (state === "active" || state === "inactive")
				root.caffeineState = state
			}
		}
	}

	// ─────────────────────────────────────────────
	// Toggle
	// ─────────────────────────────────────────────

	Process {
		id: toggleProcess

		command: [
			"bash",
			"-lc",
			'bash "$HOME/.config/quickshell/bin/caffeine.sh" toggle'
		]

		onRunningChanged: {
			if (!running)
			statusProcess.running = true
		}
	}

	// ─────────────────────────────────────────────
	// Periodic state refresh
	// ─────────────────────────────────────────────

	Timer {
		interval: 2000
		running: true
		repeat: true
		triggeredOnStart: true

		onTriggered: {
			if (!statusProcess.running && !toggleProcess.running)
			statusProcess.running = true
		}
	}

	// ─────────────────────────────────────────────
	// Quick Toggle
	// ─────────────────────────────────────────────

	QuickToggle {
		id: toggle

		anchors.fill: parent

		checked: root.active

		activeIcon: "󰅶"
		inactiveIcon: "󰅶"

		label: "Caffeine"

		subLabel: root.active
		? "On"
		: "Off"

		onToggled: {
			if (!toggleProcess.running)
			toggleProcess.running = true
		}
	}
}
