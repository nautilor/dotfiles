import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

Flickable {
	id: root

	contentHeight: col.implicitHeight + 8
	clip: true
	boundsBehavior: Flickable.StopAtBounds
	Component.onCompleted: Colorschemes.reload()

	ColumnLayout {
		id: col
		width: root.width - 12
		spacing: 8

		SectionLabel {
			text: "APPEARANCE"
		}
		// collapses (height, fade, slight slide) when a colour scheme replaces the accent
		Item {
			id: accentWrap
			readonly property bool shown: Settings.colorscheme === ""
			property real amount: shown ? 1 : 0
			Behavior on amount {
				NumberAnimation {
					duration: Theme.durMedium
					easing.type: Easing.OutCubic
				}
			}
			Layout.fillWidth: true
			Layout.preferredHeight: accentRow.implicitHeight * amount
			Layout.bottomMargin: -col.spacing * (1 - amount)
			visible: amount > 0
			clip: true
			opacity: amount
			SettingRow {
				id: accentRow
				width: parent.width
				y: -8 * (1 - accentWrap.amount)
				title: "Accent colour"
				subtitle: "Seed for the Material tonal palette"
				Repeater {
					model: [0.53, 0.6, 0.75, 0.92, 0.04, 0.12, 0.35]
					// fixed-size cell so the row never reflows while a swatch animates
					Item {
						id: cell
						required property real modelData
						readonly property bool current: Math.abs(Settings.hue - modelData) < 0.01
						Layout.preferredWidth: 36
						Layout.preferredHeight: 36
						Rectangle {
							anchors.centerIn: parent
							width: cell.current ? 32 : 26
							height: width
							radius: cell.current ? 11 : width / 2
							color: Qt.hsla(cell.modelData, 0.55, 0.62, 1)
							border.width: cell.current ? 3 : 0
							border.color: Theme.surfaceFg
							Behavior on width {
								NumberAnimation {
									duration: Theme.durShort
									easing.type: Easing.OutBack
								}
							}
							Behavior on radius {
								NumberAnimation {
									duration: Theme.durShort
								}
							}
						}
						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							onClicked: Settings.hue = cell.modelData
						}
					}
				}
			}
		}

		SettingRow {
			title: "Colour scheme"
			subtitle: (Colorschemes.current ? Colorschemes.current.name : "Accent") + " · your own .json files go in ~/.config/quickshell-notch/colorschemes/"
			Btn {
				icon: "chevron_right"
				implicitWidth: 40
				implicitHeight: 40
				rotation: schemeWrap.expanded ? 270 : 90
				Behavior on rotation {
					NumberAnimation {
						duration: Theme.durMedium
						easing.type: Easing.OutCubic
					}
				}
				onClicked: schemeWrap.expanded = !schemeWrap.expanded
			}
		}
		// one row of chips when collapsed, all of them when expanded
		Item {
			id: schemeWrap
			property bool expanded: false
			Layout.fillWidth: true
			Layout.preferredHeight: expanded ? schemeFlow.implicitHeight : 54
			clip: true
			Behavior on Layout.preferredHeight {
				NumberAnimation {
					duration: Theme.durMedium
					easing.type: Easing.OutCubic
				}
			}
			Flow {
				id: schemeFlow
				width: parent.width
				spacing: 8
				Repeater {
					model: [{
							id: "",
							name: "Accent",
							preview: [Theme.tone(0.18, 0.15), Qt.hsla(Settings.hue, 0.55, 0.76, 1), Qt.hsla((Settings.hue + 0.02) % 1, 0.35, 0.88, 1), Qt.hsla((Settings.hue + 0.16) % 1, 0.5, 0.79, 1)]
						}].concat(Colorschemes.schemes)
					Rectangle {
						id: chip
						required property var modelData
						readonly property bool current: Settings.colorscheme === modelData.id
						width: 150
						height: 54
						radius: current ? Theme.radiusSmall : Theme.radiusMedium
						color: current ? Theme.primaryContainer : Theme.surfaceContainerHigh
						Behavior on radius {
							NumberAnimation {
								duration: Theme.durShort
							}
						}
						Row {
							anchors.left: parent.left
							anchors.leftMargin: 12
							anchors.top: parent.top
							anchors.topMargin: 10
							spacing: 4
							Repeater {
								model: chip.modelData.preview
								Rectangle {
									required property color modelData
									width: 14
									height: 14
									radius: 7
									color: modelData
									border.width: 1
									border.color: Theme.outlineVariant
								}
							}
						}
						Txt {
							anchors.left: parent.left
							anchors.right: parent.right
							anchors.bottom: parent.bottom
							anchors.margins: 12
							anchors.bottomMargin: 8
							text: chip.modelData.name
							font.pixelSize: 12
							color: chip.current ? Theme.primaryContainerFg : Theme.surfaceVariantFg
						}
						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							onClicked: Settings.colorscheme = chip.modelData.id
						}
					}
				}
			}
		}

		SectionLabel {
			text: "BEHAVIOUR"
		}
		SettingRow {
			title: "Open on hover"
			subtitle: "Otherwise click the notch or use IPC"
			Switch {
				checked: Settings.hoverOpen
				onToggled: v => Settings.hoverOpen = v
			}
		}
		SettingRow {
			title: "Built-in lock screen"
			subtitle: "Lock button uses this instead of hyprlock"
			Switch {
				checked: Settings.builtinLock
				onToggled: v => Settings.builtinLock = v
			}
		}
		SettingRow {
			title: "Clock on closed notch"
			subtitle: "Show the time in the middle while idle"
			Switch {
				checked: Settings.showClock
				onToggled: v => Settings.showClock = v
			}
		}
		SettingRow {
			title: "Home on hover"
			subtitle: "Hovering the notch always opens the Home tab"
			Switch {
				checked: Settings.homeOnHover
				onToggled: v => Settings.homeOnHover = v
			}
		}
		SettingRow {
			title: "Rounded screen corners"
			subtitle: "Round every corner of every screen"
			Switch {
				checked: Settings.screenCorners
				onToggled: v => Settings.screenCorners = v
			}
		}
		SettingRow {
			title: "Show on all screens"
			subtitle: "Otherwise only on the first screen"
			Switch {
				checked: Settings.allScreens
				onToggled: v => Settings.allScreens = v
			}
		}
		SettingRow {
			title: "Date on closed notch"
			subtitle: "Show the date in the middle while idle"
			Switch {
				checked: Settings.showDate
				onToggled: v => Settings.showDate = v
			}
		}
		SettingRow {
			title: "Battery on closed notch"
			subtitle: "Show the battery percentage while idle"
			Switch {
				checked: Settings.showBattery
				onToggled: v => Settings.showBattery = v
			}
		}
		SettingRow {
			title: "Date on Home tab"
			subtitle: "Show the date next to the clock in the header"
			Switch {
				checked: Settings.showDateHome
				onToggled: v => Settings.showDateHome = v
			}
		}
		SettingRow {
			title: "Autohide"
			subtitle: "Slide the idle notch off screen; hover the top edge to bring it back"
			Switch {
				checked: Settings.autohide
				onToggled: v => Settings.autohide = v
			}
		}
		SettingRow {
			title: "Do not disturb"
			subtitle: "Notifications are kept, but not shown"
			Switch {
				checked: Settings.dnd
				onToggled: v => Settings.dnd = v
			}
		}
		SettingRow {
			title: "Notification time"
			subtitle: (Settings.notifTimeout / 1000) + " seconds on the notch"
			Btn {
				icon: "remove"
				implicitWidth: 40
				implicitHeight: 40
				onClicked: Settings.notifTimeout = Math.max(2000, Settings.notifTimeout - 1000)
			}
			Btn {
				icon: "add"
				implicitWidth: 40
				implicitHeight: 40
				onClicked: Settings.notifTimeout = Math.min(30000, Settings.notifTimeout + 1000)
			}
		}
		SettingRow {
			title: "24-hour clock"
			Switch {
				checked: Settings.use24h
				onToggled: v => Settings.use24h = v
			}
		}
		SettingRow {
			title: "Week starts on Monday"
			Switch {
				checked: Settings.weekStartsMonday
				onToggled: v => {
					Settings.weekStartsMonday = v;
					Gcal.weekStart = Gcal.startOfWeek(Gcal.today);
					Gcal.refresh();
				}
			}
		}

		SectionLabel {
			text: "CUSTOM MESSAGES"
		}
		SettingRow {
			title: "Caffeine on"
			Field {
				implicitWidth: 300
				text: Settings.caffeineOnMessage
				onEdited: v => Settings.caffeineOnMessage = v
			}
		}
		SettingRow {
			title: "Caffeine off"
			Field {
				implicitWidth: 300
				text: Settings.caffeineOffMessage
				onEdited: v => Settings.caffeineOffMessage = v
			}
		}
		SettingRow {
			title: "Microphone live"
			Field {
				implicitWidth: 300
				text: Settings.micOnMessage
				onEdited: v => Settings.micOnMessage = v
			}
		}
		SettingRow {
			title: "Microphone muted"
			Field {
				implicitWidth: 300
				text: Settings.micOffMessage
				onEdited: v => Settings.micOffMessage = v
			}
		}

		SectionLabel {
			text: "GOOGLE CALENDAR"
		}
		SettingRow {
			title: Gcal.authState === "ready" ? "Signed in" : "Not signed in"
			subtitle: Gcal.authState === "no-client" ? "Missing " + Gcal.clientFile : ""
			Btn {
				visible: Gcal.authState === "ready"
				label: "Sign out"
				onClicked: Gcal.logout()
			}
			Btn {
				visible: Gcal.authState === "logged-out"
				label: "Sign in"
				variant: 1
				onClicked: Gcal.login()
			}
		}
	}
}
