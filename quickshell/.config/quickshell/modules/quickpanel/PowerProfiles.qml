import Quickshell
import QtQuick
import Quickshell.Io

Item {
	id: root

	// ─────────────────────────────────────────────
	// State
	// ─────────────────────────────────────────────

	property string profile: "balanced"

	readonly property string profileLabel: {
		switch (root.profile) {
			case "performance":
			return "Performance"

			case "power-saver":
			return "Power Saver"

			case "balanced":
			default:
			return "Balanced"
		}
	}

	readonly property string profileIcon: {
		switch (root.profile) {
			case "performance":
			return "󰈸"

			case "power-saver":
			return "󰌪"

			case "balanced":
			default:
			return "󰗑"
		}
	}

	// ─────────────────────────────────────────────
	// Status
	// ─────────────────────────────────────────────

	Process {
		id: statusProcess

		command: [
			"powerprofilesctl",
			"get"
		]

		stdout: StdioCollector {
			onStreamFinished: {
				const value = this.text.trim()

				if (
					value === "performance"
					|| value === "balanced"
					|| value === "power-saver"
				) {
					root.profile = value
				}
			}
		}
	}

	// ─────────────────────────────────────────────
	// Change profile
	// ─────────────────────────────────────────────

	Process {
		id: setProfileProcess

		property string targetProfile: ""

		command: [
			"powerprofilesctl",
			"set",
			targetProfile
		]

		onRunningChanged: {
			if (!running)
			statusProcess.running = true
		}
	}

	// ─────────────────────────────────────────────
	// Cycle profiles
	// ─────────────────────────────────────────────

	function cycleProfile() {
		let nextProfile

		switch (root.profile) {
			case "balanced":
			nextProfile = "performance"
			break

			case "performance":
			nextProfile = "power-saver"
			break

			case "power-saver":
			default:
			nextProfile = "balanced"
			break
		}

		if (setProfileProcess.running)
		return

		setProfileProcess.targetProfile = nextProfile
		setProfileProcess.running = true
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
			if (
				!statusProcess.running
				&& !setProfileProcess.running
			) {
				statusProcess.running = true
			}
		}
	}

	// ─────────────────────────────────────────────
	// Quick Toggle
	// ─────────────────────────────────────────────

	QuickToggle {
		id: toggle

		anchors.fill: parent

		checked: root.profile !== "power-saver"

		activeIcon: root.profileIcon
		inactiveIcon: root.profileIcon

		label: "Power Profile"

		subLabel: root.profileLabel

		onToggled: {
			root.cycleProfile()
		}
	}
}
