import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets
import "../shared" as Shared

Scope {
	id: barScope

	Variants {
		model: Quickshell.screens

		PanelWindow {
			id: barWindow
			required property var modelData

			screen: modelData
			Shared.Theme { id: theme }

			property var pomodoroState: ({
				text: "25:00",
				tooltip: "",
				classes: [],
				alt: "",
			})
			property var caffeineState: ({
				text: "󰅶",
				classes: ["inactive"],
			})
			property bool microphoneMuted: false
			property bool recording: false
			property bool batteryAlt: false
			property bool clockAlt: false
			property date currentTime: new Date()

			readonly property color bgPrimary: theme.barBgPrimary
			readonly property color capsuleColor: theme.barCapsule
			readonly property color capsuleHoverColor: theme.barCapsuleHover
			readonly property color textPrimary: theme.barTextPrimary
			readonly property color textSecondary: theme.barTextSecondary
			readonly property color textDisabled: theme.barTextDisabled
			readonly property color accent: theme.barAccent
			readonly property color accentContainer: theme.barAccentContainer
			readonly property color tertiary: theme.barTertiary
			readonly property color error: theme.barError
			readonly property color onError: theme.barOnError
			readonly property color panelSuccess: theme.barTertiary

			readonly property var pomodoroClasses: normalizeClasses(pomodoroState.classes)
			readonly property var caffeineClasses: normalizeClasses(caffeineState.classes)
			readonly property bool caffeineActive: caffeineClasses.indexOf("active") !== -1
			readonly property var batteryDevice: UPower.displayDevice
			readonly property bool batteryVisible: batteryDevice && batteryDevice.ready && batteryDevice.isPresent && batteryDevice.isLaptopBattery
			readonly property int connectedBluetoothCount: {
				const devices = Bluetooth.devices.values || [];
				return devices.filter(device => device && device.connected).length;
			}
			readonly property var activeNetworkDevice: {
				const devices = Networking.devices.values || [];
				return devices.find(device => device && device.connected) || null;
			}
			readonly property var activeWifiNetwork: {
				const device = activeNetworkDevice;
				if (!device || device.type !== DeviceType.Wifi)
					return null;

				const networks = device.networks.values || [];
				return networks.find(network => network && network.connected) || null;
			}
			readonly property string workspaceModeIcon: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.hasFullscreen ? "󰄶" : "󰙀"
			readonly property var trayItems: {
				const items = SystemTray.items.values || [];
				return items.filter(item => item && item.status !== Status.Passive);
			}
			readonly property var workspaceIds: {
				const ids = [1, 2, 3];
				const workspaces = Hyprland.workspaces.values || [];

				for (const workspace of workspaces) {
					if (!workspace || workspace.id < 1)
						continue;
					if ((workspace.name || "").startsWith("special:"))
						continue;
					if (ids.indexOf(workspace.id) === -1)
						ids.push(workspace.id);
				}

				ids.sort((left, right) => left - right);
				return ids;
			}

			function normalizeClasses(value) {
				if (Array.isArray(value))
					return value;
				if (typeof value === "string" && value !== "")
					return [value];
				return [];
			}

			function parseJsonLine(line, sourceName) {
				const trimmed = (line || "").trim();
				if (trimmed === "")
					return null;

				try {
					return JSON.parse(trimmed);
				} catch (error) {
					console.warn(`bar: failed to parse ${sourceName}: ${error}`);
					return null;
				}
			}

			function workspaceForId(workspaceId) {
				const workspaces = Hyprland.workspaces.values || [];
				return workspaces.find(workspace => workspace && workspace.id === workspaceId) || null;
			}

			function pomodoroColors() {
				if (pomodoroClasses.indexOf("pause") !== -1)
				return { background: tertiary, foreground: bgPrimary };
				if (pomodoroClasses.indexOf("work") !== -1)
					return { background: accent, foreground: bgPrimary };
				if (pomodoroClasses.indexOf("break") !== -1)
					return { background: textSecondary, foreground: bgPrimary };
				return { background: capsuleColor, foreground: textPrimary };
			}

			function networkIcon() {
				const device = activeNetworkDevice;
				if (device && device.type === DeviceType.Wired)
					return "󰈀";

				if (!Networking.wifiEnabled || !Networking.wifiHardwareEnabled)
					return "󰤮";

				if (!device || device.type !== DeviceType.Wifi || !activeWifiNetwork)
					return "󰤭";

				const strength = (activeWifiNetwork.signalStrength || 0) * 100;
				if (strength >= 80)
					return "󰤨";
				if (strength >= 55)
					return "󰤥";
				if (strength >= 30)
					return "󰤢";
				if (strength > 0)
					return "󰤟";
				return "󰤯";
			}

			function networkColor() {
				if (activeNetworkDevice && activeNetworkDevice.connected)
					return textPrimary;
				return textDisabled;
			}

			function bluetoothIcon() {
				const adapter = Bluetooth.defaultAdapter;
				if (!adapter || !adapter.enabled)
					return "󰂲";
				return "󰂯";
			}

			function bluetoothColor() {
				if (connectedBluetoothCount > 0)
					return accent;
				if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)
					return textPrimary;
				return textDisabled;
			}

			function powerProfileIcon() {
				switch (PowerProfiles.profile) {
				case PowerProfile.Performance:
					return "󰈸";
				case PowerProfile.PowerSaver:
					return "󰌪";
				default:
					return "󰗑";
				}
			}

			function cyclePowerProfile() {
				switch (PowerProfiles.profile) {
				case PowerProfile.PowerSaver:
					PowerProfiles.profile = PowerProfile.Balanced;
					break;
				case PowerProfile.Balanced:
					PowerProfiles.profile = PowerProfiles.hasPerformanceProfile ? PowerProfile.Performance : PowerProfile.PowerSaver;
					break;
				case PowerProfile.Performance:
				default:
					PowerProfiles.profile = PowerProfile.PowerSaver;
					break;
				}
			}

			function batteryIcon() {
				if (!batteryVisible)
					return "";

				switch (batteryDevice.state) {
				case UPowerDeviceState.Charging:
				case UPowerDeviceState.PendingCharge:
					return "󰂄";
				case UPowerDeviceState.FullyCharged:
					return "󰁹";
				default: {
					const raw = batteryDevice.percentage || 0;
					const percentage = raw <= 1 ? raw * 100 : raw;
					if (percentage <= 10)
						return "󰂃";
					if (percentage <= 20)
						return "󰁺";
					if (percentage <= 20)
						return "󰁻";
					if (percentage <= 30)
						return "󰁼";
					if (percentage <= 40)
						return "󰁽";
					if (percentage <= 50)
						return "󰁾";
					if (percentage <= 60)
						return "󰁿";
					if (percentage <= 70)
						return "󰂀";
					if (percentage <= 80)
						return "󰂁";
					if (percentage <= 90)
						return "󰂂";
					return "󰁹";
				}
				}
			}

			function batteryColor() {
				if (!batteryVisible)
					return textPrimary;

				if (batteryDevice.state === UPowerDeviceState.Charging || batteryDevice.state === UPowerDeviceState.PendingCharge || batteryDevice.state === UPowerDeviceState.FullyCharged)
					return panelSuccess;
				const raw = batteryDevice.percentage || 0;
				const percentage = raw <= 1 ? raw * 100 : raw;
				if (percentage <= 10)
					return error;
				if (percentage <= 30)
					return tertiary;
				return textPrimary;
			}

			function batteryText() {
				if (!batteryVisible)
					return "";

				if (batteryAlt) {
					const raw = batteryDevice.percentage || 0;
					const percent = raw <= 1 ? raw * 100 : raw;
					return `${Math.round(percent)}%`;
				}

				return batteryIcon();
			}

			function trayItemClick(item, point, alternate) {
				if (!item)
					return;

				if (item.hasMenu) {
					item.display(barWindow, point.x, point.y);
					return;
				}

				if (alternate)
					item.secondaryActivate();
				else
					item.activate();
			}

			visible: true
			color: bgPrimary
			implicitHeight: theme.barHeight
			exclusionMode: ExclusionMode.Auto

			anchors {
				top: true
				left: true
				right: true
			}

			Process {
				id: pomodoroProcess
				command: ["bash", "-lc", 'exec "$HOME/.config/quickshell/bin/pomodoro" --no-icons --no-work-icons']
				running: true
				stdout: SplitParser {
					splitMarker: "\n"

					onRead: data => {
						const parsed = barWindow.parseJsonLine(data, "pomodoro");
						if (!parsed)
							return;

						barWindow.pomodoroState = {
							text: parsed.text || "",
							tooltip: parsed.tooltip || "",
							classes: barWindow.normalizeClasses(parsed.class),
							alt: parsed.alt || "",
						};
					}
				}
			}

			Process {
				id: pomodoroActionProcess
				property string actionName: ""
				command: ["bash", "-lc", 'exec "$HOME/.config/waybar/bin/pomodoro" "$1"', "_", actionName]

				onRunningChanged: {
					if (!running)
						actionName = "";
				}
			}

			Process {
				id: caffeineStatusProcess
				command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/caffeine.sh" icon']
				stdout: StdioCollector {
					onStreamFinished: {
						const parsed = barWindow.parseJsonLine(this.text, "caffeine");
						if (!parsed)
							return;

						barWindow.caffeineState = {
							text: parsed.text || "󰅶",
							classes: barWindow.normalizeClasses(parsed.class),
						};
					}
				}
			}

			Process {
				id: caffeineToggleProcess
				command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/caffeine.sh" toggle']

				onRunningChanged: {
					if (!running && !caffeineStatusProcess.running)
						caffeineStatusProcess.running = true;
				}
			}


			Process {
				id: microphoneStatusProcess
				command: ["bash", "-lc", 'pactl get-source-mute @DEFAULT_SOURCE@']
				stdout: StdioCollector {
					onStreamFinished: {
						const output = this.text.trim().toLowerCase();
						barWindow.microphoneMuted = output.endsWith("yes");
					}
				}
			}

			Process {
				id: microphoneToggleProcess
				command: ["bash", "-lc", 'pactl set-source-mute @DEFAULT_SOURCE@ toggle']
				
				onRunningChanged: {
					if (!running && !microphoneStatusProcess.running)
						microphoneStatusProcess.running = true;
				}
			}

			Process {
				id: recorderStatusProcess
				command: ["bash", "-lc", '[ -f /tmp/recorder_pid ] && echo "recording" || echo "stopped"']
				stdout: StdioCollector {
					onStreamFinished: {
						barWindow.recording = this.text.trim() === "recording";
					}
				}
			}

			Process {
				id: recorderToggleProcess
				command: ["bash", "-lc", 'bash "$HOME/.config/hypr/bin/recorder.sh"']
				
				onRunningChanged: {
					if (!running && !recorderStatusProcess.running)
						recorderStatusProcess.running = true;
				}
			}

			Process {
				id: networkEditorProcess
				command: ["nm-connection-editor"]
			}

			Process {
				id: bluetoothManagerProcess
				command: ["blueman-manager"]
			}

			Timer {
				interval: 2000
				running: true
				repeat: true
				triggeredOnStart: true

				onTriggered: {
					if (!pomodoroProcess.running)
						pomodoroProcess.running = true;
					if (!caffeineStatusProcess.running)
						caffeineStatusProcess.running = true;
					if (!microphoneStatusProcess.running)
						microphoneStatusProcess.running = true;
					if (!recorderStatusProcess.running)
						recorderStatusProcess.running = true;
				}
			}

			Item {
				id: content
				anchors.fill: parent

				RowLayout {
					anchors.fill: parent
					anchors.leftMargin: theme.barHorizontalPadding
					anchors.rightMargin: theme.barHorizontalPadding
					anchors.topMargin: theme.barVerticalPadding
					anchors.bottomMargin: theme.barVerticalPadding
					spacing: theme.barSectionGap

					BarCapsule {
						RowLayout {
							spacing: theme.microGap

							IconText {
								text: barWindow.workspaceModeIcon
								color: textSecondary
								font.weight: Font.Medium
							}
						}
					}

					BarCapsule {
						RowLayout {
							spacing: theme.microGap

							Repeater {
								model: barWindow.workspaceIds

								delegate: Rectangle {
									required property var modelData

									readonly property int workspaceId: Number(modelData)
									readonly property var workspace: barWindow.workspaceForId(workspaceId)

									color: workspace && workspace.active ? accentContainer : (workspaceButtonHover.containsMouse ? Qt.alpha(textPrimary, 0.08) : "transparent")
									radius: theme.barWorkspaceButtonSize / 2
									implicitWidth: theme.barWorkspaceButtonSize
									implicitHeight: theme.barWorkspaceButtonSize

									Behavior on color {
										ColorAnimation { duration: 150 }
									}

									Text {
										anchors.centerIn: parent
										text: workspaceId
										color: workspace && workspace.active && workspace.focused ? textPrimary : (workspace && workspace.urgent ? error : (workspace && workspace.toplevels && workspace.toplevels.values.length === 0 ? Qt.alpha(textSecondary, 0.65) : textDisabled))
										font.pixelSize: 14
										font.weight: Font.DemiBold
									}

									MouseArea {
										id: workspaceButtonHover
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: Hyprland.dispatch(`workspace ${parent.workspaceId}`)
									}
								}
							}
						}
					}

					Item {
						Layout.fillWidth: true
						Layout.preferredWidth: 1

						BarCapsule {
							anchors.centerIn: parent
							width: Math.min(implicitWidth, parent.width)
							visible: false

							RowLayout {
								width: parent.width - (theme.barCapsuleHorizontalPadding * 2)

								Text {
									Layout.fillWidth: true
									text: ""
									color: textPrimary
									font.pixelSize: 13
									elide: Text.ElideRight
									horizontalAlignment: Text.AlignHCenter
									verticalAlignment: Text.AlignVCenter
								}
							}
						}
					}

					RowLayout {
						spacing: theme.barSectionGap

						BarCapsule {
							id: pomodoroCapsule
							readonly property var pomodoroColors: barWindow.pomodoroColors()
							color: pomodoroColors.background

							Item {
								implicitWidth: pomodoroContent.implicitWidth
								implicitHeight: pomodoroContent.implicitHeight

								RowLayout {
									id: pomodoroContent
									anchors.centerIn: parent
									spacing: theme.tightGap

									Text {
										text: barWindow.pomodoroState.text || "25:00"
										color: pomodoroCapsule.pomodoroColors.foreground
										font.pixelSize: 13
										font.weight: Font.DemiBold
									}
								}

								MouseArea {
									anchors.fill: parent
									acceptedButtons: Qt.LeftButton | Qt.RightButton
									cursorShape: Qt.PointingHandCursor

									onClicked: mouse => {
										if (pomodoroActionProcess.running)
											return;

										pomodoroActionProcess.actionName = mouse.button === Qt.RightButton ? "reset" : "toggle";
										pomodoroActionProcess.running = true;
									}
								}
							}
						}

						BarCapsule {
							RowLayout {
								spacing: theme.microGap

								StatusButton {
									text: barWindow.networkIcon()
									foreground: barWindow.networkColor()

									onClicked: {
										Networking.wifiEnabled = !Networking.wifiEnabled;
									}

									onRightClicked: {
										if (!networkEditorProcess.running)
											networkEditorProcess.running = true;
									}
								}

								StatusButton {
									visible: barWindow.caffeineActive
									text: barWindow.caffeineState.text || "󰅶"
									foreground: accent

									onClicked: {
										if (!caffeineToggleProcess.running)
											caffeineToggleProcess.running = true;
									}
								}

								StatusButton {
									text: barWindow.bluetoothIcon()
									foreground: barWindow.bluetoothColor()

									onClicked: {
										if (Bluetooth.defaultAdapter)
											Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
									}

									onRightClicked: {
										if (!bluetoothManagerProcess.running)
											bluetoothManagerProcess.running = true;
									}
								}

									StatusButton {
										visible: barWindow.microphoneMuted
										text: "󰍭"
										foreground: error
					
										onClicked: {
											if (!microphoneToggleProcess.running)
												microphoneToggleProcess.running = true;
										}
									}

									StatusButton {
										text: barWindow.recording ? "●" : ""
										foreground: barWindow.recording ? error : barWindow.textDisabled
										pixelSize: 12
										onClicked: {
											if (!recorderToggleProcess.running)
												recorderToggleProcess.running = true;
										}
									}

								StatusButton {
									text: barWindow.powerProfileIcon()
									foreground: textPrimary

									onClicked: {
										barWindow.cyclePowerProfile();
									}
								}

								StatusButton {
									visible: barWindow.batteryVisible
									text: barWindow.batteryText()
									pixelSize: barWindow.batteryAlt ? 14 : 16
									foreground: barWindow.batteryColor()

									onClicked: {
										barWindow.batteryAlt = !barWindow.batteryAlt;
									}
								}
							}
						}

						BarCapsule {
							Item {
								implicitWidth: clockContent.implicitWidth
								implicitHeight: clockContent.implicitHeight

								RowLayout {
									id: clockContent
									anchors.centerIn: parent

									Text {
										text: barWindow.clockAlt ? Qt.formatDateTime(barWindow.currentTime, "HH:mm dd/MM/yyyy") : Qt.formatDateTime(barWindow.currentTime, "HH:mm")
										color: textPrimary
										font.pixelSize: 13
										font.weight: Font.Medium
									}
								}

								MouseArea {
									anchors.fill: parent
									acceptedButtons: Qt.LeftButton
									cursorShape: Qt.PointingHandCursor
									onClicked: barWindow.clockAlt = !barWindow.clockAlt
								}
							}

							Timer {
								interval: 1000
								running: true
								repeat: true
								onTriggered: barWindow.currentTime = new Date()
							}
						}

						BarCapsule {
							id: trayCapsule
							property bool trayExpanded: false

							Item {
								width: implicitWidth
								height: implicitHeight
								implicitWidth: trayMenuButton.implicitWidth
									+ (trayCapsule.trayExpanded ? theme.smallGap + trayIcons.implicitWidth : 0)
								implicitHeight: Math.max(trayMenuButton.implicitHeight, trayIcons.implicitHeight)
								clip: true

								Row {
									anchors.centerIn: parent
									spacing: theme.smallGap

									StatusButton {
										id: trayMenuButton
										text: trayCapsule.trayExpanded ? "󰅂" : "󰅁"
										foreground: textPrimary

										onClicked: {
											if (barWindow.trayItems.length === 0)
												return;

											trayCapsule.trayExpanded = !trayCapsule.trayExpanded;
										}
									}

									Item {
										width: trayCapsule.trayExpanded ? trayIcons.implicitWidth : 0
										height: trayIcons.implicitHeight
										clip: true
										opacity: trayCapsule.trayExpanded ? 1 : 0
										visible: barWindow.trayItems.length > 0

										MouseArea {
											anchors.fill: parent
											acceptedButtons: Qt.LeftButton
											cursorShape: Qt.PointingHandCursor

											onClicked: mouse => {
												if (barWindow.trayItems.length === 0)
													return;

												trayCapsule.trayExpanded = !trayCapsule.trayExpanded;
											}
										}

										Behavior on opacity {
											NumberAnimation {
												duration: 250
												easing.type: Easing.Linear
											}
										}

										Row {
											id: trayIcons
											anchors.verticalCenter: parent.verticalCenter
											spacing: theme.tightGap

											Repeater {
												model: barWindow.trayItems

												delegate: Item {
													required property var modelData

													implicitWidth: theme.barStatusButtonSize
													implicitHeight: theme.barStatusButtonSize

													Rectangle {
														anchors.fill: parent
														radius: width / 2
														color: trayMouse.containsMouse ? Qt.alpha(textPrimary, 0.08) : "transparent"

														Behavior on color {
															ColorAnimation { duration: 150 }
														}
													}

													IconImage {
														anchors.centerIn: parent
														implicitSize: theme.barTrayIconSize
														source: modelData.icon
													}

													MouseArea {
														id: trayMouse
														anchors.fill: parent
														acceptedButtons: Qt.LeftButton | Qt.RightButton
														hoverEnabled: true
														cursorShape: Qt.PointingHandCursor

														onClicked: mouse => {
															const point = mapToItem(content, 0, height);
															barWindow.trayItemClick(modelData, point, mouse.button === Qt.RightButton);
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

			component BarCapsule: Rectangle {
				id: capsule

				default property alias contentData: capsuleLayout.data

				implicitWidth: capsuleLayout.implicitWidth + (theme.barCapsuleHorizontalPadding * 2)
				implicitHeight: theme.barHeight - (theme.barVerticalPadding * 2)
				radius: theme.barCapsuleRadius
				color: barWindow.capsuleColor

				Rectangle {
					anchors.fill: parent
					radius: parent.radius
					color: "transparent"
				}

				RowLayout {
					id: capsuleLayout
					anchors.centerIn: parent
					spacing: theme.smallGap
				}
			}

			component IconText: Text {
				color: barWindow.textPrimary
				font.pixelSize: 15
				font.weight: Font.Medium
				verticalAlignment: Text.AlignVCenter
			}

			component StatusButton: Item {
				id: statusButton

				property string text: ""
				property color foreground: barWindow.textPrimary
				property color background: "transparent"
				property bool clickable: true
				property int pixelSize: 16
				signal clicked()
				signal rightClicked()

				visible: text !== ""
				implicitWidth: theme.barStatusButtonSize
				implicitHeight: theme.barStatusButtonSize

				Rectangle {
					anchors.fill: parent
					radius: width / 2
					color: statusMouse.containsMouse && statusButton.clickable ? Qt.alpha(barWindow.textPrimary, 0.08) : statusButton.background

					Behavior on color {
						ColorAnimation { duration: 150 }
					}
				}

				Text {
					anchors.centerIn: parent
					text: statusButton.text
					color: statusButton.foreground
					font.pixelSize: statusButton.pixelSize
					font.weight: Font.Medium
				}

				MouseArea {
					id: statusMouse
					anchors.fill: parent
					acceptedButtons: Qt.LeftButton | Qt.RightButton
					hoverEnabled: true
					cursorShape: statusButton.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor

					onClicked: mouse => {
						if (!statusButton.clickable)
							return;
						if (mouse.button === Qt.RightButton)
							statusButton.rightClicked();
						else
							statusButton.clicked();
					}
				}
			}
		}
	}
}
