import Quickshell
import Quickshell.Services.Notifications
import QtQuick.Effects
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.colors

Item {
	id: notificationPanel

	property var barWindow: null
	readonly property bool active: server.trackedNotifications.values.length > 0

	Colors {
		id: colors
	}

	readonly property color bgPrimary: colors.windowBackground
	readonly property color bgSecondary: colors.quickToggleBackground
	readonly property color textPrimary: colors.windowForeground
	readonly property color textMuted: Qt.alpha(
		colors.windowForeground,
		0.65
	)
	readonly property color accent: colors.quickToggleActiveBackground
	readonly property color accentForeground: colors.quickToggleActiveForeground
	readonly property color critical: colors.critical

	implicitWidth: {
		var maxActions = 0
		for (var i = 0; i < server.trackedNotifications.values.length; i++) {
			var notif = server.trackedNotifications.values[i]
			if (notif.actions.length > maxActions) {
				maxActions = notif.actions.length
			}
		}
		return Math.max(300, 160 * maxActions + 24)
	}
	implicitHeight: contentColumn.implicitHeight + 24

	opacity: active ? 1 : 0
	visible: active || opacity > 0


	function trimText(text) {
		var maxChars = Math.floor((implicitWidth - 100) / 8)
		if (text.length > maxChars) {
			return text.substring(0, maxChars) + "…"
		}
		if (text.length <= 20) {
			return text
		}
		return text.substring(0, 20) + "…"
	}

	Behavior on opacity {
		NumberAnimation {
			duration: active ? 150 : 250
			easing.type: active ? Easing.OutCubic : Easing.InCubic
		}
	}

	NotificationServer {
		id: server
		actionsSupported: true
		imageSupported: true
		keepOnReload: true

		onNotification: notif => {
			notif.tracked = true

			if (barWindow) {
				barWindow.quickPanelOpen = false
				barWindow.launcherPanelOpen = false
				barWindow.focusable = false
			}
		}
	}

	Rectangle {
		id: panel
		anchors.fill: parent
		color: "transparent"
		radius: 24

		MouseArea {
			anchors.fill: parent
			acceptedButtons: Qt.AllButtons
			onClicked: mouse => mouse.accepted = true
		}

		ColumnLayout {
			id: contentColumn
			anchors.fill: parent
			anchors.margins: 12
			spacing: 8

			Repeater {
				model: server.trackedNotifications.values

				delegate: Item {
					id: card
					required property var modelData
					required property int index

					Layout.fillWidth: true
					implicitHeight: tile.implicitHeight
					opacity: 0

					Component.onCompleted: enterAnim.start()

					ParallelAnimation {
						id: enterAnim
						NumberAnimation {
							target: card
							property: "opacity"
							from: 0
							to: 1
							duration: 150
							easing.type: Easing.OutCubic
						}
					}

					SequentialAnimation {
						id: exitAnim
						NumberAnimation {
							target: card
							property: "opacity"
							to: 0
							duration: 250
							easing.type: Easing.InCubic
						}
						ScriptAction { script: card.modelData.expire() }
					}

					Timer {
						id: dismissTimer
						readonly property real timeoutSecs: card.modelData.expireTimeout
						interval: (timeoutSecs > 0 ? timeoutSecs : 3) * 1000
						running: true
						repeat: false
						onTriggered: exitAnim.start()
					}

					Rectangle {
						id: tile
						property bool isCritical: card.modelData.urgency === NotificationUrgency.Critical
						width: parent.width
						implicitHeight: tileRow.implicitHeight + 18
						radius: 18
						color: "transparent"

						Rectangle {
							anchors.fill: parent
							radius: parent.radius
							color: textPrimary
							opacity: tileHover.containsMouse ? 0.04 : 0
							Behavior on opacity { NumberAnimation { duration: 120 } }
						}

						MouseArea {
							id: tileHover
							anchors.fill: parent
							hoverEnabled: true
							propagateComposedEvents: true
							onClicked: mouse => mouse.accepted = false
							onEntered: dismissTimer.stop()
							onExited: dismissTimer.start()
						}

						RowLayout {
							id: tileRow
							anchors.fill: parent
							anchors.margins: 10
							spacing: 10

							Rectangle {
								Layout.preferredWidth: 40
								Layout.preferredHeight: 40
								Layout.rightMargin: 10
								radius: 12
								color: "transparent"

								IconImage {
									anchors.centerIn: parent
									implicitSize: 34
									source: card.modelData.image
								}
							}

							ColumnLayout {
								Layout.fillWidth: true
								spacing: 4

								RowLayout {
									Layout.fillWidth: true
									spacing: 8

									Text {
										visible: card.modelData.summary !== ""
										text: trimText(card.modelData.summary)
										color: tile.isCritical ? critical : textPrimary
										font.pixelSize: 14
										font.weight: Font.Medium
										Layout.fillWidth: true
										elide: Text.ElideRight
										textFormat: Text.PlainText
									}

									Rectangle {
										width: 30
										height: 30
										radius: 50
										color: "transparent"
										Behavior on color { ColorAnimation { duration: 120 } }

										Text {
											anchors.centerIn: parent
											text: "󰅙"
											font.weight: Font.Bold
											color: tile.isCritical ? (
												closeBtnHover.containsMouse ? critical : Qt.alpha(critical, 0.8)
											) : (
												closeBtnHover.containsMouse ? accent : Qt.alpha(accent, 0.8)
											)
											font.pixelSize: 24
										}

										MouseArea {
											id: closeBtnHover
											anchors.fill: parent
											hoverEnabled: true
											cursorShape: Qt.PointingHandCursor
											onClicked: {
												enterAnim.stop()
												exitAnim.start()
											}
											onEntered: dismissTimer.stop()
											onExited: dismissTimer.start()
										}
									}
								}

								Text {
									Layout.fillWidth: true
									visible: card.modelData.body !== ""
									text: trimText(card.modelData.body)
									color: tile.isCritical ? critical : textMuted
									font.pixelSize: 12
									wrapMode: Text.WordWrap
									textFormat: Text.PlainText
								}

								Flow {
									visible: card.modelData.actions.length > 0
									Layout.fillWidth: true
									Layout.topMargin: 10
									spacing: 8

									Repeater {
										model: card.modelData.actions

										delegate: Rectangle {
											required property var modelData

											height: 30
											implicitWidth: 116
											radius: height / 2
											color: tile.isCritical ? Qt.alpha(critical, 0.14) : accent
											Behavior on color { ColorAnimation { duration: 120 } }

											Rectangle {
												anchors.fill: parent
												radius: parent.radius
												color: tile.isCritical ? critical : accentForeground
												opacity: actionHover.containsMouse ? 0.08 : 0
												Behavior on opacity { NumberAnimation { duration: 120 } }
											}

											Text {
												anchors.centerIn: parent
												text: modelData.text
												color: bgPrimary
												font.pixelSize: 12
												font.weight: Font.Medium
												elide: Text.ElideRight
											}

											MouseArea {
												id: actionHover
												anchors.fill: parent
												hoverEnabled: true
												cursorShape: Qt.PointingHandCursor
												onClicked: {
													modelData.invoke()
													if (!card.modelData.resident) {
														enterAnim.stop()
														exitAnim.start()
													}
												}
												onEntered: dismissTimer.stop()
												onExited: dismissTimer.start()
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
