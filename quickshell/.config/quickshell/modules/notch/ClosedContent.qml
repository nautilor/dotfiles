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

	// both sides get the width of the wider one, so the centre text sits in the middle of a gap that never overlaps the icons
	readonly property real side: Math.max(left.implicitWidth, right.implicitWidth)
	readonly property bool showCenter: Settings.showClock || Settings.showDate
	readonly property real gap: showCenter ? Math.max(90, center.implicitWidth + 36) : 90
	implicitWidth: 2 * side + gap + 20
	implicitHeight: 34

	readonly property var workspace: Hyprland.focusedWorkspace
	readonly property var player: Media.player

	Txt {
		id: center
		property date now: new Date()
		readonly property string dateText: Qt.formatDate(now, "ddd d MMM")
		readonly property string timeText: Qt.formatTime(now, Settings.use24h ? "HH:mm" : "h:mm AP")
		visible: root.showCenter
		anchors.centerIn: parent
		text: Settings.showDate && Settings.showClock ? dateText + "  " + timeText : Settings.showDate ? dateText : timeText
		font.pixelSize: 13
		font.weight: Font.Medium
		elide: Text.ElideNone
		Timer {
			interval: 5000
			running: root.showCenter && root.visible
			repeat: true
			triggeredOnStart: true
			onTriggered: center.now = new Date()
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
				color: Battery.color
				anchors.verticalCenter: parent.verticalCenter
			}
			Txt {
				visible: Settings.showBattery
				text: Battery.percent + "%"
				font.pixelSize: 12
				font.weight: Font.Medium
				color: Battery.color
				elide: Text.ElideNone
				anchors.verticalCenter: parent.verticalCenter
			}
		}
	}
}
