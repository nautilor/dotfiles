import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import QtQuick.Effects
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../shared" as Shared

Scope {
id: notifScope

NotificationServer {
	id: server
	actionsSupported: true
	imageSupported: true
	keepOnReload: true

	onNotification: notif => {
		notif.tracked = !notifWindow.doNotDisturb;
	}
}

PanelWindow {
	id: notifWindow
	Shared.Theme { id: theme }
	property bool doNotDisturb: false

	visible: !notifWindow.doNotDisturb && server.trackedNotifications.values.length > 0
	color: "transparent"
	implicitWidth: theme.notificationWidth
	implicitHeight: notifColumn.implicitHeight + (theme.smallGap * 2)
	exclusionMode: ExclusionMode.Normal

	readonly property color mdSurfaceContainerHigh: theme.notificationSurface
	readonly property color mdSurfaceContainerHighCritical: theme.notificationSurfaceCritical
	readonly property color mdOnSurface: theme.notificationOnSurface
	readonly property color mdOnSurfaceVariant: theme.notificationOnSurfaceVariant
	readonly property color mdPrimary: theme.notificationPrimary
	readonly property color mdSecondaryContainer: theme.notificationSecondaryContainer
	readonly property color mdOnSecondaryContainer: theme.notificationOnSecondaryContainer
	readonly property color mdError: theme.notificationError
	readonly property color mdErrorContainer: theme.notificationErrorContainer
	readonly property color mdOutlineVariant: theme.notificationOutlineVariant
	anchors {
		top: true
		right: true
	}

	Process {
		id: dndStatusReader
		command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/control-center.sh" dnd-status']
		stdout: StdioCollector {
			onStreamFinished: notifWindow.doNotDisturb = this.text.trim() === "on"
		}
	}

	Timer {
		interval: 1500
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			if (!dndStatusReader.running)
				dndStatusReader.running = true;
		}
	}

	Item {
		anchors.fill: parent

		ColumnLayout {
			id: notifColumn
			anchors {
				top: parent.top
				left: parent.left
				right: parent.right
				topMargin: theme.smallGap
				leftMargin: theme.smallGap
				rightMargin: theme.smallGap
			}
			spacing: theme.smallGap

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
						interval: (timeoutSecs > 0 ? timeoutSecs : 3) * 1000
						running: true; repeat: false
						onTriggered: exitAnim.start()
					}

					Rectangle {
						id: cardRect
						property bool isUrgent: card.modelData.urgency === NotificationUrgency.Critical
						width: parent.width
						implicitHeight: cardInner.implicitHeight + 20
						radius: theme.notificationCardRadius
						color: isUrgent ? notifWindow.mdSurfaceContainerHighCritical : notifWindow.mdSurfaceContainerHigh
						border.width: 0
						border.color: notifWindow.mdOutlineVariant

						RectangularShadow {
							anchors.fill: cardRect
							radius: cardRect.radius
							blur: 5
							spread: 0.2
							color: Qt.darker(cardRect.color, 1.6)
						}	

						// State layer on hover
						Rectangle {
							anchors.fill: parent
							radius: parent.radius
							color: notifWindow.mdOnSurface
							opacity: cardHover.containsMouse ? 0.04 : 0
							Behavior on opacity { NumberAnimation { duration: 150 } }
						}

						MouseArea {
							id: cardHover
							anchors.fill: parent
							hoverEnabled: true
							propagateComposedEvents: true
							onClicked: mouse => mouse.accepted = false
							onEntered: dismissTimer.stop()
							onExited: dismissTimer.start()
						}

						ColumnLayout {
							id: cardInner
							anchors {
								left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom
								leftMargin: theme.notificationCardPadding; rightMargin: theme.notificationCardPadding; topMargin: theme.notificationCardPadding; bottomMargin: theme.notificationCardPadding
							}
							spacing: theme.tightGap
							RowLayout {
								Layout.fillWidth: true
								Layout.topMargin: 4
								Layout.bottomMargin: 8
								spacing: theme.smallGap
								// Icon of application
								IconImage {
									Layout.alignment: Qt.AlignLeft
									implicitSize: 48
									source: card.modelData.image
									visible: true
								}
								ColumnLayout {
									Layout.fillWidth: true
									spacing: theme.tightGap

									// Summary — M3 title/medium
									RowLayout {
										Layout.fillWidth: true
										spacing: 8
										Text {
											visible: card.modelData.summary !== ""
											text: card.modelData.summary
											color: cardRect.isUrgent ? notifWindow.mdError : notifWindow.mdOnSurface
											font.pixelSize: 16; font.weight: Font.Medium
											Layout.fillWidth: true
											Layout.topMargin: 4
											wrapMode: Text.WordWrap
											textFormat: Text.PlainText
										}

										// Icon close button
										Rectangle {
											width: theme.notificationDismissSize; height: theme.notificationDismissSize; radius: theme.notificationDismissRadius
											color: cardRect.isUrgent ? (closeBtnHover.containsMouse
											? Qt.alpha(notifWindow.mdError, 0.08)
											: "transparent") : (
												closeBtnHover.containsMouse
												? Qt.alpha(notifWindow.mdOnSurface, 0.08)
												: "transparent")
												Behavior on color { ColorAnimation { duration: 150 } }

												Text {
													anchors.centerIn: parent
													text: ""
													color: cardRect.isUrgent ? Qt.darker(notifWindow.mdError, 1.8) : notifWindow.mdOnSurfaceVariant
													font.pixelSize: 15
												}

												MouseArea {
													id: closeBtnHover
													anchors.fill: parent
													hoverEnabled: true
													cursorShape: Qt.PointingHandCursor
													onClicked: { enterAnim.stop(); exitAnim.start() }
													onEntered: dismissTimer.stop()
													onExited: dismissTimer.start()
												}
											}
										}

										// Body — M3 body/medium
										Text {
											Layout.bottomMargin: card.modelData.actions.length > 0 ? 0 : 14
											visible: card.modelData.body !== ""
											text: card.modelData.body
											color: cardRect.isUrgent ? notifWindow.mdError : notifWindow.mdOnSurface
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

											height: theme.notificationActionHeight
											implicitWidth: cardInner.width / card.modelData.actions.length - (2 * card.modelData.actions.length)
											radius: theme.smallGap
											color: cardRect.isUrgent ? Qt.darker(notifWindow.mdError, 1.8) : notifWindow.mdSecondaryContainer
											Behavior on color { ColorAnimation { duration: 150 } }

											// State layer
											Rectangle {
												anchors.fill: parent; radius: parent.radius
												color: cardRect.isUrgent ? notifWindow.mdError : notifWindow.mdOnSurface
												opacity: btnArea.containsMouse ? 0.08 : 0
												Behavior on opacity { NumberAnimation { duration: 150 } }
											}

											Text {
												id: btnLabel
												anchors.centerIn: parent
												text: modelData.text
												color: cardRect.isUrgent ? notifWindow.mdSurfaceContainerHigh : notifWindow.mdOnSurface
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
