import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// Google-Calendar-style week view: overlapping events share the column width side by side.
Item {
	id: root

	readonly property real hourH: 46
	readonly property real gutter: 46
	property var selectedEvent: null
	property date now: new Date()

	readonly property var days: {
		const out = [];
		for (let i = 0; i < 7; i++)
			out.push(Gcal.addDays(Gcal.weekStart, i));
		return out;
	}

	Timer {
		interval: 30000
		running: root.visible
		repeat: true
		onTriggered: root.now = new Date()
	}

	function readableOn(c) {
		const col = Qt.color(c);
		return (0.299 * col.r + 0.587 * col.g + 0.114 * col.b) > 0.58 ? "#1b1b1f" : "#ffffff";
	}

	function scrollToNow() {
		const target = Math.max(0, ((Gcal.sameDay(Gcal.today, root.now) && Gcal.weekStart <= root.now && root.now < Gcal.addDays(Gcal.weekStart, 7)) ? root.now.getHours() - 1 : 8) * hourH);
		grid.contentY = Math.min(target, Math.max(0, grid.contentHeight - grid.height));
	}

	Component.onCompleted: {
		Gcal.today = new Date();
		if (Gcal.authState === "ready")
			Gcal.refresh();
		Qt.callLater(scrollToNow);
	}

	// ---- not connected ----
	Column {
		visible: Gcal.authState !== "ready"
		anchors.centerIn: parent
		spacing: 12
		width: 420

		Icon {
			name: "event_busy"
			size: 52
			color: Theme.outline
			anchors.horizontalCenter: parent.horizontalCenter
		}
		Txt {
			width: parent.width
			horizontalAlignment: Text.AlignHCenter
			wrapMode: Text.Wrap
			font.pixelSize: 16
			font.weight: Font.Bold
			text: Gcal.reauth ? "Sign in again to allow editing events" : Gcal.authState === "no-client" ? "Google Calendar needs an OAuth client" : Gcal.authState === "checking" ? "Checking…" : "Connect Google Calendar"
		}
		Txt {
			visible: Gcal.authState === "no-client"
			width: parent.width
			horizontalAlignment: Text.AlignHCenter
			wrapMode: Text.Wrap
			color: Theme.surfaceVariantFg
			text: "Create a Desktop-app OAuth client in Google Cloud Console (Calendar API enabled) and save it as\n" + Gcal.clientFile
		}
		Txt {
			visible: Gcal.error !== ""
			width: parent.width
			horizontalAlignment: Text.AlignHCenter
			wrapMode: Text.Wrap
			color: Theme.error
			text: Gcal.error
		}
		Btn {
			visible: Gcal.authState === "logged-out"
			icon: "login"
			label: Gcal.loggingIn ? "Waiting for browser…" : "Sign in with Google"
			variant: 1
			enabled: !Gcal.loggingIn
			anchors.horizontalCenter: parent.horizontalCenter
			onClicked: Gcal.login()
		}
		Btn {
			visible: Gcal.authState === "no-client"
			icon: "refresh"
			label: "Check again"
			anchors.horizontalCenter: parent.horizontalCenter
			onClicked: Gcal.checkStatus()
		}
	}

	// ---- week view ----
	ColumnLayout {
		visible: Gcal.authState === "ready"
		anchors.fill: parent
		spacing: 6

		RowLayout {
			Layout.fillWidth: true
			spacing: 6

			Txt {
				text: {
					const a = Gcal.weekStart, b = Gcal.addDays(a, 6);
					return a.getMonth() === b.getMonth() ? Qt.formatDate(a, "MMMM yyyy") : Qt.formatDate(a, "MMM") + " – " + Qt.formatDate(b, "MMM yyyy");
				}
				font.pixelSize: 19
				font.weight: Font.Bold
				Layout.fillWidth: true
			}
			Txt {
				visible: Gcal.error !== ""
				text: Gcal.error
				color: Theme.error
				font.pixelSize: 12
			}
			Icon {
				visible: Gcal.loading
				name: "sync"
				size: 18
				color: Theme.surfaceVariantFg
				RotationAnimation on rotation {
					running: Gcal.loading
					from: 0
					to: 360
					duration: 900
					loops: Animation.Infinite
				}
			}
			Btn {
				icon: "chevron_left"
				variant: 2
				implicitWidth: 38
				implicitHeight: 38
				onClicked: Gcal.shiftWeek(-1)
			}
			Btn {
				label: "Today"
				implicitHeight: 38
				onClicked: {
					Gcal.goToday();
					root.scrollToNow();
				}
			}
			Btn {
				icon: "chevron_right"
				variant: 2
				implicitWidth: 38
				implicitHeight: 38
				onClicked: Gcal.shiftWeek(1)
			}
			Btn {
				icon: "refresh"
				variant: 2
				implicitWidth: 38
				implicitHeight: 38
				onClicked: Gcal.refresh()
			}
		}

		// day headers
		Row {
			Layout.fillWidth: true
			Layout.preferredHeight: 48
			Item {
				width: root.gutter
				height: 1
			}
			Repeater {
				model: root.days
				Item {
					required property date modelData
					readonly property bool isToday: Gcal.sameDay(modelData, root.now)
					width: (parent.width - root.gutter) / 7
					height: 48
					Column {
						anchors.centerIn: parent
						spacing: 2
						Txt {
							anchors.horizontalCenter: parent.horizontalCenter
							text: Qt.formatDate(modelData, "ddd").toUpperCase()
							font.pixelSize: 11
							font.weight: Font.Medium
							color: isToday ? Theme.primary : Theme.surfaceVariantFg
						}
						Rectangle {
							width: 30
							height: 30
							radius: isToday ? 15 : 10
							color: isToday ? Theme.primary : "transparent"
							anchors.horizontalCenter: parent.horizontalCenter
							Txt {
								anchors.centerIn: parent
								text: modelData.getDate()
								font.pixelSize: 15
								font.weight: Font.Bold
								color: isToday ? Theme.primaryFg : Theme.surfaceFg
							}
						}
					}
				}
			}
		}

		// all-day strip
		Row {
			id: allDayRow
			Layout.fillWidth: true
			readonly property int rows: {
				let m = 0;
				for (const d of root.days)
					m = Math.max(m, Gcal.allDayOf(d).length);
				return Math.min(m, 3);
			}
			Layout.preferredHeight: rows > 0 ? rows * 22 + 4 : 0
			visible: rows > 0
			Item {
				width: root.gutter
				height: 1
				Txt {
					anchors.right: parent.right
					anchors.rightMargin: 8
					text: "all‑day"
					font.pixelSize: 10
					color: Theme.outline
				}
			}
			Repeater {
				model: root.days
				Column {
					id: adCol
					required property date modelData
					readonly property var list: Gcal.allDayOf(modelData)
					width: (parent.width - root.gutter) / 7
					spacing: 2
					Repeater {
						model: adCol.list.slice(0, 3)
						Rectangle {
							required property var modelData
							width: adCol.width - 4
							x: 2
							height: 20
							radius: 7
							color: modelData.color
							Txt {
								anchors.fill: parent
								anchors.leftMargin: 6
								anchors.rightMargin: 4
								verticalAlignment: Text.AlignVCenter
								text: modelData.title
								font.pixelSize: 11
								font.weight: Font.Medium
								color: root.readableOn(modelData.color)
							}
							MouseArea {
								anchors.fill: parent
								onClicked: root.selectedEvent = modelData
							}
						}
					}
				}
			}
		}

		// hour grid
		Rectangle {
			Layout.fillWidth: true
			Layout.fillHeight: true
			radius: Theme.radiusMedium
			color: Theme.surfaceContainerLow
			clip: true

			Flickable {
				id: grid
				anchors.fill: parent
				contentWidth: width
				contentHeight: 24 * root.hourH + 16
				boundsBehavior: Flickable.StopAtBounds
				clip: true

				Item {
					id: sheet
					width: grid.width
					height: grid.contentHeight

					// hour lines + labels
					Repeater {
						model: 24
						Item {
							required property int index
							y: 8 + index * root.hourH
							width: sheet.width
							height: 1
							Txt {
								x: 0
								width: root.gutter - 8
								y: -8
								horizontalAlignment: Text.AlignRight
								visible: index > 0
								text: Settings.use24h ? String(index).padStart(2, "0") + ":00" : (index % 12 === 0 ? 12 : index % 12) + (index < 12 ? " AM" : " PM")
								font.pixelSize: 10
								color: Theme.outline
							}
							Rectangle {
								x: root.gutter
								width: sheet.width - root.gutter
								height: 1
								color: Theme.outlineVariant
								opacity: 0.6
							}
						}
					}

					// day columns
					Row {
						x: root.gutter
						y: 8
						width: sheet.width - root.gutter
						height: 24 * root.hourH

						Repeater {
							model: root.days

							Item {
								id: col
								required property date modelData
								readonly property bool isToday: Gcal.sameDay(modelData, root.now)
								readonly property var laid: Gcal.layoutFor(modelData)
								width: parent.width / 7
								height: parent.height

								Rectangle {
									anchors.fill: parent
									color: Theme.primary
									opacity: col.isToday ? 0.06 : 0
								}
								Rectangle {
									width: 1
									height: parent.height
									color: Theme.outlineVariant
									opacity: 0.6
								}

								// click an empty slot to create an event there
								MouseArea {
									anchors.fill: parent
									onClicked: mouse => {
										const h = Math.floor(mouse.y / root.hourH);
										const start = new Date(col.modelData.getFullYear(), col.modelData.getMonth(), col.modelData.getDate(), h, 0);
										editor.open(null, start);
									}
								}

								Repeater {
									model: col.laid

									Rectangle {
										id: evBox
										required property var modelData
										readonly property var ev: modelData.ev
										x: 2 + modelData.lane * ((col.width - 4) / modelData.lanes)
										width: (col.width - 4) / modelData.lanes - 2
										y: modelData.sm / 60 * root.hourH + 1
										height: Math.max(18, (modelData.em - modelData.sm) / 60 * root.hourH - 2)
										radius: 8
										color: ev.color
										border.width: root.selectedEvent && root.selectedEvent.id === ev.id ? 2 : 0
										border.color: Theme.surfaceFg
										clip: true

										Rectangle {
											anchors.fill: parent
											radius: parent.radius
											color: "white"
											opacity: evArea.containsMouse ? 0.15 : 0
										}
										Column {
											anchors.fill: parent
											anchors.margins: 4
											anchors.leftMargin: 6
											spacing: 0
											Txt {
												width: parent.width
												text: evBox.ev.title
												font.pixelSize: 11
												font.weight: Font.Bold
												color: root.readableOn(evBox.ev.color)
											}
											Txt {
												width: parent.width
												visible: evBox.height > 34
												text: Qt.formatTime(evBox.ev.s, "hh:mm")
												font.pixelSize: 10
												color: root.readableOn(evBox.ev.color)
												opacity: 0.85
											}
										}
										MouseArea {
											id: evArea
											anchors.fill: parent
											hoverEnabled: true
											onClicked: root.selectedEvent = evBox.ev
										}
									}
								}

								// now indicator
								Rectangle {
									visible: col.isToday
									y: (root.now.getHours() * 60 + root.now.getMinutes()) / 60 * root.hourH - 1
									width: parent.width
									height: 2
									color: Theme.error
									Rectangle {
										width: 10
										height: 10
										radius: 5
										x: -5
										y: -4
										color: Theme.error
									}
								}
							}
						}
					}
				}
			}

			// floating create button, bottom right like Google Calendar
			Item {
				id: fab
				anchors.right: parent.right
				anchors.bottom: parent.bottom
				anchors.margins: 14
				width: fabRow.implicitWidth + 32
				height: 52
				scale: fabArea.pressed ? 0.94 : 1
				Behavior on scale {
					SpringAnimation {
						spring: 5
						damping: 0.4
						epsilon: 0.002
					}
				}
				Rectangle {
					anchors.fill: parent
					radius: fabArea.pressed ? 12 : 18
					color: Theme.primaryContainer
					Behavior on radius {
						NumberAnimation {
							duration: Theme.durShort
						}
					}
					Rectangle {
						anchors.fill: parent
						radius: parent.radius
						color: Theme.primaryContainerFg
						opacity: fabArea.containsMouse ? 0.1 : 0
					}
				}
				Row {
					id: fabRow
					anchors.centerIn: parent
					spacing: 8
					Icon {
						name: "add"
						size: 24
						color: Theme.primaryContainerFg
						anchors.verticalCenter: parent.verticalCenter
					}
					Txt {
						text: "Create"
						font.weight: Font.Medium
						elide: Text.ElideNone
						color: Theme.primaryContainerFg
						anchors.verticalCenter: parent.verticalCenter
					}
				}
				MouseArea {
					id: fabArea
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: {
						const n = new Date();
						n.setMinutes(0, 0, 0);
						n.setHours(n.getHours() + 1);
						editor.open(null, n);
					}
				}
			}

			// event details
			Rectangle {
				id: detail
				visible: root.selectedEvent !== null
				anchors.bottom: parent.bottom
				anchors.left: parent.left
				anchors.leftMargin: 14
				anchors.bottomMargin: 14
				width: Math.min(parent.width - fab.width - 44, 460)
				height: detailCol.implicitHeight + 24
				radius: Theme.radiusMedium
				color: Theme.surfaceContainerHighest

				Rectangle {
					width: 6
					height: parent.height - 20
					radius: 3
					x: 10
					anchors.verticalCenter: parent.verticalCenter
					color: root.selectedEvent ? root.selectedEvent.color : "transparent"
				}
				Column {
					id: detailCol
					anchors.left: parent.left
					anchors.leftMargin: 28
					anchors.right: parent.right
					anchors.rightMargin: 84
					anchors.verticalCenter: parent.verticalCenter
					spacing: 2
					Txt {
						width: parent.width
						text: root.selectedEvent ? root.selectedEvent.title : ""
						font.pixelSize: 15
						font.weight: Font.Bold
					}
					Txt {
						width: parent.width
						text: root.selectedEvent ? Qt.formatDate(root.selectedEvent.s, "dddd d MMMM") + " · " + Gcal.timeLabel(root.selectedEvent) : ""
						color: Theme.surfaceVariantFg
						font.pixelSize: 12
					}
					Txt {
						width: parent.width
						visible: root.selectedEvent && root.selectedEvent.location !== ""
						text: root.selectedEvent ? "📍 " + root.selectedEvent.location : ""
						color: Theme.surfaceVariantFg
						font.pixelSize: 12
					}
					Txt {
						width: parent.width
						text: root.selectedEvent ? root.selectedEvent.calendar : ""
						color: Theme.outline
						font.pixelSize: 11
					}
				}
				Row {
					anchors.top: parent.top
					anchors.right: parent.right
					anchors.margins: 6
					spacing: 2
					Btn {
						visible: root.selectedEvent && root.selectedEvent.canEdit
						icon: "edit"
						variant: 2
						iconSize: 18
						implicitWidth: 34
						implicitHeight: 34
						onClicked: editor.open(root.selectedEvent, null)
					}
					Btn {
						icon: "close"
						variant: 2
						iconSize: 18
						implicitWidth: 34
						implicitHeight: 34
						onClicked: root.selectedEvent = null
					}
				}
			}
		}
	}

	EventEditor {
		id: editor
		visible: false
		anchors.fill: parent
		onClosed: {
			visible = false;
			root.selectedEvent = null;
		}
	}
}
