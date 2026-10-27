import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// Home layout "Strip": one wide row, in the spirit of a dock bar.
// Player, week and clock, connectivity / tray / power profile / next event, volume.
Item {
	id: root

	readonly property var player: Media.player
	property date now: new Date()

	function fmt(sec) {
		const s = Math.max(0, Math.floor(sec));
		return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
	}

	// the seven days of the current week, starting on Monday or Sunday
	readonly property var week: {
		const d = new Date(now.getFullYear(), now.getMonth(), now.getDate());
		const back = (d.getDay() - (Settings.weekStartsMonday ? 1 : 0) + 7) % 7;
		const out = [];
		for (let i = 0; i < 7; i++)
			out.push(new Date(d.getFullYear(), d.getMonth(), d.getDate() - back + i));
		return out;
	}

	Timer {
		interval: 10000
		running: root.visible
		repeat: true
		triggeredOnStart: true
		onTriggered: root.now = new Date()
	}
	Timer {
		interval: 500
		running: root.visible && Media.playing
		repeat: true
		onTriggered: root.player.positionChanged()
	}

	Rectangle {
		anchors.fill: parent
		radius: Theme.radiusLarge
		color: Theme.surfaceContainer
	}

	RowLayout {
		anchors.fill: parent
		anchors.margins: 14
		spacing: 14

		// ---- player ----
		RowLayout {
			Layout.fillHeight: true
			Layout.preferredWidth: 230
			spacing: 12

			Item {
				id: art
				Layout.preferredWidth: 88
				Layout.preferredHeight: 88
				Layout.alignment: Qt.AlignVCenter
				property real corner: Media.playing ? 36 : 22
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
						name: root.player ? "music_note" : "music_off"
						size: 36
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
				Layout.fillHeight: true
				spacing: 2
				Item {
					Layout.fillHeight: true
				}
				Txt {
					Layout.fillWidth: true
					text: root.player ? (root.player.trackTitle || "Unknown") : "Nothing playing"
					font.pixelSize: 15
					font.weight: Font.Bold
				}
				Txt {
					Layout.fillWidth: true
					visible: root.player !== null
					text: root.player ? root.player.trackArtist : ""
					color: Theme.surfaceVariantFg
				}
				RowLayout {
					Layout.topMargin: 4
					spacing: 2
					Btn {
						icon: "skip_previous"
						variant: 2
						iconSize: 22
						implicitWidth: 38
						implicitHeight: 36
						enabled: root.player && root.player.canGoPrevious
						onClicked: root.player.previous()
					}
					Btn {
						icon: Media.playing ? "pause" : "play_arrow"
						variant: 1
						toggleable: true
						toggled: Media.playing
						toggledRadius: 12
						iconSize: 22
						implicitWidth: 48
						implicitHeight: 36
						enabled: root.player !== null
						onClicked: root.player.togglePlaying()
					}
					Btn {
						icon: "skip_next"
						variant: 2
						iconSize: 22
						implicitWidth: 38
						implicitHeight: 36
						enabled: root.player && root.player.canGoNext
						onClicked: root.player.next()
					}
				}
				RowLayout {
					Layout.fillWidth: true
					spacing: 6
					visible: root.player && root.player.lengthSupported
					Txt {
						text: root.player ? root.fmt(root.player.position) : ""
						font.pixelSize: 10
						color: Theme.outline
					}
					Item {
						Layout.fillWidth: true
						Layout.preferredHeight: 14
						Rectangle {
							anchors.verticalCenter: parent.verticalCenter
							width: parent.width
							height: seek.pressed ? 8 : 4
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
							onPressed: m => root.player.position = root.player.length * Math.max(0, Math.min(1, m.x / width))
							onPositionChanged: m => root.player.position = root.player.length * Math.max(0, Math.min(1, m.x / width))
						}
					}
					Txt {
						text: root.player ? root.fmt(root.player.length) : ""
						font.pixelSize: 10
						color: Theme.outline
					}
				}
				Item {
					Layout.fillHeight: true
				}
			}
		}

		Rectangle {
			Layout.fillHeight: true
			Layout.topMargin: 10
			Layout.bottomMargin: 10
			width: 1
			color: Theme.outlineVariant
		}

		// ---- month, clock, week ----
		ColumnLayout {
			Layout.fillHeight: true
			Layout.fillWidth: true
			spacing: 6
			Item {
				Layout.fillHeight: true
			}
			RowLayout {
				Layout.fillWidth: true
				Txt {
					text: Qt.formatDate(root.now, "MMMM")
					font.pixelSize: 18
					font.weight: Font.Bold
				}
				Item {
					Layout.fillWidth: true
				}
				Txt {
					text: Qt.formatTime(root.now, Settings.use24h ? "HH:mm" : "h:mm AP")
					font.pixelSize: 18
					font.weight: Font.Bold
					elide: Text.ElideNone
				}
			}
			RowLayout {
				Layout.fillWidth: true
				spacing: 0
				Repeater {
					model: root.week
					Item {
						id: day
						required property date modelData
						readonly property bool today: modelData.getDate() === root.now.getDate() && modelData.getMonth() === root.now.getMonth()
						readonly property bool weekend: modelData.getDay() === 0 || modelData.getDay() === 6
						Layout.fillWidth: true
						Layout.preferredWidth: 1
						Layout.preferredHeight: 60
						Rectangle {
							anchors.centerIn: parent
							width: Math.min(parent.width - 2, 32)
							height: parent.height
							radius: width / 2
							color: day.today ? Theme.primary : "transparent"
						}
						Column {
							anchors.centerIn: parent
							spacing: 6
							Txt {
								anchors.horizontalCenter: parent.horizontalCenter
								text: Qt.formatDate(day.modelData, "ddd").charAt(0)
								font.pixelSize: 10
								elide: Text.ElideNone
								color: day.today ? Theme.primaryFg : Theme.outline
							}
							Txt {
								anchors.horizontalCenter: parent.horizontalCenter
								text: day.modelData.getDate()
								font.pixelSize: 13
								font.weight: day.today ? Font.Bold : Font.Normal
								elide: Text.ElideNone
								color: day.today ? Theme.primaryFg : day.weekend ? Theme.tertiary : Theme.surfaceFg
							}
						}
					}
				}
			}
			Item {
				Layout.fillHeight: true
			}
		}

		Rectangle {
			Layout.fillHeight: true
			Layout.topMargin: 10
			Layout.bottomMargin: 10
			width: 1
			color: Theme.outlineVariant
		}

		// ---- connectivity, tray, power profile, next event ----
		ColumnLayout {
			Layout.fillHeight: true
			Layout.preferredWidth: 230
			spacing: 6

			RowLayout {
				Layout.fillWidth: true
				spacing: 6
				Btn {
					icon: Toggles.icon("wifi")
					toggleable: true
					toggled: Toggles.on("wifi")
					toggledRadius: 14
					implicitWidth: 40
					implicitHeight: 40
					onClicked: Toggles.toggle("wifi")
				}
				Btn {
					icon: Toggles.icon("bluetooth")
					toggleable: true
					toggled: Toggles.on("bluetooth")
					toggledRadius: 14
					implicitWidth: 40
					implicitHeight: 40
					onClicked: Toggles.toggle("bluetooth")
				}
				TrayPill {
					Layout.fillWidth: true
					Layout.preferredHeight: 40
				}
			}
			ProfileSwitch {
				Layout.fillWidth: true
				Layout.preferredHeight: 40
			}
			EventCard {
				Layout.fillWidth: true
				Layout.fillHeight: true
			}
		}

		Rectangle {
			Layout.fillHeight: true
			Layout.topMargin: 10
			Layout.bottomMargin: 10
			width: 1
			color: Theme.outlineVariant
		}

		// ---- volume, mic, settings ----
		RowLayout {
			Layout.fillHeight: true
			spacing: 8

			SliderBar {
				Layout.fillHeight: true
				Layout.preferredWidth: 44
				kind: "volume"
			}
			ColumnLayout {
				Layout.fillHeight: true
				spacing: 0
				Btn {
					icon: Mic.muted ? "mic_off" : "mic"
					toggleable: true
					toggled: !Mic.muted
					toggledRadius: 14
					implicitWidth: 40
					implicitHeight: 40
					onClicked: Mic.toggle()
				}
				Item {
					Layout.fillHeight: true
				}
				Btn {
					icon: Settings.dnd ? "notifications_off" : "notifications_active"
					toggleable: true
					toggled: Settings.dnd
					toggledRadius: 14
					implicitWidth: 40
					implicitHeight: 40
					onClicked: Settings.dnd = !Settings.dnd
				}
				Item {
					Layout.fillHeight: true
				}
				Btn {
					icon: "coffee"
					toggleable: true
					toggled: Caffeine.active
					toggledRadius: 14
					implicitWidth: 40
					implicitHeight: 40
					onClicked: Caffeine.toggle()
				}
			}
		}
	}
}
