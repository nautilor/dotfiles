import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// One-row now-playing pill: art, title / artist, play and skip buttons.
Rectangle {
	id: root

	readonly property var player: Media.player

	radius: Math.min(height / 2, 24)
	color: Theme.surfaceContainer
	clip: true

	RowLayout {
		anchors.fill: parent
		anchors.leftMargin: 8
		anchors.rightMargin: 8
		spacing: 10

		Item {
			Layout.preferredWidth: root.height - 14
			Layout.preferredHeight: root.height - 14
			Rectangle {
				anchors.fill: parent
				radius: Media.playing ? width / 2 : 10
				color: Theme.secondaryContainer
				Behavior on radius {
					NumberAnimation {
						duration: Theme.durMedium
					}
				}
				Icon {
					anchors.centerIn: parent
					name: root.player ? "music_note" : "music_off"
					size: 18
					fill: 1
					color: Theme.secondaryContainerFg
				}
			}
			RoundedImage {
				anchors.fill: parent
				radius: Media.playing ? width / 2 : 10
				source: root.player ? root.player.trackArtUrl : ""
				visible: status === Image.Ready
			}
		}

		ColumnLayout {
			Layout.fillWidth: true
			spacing: 0
			Txt {
				Layout.fillWidth: true
				text: root.player ? (root.player.trackTitle || "Unknown") : "Nothing playing"
				font.weight: Font.Bold
			}
			Txt {
				Layout.fillWidth: true
				visible: root.player !== null
				text: root.player ? root.player.trackArtist : ""
				font.pixelSize: 11
				color: Theme.surfaceVariantFg
			}
		}

		Btn {
			icon: "skip_previous"
			variant: 2
			iconSize: 20
			implicitWidth: 34
			implicitHeight: 34
			enabled: root.player && root.player.canGoPrevious
			onClicked: root.player.previous()
		}
		Btn {
			icon: Media.playing ? "pause" : "play_arrow"
			variant: 1
			toggleable: true
			toggled: Media.playing
			toggledRadius: 12
			iconSize: 20
			implicitWidth: 40
			implicitHeight: 34
			enabled: root.player !== null
			onClicked: root.player.togglePlaying()
		}
		Btn {
			icon: "skip_next"
			variant: 2
			iconSize: 20
			implicitWidth: 34
			implicitHeight: 34
			enabled: root.player && root.player.canGoNext
			onClicked: root.player.next()
		}
	}
}
