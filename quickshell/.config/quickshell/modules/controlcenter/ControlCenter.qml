import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
	id: controlCenterScope

	PanelWindow {
		id: controlCenter

		property var state: ({})
		property var wifiNetworks: []
		property var bluetoothDevices: []

		readonly property color bgPrimary: "#16161f"
		readonly property color bgSecondary: "#1f2030"
		readonly property color bgTertiary: "#26283a"
		readonly property color musicSurface: "#2c2130"
		readonly property color border: "#3d3d3d"
		readonly property color divider: "#414868"
		readonly property color textPrimary: "#c8d3f5"
		readonly property color textMuted: "#a9b1d6"
		readonly property color accent: "#7aa2f7"
		readonly property color accentSoft: "#3B4261"
		readonly property color success: "#57e389"
		readonly property color danger: "#f7768e"
		readonly property color track: "#3a3f5a"
		readonly property color thumb: "#f6f7fb"

		property bool wifiEnabled: readBool("wifiEnabled", false)
		property string wifiLabel: readString("wifiLabel", "Wi-Fi off")
		property bool bluetoothEnabled: readBool("bluetoothEnabled", false)
		property string bluetoothLabel: readString("bluetoothLabel", "Bluetooth off")
		property int brightnessPercent: readInt("brightnessPercent", 0)
		property int volumePercent: readInt("volumePercent", 0)
		property bool volumeMuted: readBool("volumeMuted", false)
		property bool dndEnabled: readBool("dndEnabled", false)
		property bool mediaAvailable: readBool("mediaAvailable", false)
		property string mediaStatus: readString("mediaStatus", "Stopped")
		property string mediaTitle: readString("mediaTitle", "Nothing playing")
		property string mediaArtist: readString("mediaArtist", "Start media to show controls")

		function readBool(key, fallback) {
			const value = state[key];
			if (value === true || value === "true")
				return true;
			if (value === false || value === "false")
				return false;
			return fallback;
		}

		function readInt(key, fallback) {
			const parsed = parseInt(state[key]);
			return Number.isNaN(parsed) ? fallback : parsed;
		}

		function readString(key, fallback) {
			const value = state[key];
			if (value === undefined || value === null || value === "")
				return fallback;
			return value;
		}

		function parseKvOutput(text) {
			const nextState = {};
			const lines = text.split("\n").filter(line => line.trim() !== "");

			for (const line of lines) {
				const separator = line.indexOf("\t");
				if (separator === -1)
					continue;

				nextState[line.slice(0, separator)] = line.slice(separator + 1);
			}

			return nextState;
		}

		function parseRows(text, fields) {
			const rows = [];
			const lines = text.split("\n").filter(line => line.trim() !== "");

			for (const line of lines) {
				const parts = line.split("\t");
				const row = {};

				for (let i = 0; i < fields.length; ++i)
					row[fields[i]] = parts[i] !== undefined ? parts[i] : "";

				rows.push(row);
			}

			return rows;
		}

		function wifiSignalIcon(signal) {
			if (signal >= 80)
				return "󰤨";
			if (signal >= 55)
				return "󰤥";
			if (signal >= 30)
				return "󰤢";
			return "󰤟";
		}

		function closePanel() {
			controlCenter.visible = false;
			focusGrab.active = false;
		}

		function openPanel() {
			controlCenter.visible = true;
			focusGrab.active = true;
			controlCenter.refreshAll();
			mainWindow.forceActiveFocus();
		}

		function togglePanel() {
			if (controlCenter.visible)
				controlCenter.closePanel();
			else
				controlCenter.openPanel();
		}

		function refreshState() {
			if (!statusProcess.running)
				statusProcess.running = true;
		}

		function refreshLists() {
			if (!wifiListProcess.running)
				wifiListProcess.running = true;
			if (!bluetoothListProcess.running)
				bluetoothListProcess.running = true;
		}

		function refreshAll() {
			controlCenter.refreshState();
			controlCenter.refreshLists();
		}

		function runAction(actionName, actionValue) {
			if (actionProcess.running)
				return;

			actionProcess.actionName = actionName;
			actionProcess.actionValue = actionValue || "";
			actionProcess.running = true;
		}

		visible: false
		color: "transparent"
		implicitWidth: 500
		implicitHeight: 560
		exclusionMode: ExclusionMode.Normal
		focusable: true

		anchors {
			bottom: true
			right: true
		}

		margins {
			top: 0
			right: 0
		}

		HyprlandFocusGrab {
			id: focusGrab
			windows: [controlCenter]
			onCleared: controlCenter.closePanel()
		}

		Process {
			id: statusProcess
			command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/control-center.sh" status']
			stdout: StdioCollector {
				onStreamFinished: {
					controlCenter.state = controlCenter.parseKvOutput(this.text);

					if (!volumeSlider.pressed)
						volumeSlider.value = controlCenter.readInt("volumePercent", 0);
					if (!brightnessSlider.pressed)
						brightnessSlider.value = controlCenter.readInt("brightnessPercent", 0);
				}
			}
		}

		Process {
			id: wifiListProcess
			command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/control-center.sh" wifi-list']
			stdout: StdioCollector {
				onStreamFinished: {
					controlCenter.wifiNetworks = controlCenter.parseRows(this.text, ["active", "saved", "security", "signal", "ssid"]).map(network => ({
						active: network.active === "true",
						saved: network.saved === "true",
						security: network.security,
						signal: parseInt(network.signal) || 0,
						ssid: network.ssid
					}));
				}
			}
		}

		Process {
			id: bluetoothListProcess
			command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/control-center.sh" bluetooth-list']
			stdout: StdioCollector {
				onStreamFinished: {
					controlCenter.bluetoothDevices = controlCenter.parseRows(this.text, ["connected", "paired", "trusted", "address", "name"]).map(device => ({
						connected: device.connected === "true",
						paired: device.paired === "true",
						trusted: device.trusted === "true",
						address: device.address,
						name: device.name
					}));
				}
			}
		}

		Process {
			id: actionProcess
			property string actionName: ""
			property string actionValue: ""
			command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/control-center.sh" "$1" "$2"', "_", actionName, actionValue]
			onRunningChanged: {
				if (!running && actionName !== "") {
					actionName = "";
					actionValue = "";
					controlCenter.refreshAll();
				}
			}
		}

		Timer {
			interval: 5000
			running: controlCenter.visible
			repeat: true
			onTriggered: controlCenter.refreshAll()
		}

		Item {
			anchors.fill: parent

			RectangularShadow {
				anchors.fill: mainWindow
				radius: mainWindow.radius
				blur: 5
				spread: 0.2
				color: Qt.darker(controlCenter.bgPrimary, 1.6)
			}

			Rectangle {
				id: mainWindow
				anchors.fill: parent
				anchors.margins: 8
				radius: 22
				color: Qt.rgba(22 / 255, 22 / 255, 31 / 255, 1)
				border.width: 0
				border.color: Qt.rgba(97 / 255, 104 / 255, 139 / 255, 1)
				clip: true
				focus: true

				Keys.onPressed: event => {
					const ctrl = event.modifiers & Qt.ControlModifier;

					if (event.key === Qt.Key_Escape || event.key === Qt.Key_C && ctrl) {
						controlCenter.closePanel();
						event.accepted = true;
					} else if (event.key === Qt.Key_R && ctrl) {
						controlCenter.refreshAll();
						event.accepted = true;
					}
				}

				Rectangle {
					anchors.fill: parent
					color: Qt.rgba(255, 255, 255, 0)
				}

				Flickable {
					id: controlScroll
					anchors.fill: parent
					anchors.margins: 16
					clip: true
					contentWidth: width
					contentHeight: contentColumn.implicitHeight
					boundsBehavior: Flickable.OvershootBounds
					flickableDirection: Flickable.VerticalFlick
					interactive: contentHeight > height
					pixelAligned: false
					maximumFlickVelocity: 3200
					flickDeceleration: 2400

					ScrollBar.vertical: ScrollBar {
						policy: ScrollBar.AsNeeded
						width: 0

						contentItem: Rectangle {
							implicitWidth: 8
							radius: 4
							color: Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.55)
						}

						background: Rectangle {
							color: "transparent"
						}
					}

					ColumnLayout {
						id: contentColumn
						width: controlScroll.width
						spacing: 12
						Item {
							Layout.fillWidth: true
							implicitHeight: quickRow.implicitHeight

							RowLayout {
								id: quickRow
								anchors.left: parent.left
								anchors.right: parent.right
								spacing: 12

								Rectangle {
									Layout.fillWidth: true
									Layout.preferredWidth: 3
									implicitHeight: networkColumn.implicitHeight + 24
									radius: 18
									color: controlCenter.bgSecondary
									border.width: 1
									border.color: Qt.rgba(97 / 255, 104 / 255, 139 / 255, 0.24)

									ColumnLayout {
										id: networkColumn
										anchors.left: parent.left
										anchors.right: parent.right
										anchors.top: parent.top
										anchors.margins: 12
										spacing: 0

										Rectangle {
											Layout.fillWidth: true
											implicitHeight: 64
											radius: 14
											color: "transparent"

											MouseArea {
												anchors.fill: parent
												hoverEnabled: true
												cursorShape: Qt.PointingHandCursor
												onClicked: controlCenter.runAction("wifi-toggle")
											}

											RowLayout {
												anchors.fill: parent
												anchors.margins: 10
												spacing: 12

												Rectangle {
													width: 40
													height: 40
													radius: 20
													color: controlCenter.wifiEnabled ? controlCenter.accent : controlCenter.bgTertiary

													Text {
														anchors.centerIn: parent
														text: controlCenter.wifiEnabled ? "󰤨" : "󰤮"
														color: "#ffffff"
														font.pixelSize: 18
													}
												}

												ColumnLayout {
													Layout.fillWidth: true
													spacing: 2

													Text {
														text: "Wi-Fi"
														color: controlCenter.textPrimary
														font.pixelSize: 15
														font.weight: Font.DemiBold
													}

													Text {
														Layout.fillWidth: true
														text: controlCenter.wifiLabel
														color: controlCenter.textMuted
														font.pixelSize: 12
														elide: Text.ElideRight
													}
												}
											}
										}

										Rectangle {
											Layout.fillWidth: true
											height: 1
											color: controlCenter.divider
											opacity: 0.55
										}

										Rectangle {
											Layout.fillWidth: true
											implicitHeight: 64
											radius: 14
											color: "transparent"

											MouseArea {
												anchors.fill: parent
												hoverEnabled: true
												cursorShape: Qt.PointingHandCursor
												onClicked: controlCenter.runAction("bluetooth-toggle")
											}

											RowLayout {
												anchors.fill: parent
												anchors.margins: 10
												spacing: 12

												Rectangle {
													width: 40
													height: 40
													radius: 20
													color: controlCenter.bluetoothEnabled ? controlCenter.accent : controlCenter.bgTertiary

													Text {
														anchors.centerIn: parent
														text: controlCenter.bluetoothEnabled ? "󰂯" : "󰂲"
														color: "#ffffff"
														font.pixelSize: 18
													}
												}

												ColumnLayout {
													Layout.fillWidth: true
													spacing: 2

													Text {
														text: "Bluetooth"
														color: controlCenter.textPrimary
														font.pixelSize: 15
														font.weight: Font.DemiBold
													}

													Text {
														Layout.fillWidth: true
														text: controlCenter.bluetoothLabel
														color: controlCenter.textMuted
														font.pixelSize: 12
														elide: Text.ElideRight
													}
												}
											}
										}

										Rectangle {
											Layout.fillWidth: true
											height: 1
											color: controlCenter.divider
											opacity: 0.55
										}

										Rectangle {
											Layout.fillWidth: true
											implicitHeight: 64
											radius: 14
											color: "transparent"

											MouseArea {
												anchors.fill: parent
												hoverEnabled: true
												cursorShape: Qt.PointingHandCursor
												onClicked: controlCenter.runAction("volume-toggle-mute")
											}

											RowLayout {
												anchors.fill: parent
												anchors.margins: 10
												spacing: 12

												Rectangle {
													width: 40
													height: 40
													radius: 20
													color: controlCenter.volumeMuted ? controlCenter.bgTertiary : controlCenter.accent

													Text {
														anchors.centerIn: parent
														text: controlCenter.volumeMuted ? "󰝟" : "󰕾"
														color: "#ffffff"
														font.pixelSize: 18
													}
												}

												ColumnLayout {
													Layout.fillWidth: true
													spacing: 2

													Text {
														text: "Sound"
														color: controlCenter.textPrimary
														font.pixelSize: 15
														font.weight: Font.DemiBold
													}

													Text {
														Layout.fillWidth: true
														text: controlCenter.volumeMuted ? "Muted" : controlCenter.volumePercent + "% output"
														color: controlCenter.textMuted
														font.pixelSize: 12
														elide: Text.ElideRight
													}
												}
											}
										}
									}
								}

								Rectangle {
									Layout.fillWidth: true
									Layout.preferredWidth: 2
									implicitHeight: 216
									radius: 18
									color: controlCenter.bgSecondary
									border.width: 1
									border.color: Qt.rgba(97 / 255, 104 / 255, 139 / 255, 0.24)

									Rectangle {
										anchors.fill: parent
										anchors.margins: 12
										radius: 16
										color: controlCenter.dndEnabled ? Qt.rgba(247 / 255, 118 / 255, 142 / 255, 0.12) : controlCenter.bgTertiary
										border.width: 1
										border.color: controlCenter.dndEnabled ? Qt.rgba(247 / 255, 118 / 255, 142 / 255, 0.35) : Qt.rgba(97 / 255, 104 / 255, 139 / 255, 0.2)

										MouseArea {
											anchors.fill: parent
											hoverEnabled: true
											cursorShape: Qt.PointingHandCursor
											onClicked: controlCenter.runAction("dnd-toggle")
										}

										Column {
											anchors.fill: parent
											anchors.margins: 14
											spacing: 10

											Text {
												text: controlCenter.dndEnabled ? "󰂛" : "󰂚"
												color: controlCenter.dndEnabled ? controlCenter.danger : controlCenter.textPrimary
												font.pixelSize: 24
											}

											Text {
												text: "Do Not\nDisturb"
												color: controlCenter.textPrimary
												font.pixelSize: 16
												font.weight: Font.Medium
											}

											Text {
												width: parent.width
												text: controlCenter.dndEnabled ? "Notifications stay quiet until you turn this off." : "Allow banners and sounds from notifications."
												color: controlCenter.textMuted
												font.pixelSize: 12
												wrapMode: Text.WordWrap
											}
										}
									}
								}
							}
						}

						Rectangle {
							Layout.fillWidth: true
							implicitHeight: displaySection.implicitHeight + 28
							radius: 18
							color: controlCenter.bgSecondary
							border.width: 1
							border.color: Qt.rgba(97 / 255, 104 / 255, 139 / 255, 0.24)

							ColumnLayout {
								id: displaySection
								anchors.left: parent.left
								anchors.right: parent.right
								anchors.top: parent.top
								anchors.margins: 14
								spacing: 12

								Text {
									text: "Display"
									color: controlCenter.textPrimary
									font.pixelSize: 14
									font.weight: Font.Medium
								}

								RowLayout {
									Layout.fillWidth: true
									spacing: 12

									Text {
										text: "󰃠"
										color: controlCenter.textPrimary
										font.pixelSize: 18
									}

									Slider {
										id: brightnessSlider
										Layout.fillWidth: true
										Layout.preferredHeight: 24
										from: 1
										to: 100
										stepSize: 1
										onMoved: {
											if (pressed)
												controlCenter.runAction("brightness-set", Math.round(value).toString());
										}

										background: Rectangle {
											x: brightnessSlider.leftPadding
											y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
											width: brightnessSlider.availableWidth
											height: 8
											radius: 4
											color: controlCenter.track
										}

										handle: Rectangle {
											x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
											y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
											width: 18
											height: 18
											radius: 9
											color: controlCenter.thumb
											border.width: 1
											border.color: Qt.rgba(0, 0, 0, 0.08)
										}
									}
								}
							}
						}

						Rectangle {
							Layout.fillWidth: true
							implicitHeight: soundSection.implicitHeight + 28
							radius: 18
							color: controlCenter.bgSecondary
							border.width: 1
							border.color: Qt.rgba(97 / 255, 104 / 255, 139 / 255, 0.24)

							ColumnLayout {
								id: soundSection
								anchors.left: parent.left
								anchors.right: parent.right
								anchors.top: parent.top
								anchors.margins: 14
								spacing: 12

								Text {
									text: "Sound"
									color: controlCenter.textPrimary
									font.pixelSize: 14
									font.weight: Font.Medium
								}

								RowLayout {
									Layout.fillWidth: true
									spacing: 12

									Text {
										text: controlCenter.volumeMuted ? "󰝟" : "󰕾"
										color: controlCenter.textPrimary
										font.pixelSize: 18
									}

									Slider {
										id: volumeSlider
										Layout.fillWidth: true
										Layout.preferredHeight: 24
										from: 0
										to: 100
										stepSize: 1
										onMoved: {
											if (pressed)
												controlCenter.runAction("volume-set", Math.round(value).toString());
										}

										background: Rectangle {
											x: volumeSlider.leftPadding
											y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
											width: volumeSlider.availableWidth
											height: 8
											radius: 4
											color: controlCenter.track
										}

										handle: Rectangle {
											x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
											y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
											width: 18
											height: 18
											radius: 9
											color: controlCenter.thumb
											border.width: 1
											border.color: Qt.rgba(0, 0, 0, 0.08)
										}
									}

									Rectangle {
										width: 36
										height: 36
										radius: 18
										color: controlCenter.bgTertiary

										MouseArea {
											anchors.fill: parent
											hoverEnabled: true
											cursorShape: Qt.PointingHandCursor
											onClicked: controlCenter.runAction("volume-toggle-mute")
										}

										Text {
											anchors.centerIn: parent
											text: "󰓃"
											color: controlCenter.textPrimary
											font.pixelSize: 16
										}
									}
								}
							}
						}

						Rectangle {
							Layout.fillWidth: true
							implicitHeight: musicSection.implicitHeight + 28
							radius: 18
							color: controlCenter.musicSurface
							border.width: 1
							border.color: Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.18)

							RowLayout {
								id: musicSection
								anchors.left: parent.left
								anchors.right: parent.right
								anchors.top: parent.top
								anchors.margins: 14
								spacing: 12

								Rectangle {
									width: 48
									height: 48
									radius: 14
									color: "#c94f6d"

									RectangularShadow {
										anchors.fill: parent
										radius: parent.radius
										blur: 12
										spread: 0.05
										color: Qt.rgba(0.3, 0.1, 0.15, 0.45)
									}

									Text {
										anchors.centerIn: parent
										text: "󰎈"
										color: "#ffffff"
										font.pixelSize: 22
									}
								}

								ColumnLayout {
									Layout.fillWidth: true
									spacing: 2

									Text {
										Layout.fillWidth: true
										text: controlCenter.mediaTitle
										color: controlCenter.textPrimary
										font.pixelSize: 15
										font.weight: Font.DemiBold
										elide: Text.ElideRight
									}

									Text {
										Layout.fillWidth: true
										text: controlCenter.mediaArtist
										color: controlCenter.textMuted
										font.pixelSize: 12
										elide: Text.ElideRight
									}
								}

								RowLayout {
									spacing: 10

									Rectangle {
										width: 34
										height: 34
										radius: 17
										color: controlCenter.bgTertiary

										MouseArea {
											anchors.fill: parent
											hoverEnabled: true
											enabled: controlCenter.mediaAvailable
											cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
											onClicked: controlCenter.runAction("media-play-pause")
										}

										Text {
											anchors.centerIn: parent
											text: controlCenter.mediaStatus === "Playing" ? "󰏤" : "󰐊"
											color: controlCenter.textPrimary
											font.pixelSize: 16
										}
									}

									Rectangle {
										width: 34
										height: 34
										radius: 17
										color: controlCenter.bgTertiary

										MouseArea {
											anchors.fill: parent
											hoverEnabled: true
											enabled: controlCenter.mediaAvailable
											cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
											onClicked: controlCenter.runAction("media-next")
										}

										Text {
											anchors.centerIn: parent
											text: "󰒭"
											color: controlCenter.textPrimary
											font.pixelSize: 16
										}
									}
								}
							}
						}

						Rectangle {
							Layout.fillWidth: true
							implicitHeight: wifiSection.implicitHeight + 28
							radius: 18
							color: controlCenter.bgSecondary
							border.width: 1
							border.color: Qt.rgba(97 / 255, 104 / 255, 139 / 255, 0.24)

							ColumnLayout {
								id: wifiSection
								anchors.left: parent.left
								anchors.right: parent.right
								anchors.top: parent.top
								anchors.margins: 14
								spacing: 10

								RowLayout {
									Layout.fillWidth: true

									Text {
										text: "Wi-Fi Networks"
										color: controlCenter.textPrimary
										font.pixelSize: 14
										font.weight: Font.Medium
									}

									Item { Layout.fillWidth: true }

									Rectangle {
										width: 34
										height: 34
										radius: 17
										color: controlCenter.bgTertiary

										MouseArea {
											anchors.fill: parent
											hoverEnabled: true
											cursorShape: Qt.PointingHandCursor
											onClicked: controlCenter.runAction("wifi-rescan")
										}

										Text {
											anchors.centerIn: parent
											text: "󰑐"
											color: controlCenter.textPrimary
											font.pixelSize: 16
										}
									}
								}

								Text {
									visible: !controlCenter.wifiEnabled
									text: "Turn Wi-Fi on to see nearby networks."
									color: controlCenter.textMuted
									font.pixelSize: 12
								}

								Text {
									visible: controlCenter.wifiEnabled && controlCenter.wifiNetworks.length === 0
									text: "No networks found."
									color: controlCenter.textMuted
									font.pixelSize: 12
								}

								Repeater {
									model: controlCenter.wifiNetworks

									delegate: Rectangle {
										required property var modelData

										Layout.fillWidth: true
										implicitHeight: 56
										radius: 14
										color: modelData.active ? Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.14) : controlCenter.bgTertiary
										border.width: 1
										border.color: modelData.active ? Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.35) : Qt.rgba(97 / 255, 104 / 255, 139 / 255, 0.16)

										RowLayout {
											anchors.fill: parent
											anchors.margins: 12
											spacing: 10

											Text {
												text: controlCenter.wifiSignalIcon(modelData.signal)
												color: modelData.active ? controlCenter.accent : controlCenter.textMuted
												font.pixelSize: 18
											}

											ColumnLayout {
												Layout.fillWidth: true
												spacing: 2

												Text {
													Layout.fillWidth: true
													text: modelData.ssid
													color: controlCenter.textPrimary
													font.pixelSize: 13
													font.weight: Font.Medium
													elide: Text.ElideRight
												}

												Text {
													Layout.fillWidth: true
													text: (modelData.security !== "" ? modelData.security : "Open") + " • " + modelData.signal + "%"
													color: controlCenter.textMuted
													font.pixelSize: 11
													elide: Text.ElideRight
												}
											}

											Rectangle {
												width: wifiActionLabel.implicitWidth + 18
												height: 30
												radius: 10
												color: modelData.active ? controlCenter.success : controlCenter.accentSoft

												MouseArea {
													anchors.fill: parent
													hoverEnabled: true
													enabled: !modelData.active
													cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
													onClicked: controlCenter.runAction("wifi-connect", modelData.ssid)
												}

												Text {
													id: wifiActionLabel
													anchors.centerIn: parent
													text: modelData.active ? "Connected" : (modelData.saved ? "Join" : "Connect")
													color: modelData.active ? controlCenter.bgPrimary : controlCenter.textPrimary
													font.pixelSize: 11
													font.weight: Font.Medium
												}
											}
										}
									}
								}
							}
						}

						Rectangle {
							Layout.fillWidth: true
							implicitHeight: bluetoothSection.implicitHeight + 28
							radius: 18
							color: controlCenter.bgSecondary
							border.width: 1
							border.color: Qt.rgba(97 / 255, 104 / 255, 139 / 255, 0.24)

							ColumnLayout {
								id: bluetoothSection
								anchors.left: parent.left
								anchors.right: parent.right
								anchors.top: parent.top
								anchors.margins: 14
								spacing: 10

								Text {
									text: "Bluetooth Devices"
									color: controlCenter.textPrimary
									font.pixelSize: 14
									font.weight: Font.Medium
								}

								Text {
									visible: !controlCenter.bluetoothEnabled
									text: "Turn Bluetooth on to manage paired devices."
									color: controlCenter.textMuted
									font.pixelSize: 12
								}

								Text {
									visible: controlCenter.bluetoothEnabled && controlCenter.bluetoothDevices.length === 0
									text: "No paired devices found."
									color: controlCenter.textMuted
									font.pixelSize: 12
								}

								Repeater {
									model: controlCenter.bluetoothDevices

									delegate: Rectangle {
										required property var modelData

										Layout.fillWidth: true
										implicitHeight: 56
										radius: 14
										color: modelData.connected ? Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.14) : controlCenter.bgTertiary
										border.width: 1
										border.color: modelData.connected ? Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.35) : Qt.rgba(97 / 255, 104 / 255, 139 / 255, 0.16)

										RowLayout {
											anchors.fill: parent
											anchors.margins: 12
											spacing: 10

											Text {
												text: modelData.connected ? "󰂱" : "󰂯"
												color: modelData.connected ? controlCenter.accent : controlCenter.textMuted
												font.pixelSize: 18
											}

											ColumnLayout {
												Layout.fillWidth: true
												spacing: 2

												Text {
													Layout.fillWidth: true
													text: modelData.name
													color: controlCenter.textPrimary
													font.pixelSize: 13
													font.weight: Font.Medium
													elide: Text.ElideRight
												}

												Text {
													Layout.fillWidth: true
													text: modelData.address
													color: controlCenter.textMuted
													font.pixelSize: 11
													elide: Text.ElideRight
												}
											}

											Rectangle {
												width: bluetoothActionLabel.implicitWidth + 18
												height: 30
												radius: 10
												color: modelData.connected ? controlCenter.success : controlCenter.accentSoft

												MouseArea {
													anchors.fill: parent
													hoverEnabled: true
													cursorShape: Qt.PointingHandCursor
													onClicked: controlCenter.runAction("bluetooth-device-toggle", modelData.address)
												}

												Text {
													id: bluetoothActionLabel
													anchors.centerIn: parent
													text: modelData.connected ? "Disconnect" : "Connect"
													color: modelData.connected ? controlCenter.bgPrimary : controlCenter.textPrimary
													font.pixelSize: 11
													font.weight: Font.Medium
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

	IpcHandler {
		target: "controlCenter"

		function toggle() {
			controlCenter.togglePanel();
		}

		function open() {
			controlCenter.openPanel();
		}

		function close() {
			controlCenter.closePanel();
		}

		function refresh() {
			controlCenter.refreshAll();
		}
	}
}
