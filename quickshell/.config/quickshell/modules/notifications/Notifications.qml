import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import QtQuick.Effects
import Quickshell.Services.Notifications
import Quickshell.Widgets

Scope {
	id: notifScope

	NotificationServer {
		id: server
		actionsSupported: true
		imageSupported: true
		keepOnReload: true

		onNotification: notif => {
			notif.tracked = true;
		}
	}

	PanelWindow {
		id: notifWindow
		visible: server.trackedNotifications.values.length > 0
		color: "transparent"
		implicitWidth: 360
		implicitHeight: notifColumn.implicitHeight + 16
		exclusionMode: ExclusionMode.Normal

		// Material 3 dark baseline color tokens
		readonly property color mdSurfaceContainerHigh: "#16161f" // bg_dark-ish
		readonly property color mdOnSurface:            "#c0caf5" // fg
		readonly property color mdOnSurfaceVariant:     "#a9b1d6" // fg_dark
		readonly property color mdPrimary:              "#7aa2f7" // blue
		readonly property color mdSecondaryContainer:   "#1f2030" // subtle elevated bg
		readonly property color mdOnSecondaryContainer: "#c0caf5" // readable fg
		readonly property color mdError:                "#f7768e" // red
		readonly property color mdErrorContainer:       "#3b1f29" // dark red bg
		readonly property color mdOutlineVariant:       "#414868" // comment / border
		anchors {
			top: true
			right: true
		}

		Item {
			anchors.fill: parent
			
			RectangularShadow {
				anchors.fill: cardRect
				radius: cardRect.radius
				blur: 5
				spread: 0.2
				color: Qt.darker(cardRect.color, 1.6)
			}	

			ColumnLayout {
				id: notifColumn
				anchors {
					top: parent.top
					left: parent.left
					right: parent.right
					topMargin: 8
					leftMargin: 8
					rightMargin: 8
				}
				spacing: 8

				Repeater {
					model: server.trackedNotifications.values

					delegate: Item {
						id: card
						required property var modelData
						required property int index

						Layout.fillWidth: true
						implicitHeight: cardRect.implicitHeight
						opacity: 0

						Component.onCompleted: enterAnim.start()

						ParallelAnimation {
							id: enterAnim
							NumberAnimation {
								target: card; property: "opacity"
								from: 0; to: 1
								duration: 300; easing.type: Easing.OutCubic
							}
							NumberAnimation {
								target: slideOffset; property: "x"
								from: 40; to: 0
								duration: 300; easing.type: Easing.OutCubic
							}
						}

						SequentialAnimation {
							id: exitAnim
							ParallelAnimation {
								NumberAnimation {
									target: card; property: "opacity"
									to: 0; duration: 220; easing.type: Easing.InCubic
								}
								NumberAnimation {
									target: slideOffset; property: "x"
									to: 40; duration: 220; easing.type: Easing.InCubic
								}
							}
							ScriptAction { script: card.modelData.expire() }
						}

						transform: Translate { id: slideOffset; x: 40 }

						Timer {
							id: dismissTimer
							readonly property real timeoutSecs: card.modelData.expireTimeout
							interval: (timeoutSecs > 0 ? timeoutSecs : 5) * 1000
							running: true; repeat: false
							onTriggered: exitAnim.start()
						}

						Rectangle {
							id: cardRect
							width: parent.width
							implicitHeight: cardInner.implicitHeight + 20
							radius: 16
							color: notifWindow.mdSurfaceContainerHigh
							border.width: 0
							border.color: notifWindow.mdOutlineVariant

							// State layer on hover
							Rectangle {
								anchors.fill: parent
								radius: parent.radius
								color: notifWindow.mdOnSurface
								opacity: cardHover.containsMouse ? 0.02 : 0
								Behavior on opacity { NumberAnimation { duration: 150 } }
							}

							MouseArea {
								id: cardHover
								anchors.fill: parent
								hoverEnabled: true
								propagateComposedEvents: true
								onClicked: mouse => mouse.accepted = false
							}

							ColumnLayout {
								id: cardInner
								anchors {
									left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom
									leftMargin: 16; rightMargin: 16; topMargin: 16; bottomMargin: 16
								}
								spacing: 4
								RowLayout {
									Layout.fillWidth: true
									Layout.topMargin: 4
									Layout.bottomMargin: 8
									spacing: 8
									// Icon of application
									IconImage {
										Layout.alignment: Qt.AlignLeft
										implicitSize: 48
										source: card.modelData.image
										visible: true
									}
									ColumnLayout {
										Layout.fillWidth: true
										spacing: 4

										// Summary — M3 title/medium
										RowLayout {
											Layout.fillWidth: true
											spacing: 8
										Text {
											visible: card.modelData.summary !== ""
											text: card.modelData.summary
											color: notifWindow.mdOnSurface
											font.pixelSize: 16; font.weight: Font.Medium
											Layout.fillWidth: true
											Layout.topMargin: 4
											wrapMode: Text.WordWrap
											textFormat: Text.PlainText
										}

									// Critical urgency chip
									Rectangle {
										visible: card.modelData.urgency === NotificationUrgency.Critical
										height: 18
										implicitWidth: urgencyLabel.implicitWidth + 12
										radius: 9
										color: notifWindow.mdErrorContainer

										Text {
											id: urgencyLabel
											anchors.centerIn: parent
											text: "Urgent"
											color: notifWindow.mdError
											font.pixelSize: 10
											font.weight: Font.Medium
										}
									}

									// Icon close button
									Rectangle {
										width: 28; height: 28; radius: 14
										color: closeBtnHover.containsMouse
										? Qt.alpha(notifWindow.mdOnSurface, 0.08)
										: "transparent"
										Behavior on color { ColorAnimation { duration: 150 } }

										Text {
											anchors.centerIn: parent
											text: ""
											color: notifWindow.mdOnSurfaceVariant
											font.pixelSize: 15
										}

										MouseArea {
											id: closeBtnHover
											anchors.fill: parent
											hoverEnabled: true
											cursorShape: Qt.PointingHandCursor
											onClicked: { enterAnim.stop(); exitAnim.start() }
										}
									}
									}

										// Body — M3 body/medium
										Text {
											visible: card.modelData.body !== ""
											text: card.modelData.body
											color: notifWindow.mdOnSurfaceVariant
											font.pixelSize: 14
											Layout.fillWidth: true
											wrapMode: Text.WordWrap
											textFormat: Text.PlainText
										}
									}
								}

								// Action buttons — M3 filled-tonal style
								Flow {
									visible: card.modelData.actions.length > 0
									Layout.fillWidth: true
									Layout.topMargin: 4
									Layout.bottomMargin: 8
									spacing: 8

									Repeater {
										model: card.modelData.actions

										delegate: Rectangle {
											required property var modelData

											height: 32
											implicitWidth: cardInner.width / card.modelData.actions.length - 5
											radius:8
											color: notifWindow.mdSecondaryContainer
											Behavior on color { ColorAnimation { duration: 150 } }

											// State layer
											Rectangle {
												anchors.fill: parent; radius: parent.radius
												color: notifWindow.mdOnSecondaryContainer
												opacity: btnArea.containsMouse ? 0.08 : 0
												Behavior on opacity { NumberAnimation { duration: 150 } }
											}

											Text {
												id: btnLabel
												anchors.centerIn: parent
												text: modelData.text
												color: notifWindow.mdOnSecondaryContainer
												font.pixelSize: 13; font.weight: Font.Medium
												font.letterSpacing: 0.1
											}

											MouseArea {
												id: btnArea
												anchors.fill: parent
												hoverEnabled: true
												cursorShape: Qt.PointingHandCursor
												onClicked: {
													modelData.invoke();
													if (!card.modelData.resident) {
														enterAnim.stop();
														exitAnim.start();
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
	}
}
