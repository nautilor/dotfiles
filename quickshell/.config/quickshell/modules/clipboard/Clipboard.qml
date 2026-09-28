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
	property string scriptPath: "$HOME/.config/quickshell/bin/clipse-visual.sh"
	property string query: ""
	property var entries: []
	property int selectedIndex: -1
	property bool loading: false

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
						text: "󰅌"
						color: root.textMuted
						font.pixelSize: 20
						font.weight: Font.Medium
					}

					TextField {
						id: input
						Layout.fillWidth: true
						placeholderText: "Search clipboard..."
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
							root.selectedIndex = filteredEntries.length > 0 ? 0 : -1
						}

						Keys.onEscapePressed: root.closeRequested()

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
								root.copySelected()
							} else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
								event.accepted = true
								root.removeSelected()
							} else if (event.key === Qt.Key_C && ctrl) {
								event.accepted = true
								root.closeRequested()
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
					model: filteredEntries
					currentIndex: root.selectedIndex
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

					delegate: ClipboardDelegate {
						clipboard: root
					}

					onCurrentIndexChanged: root.selectedIndex = currentIndex
					Keys.onReturnPressed: root.copySelected()
				}
			}
		}
	}

	function refreshClipboard() {
		loading = true
		listProc.running = true
	}

	function focusInput() {
		input.forceActiveFocus()
		input.selectAll()
	}

	function closeClipboard() {
		root.query = ""
		root.selectedIndex = -1
		input.text = ""
		root.closeRequested()
	}

	function copySelected() {
		const entry = filteredEntries[root.selectedIndex]
		if (!entry)
			return

		copyEntry(entry)
	}

	function removeSelected() {
		const entry = filteredEntries[root.selectedIndex]
		if (!entry)
			return

		removeEntry(entry)
	}

	function copyEntry(entry) {
		copyProc.command = [
			"bash",
			"-lc",
			`bash "${scriptPath}" copy "$1"`,
			"_",
			entry.raw
		]
		copyProc.running = true
		closeClipboard()
	}

	function removeEntry(entry) {
		removeProc.command = [
			"bash",
			"-lc",
			`bash "${scriptPath}" delete "$1"`,
			"_",
			entry.raw
		]
		removeProc.running = true
	}

	readonly property var filteredEntries: {
		const raw = Array.isArray(entries) ? entries : []
		const qv = query.trim().toLowerCase()
		if (!qv)
			return raw

		return raw.filter(entry => {
			if (!entry)
				return false
			const display = String(entry.display || "").toLowerCase()
			const rawId = String(entry.raw || "").toLowerCase()
			return display.includes(qv) || rawId.includes(qv)
		})
	}

	onFilteredEntriesChanged: {
		if (filteredEntries.length === 0) {
			root.selectedIndex = -1
		} else if (root.selectedIndex >= filteredEntries.length) {
			root.selectedIndex = filteredEntries.length - 1
		}
	}

	onVisibleChanged: {
		if (visible) {
			if (barWindow) {
				barWindow.quickPanelOpen = false
				barWindow.launcherPanelOpen = false
			}
			root.query = ""
			input.text = ""
			root.selectedIndex = -1
			refreshClipboard()
			focusInput()
		}
	}

	Process {
		id: listProc
		running: false
		command: ["bash", "-lc", `bash "${scriptPath}" list`]
		stdout: StdioCollector {
			onStreamFinished: {
				const out = []
				const lines = text.split("\n")
				for (let i = 0; i < lines.length; i++) {
					const line = lines[i]
					if (!line)
						continue

					const tabIdx = line.indexOf("\t")
					if (tabIdx < 0)
						continue

					const raw = line.substring(0, tabIdx)
					const display = line.substring(tabIdx + 1)
					const imagePathIdx = display.indexOf("\t")
					const cleanDisplay = imagePathIdx >= 0 ? display.substring(0, imagePathIdx) : display
					const imagePath = imagePathIdx >= 0 ? display.substring(imagePathIdx + 1) : ""

					out.push({
						raw: raw,
						display: cleanDisplay,
						imagePath: imagePath,
						isImage: imagePath !== "",
					})
				}

				entries = out
				loading = false
				selectedIndex = out.length > 0 ? 0 : -1
			}
		}

		onRunningChanged: {
			if (!running)
				loading = false
		}
	}

	Process {
		id: copyProc
		running: false
	}

	Process {
		id: removeProc
		running: false
		onRunningChanged: {
			if (!running)
				refreshClipboard()
		}
	}
}
