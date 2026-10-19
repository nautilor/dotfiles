import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// Create / edit / delete a Google Calendar event.
Rectangle {
	id: root

	property var event: null          // existing event, or null for a new one
	property string calendarId: ""
	property bool allDay: false
	property string error: ""
	readonly property bool editing: event !== null

	signal closed

	radius: Theme.radiusLarge
	color: Theme.surfaceContainerHigh

	// start: Date used for new events
	function open(ev, start) {
		error = "";
		event = ev;
		if (ev) {
			calendarId = ev.calendarId;
			allDay = ev.allDay;
			titleField.text = ev.title;
			locationField.text = ev.location || "";
			let e = ev.e;
			if (ev.allDay)
				e = Gcal.addDays(e, -1);   // Google's all-day end is exclusive
			startDate.text = Gcal.iso(ev.s);
			endDate.text = Gcal.iso(e);
			startTime.text = ev.allDay ? "09:00" : Gcal.fmtTime(ev.s);
			endTime.text = ev.allDay ? "10:00" : Gcal.fmtTime(e);
		} else {
			const primary = Gcal.calendars.find(c => c.primary) || Gcal.calendars[0];
			calendarId = primary ? primary.id : "";
			allDay = false;
			titleField.text = "";
			locationField.text = "";
			const end = new Date(start.getTime() + 3600000);
			startDate.text = Gcal.iso(start);
			endDate.text = Gcal.iso(end);
			startTime.text = Gcal.fmtTime(start);
			endTime.text = Gcal.fmtTime(end);
		}
		visible = true;
		titleField.forceFocus();
	}

	function validate() {
		const dateRe = /^\d{4}-\d{2}-\d{2}$/;
		const timeRe = /^([01]\d|2[0-3]):[0-5]\d$/;
		if (titleField.text.trim() === "")
			return "Title is required.";
		if (calendarId === "")
			return "No writable calendar.";
		if (!dateRe.test(startDate.text) || !dateRe.test(endDate.text))
			return "Dates use YYYY-MM-DD.";
		if (!allDay && (!timeRe.test(startTime.text) || !timeRe.test(endTime.text)))
			return "Times use HH:MM.";
		const s = allDay ? startDate.text : startDate.text + "T" + startTime.text;
		const e = allDay ? endDate.text : endDate.text + "T" + endTime.text;
		if (e < s || (!allDay && e === s))
			return "End must be after start.";
		return "";
	}

	function save() {
		const err = validate();
		error = err;
		if (err !== "")
			return;
		const payload = {
			calendarId: calendarId,
			title: titleField.text.trim(),
			location: locationField.text.trim(),
			allDay: allDay,
			start: allDay ? startDate.text : startDate.text + "T" + startTime.text,
			end: allDay ? endDate.text : endDate.text + "T" + endTime.text
		};
		if (editing)
			payload.id = event.id;
		Gcal.saveEvent(payload);
	}

	Connections {
		target: Gcal
		function onEditFinished(ok, message) {
			if (!root.visible)
				return;
			if (ok)
				root.closed();
			else
				root.error = message;
		}
	}

	// swallow clicks so they don't reach the grid underneath
	MouseArea {
		anchors.fill: parent
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 14
		spacing: 8

		RowLayout {
			Layout.fillWidth: true
			Txt {
				text: root.editing ? "Edit event" : "New event"
				font.pixelSize: 17
				font.weight: Font.Bold
				Layout.fillWidth: true
			}
			Btn {
				icon: "close"
				variant: 2
				iconSize: 18
				implicitWidth: 34
				implicitHeight: 34
				onClicked: root.closed()
			}
		}

		Field {
			color: Theme.surfaceContainerHighest
			id: titleField
			Layout.fillWidth: true
			icon: "edit"
			placeholder: "Title"
			onAccepted: root.save()
		}

		// calendar picker (new events only)
		Flow {
			Layout.fillWidth: true
			spacing: 6
			visible: !root.editing && Gcal.calendars.length > 1
			Repeater {
				model: Gcal.calendars
				Btn {
					required property var modelData
					implicitHeight: 32
					label: modelData.name
					toggleable: true
					toggled: root.calendarId === modelData.id
					toggledRadius: 14
					onClicked: root.calendarId = modelData.id
				}
			}
		}
		Txt {
			visible: root.editing
			text: root.event ? root.event.calendar : ""
			color: Theme.surfaceVariantFg
			font.pixelSize: 12
		}

		RowLayout {
			Layout.fillWidth: true
			Txt {
				text: "All day"
				Layout.fillWidth: true
			}
			Switch {
				checked: root.allDay
				onToggled: v => root.allDay = v
			}
		}

		GridLayout {
			Layout.fillWidth: true
			columns: 3
			columnSpacing: 8
			rowSpacing: 6

			Txt {
				text: "Start"
				color: Theme.surfaceVariantFg
			}
			Field {
				color: Theme.surfaceContainerHighest
				id: startDate
				Layout.fillWidth: true
				implicitHeight: 38
				placeholder: "YYYY-MM-DD"
			}
			Field {
				color: Theme.surfaceContainerHighest
				id: startTime
				visible: !root.allDay
				Layout.preferredWidth: 90
				implicitHeight: 38
				placeholder: "HH:MM"
			}
			Item {
				visible: root.allDay
				Layout.preferredWidth: 90
			}

			Txt {
				text: "End"
				color: Theme.surfaceVariantFg
			}
			Field {
				color: Theme.surfaceContainerHighest
				id: endDate
				Layout.fillWidth: true
				implicitHeight: 38
				placeholder: "YYYY-MM-DD"
			}
			Field {
				color: Theme.surfaceContainerHighest
				id: endTime
				visible: !root.allDay
				Layout.preferredWidth: 90
				implicitHeight: 38
				placeholder: "HH:MM"
			}
			Item {
				visible: root.allDay
				Layout.preferredWidth: 90
			}
		}

		Field {
			color: Theme.surfaceContainerHighest
			id: locationField
			Layout.fillWidth: true
			implicitHeight: 38
			icon: "place"
			placeholder: "Location"
			onAccepted: root.save()
		}

		Txt {
			visible: root.error !== ""
			text: root.error
			color: Theme.error
			font.pixelSize: 12
			Layout.fillWidth: true
		}

		Item {
			Layout.fillHeight: true
		}

		RowLayout {
			Layout.fillWidth: true
			spacing: 8
			Btn {
				visible: root.editing
				icon: "delete"
				label: "Delete"
				variant: 3
				enabled: !Gcal.saving
				onClicked: Gcal.deleteEvent(root.event.calendarId, root.event.id)
			}
			Item {
				Layout.fillWidth: true
			}
			Btn {
				label: "Cancel"
				onClicked: root.closed()
			}
			Btn {
				icon: "save"
				label: Gcal.saving ? "Saving…" : "Save"
				variant: 1
				enabled: !Gcal.saving
				onClicked: root.save()
			}
		}
	}
}
