import QtQuick
import QtQuick.Effects
import Quickshell
import qs.config
import qs.services
import qs.components

// Shared look of the lock screen and the login screen: blurred wallpaper, big clock, and a card with
// avatar, name and a password field. The parent owns the state and the authentication.
Item {
	id: root

	property string wallpaper
	property string avatar
	property string name
	property string prompt: "Password"
	// what has been typed; the parent keeps it and updates it from `edited`
	property string buffer
	property bool busy: false
	property string error
	// bumped on every failed attempt: shakes the card
	property int failures: 0
	property bool showPower: true
	// extra rows inside the card, under the password field
	default property alias extra: extraSlot.data

	signal edited(string text)
	signal submitted

	readonly property bool hasWallpaper: wallpaper !== ""
	readonly property bool hasAvatar: avatar !== ""
	readonly property bool keyboardFocused: kb.activeFocus
	// shrink everything on small screens
	readonly property real fit: Math.min(1, height / 820, width / 460)

	function focusInput() {
		kb.forceActiveFocus();
	}

	SystemClock {
		id: clock
		precision: SystemClock.Minutes
	}


	// Typing goes into a real (invisible) password input so the compositor's keyboard focus and the
	// input method work normally. Focus is taken back on click and whenever it is lost, e.g. after resume.
	TextInput {
		id: kb
		width: 1
		height: 1
		opacity: 0
		focus: true
		echoMode: TextInput.Password
		readOnly: root.busy
		Connections {
			target: root
			function onBufferChanged() {
				if (kb.text !== root.buffer)
					kb.text = root.buffer;
			}
		}
		onTextChanged: {
			if (text !== root.buffer)
				root.edited(text);
		}
		Keys.onPressed: event => {
			if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
				root.submitted();
				event.accepted = true;
			} else if (event.key === Qt.Key_Escape) {
				root.edited("");
				event.accepted = true;
			}
		}
		Component.onCompleted: forceActiveFocus()
	}
	Timer {
		interval: 400
		repeat: true
		running: true
		onTriggered: if (!kb.activeFocus)
			kb.forceActiveFocus()
	}
	MouseArea {
		anchors.fill: parent
		onPressed: kb.forceActiveFocus()
	}

	// ---- background ----
	Image {
		id: wall
		anchors.fill: parent
		visible: false
		source: root.hasWallpaper ? "file://" + root.wallpaper : ""
		fillMode: Image.PreserveAspectCrop
		asynchronous: true
		sourceSize.width: root.width
		sourceSize.height: root.height
	}
	MultiEffect {
		anchors.fill: parent
		visible: root.hasWallpaper && wall.status === Image.Ready
		source: wall
		blurEnabled: true
		blurMax: 64
		blur: 1.0
		brightness: 0
		saturation: -0.1
	}
	// tint and darken so text stays readable on any wallpaper
	Rectangle {
		anchors.fill: parent
		color: root.hasWallpaper ? Qt.alpha(Theme.notch, 0.35) : Theme.notch
	}

	// ---- clock ----
	Column {
		id: clockCol
		scale: root.fit
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.verticalCenter: parent.verticalCenter
		anchors.verticalCenterOffset: -parent.height * 0.2
		spacing: 4

		Txt {
			anchors.horizontalCenter: parent.horizontalCenter
			text: Qt.formatTime(clock.date, Settings.use24h ? "HH:mm" : "h:mm")
			font.pixelSize: Math.min(root.height * 0.2, 180)
			font.weight: Font.Light
			color: Theme.surfaceFg
		}
		Txt {
			anchors.horizontalCenter: parent.horizontalCenter
			text: Qt.formatDate(clock.date, "dddd, d MMMM")
			font.pixelSize: 24
			color: Theme.primaryContainerFg
		}
	}

	// ---- card ----
	Rectangle {
		id: card
		width: 400
		height: cardCol.implicitHeight + 48
		radius: Theme.radiusLarge + 8
		color: Qt.alpha(Theme.surfaceContainer, 0.88)
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.top: clockCol.bottom
		anchors.topMargin: 36 * root.fit
		transformOrigin: Item.Top

		property real shake: 0
		scale: root.fit
		transform: Translate {
			x: card.shake
		}
		Connections {
			target: root
			function onFailuresChanged() {
				shakeAnim.restart();
			}
		}
		SequentialAnimation {
			id: shakeAnim
			NumberAnimation { target: card; property: "shake"; to: -18; duration: 55 }
			NumberAnimation { target: card; property: "shake"; to: 16; duration: 80 }
			NumberAnimation { target: card; property: "shake"; to: -10; duration: 70 }
			NumberAnimation { target: card; property: "shake"; to: 6; duration: 60 }
			NumberAnimation { target: card; property: "shake"; to: 0; duration: 50 }
		}

		Column {
			id: cardCol
			anchors.fill: parent
			anchors.margins: 24
			spacing: 16

			// avatar: round, squares up while typing
			Item {
				anchors.horizontalCenter: parent.horizontalCenter
				width: 96
				height: 96
				Rectangle {
					id: avatar
					anchors.fill: parent
					radius: root.busy ? 20 : root.buffer.length > 0 ? 32 : 48
					color: Theme.primaryContainer
					clip: true
					Behavior on radius {
						SpringAnimation {
							spring: Theme.springBouncy
							damping: Theme.dampBouncy
							epsilon: 0.25
						}
					}
					Txt {
						anchors.centerIn: parent
						visible: !root.hasAvatar || avatarImg.status !== Image.Ready
						text: root.name.charAt(0).toUpperCase()
						font.pixelSize: 44
						font.weight: Font.Medium
						color: Theme.primaryContainerFg
					}
					RoundedImage {
						id: avatarImg
						anchors.fill: parent
						visible: root.hasAvatar
						source: root.hasAvatar ? "file://" + root.avatar : ""
						radius: avatar.radius
					}
				}
			}

			Txt {
				anchors.horizontalCenter: parent.horizontalCenter
				text: root.name
				font.pixelSize: 20
				font.weight: Font.Medium
			}

			// password field + unlock button
			Row {
				spacing: 10
				anchors.horizontalCenter: parent.horizontalCenter

				Rectangle {
					id: field
					width: 292
					height: 56
					radius: height / 2
					color: Theme.surfaceContainerHigh
					border.width: 2
					border.color: root.error !== "" ? Theme.error : root.buffer.length > 0 ? Theme.primary : "transparent"
					Behavior on border.color {
						ColorAnimation { duration: Theme.durShort }
					}

					Txt {
						anchors.centerIn: parent
						visible: root.buffer.length === 0
						text: root.busy ? "Checking…" : root.prompt
						color: Theme.surfaceVariantFg
					}
					Row {
						anchors.centerIn: parent
						spacing: 6
						Repeater {
							model: Math.min(root.buffer.length, 18)
							Rectangle {
								width: 12
								height: 12
								radius: 6
								color: Theme.primary
								scale: 0
								Component.onCompleted: scale = 1
								Behavior on scale {
									SpringAnimation {
										spring: Theme.springBouncy
										damping: Theme.dampBouncy
										epsilon: 0.01
									}
								}
							}
						}
					}
				}

				Btn {
					width: 56
					height: 56
					implicitWidth: 56
					implicitHeight: 56
					variant: 1
					icon: root.busy ? "sync" : "arrow_forward"
					iconSize: 24
					busy: root.busy
					onClicked: root.submitted()
				}
			}

			Txt {
				anchors.horizontalCenter: parent.horizontalCenter
				visible: root.error === "" && !kb.activeFocus
				text: "Waiting for keyboard focus. Click anywhere or move the mouse."
				color: Theme.surfaceVariantFg
				font.pixelSize: 12
				width: parent.width
				horizontalAlignment: Text.AlignHCenter
				wrapMode: Text.WordWrap
			}

			Txt {
				anchors.horizontalCenter: parent.horizontalCenter
				visible: root.error !== ""
				text: root.error
				color: Theme.error
				font.pixelSize: 13
				width: parent.width
				horizontalAlignment: Text.AlignHCenter
				wrapMode: Text.WordWrap
				elide: Text.ElideNone
			}

			Column {
				id: extraSlot
				anchors.horizontalCenter: parent.horizontalCenter
				spacing: 10
			}
		}
	}

	// ---- bottom: battery and session actions ----
	Row {
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 24
			visible: root.showPower || Battery.present
		scale: root.fit
		transformOrigin: Item.Bottom
		spacing: 10

		Rectangle {
			visible: Battery.present
			height: 44
			width: batRow.implicitWidth + 28
			radius: height / 2
			color: Qt.alpha(Theme.surfaceContainer, 0.88)
			Row {
				id: batRow
				anchors.centerIn: parent
				spacing: 8
				Icon {
					name: Battery.icon
					size: 20
					color: Battery.color
					anchors.verticalCenter: parent.verticalCenter
				}
				Txt {
					text: Battery.percent + "%"
					color: Battery.color
					anchors.verticalCenter: parent.verticalCenter
				}
			}
		}
		Btn {
			visible: root.showPower
			icon: "bedtime"
			label: "Sleep"
			iconSize: 20
			onClicked: PowerActions.suspend()
		}
		Btn {
			visible: root.showPower
			icon: "restart_alt"
			label: "Restart"
			iconSize: 20
			onClicked: PowerActions.reboot()
		}
		Btn {
			visible: root.showPower
			icon: "power_settings_new"
			label: "Power off"
			iconSize: 20
			variant: 3
			onClicked: PowerActions.poweroff()
		}
	}
}
