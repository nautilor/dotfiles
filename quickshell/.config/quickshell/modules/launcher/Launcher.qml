import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.modules.colors

Item {
	id: root

	signal closeRequested()

	property var barWindow: null
	property string query: ""

	Colors {
		id: colors
	}

	readonly property color bgPrimary: colors.windowBackground
	readonly property color bgSecondary: colors.quickToggleBackground
	readonly property color textPrimary: colors.windowForeground
	readonly property color textMuted: Qt.rgba(
		colors.windowForeground.r,
		colors.windowForeground.g,
		colors.windowForeground.b,
		0.65
	)
	readonly property color accent: colors.quickToggleActiveBackground
	readonly property color accentForeground: colors.quickToggleActiveForeground

	Functions {
		id: functions
		root: root
		input: input
		listView: listView
	}

	anchors.fill: parent

	Rectangle {
		id: panel
		anchors.fill: parent
		anchors.margins: 12
		color: root.bgPrimary
		radius: 24

		ColumnLayout {
			anchors.fill: parent
			spacing: 12

			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: 50
				radius: 50
				color: root.bgSecondary

				RowLayout {
					anchors.fill: parent
					anchors.leftMargin: 14
					anchors.rightMargin: 14
					spacing: 10

					Text {
						text: "󰍉"
						color: root.textMuted
						font.pixelSize: 20
						font.weight: Font.Medium
					}

					TextField {
						id: input
						Layout.fillWidth: true
						placeholderText: "Search applications..."
						font.pixelSize: 16
						color: root.textPrimary
						selectionColor: root.accent
						selectedTextColor: root.bgPrimary
						placeholderTextColor: root.textMuted
						focus: true

						background: Rectangle {
							color: "transparent"
							border.width: 0
						}

						onTextChanged: {
							root.query = text
							listView.currentIndex = filtered.values.length > 0 ? 0 : -1
						}

						Keys.onEscapePressed: {
							functions.resetLauncher()
						}

						Keys.onPressed: event => {
							const ctrl = event.modifiers & Qt.ControlModifier
							if (event.key === Qt.Key_Up || (event.key === Qt.Key_P && ctrl)) {
								event.accepted = true
								if (listView.currentIndex > 0)
									listView.currentIndex--
							} else if (event.key === Qt.Key_Down || (event.key === Qt.Key_N && ctrl)) {
								event.accepted = true
								if (listView.currentIndex < listView.count - 1)
									listView.currentIndex++
							} else if ([Qt.Key_Return, Qt.Key_Enter].includes(event.key)) {
								event.accepted = true
								functions.launchSelected()
							} else if (event.key === Qt.Key_C && ctrl) {
								event.accepted = true
								functions.resetLauncher()
							}
						}
					}
				}
			}

			ScrollView {
				Layout.fillWidth: true
				Layout.fillHeight: true
				clip: true
				ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
				ScrollBar.vertical.policy: ScrollBar.AlwaysOff

				ListView {
					id: listView
					model: filtered.values
					currentIndex: filtered.values.length > 0 ? 0 : -1
					spacing: 8
					keyNavigationWraps: false
					preferredHighlightBegin: 0
					preferredHighlightEnd: height
					highlightRangeMode: ListView.ApplyRange
					highlightMoveDuration: 150

					highlight: Rectangle {
						radius: 18
						color: root.accent
						opacity: 0.75
					}

					delegate: Item {
						id: entry
						required property var modelData
						required property int index

						width: ListView.view.width
						height: 60

						MouseArea {
							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: listView.currentIndex = entry.index
							onDoubleClicked: functions.launchSelected()
						}

						Rectangle {
							anchors.fill: parent
							radius: 18
							color: listView.currentIndex === entry.index
							? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20)
							: "transparent"
							border.width: 0

							RowLayout {
								anchors.fill: parent
								anchors.margins: 10
								spacing: 10

								Rectangle {
									Layout.preferredWidth: 40
									Layout.preferredHeight: 40
									radius: 12
									color: Qt.rgba(1, 1, 1, 0.06)

									IconImage {
										anchors.centerIn: parent
										implicitSize: 24
										source: Quickshell.iconPath(modelData.icon, true)
									}
								}

								ColumnLayout {
									Layout.fillWidth: true
									spacing: 2

									Text {
										Layout.fillWidth: true
										text: modelData.name
										color: root.textPrimary
										font.pixelSize: 14
										font.weight: Font.Medium
										elide: Text.ElideRight
									}

									Text {
										Layout.fillWidth: true
										text: modelData.comment ? modelData.comment : "No description available"
										color: root.textMuted
										opacity: 0.9
										font.pixelSize: 12
										elide: Text.ElideRight
									}
								}
							}
						}
					}

					Keys.onReturnPressed: functions.launchSelected()
				}
			}
		}

		ScriptModel {
			id: filtered
			values: functions.values()
		}
	}

	onVisibleChanged: {
		if (visible) {
			functions.focusInput()
		}
	}
}
