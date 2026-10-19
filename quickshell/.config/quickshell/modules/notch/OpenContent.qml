import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components

// Expanded notch: tab bar + the active tab.
Item {
	id: root

	property bool active: false

	readonly property var tabDefs: [
		{ id: "home", icon: "home", label: "Home" },
		{ id: "apps", icon: "apps", label: "Apps" },
		{ id: "clipboard", icon: "content_paste", label: "Clipboard" },
		{ id: "calendar", icon: "calendar_month", label: "Calendar" },
		{ id: "notifications", icon: "notifications", label: "Alerts" },
		{ id: "power", icon: "power_settings_new", label: "Power" },
		{ id: "settings", icon: "tune", label: "Settings" }
	]

	Row {
		id: tabBar
		anchors.top: parent.top
		anchors.topMargin: 10
		anchors.left: parent.left
		anchors.leftMargin: 6
		spacing: 4

		Repeater {
			model: root.tabDefs

			Item {
				id: tabItem
				required property var modelData
				readonly property bool current: NotchCtl.tab === modelData.id

				height: 38
				width: current ? 38 + label.implicitWidth + 14 : 38

				Behavior on width {
					SpringAnimation {
						spring: Theme.springBouncy
						damping: Theme.dampBouncy
						epsilon: 0.5
					}
				}

				Rectangle {
					anchors.fill: parent
					radius: height / 2
					color: tabItem.current ? Theme.secondaryContainer : "transparent"
					Behavior on color {
						ColorAnimation {
							duration: Theme.durShort
						}
					}
					Rectangle {
						anchors.fill: parent
						radius: parent.radius
						color: Theme.surfaceFg
						opacity: tabMouse.pressed ? 0.12 : tabMouse.containsMouse ? 0.08 : 0
					}
				}

				Icon {
					id: tabIcon
					x: 8
					anchors.verticalCenter: parent.verticalCenter
					name: tabItem.modelData.icon
					size: 22
					fill: tabItem.current ? 1 : 0
					color: tabItem.current ? Theme.secondaryContainerFg : Theme.surfaceVariantFg
				}
				Txt {
					id: label
					anchors.left: tabIcon.right
					anchors.leftMargin: 6
					anchors.verticalCenter: parent.verticalCenter
					text: tabItem.modelData.label
					font.weight: Font.Medium
					color: Theme.secondaryContainerFg
					opacity: tabItem.current ? 1 : 0
					elide: Text.ElideNone
					Behavior on opacity {
						NumberAnimation {
							duration: Theme.durShort
						}
					}
				}

				// unread badge on the alerts tab
				Rectangle {
					visible: tabItem.modelData.id === "notifications" && Notifs.count > 0 && !tabItem.current
					width: 8
					height: 8
					radius: 4
					color: Theme.tertiary
					x: 26
					y: 6
				}

				MouseArea {
					id: tabMouse
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: NotchCtl.tab = tabItem.modelData.id
				}
			}
		}
	}

	// right side of the header: clock, battery, pin
	Row {
		anchors.right: parent.right
		anchors.rightMargin: 8
		anchors.verticalCenter: tabBar.verticalCenter
		spacing: 10

		Icon {
			visible: Caffeine.active
			name: "coffee"
			size: 18
			fill: 1
			color: Theme.tertiary
			anchors.verticalCenter: parent.verticalCenter
		}
		Icon {
			visible: Mic.muted
			name: "mic_off"
			size: 18
			fill: 1
			color: Theme.error
			anchors.verticalCenter: parent.verticalCenter
		}
		Row {
			visible: Battery.present
			spacing: 2
			anchors.verticalCenter: parent.verticalCenter
			Icon {
				name: Battery.icon
				size: 18
				fill: 1
				color: Theme.surfaceVariantFg
				anchors.verticalCenter: parent.verticalCenter
			}
			Txt {
				text: Battery.percent + "%"
				font.pixelSize: 12
				color: Theme.surfaceVariantFg
				anchors.verticalCenter: parent.verticalCenter
			}
		}
		Txt {
			id: clock
			property date now: new Date()
			text: Qt.formatTime(now, Settings.use24h ? "HH:mm" : "h:mm AP")
			font.weight: Font.Medium
			color: Theme.surfaceVariantFg
			anchors.verticalCenter: parent.verticalCenter
			Timer {
				interval: 10000
				running: root.active
				repeat: true
				triggeredOnStart: true
				onTriggered: clock.now = new Date()
			}
		}
		Btn {
			icon: "push_pin"
			variant: 2
			toggleable: true
			toggled: NotchCtl.sticky
			iconSize: 18
			implicitWidth: 34
			implicitHeight: 34
			anchors.verticalCenter: parent.verticalCenter
			onClicked: NotchCtl.sticky = !NotchCtl.sticky
		}
	}

	Loader {
		id: tabLoader
		anchors.top: tabBar.bottom
		anchors.topMargin: 10
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 18
		anchors.leftMargin: 6
		anchors.rightMargin: 6
		active: root.active
		source: {
			switch (NotchCtl.tab) {
			case "apps":
				return "tabs/AppsTab.qml";
			case "clipboard":
				return "tabs/ClipboardTab.qml";
			case "calendar":
				return "tabs/CalendarTab.qml";
			case "notifications":
				return "tabs/NotificationsTab.qml";
			case "power":
				return "tabs/PowerTab.qml";
			case "settings":
				return "tabs/SettingsTab.qml";
			default:
				return "tabs/HomeTab.qml";
			}
		}
		onLoaded: if (item && item.focusInput)
			item.focusInput()
	}
}
