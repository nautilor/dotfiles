import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components

// Idle notch: workspace chip + media on the left, status indicators on the right.
Item {
	id: root

	readonly property real gap: Settings.showClock ? Math.max(90, clock.implicitWidth + 28) : 90
	implicitWidth: left.implicitWidth + right.implicitWidth + gap + 20
	implicitHeight: 34

	readonly property var workspace: Hyprland.focusedWorkspace
	readonly property var player: Media.player

	Txt {
		id: clock
		property date now: new Date()
		visible: Settings.showClock
		anchors.centerIn: parent
		text: Qt.formatTime(now, Settings.use24h ? "HH:mm" : "h:mm AP")
		font.pixelSize: 13
		font.weight: Font.Medium
		elide: Text.ElideNone
		Timer {
			interval: 5000
			running: Settings.showClock && root.visible
			repeat: true
			triggeredOnStart: true
			onTriggered: clock.now = new Date()
		}
	}

	Row {
		id: left
		anchors.left: parent.left
		anchors.verticalCenter: parent.verticalCenter
		spacing: 8

		Rectangle {
			id: chip
			width: Math.max(24, wsText.implicitWidth + 14)
			height: 24
			radius: 8
			color: Theme.primaryContainer
			anchors.verticalCenter: parent.verticalCenter

			Txt {
				id: wsText
				anchors.centerIn: parent
				text: root.workspace ? (root.workspace.name || root.workspace.id) : "–"
				color: Theme.primaryContainerFg
				font.pixelSize: 13
				font.weight: Font.Bold
			}

			// bump on workspace change
			Connections {
				target: Hyprland
				function onFocusedWorkspaceChanged() {
					bump.restart();
				}
			}
			SequentialAnimation {
				id: bump
				NumberAnimation {
					target: chip
					property: "scale"
					to: 0.7
					duration: 70
				}
				NumberAnimation {
					target: chip
					property: "scale"
					to: 1
					duration: 380
					easing.type: Easing.OutBack
					easing.overshoot: 3
				}
			}
		}

		RoundedImage {
			visible: Media.playing && source != ""
			width: 24
			height: 24
			radius: 8
			anchors.verticalCenter: parent.verticalCenter
			source: root.player ? root.player.trackArtUrl : ""
		}
	}

	Row {
		id: right
		anchors.right: parent.right
		anchors.verticalCenter: parent.verticalCenter
		spacing: 8

		Icon {
			visible: Caffeine.active
			name: "coffee"
			size: 18
			fill: 1
			color: Theme.tertiary
			anchors.verticalCenter: parent.verticalCenter
		}
		Icon {
			visible: Mic.muted
			name: "mic_off"
			size: 18
			fill: 1
			color: Theme.error
			anchors.verticalCenter: parent.verticalCenter
		}
		Icon {
			visible: Settings.dnd
			name: "notifications_off"
			size: 18
			fill: 1
			color: Theme.surfaceVariantFg
			anchors.verticalCenter: parent.verticalCenter
		}
		Rectangle {
			visible: Notifs.count > 0
			width: Math.max(18, countText.implicitWidth + 10)
			height: 18
			radius: 9
			color: Theme.tertiaryContainer
			anchors.verticalCenter: parent.verticalCenter
			Txt {
				id: countText
				anchors.centerIn: parent
				text: Notifs.count
				font.pixelSize: 11
				font.weight: Font.Bold
				color: Theme.tertiaryContainerFg
			}
		}
		Visualizer {
			visible: Media.playing
			active: Media.playing
			anchors.verticalCenter: parent.verticalCenter
		}
		Row {
			visible: Battery.present
			spacing: 2
			anchors.verticalCenter: parent.verticalCenter
			Icon {
				name: Battery.icon
				size: 18
				fill: 1
				color: Battery.percent <= 15 && !Battery.charging ? Theme.error : Theme.surfaceVariantFg
				anchors.verticalCenter: parent.verticalCenter
			}
		}
	}
}
