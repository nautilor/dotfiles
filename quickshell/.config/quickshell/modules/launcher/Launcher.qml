import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

Scope {
	id: launcherScope

	PanelWindow {
		id: launcher

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
		implicitWidth: 500
		implicitHeight: 700
		exclusionMode: ExclusionMode.Normal
		focusable: true

		anchors {
			bottom: true
			left: true
		}

		readonly property color bgPrimary:    "#16161f"   // window background
		readonly property color bgSecondary:  "#1f2030"   // panels / cards
		readonly property color bgHighlight:  "#2a2a2a"   // hover / selection
		readonly property color border:       "#3d3d3d"   // subtle borders

		readonly property color textPrimary:  "#A9B1D6"   // primary text
		readonly property color textMuted:    "#C8D3F5"   // secondary / disabled

		readonly property color accent:       "#3B4261"   // Adwaita blue
		readonly property color accentBright: "#545C7E"   // hover / active blue

		readonly property color success:      "#57e389"   // Adwaita green

		property string query: ""

		Item {
			anchors.fill: parent

			RectangularShadow {
				anchors.fill: mainWindow
				radius: mainWindow.radius
				blur: 5
				spread: 0.2
				color: Qt.darker(mainWindow.color, 1.6)
			}	

			Rectangle {
				id: mainWindow
				anchors.fill: parent
				color: launcher.bgPrimary
				anchors.centerIn: parent
				anchors.margins: 8
				opacity: 1
				radius: 16
				border.width: 0
				border.color: launcher.border

				layer.enabled: true
			}

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: 24	
				spacing: 16



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
						const parts = cmd.slice(1).split(" ").filter(p => p.trim() !== "");
						const command = parts[0];
						const args = parts.slice(1);

						// Example commands
						if (command === "open" || command === "o") {
							// Open a URL or file
							if (args.length > 0) {
								const target = args.join(" ");
								return [{
									name: `Open ${target}`,
									comment: `Open ${target} with default application`,
									icon: "document-open",
									execute: function() {
										if (target.startsWith("http://") || target.startsWith("https://")) {
											// Open URL
											Qt.openUrlExternally(target);
										} else {
											// Open file
											Qt.openUrlExternally("https://" + target);
										}
										Qt.quit();
									}
								}];
							} 
							return [{
								name: "Open Command",
								comment: "Usage: :open, :o <URL>",
								icon: "document-open",
								execute : function() {}
							}];	
						} else if (command === "calc" || command === "c") {
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
											Qt.quit();
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
								comment: "Usage: :calc, :c <expression>",
								icon: "accessories-calculator",
								execute : function() {}
							}];
						} else if (command === "google" || command === "g") {
							// Google search
							if (args.length > 0) {
								const query = args.join(" ");
								return [{
									name: `Search Google for "${query}"`,
									comment: `Open in web browser`,
									icon: "internet-web-browser",
									execute: function() {
										const url = "https://www.google.com/search?q=" + encodeURIComponent(query);
										Qt.openUrlExternally(url);
										Qt.quit();
									}
								}];
							}
							return [{
								name: "Google Search Command",
								comment: "Usage: :google, :g <search terms>",
								icon: "internet-web-browser",
								execute : function() {}
							}];
						} else if (command === "youtube" || command === "y") {
							// YouTube search
							if (args.length > 0) {
								const query = args.join(" ");
								return [{
									name: `Search YouTube for "${query}"`,
									comment: `Open in web browser`,
									icon: "applications-multimedia",
									execute: function() {
										const url = "https://www.youtube.com/results?search_query=" + encodeURIComponent(query);
										Qt.openUrlExternally(url);
										Qt.quit();
									}
								}];
							}
							return [{
								name: "YouTube Search Command",
								comment: "Usage: :youtube, :y <search terms>",
								icon: "applications-multimedia",
								execute : function() {}
							}];
						}
						return [{
							name: "Unknown command",
							comment: `No such command: ${command}`,
							icon: "dialog-error",
							execute: function() {}
						}];
					}

					values: {
						const allEntries = [...DesktopEntries.applications.values];
						const q = launcher.query.trim().toLowerCase();
						if (q.startsWith(":")) {
							if (q.length === 1) {
								return [{
									name: "Command Mode",
									comment: "Enter a command to execute custom actions",
									icon: "system-run",
									execute: function() {}
								},
								{
									name: "Calculator",
									comment: "Examples: :calc 2+2 , :c sqrt(16)",
									icon: "accessories-calculator",
									execute: function() {}
								},
								{
									name: "Open URL or File",
									comment: "Examples: :open https://example.com , :o example.com",
									icon: "document-open",
									execute: function() {}
								},
								{
									name: "Google Search",
									comment: "Examples: :google cats , :g qt framework",
									icon: "internet-web-browser",
									execute: function() {}
								},
								{
									name: "YouTube Search",
									comment: "Examples: :youtube music videos , :y funny cats",
									icon: "applications-multimedia",
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
							return [{
								name: "Search the web",
								comment: `No results found for "${launcher.query}", search the web instead`,
								icon: "internet-web-browser",
								execute: function() {
									const url = "https://www.google.com/search?q=" + encodeURIComponent(launcher.query);
									Qt.openUrlExternally(url);
									Qt.quit();
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
					spacing: 6
					orientation: ListView.Vertical
					keyNavigationWraps: false
					preferredHighlightBegin: 0
					preferredHighlightEnd: height
					highlightRangeMode: ListView.ApplyRange
					highlightMoveDuration: 150
					highlightMoveVelocity: -1

					highlight: Rectangle {
						radius: 10
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
							radius: 10
							width: parent.width
							height: parent.height

							RowLayout {
								anchors.fill: parent
								anchors.margins: 12
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
										text: modelData.comment
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
					height: 56
					color: launcher.bgSecondary
					radius: 12
					border.width: 0
					border.color: launcher.accent

					Behavior on border.color {
						ColorAnimation { duration: 200 }
					}

					RowLayout {
						anchors.fill: parent
						anchors.margins: 8
						anchors.leftMargin: 24
						anchors.rightMargin: 24
						spacing: 12

						Text {
							text: ""
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
							leftPadding: 5
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
			launcher.input.focus = true;
			launcher.input.selectAll();
		}
	}
}
}
