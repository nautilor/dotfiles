import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../shared" as Shared

Scope {
    id: windowSwitcherScope

    PanelWindow {
        id: windowSwitcher
        Shared.Theme { id: theme }

        property var allWindows: []
        property bool pendingOpen: false
        property string hintBuffer: ""
        property int hintLength: 1
        readonly property string hintAlphabet: "arstneioqwfpgjkluyxcvbmzhd"

        readonly property color bgPrimary: theme.background
        readonly property color bgSecondary: theme.surface
        readonly property color border: theme.outline
        readonly property color textPrimary: theme.surfaceText
        readonly property color textMuted: theme.surfaceVariantText
        readonly property color accent: theme.primaryContainer
        readonly property color accentBright: theme.primary
        readonly property color success: theme.success

        readonly property int previewWidth: 128 * 3
        readonly property int previewHeight: 76 * 3
        readonly property int switcherItemWidth: previewWidth + (theme.listItemPadding * 2)
        readonly property int switcherItemHeight: previewHeight + (theme.listItemPadding * 2)
        readonly property int switcherColumns: 5
        readonly property int switcherFramePadding: (theme.floatingWindowMargin * 2) + (theme.floatingContentPadding * 2)
        readonly property int switcherContentWidth: {
            const count = Math.max(1, allWindows.length);
            return (switcherItemWidth * count) + (theme.listGap * Math.max(0, count - 1));
        }

        // Calculate how many columns can actually fit on the screen to avoid going off-edge
        readonly property int effectiveColumns: Math.max(1, Math.min(switcherColumns, Math.floor((screen.width - switcherFramePadding + theme.listGap) / (switcherItemWidth + theme.listGap))))

        readonly property int switcherMaxContentWidth: effectiveColumns * switcherItemWidth + Math.max(0, effectiveColumns - 1) * theme.listGap

        visible: false
        color: "transparent"
				implicitWidth: (windowSwitcher.allWindows.length > 0) ? Math.min(switcherContentWidth, switcherMaxContentWidth) : switcherItemWidth
				implicitHeight: (windowSwitcher.allWindows.length > 0) ? Math.ceil(allWindows.length / windowSwitcher.effectiveColumns) * switcherItemHeight : switcherItemHeight
        exclusionMode: ExclusionMode.Normal
        focusable: true

        anchors {
        }

        margins {
        }

        function parseRows(text, keys) {
            return text.split("\n").filter(line => line.trim() !== "").map(line => {
                const parts = line.split("\t");
                const row = {};

                for (let index = 0; index < keys.length; index++)
                    row[keys[index]] = parts[index] || "";

                return row;
            });
        }

        function workspaceLabel(windowInfo) {
            if (windowInfo.workspaceName.startsWith("special:"))
                return "special " + windowInfo.workspaceName.slice("special:".length);
            if (windowInfo.workspaceName !== "")
                return "ws " + windowInfo.workspaceName;
            if (windowInfo.workspaceId !== "")
                return "ws " + windowInfo.workspaceId;
            return "unknown workspace";
        }

        function windowLabel(windowInfo) {
            const title = windowInfo.title.trim();
            const className = windowInfo.className.trim();

            if (title !== "")
                return title;
            if (className !== "")
                return className;
            return "Window";
        }

        function fallbackPreviewText(windowInfo) {
            const source = (windowInfo.className || windowInfo.title || "??").trim();

            if (source === "")
                return "??";

            const parts = source.split(/[\s._-]+/).filter(part => part !== "");
            if (parts.length >= 2)
                return (parts[0][0] + parts[1][0]).toUpperCase();

            return source.slice(0, 2).toUpperCase();
        }

        function toplevelForAddress(address) {
            return ToplevelManager.toplevels.values.find(toplevel => {
                if (!toplevel || !toplevel.HyprlandToplevel)
                    return false;

                return `0x${toplevel.HyprlandToplevel.address}` === address;
            }) || null;
        }

        function hintLengthForCount(count) {
            let length = 1;
            let capacity = windowSwitcher.hintAlphabet.length;

            while (count > capacity) {
                length++;
                capacity *= windowSwitcher.hintAlphabet.length;
            }

            return length;
        }

        function hintForIndex(index, length) {
            const base = windowSwitcher.hintAlphabet.length;
            let value = index;
            let hint = "";

            for (let position = 0; position < length; position++) {
                hint = windowSwitcher.hintAlphabet[value % base] + hint;
                value = Math.floor(value / base);
            }

            return hint;
        }

        function resetHintBuffer() {
            windowSwitcher.hintBuffer = "";
            hintResetTimer.restart();
        }

        function syncSelectionToHint() {
            if (windowSwitcher.hintBuffer === "")
                return;

            const matchIndex = windowSwitcher.allWindows.findIndex(windowInfo => windowInfo.hint.startsWith(windowSwitcher.hintBuffer));
						if (matchIndex >= 0)
						gridLayout.currentIndex = matchIndex;
					}

					function handleHintInput(text) {
						if (text.length !== 1)
						return false;

						const key = text.toLowerCase();
						if (!windowSwitcher.hintAlphabet.includes(key))
						return false;

						const nextBuffer = (windowSwitcher.hintBuffer + key).slice(-windowSwitcher.hintLength);
						const exactIndex = windowSwitcher.allWindows.findIndex(windowInfo => windowInfo.hint === nextBuffer);

						windowSwitcher.hintBuffer = nextBuffer;
						hintResetTimer.restart();
						windowSwitcher.syncSelectionToHint();

						if (nextBuffer.length < windowSwitcher.hintLength)
						return true;

						if (exactIndex >= 0) {
							gridLayout.currentIndex = exactIndex;
							windowSwitcher.focusSelected();
						} else {
							windowSwitcher.resetHintBuffer();
						}

						return true;
					}

					function closeMenu() {
						windowSwitcher.pendingOpen = false;
						windowSwitcher.visible = false;
						focusGrab.active = false;
						windowSwitcher.hintBuffer = "";
						windowSwitcher.allWindows = [];
					}

					function openMenu() {
						if (fetchWindows.running)
						return;

						windowSwitcher.pendingOpen = true;
						windowSwitcher.hintBuffer = "";
						fetchWindows.running = true;
					}

					function toggleMenu() {
						if (windowSwitcher.visible)
						windowSwitcher.closeMenu();
						else
						windowSwitcher.openMenu();
					}

					function focusSelected() {
						if (focusProcess.running || !gridLayout.currentItem)
						return;

						gridLayout.currentItem.activateWindow();
					}

					HyprlandFocusGrab {
						id: focusGrab
						windows: [windowSwitcher]
						onCleared: windowSwitcher.closeMenu()
					}

					Timer {
						id: hintResetTimer
						interval: 1100
						repeat: false
						onTriggered: windowSwitcher.hintBuffer = ""
					}

					Process {
						id: fetchWindows
						command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/window-switcher.sh" list']
						stdout: StdioCollector {
							onStreamFinished: {
								const rows = windowSwitcher.parseRows(this.text, [
									"address",
									"workspaceId",
									"workspaceName",
									"className",
									"title",
									"monitorName",
									"active",
								]);

								windowSwitcher.hintLength = windowSwitcher.hintLengthForCount(rows.length);
								windowSwitcher.allWindows = rows.map((windowInfo, index) => ({
									address: windowInfo.address,
									workspaceId: windowInfo.workspaceId,
									workspaceName: windowInfo.workspaceName,
									className: windowInfo.className,
									title: windowInfo.title,
									monitorName: windowInfo.monitorName,
									active: windowInfo.active === "true",
									hint: windowSwitcher.hintForIndex(index, windowSwitcher.hintLength),
									currentIndex: index
								}));
								gridLayout.currentIndex = windowSwitcher.allWindows.length > 0 ? 0 : -1;

								if (windowSwitcher.pendingOpen) {
									windowSwitcher.pendingOpen = false;
									windowSwitcher.visible = true;
									focusGrab.active = true;
									hintResetTimer.restart();
									mainWindow.forceActiveFocus();
								}
							}
						}
					}

					Process {
						id: focusProcess
						property string targetAddress: ""
						command: ["bash", "-lc", 'bash "$HOME/.config/quickshell/bin/window-switcher.sh" focus "$1"', "_", targetAddress]

						onRunningChanged: {
							if (!running && targetAddress !== "") {
								targetAddress = "";
								windowSwitcher.closeMenu();
							}
						}
					}

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
							color: windowSwitcher.bgPrimary
							radius: theme.floatingWindowRadius
							border.width: 0
							border.color: windowSwitcher.border
							clip: true
							focus: true

							Keys.onPressed: event => {
								const ctrl = event.modifiers & Qt.ControlModifier;
								const hasWindows = windowSwitcher.allWindows.length > 0;

								if (event.key === Qt.Key_Escape || event.key === Qt.Key_Q && ctrl) {
									windowSwitcher.closeMenu();
								} else if (hasWindows && (event.key === Qt.Key_Right || event.key === Qt.Key_N && ctrl || event.key === Qt.Key_L && ctrl)) {
									gridLayout.moveHorizontally(1);
									windowSwitcher.resetHintBuffer();
								} else if (hasWindows && (event.key === Qt.Key_Left || event.key === Qt.Key_P && ctrl || event.key === Qt.Key_H && ctrl)) {
									gridLayout.moveHorizontally(-1);
									windowSwitcher.resetHintBuffer();
								} else if (hasWindows && (event.key === Qt.Key_Down || event.key === Qt.Key_J && ctrl)) {
									gridLayout.moveVertically(1);
									windowSwitcher.resetHintBuffer();
								} else if (hasWindows && (event.key === Qt.Key_Up || event.key === Qt.Key_K && ctrl)) {
									gridLayout.moveVertically(-1);
									windowSwitcher.resetHintBuffer();
								} else if (hasWindows && (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
									windowSwitcher.focusSelected();
								} else if (event.key === Qt.Key_C && ctrl) {
									windowSwitcher.closeMenu();
								} else if (windowSwitcher.handleHintInput(event.text)) {
									event.accepted = true;
									return;
								}

								event.accepted = true;
							}

							ColumnLayout {
								anchors.fill: parent
								spacing: theme.largeGap

								Item {
									Layout.fillWidth: true
									Layout.fillHeight: true

									ScrollView {
										anchors.fill: parent
										clip: true
										ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
										ScrollBar.vertical.policy: ScrollBar.AlwaysOff

										GridLayout {
											id: gridLayout
											property int currentIndex: 0
											readonly property int itemCount: windowSwitcher.allWindows.length
											readonly property var currentItem: currentIndex >= 0 ? gridRepeater.itemAt(currentIndex) : null
											columns: windowSwitcher.effectiveColumns
											columnSpacing: theme.listGap

											function moveHorizontally(step) {
												if (itemCount === 0)
													return;

												currentIndex = (currentIndex + step + itemCount) % itemCount;
											}

											function moveVertically(step) {
												if (itemCount === 0)
													return;

												const column = currentIndex % columns;
												let nextIndex = currentIndex + (step * columns);

												if (nextIndex >= 0 && nextIndex < itemCount) {
													currentIndex = nextIndex;
													return;
												}

												if (step > 0) {
													currentIndex = Math.min(column, itemCount - 1);
													return;
												}

												const lastRow = Math.floor((itemCount - 1) / columns);
												nextIndex = column + (lastRow * columns);
												currentIndex = nextIndex < itemCount ? nextIndex : itemCount - 1;
											}

											Repeater {
												id: gridRepeater
												model: windowSwitcher.allWindows
												// highlightRangeMode: ListView.ApplyRange
												// highlightMoveDuration: 150
												// highlightMoveVelocity: -1
												// preferredHighlightBegin: 0
												// preferredHighlightEnd: width

												// highlight: Rectangle {
												// 	radius: theme.listItemRadius
												// 	color: windowSwitcher.accent
												// 	opacity: 0.75
												//
												// 	Behavior on y {
												// 		NumberAnimation {
												// 			duration: 150
												// 			easing.type: Easing.OutCubic
												// 		}
												// 	}
												// }
											delegate: Item {
												id: entry
												required property var modelData
												required property int index
												readonly property bool isCurrentItem: index === gridLayout.currentIndex

												width: windowSwitcher.switcherItemWidth
												height: windowSwitcher.switcherItemHeight
												readonly property var matchedToplevel: windowSwitcher.toplevelForAddress(modelData.address)

												function activateWindow() {
													if (focusProcess.running)
													return;

													focusProcess.targetAddress = modelData.address;
													focusProcess.running = true;
												}

												MouseArea {
													anchors.fill: parent
													hoverEnabled: true
													cursorShape: Qt.PointingHandCursor

													onEntered: gridLayout.currentIndex = entry.index
													onClicked: {
														gridLayout.currentIndex = entry.index;
														entry.activateWindow();
													}
												}

												Rectangle {
													anchors.fill: parent
													color: "transparent"
													radius: theme.listItemRadius

													Rectangle {
														anchors.centerIn: parent
														width: windowSwitcher.previewWidth
														height: windowSwitcher.previewHeight
														radius: theme.listItemSmallRadius
														color: entry.isCurrentItem ? Qt.rgba(1, 1, 1, 0.10) : windowSwitcher.bgSecondary
														border.width: entry.matchedToplevel ? 1 : 0
														border.color: Qt.rgba(255, 255, 255, 0.08)
														clip: true

														Rectangle {
															z: 2
															anchors.left: parent.left
															anchors.top: parent.top
															anchors.margins: 8
															radius: 8
															color: entry.isCurrentItem ? windowSwitcher.accentBright : (modelData.active ? windowSwitcher.success : Qt.rgba(255, 255, 255, 0.12))
															border.width: 1
															border.color: Qt.rgba(255, 255, 255, 0.12)
															implicitWidth: hintText.implicitWidth + 20
															implicitHeight: hintText.implicitHeight + 10

															Text {
																id: hintText
																anchors.centerIn: parent
																text: modelData.hint.toUpperCase()
																color: modelData.active ? windowSwitcher.bgPrimary : windowSwitcher.bgPrimary
																font.pixelSize: 14
																font.weight: Font.DemiBold
															}
														}

														Rectangle {
															z: 2
															anchors.right: parent.right
															anchors.top: parent.top
															anchors.margins: 10
															width: 10
															height: 10
															radius: 5
															visible: modelData.active
															color: windowSwitcher.success
															border.width: 1
															border.color: Qt.rgba(1, 1, 1, 0.18)
														}

														ScreencopyView {
															anchors.fill: parent
															visible: entry.matchedToplevel
															captureSource: entry.matchedToplevel
															live: true
														}

														// Application icon badge to help distinguish windows
														IconImage {
															z: 3
															anchors.left: parent.left
															anchors.bottom: parent.bottom
															anchors.margins: 8
															implicitSize: Math.min(32, Math.max(20, windowSwitcher.previewHeight / 6))
															// Best-effort icon lookup from className; fall back to lowercase title initials
															source: Quickshell.iconPath((modelData.className || modelData.title || "").toString().toLowerCase().replace(/\s+/g, "-"), true)
															visible: source !== ""
														}

														Column {
															anchors.centerIn: parent
															visible: !entry.matchedToplevel
															spacing: theme.microGap

															Text {
																anchors.horizontalCenter: parent.horizontalCenter
																text: windowSwitcher.fallbackPreviewText(modelData)
																color: windowSwitcher.textPrimary
																font.pixelSize: 22
																font.weight: Font.DemiBold
															}

															Text {
																anchors.horizontalCenter: parent.horizontalCenter
																text: windowSwitcher.workspaceLabel(modelData)
																color: windowSwitcher.textMuted
																opacity: 0.85
																font.pixelSize: 10
																font.weight: Font.Medium
															}
														}
													}
												}
											}
										}

											Keys.onReturnPressed: windowSwitcher.focusSelected()
										}
									}

									Text {
										anchors.centerIn: parent
										visible: windowSwitcher.allWindows.length === 0
										text: "No windows open"
										color: windowSwitcher.textMuted
										opacity: 0.8
										font.pixelSize: 16
										font.weight: Font.Medium
									}
								}
							}
						}
					}
				}

				IpcHandler {
					target: "windowSwitcher"

					function toggle() {
						windowSwitcher.toggleMenu();
					}

					function open() {
						windowSwitcher.openMenu();
					}

					function close() {
						windowSwitcher.closeMenu();
					}
				}
			}
