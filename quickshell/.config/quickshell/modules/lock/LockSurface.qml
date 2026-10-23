import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

// One screen of the lock screen: blurred wallpaper, big clock, and a card with the password field.
WlSessionLockSurface {
	id: root

	color: Theme.notch

	readonly property bool hasWallpaper: Settings.lockWallpaper !== ""
	readonly property bool hasAvatar: Settings.lockAvatar !== ""
	// shrink everything on small screens
	readonly property real fit: Math.min(1, height / 820, width / 460)

	SystemClock {
		id: clock
		precision: SystemClock.Minutes
	}

	Item {
		anchors.fill: parent
		focus: true

		// Typing goes into a real (invisible) password input so the compositor's keyboard focus and the
		// input method work normally. Focus is taken back on click and whenever it is lost, e.g. after resume.
		TextInput {
			id: kb
			width: 1
			height: 1
			opacity: 0
			focus: true
			echoMode: TextInput.Password
			readOnly: LockCtl.busy
			Connections {
				target: LockCtl
				function onBufferChanged() {
					if (kb.text !== LockCtl.buffer)
						kb.text = LockCtl.buffer;
				}
			}
			onTextChanged: {
				if (text !== LockCtl.buffer) {
					LockCtl.buffer = text;
					LockCtl.error = "";
				}
			}
			Keys.onPressed: event => {
				if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
					LockCtl.submit();
					event.accepted = true;
				} else if (event.key === Qt.Key_Escape) {
					LockCtl.buffer = "";
					LockCtl.error = "";
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
			source: root.hasWallpaper ? "file://" + Settings.lockWallpaper : ""
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
				target: LockCtl
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
						radius: LockCtl.busy ? 20 : LockCtl.buffer.length > 0 ? 32 : 48
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
							visible: !root.hasAvatar
							text: LockCtl.fullName.charAt(0).toUpperCase()
							font.pixelSize: 44
							font.weight: Font.Medium
							color: Theme.primaryContainerFg
						}
						RoundedImage {
							anchors.fill: parent
							visible: root.hasAvatar
							source: root.hasAvatar ? "file://" + Settings.lockAvatar : ""
							radius: avatar.radius
						}
					}
				}

				Txt {
					anchors.horizontalCenter: parent.horizontalCenter
					text: LockCtl.fullName
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
						border.color: LockCtl.error !== "" ? Theme.error : LockCtl.buffer.length > 0 ? Theme.primary : "transparent"
						Behavior on border.color {
							ColorAnimation { duration: Theme.durShort }
						}

						Txt {
							anchors.centerIn: parent
							visible: LockCtl.buffer.length === 0
							text: LockCtl.busy ? "Checking…" : "Password"
							color: Theme.surfaceVariantFg
						}
						Row {
							anchors.centerIn: parent
							spacing: 6
							Repeater {
								model: Math.min(LockCtl.buffer.length, 18)
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
						icon: LockCtl.busy ? "sync" : "arrow_forward"
						iconSize: 24
						busy: LockCtl.busy
						onClicked: LockCtl.submit()
					}
				}

				Txt {
					anchors.horizontalCenter: parent.horizontalCenter
					visible: LockCtl.error === "" && !kb.activeFocus
					text: "Waiting for keyboard focus. Click anywhere or move the mouse."
					color: Theme.surfaceVariantFg
					font.pixelSize: 12
					width: parent.width
					horizontalAlignment: Text.AlignHCenter
					wrapMode: Text.WordWrap
				}

				Txt {
					anchors.horizontalCenter: parent.horizontalCenter
					visible: LockCtl.error !== ""
					text: LockCtl.error
					color: Theme.error
					font.pixelSize: 13
					width: parent.width
					horizontalAlignment: Text.AlignHCenter
					wrapMode: Text.WordWrap
					elide: Text.ElideNone
				}
			}
		}

		// ---- bottom: battery and session actions ----
		Row {
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 24
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
				icon: "bedtime"
				label: "Sleep"
				iconSize: 20
				onClicked: PowerActions.suspend()
			}
			Btn {
				icon: "restart_alt"
				label: "Restart"
				iconSize: 20
				onClicked: PowerActions.reboot()
			}
			Btn {
				icon: "power_settings_new"
				label: "Power off"
				iconSize: 20
				variant: 3
				onClicked: PowerActions.poweroff()
			}
		}
	}
}
