import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components

// Now playing card (MPRIS).
Rectangle {
	id: root

	readonly property var player: Media.player

	radius: Theme.radiusLarge
	color: Theme.surfaceContainer

	function fmt(sec) {
		const s = Math.max(0, Math.floor(sec));
		return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
	}

	Timer {
		interval: 500
		running: root.visible && Media.playing
		repeat: true
		onTriggered: root.player.positionChanged()
	}

	// empty state
	Column {
		visible: !root.player
		anchors.centerIn: parent
		spacing: 6
		Icon {
			name: "music_off"
			size: 40
			color: Theme.outline
			anchors.horizontalCenter: parent.horizontalCenter
		}
		Txt {
			text: "Nothing playing"
			color: Theme.surfaceVariantFg
			anchors.horizontalCenter: parent.horizontalCenter
		}
	}

	ColumnLayout {
		visible: root.player !== null
		anchors.fill: parent
		anchors.margins: 14
		spacing: 8

		RowLayout {
			spacing: 12
			Layout.fillWidth: true

			Item {
				id: art
				Layout.preferredWidth: 84
				Layout.preferredHeight: 84

				// expressive: art squares up while paused, rounds off while playing
				property real corner: Media.playing ? 30 : 18
				Behavior on corner {
					SpringAnimation {
						spring: Theme.springSoft
						damping: Theme.dampSoft
						epsilon: 0.25
					}
				}

				Rectangle {
					anchors.fill: parent
					radius: art.corner
					color: Theme.secondaryContainer
					Icon {
						anchors.centerIn: parent
						name: "music_note"
						size: 34
						fill: 1
						color: Theme.secondaryContainerFg
					}
				}
				RoundedImage {
					anchors.fill: parent
					radius: art.corner
					source: root.player ? root.player.trackArtUrl : ""
					visible: status === Image.Ready
				}
			}

			ColumnLayout {
				Layout.fillWidth: true
				spacing: 2
				Txt {
					Layout.fillWidth: true
					text: root.player ? (root.player.trackTitle || "Unknown") : ""
					font.pixelSize: 16
					font.weight: Font.Bold
				}
				Txt {
					Layout.fillWidth: true
					text: root.player ? root.player.trackArtist : ""
					color: Theme.surfaceVariantFg
				}
				Txt {
					Layout.fillWidth: true
					text: root.player ? root.player.identity : ""
					font.pixelSize: 11
					color: Theme.outline
				}
			}
		}

		// progress
		Item {
			Layout.fillWidth: true
			Layout.preferredHeight: 18
			visible: root.player && root.player.lengthSupported

			Rectangle {
				id: track
				anchors.verticalCenter: parent.verticalCenter
				width: parent.width
				height: seek.pressed ? 10 : 6
				radius: height / 2
				color: Theme.surfaceContainerHighest
				Behavior on height {
					NumberAnimation {
						duration: Theme.durShort
					}
				}
				Rectangle {
					width: root.player && root.player.length > 0 ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
					height: parent.height
					radius: height / 2
					color: Theme.primary
				}
			}
			MouseArea {
				id: seek
				anchors.fill: parent
				enabled: root.player && root.player.canSeek
				onPressed: mouse => root.player.position = root.player.length * Math.max(0, Math.min(1, mouse.x / width))
				onPositionChanged: mouse => root.player.position = root.player.length * Math.max(0, Math.min(1, mouse.x / width))
			}
		}

		RowLayout {
			Layout.fillWidth: true
			spacing: 6
			Txt {
				text: root.player ? root.fmt(root.player.position) : ""
				font.pixelSize: 11
				color: Theme.outline
			}
			Item {
				Layout.fillWidth: true
			}
			Btn {
				icon: "skip_previous"
				variant: 2
				iconSize: 26
				implicitWidth: 44
				implicitHeight: 40
				enabled: root.player && root.player.canGoPrevious
				onClicked: root.player.previous()
			}
			Btn {
				icon: Media.playing ? "pause" : "play_arrow"
				variant: 1
				toggleable: true
				toggled: Media.playing
				toggledRadius: 14
				iconSize: 28
				implicitWidth: 64
				implicitHeight: 44
				onClicked: root.player.togglePlaying()
			}
			Btn {
				icon: "skip_next"
				variant: 2
				iconSize: 26
				implicitWidth: 44
				implicitHeight: 40
				enabled: root.player && root.player.canGoNext
				onClicked: root.player.next()
			}
			Item {
				Layout.fillWidth: true
			}
			Txt {
				text: root.player && root.player.lengthSupported ? root.fmt(root.player.length) : ""
				font.pixelSize: 11
				color: Theme.outline
			}
		}
	}
}
