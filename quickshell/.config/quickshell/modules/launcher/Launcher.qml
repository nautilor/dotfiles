import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "../shared" as Shared

Scope {
	id: launcherScope

	PanelWindow {
		id: launcher
		Shared.Theme { id: theme }

		function resetLauncher() {
			launcher.visible = false;
			launcher.query = "";
			input.text = "";
		}

		function launchSelected() {
			if (list.currentItem && list.currentItem.modelData) {
				list.currentItem.modelData.execute();
				launcher.resetLauncher();
			}
		}

		visible: false
		color: "transparent"
		implicitWidth: theme.floatingWindowWidth
		implicitHeight: theme.floatingWindowHeight
		exclusionMode: ExclusionMode.Normal
		focusable: true

		anchors {
			bottom: true
			left: true

		}

		margins {
		}

		readonly property color bgPrimary: theme.background
		readonly property color bgSecondary: theme.surface
		readonly property color bgHighlight: theme.surfaceVariant
		readonly property color border: theme.outline
		readonly property color textPrimary: theme.surfaceText
		readonly property color textMuted: theme.surfaceVariantText
		readonly property color accent: theme.primaryContainer
		readonly property color accentBright: theme.primary
		readonly property color success: theme.success

		property string query: ""

		Item {
			anchors.fill: parent

			RectangularShadow {
				anchors.fill: mainWindow
				radius: theme.floatingWindowRadius
				bottomRightRadius: theme.floatingWindowRadius
				bottomLeftRadius: theme.floatingWindowRadius
				blur: 5
				spread: 0.2
				offset: Qt.point(0, 4)
				color: Qt.darker(mainWindow.color, 1.6)
			}	

			Rectangle {
				id: mainWindow
				anchors.fill: parent
				color: launcher.bgPrimary
				anchors.centerIn: parent
				anchors.margins: theme.floatingWindowMargin
				opacity: 1
				radius: theme.floatingWindowRadius
				bottomRightRadius: theme.floatingWindowRadius
				bottomLeftRadius: theme.floatingWindowRadius
				border.width: 0
				border.color: launcher.border

				layer.enabled: true
			}

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: theme.floatingContentPadding
				spacing: theme.largeGap



				ScriptModel {
					id: filtered

					function safeMathEval(expr) {
						expr = expr.replace(/\s+/g, '');

						const replacements = {
							'sqrt': 'Math.sqrt',
							'sin': 'Math.sin',
							'cos': 'Math.cos',
							'tan': 'Math.tan',
							'asin': 'Math.asin',
							'acos': 'Math.acos',
							'atan': 'Math.atan',
							'log': 'Math.log',
							'ln': 'Math.log',
							'log10': 'Math.log10',
							'abs': 'Math.abs',
							'ceil': 'Math.ceil',
							'floor': 'Math.floor',
							'round': 'Math.round',
							'exp': 'Math.exp',
							'pow': 'Math.pow',
							'min': 'Math.min',
							'max': 'Math.max',
							'pi': 'Math.PI',
							'e': 'Math.E'
						};

						// Replace function names
						for (let key in replacements) {
							let regex = new RegExp('\\b' + key + '\\b', 'gi');
							expr = expr.replace(regex, replacements[key]);
						}

						// Replace ^ with ** for exponentiation
						expr = expr.replace(/\^/g, '**');

						return Function('"use strict"; return (' + expr + ')')();
					}

					function parseCommand(cmd) {
						const command = cmd.slice(1).trim();
						const args = command.split(/\s+/);

						if (command !== "") {
							if (args.length > 0) {
								try {
									const expression = args.join(" ");
									const result = safeMathEval(expression);

									// Format the result nicely
									let formattedResult;
									if (typeof result === 'number') {
										if (Number.isInteger(result)) {
											formattedResult = result.toString();
										} else {
											// Remove trailing zeros
											formattedResult = parseFloat(result.toFixed(10)).toString();
										}
									} else {
										formattedResult = result.toString();
									}

									return [{
										name: "Calculate: " + expression,
										comment: "Result: " + formattedResult,
										icon: "accessories-calculator",
										execute: function() {
											launcher.resetLauncher();
										}
									}];
								} catch (e) {
									return [{
										name: "Invalid expression",
										comment: "Error: " + e.message,
										icon: "dialog-error",
										execute: function() {}
									}];
								}
							}
							return [{
								name: "Calculator Command",
								comment: "Usage: :<expression>",
								icon: "accessories-calculator",
								execute : function() {}
							}];
						}
					}

						values: {
							const allEntries = [...DesktopEntries.applications.values];
							const q = launcher.query.trim().toLowerCase();
							if (q.startsWith(":")) {
								if (q.length === 1) {
									return [{
										name: "Calculator",
										comment: "Examples: :2+2, :sqrt(16)",
										icon: "accessories-calculator",
										execute: function() {}
									}];
								}
								return parseCommand(q);
							}
							allEntries.sort((a, b) => a.name.localeCompare(b.name));

							if (q === "") {
								return allEntries;
							} else {
								const entries = allEntries.filter(d => 
								d.name && d.name.toLowerCase().includes(q) || d.exec && d.exec.toLowerCase().includes(q)
							);
							if (entries.length === 0) {
								// check if query looks like a URL
								const urlPattern = /^(https?:\/\/)?([\w-]+\.)+[\w-]+(\/[\w\-._~:/?#[\]@!$&'()*+,;=]*)?$/;
								if (urlPattern.test(q)) {
									const url = q.startsWith("http://") || q.startsWith("https://") ? q : "https://" + q;
									return [{
										name: `Open ${url}`,
										comment: `Open ${url} with default application`,
										icon: "document-open",
										execute: function() {										
											Qt.openUrlExternally(url);
											launcher.resetLauncher();
										}
									}];
								}
								return [{
									name: "Search the web",
									comment: `No results found for "${launcher.query}", search the web instead`,
									icon: "internet-web-browser",
									execute: function() {
										const url = "https://www.google.com/search?q=" + encodeURIComponent(launcher.query);
										Qt.openUrlExternally(url);
										launcher.resetLauncher();
									}
								}];
							} else {
								return entries;
							}
						}
					}
				}

				// Results list
				ScrollView {
					Layout.fillWidth: true
					Layout.fillHeight: true
					clip: true
					ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
					ScrollBar.vertical.policy: ScrollBar.AlwaysOff

					ListView {
						id: list
						model: filtered.values
						currentIndex: filtered.values.length > 0 ? 0 : -1
						spacing: theme.listGap
						orientation: ListView.Vertical
						keyNavigationWraps: false
						preferredHighlightBegin: 0
						preferredHighlightEnd: height
						highlightRangeMode: ListView.ApplyRange
						highlightMoveDuration: 150
						highlightMoveVelocity: -1

						highlight: Rectangle {
							radius: theme.listItemRadius
							color: launcher.accent
							opacity: 0.75

							Behavior on y {
								NumberAnimation { 
									duration: 150
									easing.type: Easing.OutCubic
								}
							}
						}

						delegate: Item {
							id: entry
							required property var modelData
							required property int index
							width: parent.width
							height: 67

							MouseArea {
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor

								onClicked: list.currentIndex = entry.index
								onDoubleClicked: launcher.launchSelected()
							}
							Rectangle {

								color: "transparent"
								radius: theme.listItemRadius
								width: parent.width
								height: parent.height

								RowLayout {
									anchors.fill: parent
									anchors.margins: theme.listItemPadding
									spacing: 0

									// Icon container
									Rectangle {
										width: parent.height
										height: parent.height
										radius: 10
										color: "transparent"
										Layout.alignment: Qt.AlignCenter

										IconImage {
											anchors.centerIn: parent
											source: Quickshell.iconPath(modelData.icon, true)
											width: parent.width - 8
											height: parent.height - 8
											smooth: true
										}
									}
									ColumnLayout {
										Layout.fillWidth: true
										Layout.leftMargin: 6
										Layout.rightMargin: 6
										// App name
										Text {
											Layout.fillWidth: true
											Layout.leftMargin: 4
											Layout.rightMargin: 4
											color: launcher.textPrimary
											text: modelData.name
											font.pixelSize: 14
											font.weight: Font.Medium
											elide: Text.ElideRight
											verticalAlignment: Text.AlignVCenter
											horizontalAlignment: Text.AlignLeft
										}
										Text {
											Layout.fillWidth: true
											Layout.leftMargin: 4
											Layout.rightMargin: 4
											color: launcher.textMuted
											opacity: 0.8
											text: modelData.comment ? modelData.comment : "No description available"
											font.pixelSize: 12
											font.weight: Font.Medium
											elide: Text.ElideRight
											verticalAlignment: Text.AlignVCenter
											horizontalAlignment: Text.AlignLeft
										}
									}
								}

							}
						}

						Keys.onReturnPressed: launcher.launchSelected()
					}
				}

				Rectangle {
					Layout.fillWidth: true
					height: theme.searchFieldHeight
					color: launcher.bgSecondary
					radius: theme.searchFieldRadius
					border.width: 0
					border.color: launcher.accent

					Behavior on border.color {
						ColorAnimation { duration: 200 }
					}

					RowLayout {
						anchors.fill: parent
						anchors.margins: theme.searchFieldInset
						anchors.leftMargin: theme.searchFieldLeftPadding
						anchors.rightMargin: theme.searchFieldRightPadding
						spacing: theme.mediumGap

						Text {
							text: "󰍉"
							font.pixelSize: 22
							color: launcher.textMuted
						}

						TextField {
							id: input
							Layout.fillWidth: true
							placeholderText: "Search applications..."
							font.pixelSize: 16
							color: launcher.textPrimary
							selectionColor: launcher.accent
							selectedTextColor: launcher.bgPrimary
							focus: true
							leftPadding: theme.textFieldLeftPadding
							rightPadding: 0
							topPadding: 0
							bottomPadding: 0

							placeholderTextColor: launcher.textMuted

							onTextChanged: {
								launcher.query = text;
								list.currentIndex = filtered.values.length > 0 ? 0 : -1;
							}

							background: Rectangle {
								color: "transparent"
								border.width: 0
							}

							Keys.onEscapePressed: {
								launcher.resetLauncher();
							}
							Keys.onPressed: event => {
								const ctrl = event.modifiers & Qt.ControlModifier;
								if (event.key == Qt.Key_Up || event.key == Qt.Key_P && ctrl) {
									event.accepted = true;
									if (list.currentIndex > 0)
									list.currentIndex--;
								} else if (event.key == Qt.Key_Down || event.key == Qt.Key_N && ctrl) {
									event.accepted = true;
									if (list.currentIndex < list.count - 1)
									list.currentIndex++;
								} else if ([Qt.Key_Return, Qt.Key_Enter].includes(event.key)) {
									event.accepted = true;
									launcher.launchSelected();
								} else if (event.key == Qt.Key_C && ctrl) {
									event.accepted = true;
									launcher.resetLauncher();
								}
							}
						}
					}
				}

			}
		}
	}
	IpcHandler {
		target: "launcher"
		function toggle() {
			launcher.visible = !launcher.visible;
			if (launcher.visible) {
				input.focus = true;
				input.selectAll();
			}
		}
	}
}
