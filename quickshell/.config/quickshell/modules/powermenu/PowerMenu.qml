import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import "../shared" as Shared

Scope {
	id: powerMenuScope

	PanelWindow {
		id: powerMenu
		Shared.Theme { id: theme }

		visible: false
		focusable: true
		color: "transparent"
		exclusiveZone: 0
		exclusionMode: ExclusionMode.Normal

		anchors {
			right: true
		}

		margins {
			right: -5 
		}

		readonly property color bgPrimary: theme.background
		readonly property color border: theme.outline
		readonly property color textPrimary: theme.surfaceText
		readonly property color accentBright: theme.primaryContainer

		readonly property int pillWidth: 92
		readonly property int pillPadding: 0
		readonly property int itemSize: 80
		readonly property int iconSize: 30
		readonly property int selectedCircleSize: 58
		readonly property int shadowPadding: 16

		property int currentIndex: 0
		property var entries: [
			{ glyph: "󰐥", action: "poweroff", label: "Power off" },
			{ glyph: "󰌾", action: "lock", label: "Lock" },
			{ glyph: "󰅖", action: "exit", label: "Exit" },
			{ glyph: "󰜉", action: "reboot", label: "Reboot" },
		]

		implicitWidth: pillWidth + (shadowPadding)
		implicitHeight: (entries.length * itemSize) + (pillPadding * 2) + (shadowPadding * 2)

		HyprlandFocusGrab {
			id: focusGrab
			windows: [powerMenu]
			onCleared: powerMenu.closeMenu()
		}

		function openMenu() {
			powerMenu.visible = true;
			powerMenu.currentIndex = 0;
			focusGrab.active = true;
			powerMenu.forceActiveFocus();
		}

		function closeMenu() {
			powerMenu.visible = false;
			focusGrab.active = false;
		}

		function toggleMenu() {
			if (powerMenu.visible)
				powerMenu.closeMenu();
			else
				powerMenu.openMenu();
		}

		function moveSelection(step) {
			const count = powerMenu.entries.length;
			if (count <= 0)
				return;

			powerMenu.currentIndex = (powerMenu.currentIndex + step + count) % count;
		}

		function activateCurrent() {
			if (runAction.running || powerMenu.entries.length === 0)
				return;

			runAction.action = powerMenu.entries[powerMenu.currentIndex].action;
			runAction.running = true;
		}

		Process {
			id: runAction
			property string action: ""
			command: ["bash", "-lc", '"$HOME/.config/quickshell/bin/powermenu.sh" "$1"', "_", action]

			onRunningChanged: {
				if (!running && action !== "") {
					action = "";
					powerMenu.closeMenu();
				}
			}
		}

		Keys.onPressed: event => {
			if (event.key === Qt.Key_Escape) {
				powerMenu.closeMenu();
				event.accepted = true;
				return;
			}
		}

		Item {
			anchors.fill: parent

			RectangularShadow {
				anchors.fill: container
				radius: container.radius
				blur: 5
				spread: 0.2
				offset: Qt.point(0, 4)
				color: Qt.darker(container.color, 1.6)
			}

			Rectangle {
				id: container
				anchors.fill: parent
				anchors.margins: powerMenu.shadowPadding
				color: powerMenu.bgPrimary
				opacity: 0.96
				radius: width / 2
				border.width: 0
				border.color: powerMenu.border
				clip: true
				focus: true

				Keys.onPressed: event => {
					if (event.key === Qt.Key_Escape) {
						powerMenu.closeMenu();
					} else if (event.key === Qt.Key_Up) {
						powerMenu.moveSelection(-1);
					} else if (event.key === Qt.Key_Down) {
						powerMenu.moveSelection(1);
					} else if (event.key === Qt.Key_K) {
						powerMenu.moveSelection(-1);
					} else if (event.key === Qt.Key_J) {
						powerMenu.moveSelection(1);
					} else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
						powerMenu.activateCurrent();
					}

					event.accepted = true;
				}

				Column {
					anchors {
						fill: parent
					}
					spacing: 0

					Repeater {
						model: powerMenu.entries

						delegate: Item {
							required property var modelData
							required property int index
							width: parent.width
							height: powerMenu.itemSize

							readonly property bool selected: index === powerMenu.currentIndex

							HoverHandler {
								cursorShape: Qt.PointingHandCursor
								onHoveredChanged: {
									if (hovered)
										powerMenu.currentIndex = index;
								}
							}

							TapHandler {
								onTapped: {
									powerMenu.currentIndex = index;
									powerMenu.activateCurrent();
								}
							}

							Rectangle {
								anchors.centerIn: parent
								width: powerMenu.selectedCircleSize
								height: powerMenu.selectedCircleSize
								radius: width / 2
								color: powerMenu.accentBright
								opacity: selected ? 1 : 0

								Behavior on opacity {
									NumberAnimation { duration: 120 }
								}
							}

							Text {
								anchors.centerIn: parent
								text: modelData.glyph
								color: selected ? powerMenu.textPrimary : Qt.alpha(powerMenu.textPrimary, 0.5)
								font.family: "JetBrainsMono Nerd Font Propo"
								font.pixelSize: 30
								font.weight: Font.DemiBold
							}
						}
					}
				}
			}
		}
	}

	IpcHandler {
		target: "powerMenu"

		function toggle() {
			powerMenu.toggleMenu();
		}

		function open() {
			powerMenu.openMenu();
		}

		function close() {
			powerMenu.closeMenu();
		}
	}
}
