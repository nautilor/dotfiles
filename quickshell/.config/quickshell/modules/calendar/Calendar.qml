import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.colors

Item {
	id: root

	signal closeRequested()

	property var barWindow: null

	// "checking" | "no-client" | "logged-out" | "ready"
	property string authState: "checking"
	property string clientFile: "$HOME/.config/quickshell/gcal/client.json"
	property string errorText: ""
	property bool loading: false
	property bool loggingIn: false

	property date today: new Date()
	property int viewYear: today.getFullYear()
	property int viewMonth: today.getMonth()
	property date selected: new Date(today.getFullYear(), today.getMonth(), today.getDate())

	property var events: []
	property string loadedKey: ""
	property string requestedKey: ""

	// editor state
	property bool editing: false
	property bool saving: false
	property string editId: ""
	property string editCalendarId: ""
	property string editTitle: ""
	property string editLocation: ""
	property bool editAllDay: false
	property string editStartDate: ""
	property string editStartTime: ""
	property string editEndDate: ""
	property string editEndTime: ""
	property string editError: ""
	property var writableCalendars: []
	property bool reauth: false

	readonly property string scriptPath: Quickshell.env("HOME") + "/.config/quickshell/bin/gcal.py"
	readonly property string script: "$HOME/.config/quickshell/bin/gcal.py"
	readonly property var weekdayNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

	Colors {
		id: colors
	}

	readonly property color bgPrimary: colors.windowBackground
	readonly property color textPrimary: colors.windowForeground
	readonly property color textMuted: Qt.rgba(textPrimary.r, textPrimary.g, textPrimary.b, 0.65)
	readonly property color bgSecondary: colors.quickToggleBackground
	readonly property color accent: colors.quickToggleActiveBackground
	readonly property color accentForeground: colors.quickToggleActiveForeground
	readonly property color hoverFill: Qt.rgba(1, 1, 1, 0.06)

	// ─── date helpers ───────────────────────────────

	function startOfDay(d) {
		return new Date(d.getFullYear(), d.getMonth(), d.getDate())
	}

	function sameDay(a, b) {
		return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate()
	}

	function parseEventDate(str, allDay) {
		if (allDay) {
			const p = str.split("-")
			return new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))
		}
		return new Date(str)
	}

	function gridStart() {
		const first = new Date(viewYear, viewMonth, 1)
		const offset = (first.getDay() + 6) % 7
		return new Date(viewYear, viewMonth, 1 - offset)
	}

	function dayAt(index) {
		const s = gridStart()
		return new Date(s.getFullYear(), s.getMonth(), s.getDate() + index)
	}

	function eventsOn(day) {
		const ds = startOfDay(day)
		const de = new Date(ds.getFullYear(), ds.getMonth(), ds.getDate() + 1)
		const result = []
		for (const ev of events) {
			const s = parseEventDate(ev.start, ev.allDay)
			const e = parseEventDate(ev.end, ev.allDay)
			if (s < de && (e > ds || (e.getTime() === s.getTime() && s >= ds)))
				result.push({ ev: ev, start: s, end: e })
		}
		result.sort((a, b) => (b.ev.allDay - a.ev.allDay) || (a.start - b.start))
		return result
	}

	readonly property real hourHeight: 48

	// lay out timed events of a day in side-by-side lanes (overlapping events share the width)
	function timedLayout(day) {
		const ds = startOfDay(day)
		const de = new Date(ds.getFullYear(), ds.getMonth(), ds.getDate() + 1)
		const items = []
		for (const it of eventsOn(day)) {
			if (it.ev.allDay)
				continue
			const s = it.start < ds ? ds : it.start
			const e = it.end > de ? de : it.end
			const sm = (s - ds) / 60000
			const em = Math.max((e - ds) / 60000, sm + 30)
			items.push({ ev: it.ev, start: it.start, end: it.end, sm: sm, em: em, lane: 0, lanes: 1 })
		}
		items.sort((a, b) => a.sm - b.sm || b.em - a.em)
		let cluster = [], clusterEnd = -1, laneEnds = []
		const flush = () => {
			for (const c of cluster)
				c.lanes = laneEnds.length
			cluster = []
			laneEnds = []
		}
		for (const it of items) {
			if (it.sm >= clusterEnd)
				flush()
			let lane = laneEnds.findIndex(end => end <= it.sm)
			if (lane < 0) {
				lane = laneEnds.length
				laneEnds.push(0)
			}
			laneEnds[lane] = it.em
			it.lane = lane
			cluster.push(it)
			clusterEnd = cluster.length === 1 ? it.em : Math.max(clusterEnd, it.em)
		}
		flush()
		return items
	}

	function allDayEvents(day) {
		return eventsOn(day).filter(it => it.ev.allDay)
	}

	function scrollTimeline() {
		let minute = 8 * 60
		const laid = timedLayout(selected)
		if (laid.length > 0)
			minute = laid[0].sm
		else if (sameDay(selected, today))
			minute = today.getHours() * 60
		const maxY = Math.max(0, timeline.contentHeight - timeline.height)
		timeline.contentY = Math.max(0, Math.min(maxY, minute / 60 * hourHeight - 12))
	}

	function timeLabel(item) {
		if (item.ev.allDay)
			return "All day"
		return Qt.formatTime(item.start, "hh:mm") + " – " + Qt.formatTime(item.end, "hh:mm")
	}

	// ─── editor ─────────────────────────────────────

	function pad(n) {
		return (n < 10 ? "0" : "") + n
	}

	function fmtDate(d) {
		return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
	}

	function fmtTime(d) {
		return pad(d.getHours()) + ":" + pad(d.getMinutes())
	}

	function openEditor(ev) {
		editError = ""
		saving = false
		if (ev) {
			editId = ev.id
			editCalendarId = ev.calendarId
			editTitle = ev.title
			editLocation = ev.location
			editAllDay = ev.allDay
			const s = parseEventDate(ev.start, ev.allDay)
			let e = parseEventDate(ev.end, ev.allDay)
			if (ev.allDay)
				e = new Date(e.getFullYear(), e.getMonth(), e.getDate() - 1)
			editStartDate = fmtDate(s)
			editEndDate = fmtDate(e)
			editStartTime = ev.allDay ? "09:00" : fmtTime(s)
			editEndTime = ev.allDay ? "10:00" : fmtTime(e)
		} else {
			const now = new Date()
			let hour = sameDay(selected, now) ? now.getHours() + 1 : 9
			if (hour > 22)
				hour = 22
			editId = ""
			const primary = writableCalendars.find(c => c.primary) || writableCalendars[0]
			editCalendarId = primary ? primary.id : ""
			editTitle = ""
			editLocation = ""
			editAllDay = false
			editStartDate = fmtDate(selected)
			editEndDate = fmtDate(selected)
			editStartTime = pad(hour) + ":00"
			editEndTime = pad(hour + 1) + ":00"
		}
		editing = true
	}

	function closeEditor() {
		editing = false
		saving = false
	}

	function validate() {
		const dateRe = /^\d{4}-\d{2}-\d{2}$/
		const timeRe = /^([01]\d|2[0-3]):[0-5]\d$/
		if (editTitle.trim() === "")
			return "Title is required."
		if (editCalendarId === "")
			return "No writable calendar."
		if (!dateRe.test(editStartDate) || !dateRe.test(editEndDate))
			return "Dates use YYYY-MM-DD."
		if (!editAllDay && (!timeRe.test(editStartTime) || !timeRe.test(editEndTime)))
			return "Times use HH:MM."
		const s = editAllDay ? editStartDate : editStartDate + "T" + editStartTime
		const e = editAllDay ? editEndDate : editEndDate + "T" + editEndTime
		if (e < s || (!editAllDay && e === s))
			return "End must be after start."
		return ""
	}

	function saveEvent() {
		const err = validate()
		if (err !== "") {
			editError = err
			return
		}
		editError = ""
		saving = true
		const payload = {
			calendarId: editCalendarId,
			title: editTitle.trim(),
			location: editLocation.trim(),
			allDay: editAllDay,
			start: editAllDay ? editStartDate : editStartDate + "T" + editStartTime,
			end: editAllDay ? editEndDate : editEndDate + "T" + editEndTime
		}
		if (editId !== "")
			payload.id = editId
		saveProcess.command = ["python3", scriptPath, "save", JSON.stringify(payload)]
		saveProcess.running = true
	}

	function deleteEvent() {
		saving = true
		deleteProcess.command = ["python3", scriptPath, "delete", editCalendarId, editId]
		deleteProcess.running = true
	}

	function editResult(text) {
		saving = false
		try {
			const r = JSON.parse(text)
			if (r.error) {
				editError = r.error === "scope" ? "No write access. Sign out and sign in again."
					: r.error === "network" ? "Offline." : "Failed (" + r.error + ")"
				return
			}
		} catch (e) {
			editError = "Unexpected response."
			return
		}
		closeEditor()
		refresh()
	}

	function shiftMonth(delta) {
		const d = new Date(viewYear, viewMonth + delta, 1)
		viewYear = d.getFullYear()
		viewMonth = d.getMonth()
		refresh()
	}

	function goToday() {
		today = new Date()
		viewYear = today.getFullYear()
		viewMonth = today.getMonth()
		selected = startOfDay(today)
		refresh()
	}

	// ─── backend ────────────────────────────────────

	function checkStatus() {
		statusProcess.running = true
	}

	function refresh() {
		if (authState !== "ready")
			return
		const key = viewYear + "-" + viewMonth
		const from = gridStart()
		const to = dayAt(42)
		requestedKey = key
		loading = true
		eventsProcess.command = [
			"bash", "-lc",
			'python3 "' + script + '" events ' + Qt.formatDate(from, "yyyy-MM-dd") + " " + Qt.formatDate(to, "yyyy-MM-dd")
		]
		eventsProcess.running = true
	}

	Process {
		id: statusProcess
		command: ["bash", "-lc", 'python3 "' + root.script + '" status']

		stdout: StdioCollector {
			onStreamFinished: {
				try {
					const r = JSON.parse(this.text)
					root.authState = r.state
					root.reauth = !!r.reauth
					if (r.clientFile)
						root.clientFile = r.clientFile
					if (r.state === "ready")
						root.refresh()
				} catch (e) {
					root.authState = "no-client"
				}
			}
		}
	}

	Process {
		id: eventsProcess

		stdout: StdioCollector {
			onStreamFinished: {
				root.loading = false
				try {
					const r = JSON.parse(this.text)
					if (r.error) {
						root.errorText = r.error === "auth" ? "Session expired. Sign in again."
							: r.error === "network" ? "Offline." : "Calendar error: " + r.error
						if (r.error === "auth")
							root.authState = "logged-out"
						return
					}
					root.errorText = ""
					root.events = r.events
					root.writableCalendars = r.calendars || []
					root.loadedKey = root.requestedKey
				} catch (e) {
					root.errorText = "Could not read calendar data."
				}
			}
		}
	}

	Process {
		id: saveProcess
		stdout: StdioCollector {
			onStreamFinished: root.editResult(this.text)
		}
	}

	Process {
		id: deleteProcess
		stdout: StdioCollector {
			onStreamFinished: root.editResult(this.text)
		}
	}

	Process {
		id: loginProcess
		command: ["bash", "-lc", 'python3 "' + root.script + '" login']

		stdout: StdioCollector {
			onStreamFinished: {
				root.loggingIn = false
				try {
					const r = JSON.parse(this.text)
					root.errorText = r.error ? "Login failed (" + r.error + ")" : ""
				} catch (e) {
					root.errorText = "Login failed."
				}
				root.checkStatus()
			}
		}
	}

	Process {
		id: logoutProcess
		command: ["bash", "-lc", 'python3 "' + root.script + '" logout']
		onRunningChanged: if (!running) {
			root.events = []
			root.checkStatus()
		}
	}

	onVisibleChanged: {
		if (!visible)
			closeEditor()
		if (visible) {
			today = new Date()
			if (authState === "ready")
				refresh()
			else
				checkStatus()
		}
	}

	Timer {
		interval: 300000
		repeat: true
		running: root.visible && root.authState === "ready"
		onTriggered: root.refresh()
	}

	// ─── ui ─────────────────────────────────────────

	anchors.fill: parent

	Rectangle {
		anchors.fill: parent
		anchors.margins: 12
		color: root.bgPrimary
		radius: 24

		// message states (checking / no client / signed out)
		ColumnLayout {
			anchors.centerIn: parent
			width: parent.width - 80
			spacing: 14
			visible: root.authState !== "ready"

			Rectangle {
				Layout.alignment: Qt.AlignHCenter
				Layout.preferredWidth: 64
				Layout.preferredHeight: 64
				radius: 50
				color: root.hoverFill

				Text {
					anchors.centerIn: parent
					text: "󰃭"
					color: root.accent
					font.pixelSize: 30
					font.weight: Font.Medium
					font.family: "JetBrainsMono Nerd Font Propo"
				}
			}

			Text {
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignHCenter
				wrapMode: Text.WordWrap
				color: root.textPrimary
				font.pixelSize: 14
				font.weight: Font.Medium
				text: root.authState === "checking" ? "Checking Google Calendar…"
					: root.authState === "no-client" ? "Google OAuth client missing"
					: root.reauth ? "Sign in again to allow editing events"
					: "Sign in to see your events"
			}

			Text {
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignHCenter
				wrapMode: Text.WrapAnywhere
				visible: root.authState === "no-client"
				color: root.textMuted
				font.pixelSize: 12
				text: "Save client_id / client_secret to " + root.clientFile
			}

			Text {
				Layout.fillWidth: true
				horizontalAlignment: Text.AlignHCenter
				wrapMode: Text.WordWrap
				visible: root.errorText !== ""
				text: root.errorText
				color: colors.error
				font.pixelSize: 12
			}

			Rectangle {
				Layout.alignment: Qt.AlignHCenter
				visible: root.authState === "logged-out" || root.authState === "no-client"
				implicitWidth: btnText.implicitWidth + 40
				implicitHeight: 44
				radius: 50
				color: signInArea.containsMouse ? Qt.lighter(root.accent, 1.12) : root.accent
				opacity: root.loggingIn ? 0.6 : 1

				Behavior on color {
					ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
				}

				Text {
					id: btnText
					anchors.centerIn: parent
					text: root.authState === "no-client" ? "Re-check" : root.loggingIn ? "Waiting for browser…" : "Sign in with Google"
					color: root.accentForeground
					font.pixelSize: 14
					font.weight: Font.Medium
				}

				MouseArea {
					id: signInArea
					anchors.fill: parent
					hoverEnabled: true
					enabled: !root.loggingIn
					cursorShape: Qt.PointingHandCursor
					onClicked: {
						if (root.authState === "no-client") {
							root.checkStatus()
						} else {
							root.loggingIn = true
							loginProcess.running = true
						}
					}
				}
			}
		}

		ColumnLayout {
			anchors.fill: parent
			anchors.margins: 12
			spacing: 12
			visible: root.authState === "ready"

			// header pill (same shape as launcher search)
			Rectangle {
				Layout.fillWidth: true
				Layout.preferredHeight: 50
				radius: 50
				color: root.bgSecondary

				RowLayout {
					anchors.fill: parent
					anchors.leftMargin: 14
					anchors.rightMargin: 8
					spacing: 10

					Text {
						Layout.fillWidth: true
						text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
						color: root.textPrimary
						font.pixelSize: 16
						font.weight: Font.Medium
						elide: Text.ElideRight
					}

					Repeater {
						model: [
							{ g: "󰐕", act: "add" },
							{ g: "󰅁", act: "prev" },
							{ g: "󰅂", act: "next" },
						]

						Rectangle {
							id: hdrBtn
							required property var modelData
							Layout.preferredWidth: 34
							Layout.preferredHeight: 34
							radius: 50
							color: hdrArea.containsMouse ? root.hoverFill : "transparent"

							Behavior on color {
								ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
							}

							Text {
								anchors.centerIn: parent
								text: hdrBtn.modelData.g
								color: hdrBtn.modelData.act === "today" ? root.accent : root.textPrimary
								font.pixelSize: 18
								font.weight: Font.Medium
								font.family: "JetBrainsMono Nerd Font Propo"
							}

							MouseArea {
								id: hdrArea
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: {
									const a = hdrBtn.modelData.act
									if (a === "add") root.openEditor(null)
									else if (a === "prev") root.shiftMonth(-1)
									else if (a === "next") root.shiftMonth(1)
									else if (a === "today") root.goToday()
									else logoutProcess.running = true
								}
							}
						}
					}
				}
			}

			RowLayout {
				Layout.fillWidth: true
				Layout.fillHeight: true
				spacing: 16

				// month grid
				ColumnLayout {
					Layout.preferredWidth: 280
					Layout.fillHeight: true
					spacing: 4

					Row {
						Repeater {
							model: root.weekdayNames

							Text {
								required property string modelData
								width: 280 / 7
								horizontalAlignment: Text.AlignHCenter
								text: modelData
								color: root.textMuted
								font.pixelSize: 11
								font.weight: Font.Medium
							}
						}
					}

					Grid {
						id: dayGrid
						columns: 7
						readonly property real cell: 280 / 7

						Repeater {
							model: 42

							Item {
								id: cellItem
								required property int index
								readonly property date day: root.dayAt(index)
								readonly property bool inMonth: day.getMonth() === root.viewMonth
								readonly property bool isToday: root.sameDay(day, root.today)
								readonly property bool isSelected: root.sameDay(day, root.selected)

								width: dayGrid.cell
								height: 40

								Rectangle {
									anchors.centerIn: parent
									width: 36
									height: 36
									radius: 12
									color: cellItem.isSelected ? root.accent
										: cellItem.isToday ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.20)
										: cellArea.containsMouse ? root.hoverFill : "transparent"

									Behavior on color {
										ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
									}

									Text {
										anchors.centerIn: parent
										text: cellItem.day.getDate()
										color: cellItem.isSelected ? root.accentForeground
											: cellItem.isToday ? root.accent : root.textPrimary
										opacity: cellItem.inMonth || cellItem.isSelected ? 1 : 0.4
										font.pixelSize: 13
										font.weight: Font.Medium
									}
								}

								MouseArea {
									id: cellArea
									anchors.fill: parent
									hoverEnabled: true
									cursorShape: Qt.PointingHandCursor
									onClicked: {
										root.selected = root.startOfDay(cellItem.day)
										if (!cellItem.inMonth)
											root.shiftMonth(cellItem.day < new Date(root.viewYear, root.viewMonth, 1) ? -1 : 1)
									}
								}
							}
						}
					}

					Item { Layout.fillHeight: true }
				}

				// events for selected day
				ColumnLayout {
					Layout.fillWidth: true
					Layout.fillHeight: true
					spacing: 8

					RowLayout {
						Layout.fillWidth: true

						Text {
							Layout.fillWidth: true
							text: Qt.formatDate(root.selected, "dddd, MMM d")
							color: root.textPrimary
							font.pixelSize: 14
							font.weight: Font.Medium
							elide: Text.ElideRight
						}

						Text {
							visible: root.loading
							text: "Syncing…"
							color: root.textMuted
							font.pixelSize: 12
						}
					}

					Text {
						Layout.fillWidth: true
						visible: root.errorText !== ""
						text: root.errorText
						color: colors.error
						font.pixelSize: 12
						wrapMode: Text.WordWrap
					}

					// all-day events
					Flow {
						Layout.fillWidth: true
						spacing: 6
						visible: allDayRepeater.count > 0

						Repeater {
							id: allDayRepeater
							model: (root.events, root.allDayEvents(root.selected))

							Rectangle {
								required property var modelData
								height: 24
								width: Math.min(chipText.implicitWidth + 20, 340)
								radius: 12
								color: Qt.alpha(modelData.ev.color, 0.30)

								MouseArea {
									anchors.fill: parent
									enabled: parent.modelData.ev.canEdit
									cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
									onClicked: root.openEditor(parent.modelData.ev)
								}

								Text {
									id: chipText
									anchors.fill: parent
									anchors.leftMargin: 10
									anchors.rightMargin: 10
									verticalAlignment: Text.AlignVCenter
									text: parent.modelData.ev.title
									color: root.textPrimary
									font.pixelSize: 12
									font.weight: Font.Medium
									elide: Text.ElideRight
								}
							}
						}
					}

					// day timeline
					Flickable {
						id: timeline
						Layout.fillWidth: true
						Layout.fillHeight: true
						clip: true
						contentWidth: width
						contentHeight: 24 * root.hourHeight + 16
						boundsBehavior: Flickable.StopAtBounds

						Connections {
							target: root
							function onSelectedChanged() { root.scrollTimeline() }
							function onLoadedKeyChanged() { root.scrollTimeline() }
							function onVisibleChanged() { if (root.visible) root.scrollTimeline() }
						}

						Repeater {
							model: 24

							Item {
								required property int index
								y: index * root.hourHeight + 8
								width: timeline.width
								height: root.hourHeight

								Text {
									x: 0
									y: -7
									width: 36
									text: Qt.formatTime(new Date(2000, 0, 1, parent.index, 0), "hh:mm")
									color: root.textMuted
									font.pixelSize: 10
								}

								Rectangle {
									x: 42
									width: parent.width - 42
									height: 1
									color: Qt.rgba(1, 1, 1, 0.08)
								}
							}
						}

						Item {
							id: lanesArea
							x: 46
							y: 8
							width: timeline.width - 46
							height: 24 * root.hourHeight

							Repeater {
								model: (root.events, root.timedLayout(root.selected))

								Rectangle {
									id: block
									required property var modelData
									readonly property real laneWidth: lanesArea.width / modelData.lanes
									x: modelData.lane * laneWidth
									y: modelData.sm / 60 * root.hourHeight + 1
									width: laneWidth - 2 + (modelData.lane < modelData.lanes - 1 ? 8 : 0)
									z: modelData.lane
									height: Math.max(20, (modelData.em - modelData.sm) / 60 * root.hourHeight - 2)
									radius: 8
									color: Qt.tint(root.bgPrimary, Qt.alpha(modelData.ev.color, 0.38))
									border.width: 1
									border.color: Qt.alpha(modelData.ev.color, 0.9)
									clip: true

									MouseArea {
										anchors.fill: parent
										enabled: block.modelData.ev.canEdit
										cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
										onClicked: root.openEditor(block.modelData.ev)
									}

									Column {
										anchors.fill: parent
										anchors.margins: 5
										anchors.leftMargin: 7
										spacing: 0

										Text {
											width: parent.width
											text: block.modelData.ev.title
											color: root.textPrimary
											font.pixelSize: 12
											font.weight: Font.Medium
											elide: Text.ElideRight
										}

										Text {
											width: parent.width
											visible: block.height >= 40
											text: root.timeLabel(block.modelData)
											color: root.textMuted
											font.pixelSize: 11
											elide: Text.ElideRight
										}
									}
								}
							}
						}

						// current time
						Rectangle {
							visible: root.sameDay(root.selected, root.today)
							x: 42
							y: 8 + (root.today.getHours() * 60 + root.today.getMinutes()) / 60 * root.hourHeight
							width: timeline.width - 42
							height: 2
							radius: 1
							color: colors.error
							z: 10
						}
					}
				}
			}
		}

		// ─── event editor ───────────────────────────
		Rectangle {
			id: editor
			anchors.fill: parent
			radius: parent.radius
			color: root.bgPrimary
			visible: root.editing
			z: 20

			MouseArea {
				anchors.fill: parent
			}

			Keys.onEscapePressed: root.closeEditor()

			onVisibleChanged: {
				if (visible) {
					titleField.forceActiveFocus()
					if (root.barWindow)
						root.barWindow.focusable = true
				} else if (root.barWindow) {
					root.barWindow.focusable = false
				}
			}

			component Field: Rectangle {
				id: field
				property alias text: input.text
				property string placeholder: ""
				property alias input: input
				property real labelWidth: 0
				signal accepted()
				Layout.preferredHeight: 40
				radius: 50
				color: root.bgSecondary
				border.width: input.activeFocus ? 1 : 0
				border.color: root.accent

				TextField {
					id: input
					anchors.fill: parent
					anchors.leftMargin: 16
					anchors.rightMargin: 16
					placeholderText: field.placeholder
					font.pixelSize: 14
					color: root.textPrimary
					selectionColor: root.accent
					selectedTextColor: root.bgPrimary
					placeholderTextColor: root.textMuted
					background: Rectangle { color: "transparent" }
					onAccepted: field.accepted()
					Keys.onEscapePressed: root.closeEditor()
				}
			}

			ColumnLayout {
				anchors.fill: parent
				anchors.margins: 14
				spacing: 6

				RowLayout {
					Layout.fillWidth: true

					Text {
						Layout.fillWidth: true
						text: root.editId === "" ? "New event" : "Edit event"
						color: root.textPrimary
						font.pixelSize: 16
						font.weight: Font.Medium
					}

					Rectangle {
						Layout.preferredHeight: 30
						implicitWidth: allDayText.implicitWidth + 28
						radius: 50
						color: root.editAllDay ? root.accent : root.bgSecondary

						Behavior on color {
							ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
						}

						Text {
							id: allDayText
							anchors.centerIn: parent
							text: "All day"
							color: root.editAllDay ? root.accentForeground : root.textPrimary
							font.pixelSize: 12
							font.weight: Font.Medium
						}

						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							onClicked: root.editAllDay = !root.editAllDay
						}
					}
				}

				Field {
					id: titleField
					Layout.fillWidth: true
					placeholder: "Title"
					text: root.editTitle
					onTextChanged: root.editTitle = text
					onAccepted: root.saveEvent()
					input.KeyNavigation.tab: locationField.input
				}

				Field {
					id: locationField
					Layout.fillWidth: true
					placeholder: "Location"
					text: root.editLocation
					onTextChanged: root.editLocation = text
					onAccepted: root.saveEvent()
					input.KeyNavigation.tab: startDateField.input
				}

				RowLayout {
					Layout.fillWidth: true
					spacing: 8

					Field {
						id: startDateField
						Layout.fillWidth: true
						placeholder: "YYYY-MM-DD"
						text: root.editStartDate
						onTextChanged: root.editStartDate = text
						onAccepted: root.saveEvent()
						input.KeyNavigation.tab: startTimeField.input
					}

					Field {
						id: startTimeField
						Layout.preferredWidth: 110
						visible: !root.editAllDay
						placeholder: "HH:MM"
						text: root.editStartTime
						onTextChanged: root.editStartTime = text
						onAccepted: root.saveEvent()
						input.KeyNavigation.tab: endDateField.input
					}
				}

				RowLayout {
					Layout.fillWidth: true
					spacing: 8

					Field {
						id: endDateField
						Layout.fillWidth: true
						placeholder: "YYYY-MM-DD"
						text: root.editEndDate
						onTextChanged: root.editEndDate = text
						onAccepted: root.saveEvent()
						input.KeyNavigation.tab: endTimeField.input
					}

					Field {
						id: endTimeField
						Layout.preferredWidth: 110
						visible: !root.editAllDay
						placeholder: "HH:MM"
						text: root.editEndTime
						onTextChanged: root.editEndTime = text
						onAccepted: root.saveEvent()
						input.KeyNavigation.tab: titleField.input
					}
				}

				// calendar picker (new events only), scrolls sideways when crowded
				Flickable {
					Layout.fillWidth: true
					Layout.preferredHeight: 32
					visible: root.editId === "" && root.writableCalendars.length > 1
					clip: true
					contentWidth: calRow.width
					contentHeight: height
					flickableDirection: Flickable.HorizontalFlick
					boundsBehavior: Flickable.StopAtBounds

					Row {
						id: calRow
						spacing: 6

						Repeater {
							model: root.writableCalendars

							Rectangle {
								id: calChip
								required property var modelData
								readonly property bool chosen: root.editCalendarId === modelData.id
								height: 32
								width: Math.min(calText.implicitWidth, 120) + 38
								radius: 50
								color: chosen ? Qt.alpha(modelData.color, 0.35) : root.bgSecondary
								border.width: chosen ? 1 : 0
								border.color: modelData.color

								Rectangle {
									x: 12
									anchors.verticalCenter: parent.verticalCenter
									width: 8
									height: 8
									radius: 4
									color: calChip.modelData.color
								}

								Text {
									id: calText
									anchors.fill: parent
									anchors.leftMargin: 26
									anchors.rightMargin: 12
									verticalAlignment: Text.AlignVCenter
									text: calChip.modelData.name
									color: root.textPrimary
									font.pixelSize: 12
									elide: Text.ElideRight
								}

								MouseArea {
									anchors.fill: parent
									cursorShape: Qt.PointingHandCursor
									onClicked: root.editCalendarId = calChip.modelData.id
								}
							}
						}
					}
				}

				Text {
					Layout.fillWidth: true
					visible: root.editError !== ""
					text: root.editError
					color: colors.error
					font.pixelSize: 12
					wrapMode: Text.WordWrap
				}

				Item { Layout.fillHeight: true }

				RowLayout {
					Layout.fillWidth: true
					spacing: 8

					Rectangle {
						visible: root.editId !== ""
						Layout.preferredHeight: 40
						implicitWidth: delText.implicitWidth + 36
						radius: 50
						color: delArea.containsMouse ? Qt.alpha(colors.error, 0.28) : root.bgSecondary

						Text {
							id: delText
							anchors.centerIn: parent
							text: "Delete"
							color: colors.error
							font.pixelSize: 14
							font.weight: Font.Medium
						}

						MouseArea {
							id: delArea
							anchors.fill: parent
							hoverEnabled: true
							enabled: !root.saving
							cursorShape: Qt.PointingHandCursor
							onClicked: root.deleteEvent()
						}
					}

					Item { Layout.fillWidth: true }

					Rectangle {
						Layout.preferredHeight: 40
						implicitWidth: cancelText.implicitWidth + 36
						radius: 50
						color: cancelArea.containsMouse ? Qt.lighter(root.bgSecondary, 1.5) : root.bgSecondary

						Text {
							id: cancelText
							anchors.centerIn: parent
							text: "Cancel"
							color: root.textPrimary
							font.pixelSize: 14
							font.weight: Font.Medium
						}

						MouseArea {
							id: cancelArea
							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: root.closeEditor()
						}
					}

					Rectangle {
						Layout.preferredHeight: 40
						implicitWidth: saveText.implicitWidth + 40
						radius: 50
						color: saveArea.containsMouse ? Qt.lighter(root.accent, 1.12) : root.accent
						opacity: root.saving ? 0.6 : 1

						Text {
							id: saveText
							anchors.centerIn: parent
							text: root.saving ? "Saving…" : "Save"
							color: root.accentForeground
							font.pixelSize: 14
							font.weight: Font.Medium
						}

						MouseArea {
							id: saveArea
							anchors.fill: parent
							hoverEnabled: true
							enabled: !root.saving
							cursorShape: Qt.PointingHandCursor
							onClicked: root.saveEvent()
						}
					}
				}
			}
		}
	}
}
