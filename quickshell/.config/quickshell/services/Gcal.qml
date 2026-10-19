pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Google Calendar via scripts/gcal.py (OAuth + REST, stdlib only).
Singleton {
	id: root

	// "checking" | "no-client" | "logged-out" | "ready"
	property string authState: "checking"
	property string clientFile: Settings.configDir + "/gcal/client.json"
	property string error: ""
	property bool loading: false
	property bool loggingIn: false

	property date today: new Date()
	property date weekStart: startOfWeek(today)
	property var events: []      // week window, dates already parsed
	property bool reauth: false     // token exists but lacks write access
	property var calendars: []      // writable calendars
	property bool saving: false
	property var upcoming: []    // next events from now, for the home tab
	readonly property string script: Quickshell.shellPath("scripts/gcal.py")

	// ---- date helpers ----
	function startOfDay(d) {
		return new Date(d.getFullYear(), d.getMonth(), d.getDate());
	}
	function addDays(d, n) {
		return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n);
	}
	function startOfWeek(d) {
		const off = Settings.weekStartsMonday ? (d.getDay() + 6) % 7 : d.getDay();
		return addDays(startOfDay(d), -off);
	}
	function sameDay(a, b) {
		return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
	}
	function iso(d) {
		return Qt.formatDate(d, "yyyy-MM-dd");
	}
	function parseEvent(ev) {
		let s, e;
		if (ev.allDay) {
			const ps = ev.start.split("-"), pe = ev.end.split("-");
			s = new Date(+ps[0], +ps[1] - 1, +ps[2]);
			e = new Date(+pe[0], +pe[1] - 1, +pe[2]);
		} else {
			s = new Date(ev.start);
			e = new Date(ev.end);
		}
		return Object.assign({}, ev, { s: s, e: e });
	}

	// ---- layout: events of one day in side-by-side lanes (Google Calendar style) ----
	function dayEvents(day) {
		const ds = startOfDay(day), de = addDays(ds, 1);
		return events.filter(ev => ev.s < de && (ev.e > ds || (ev.e.getTime() === ev.s.getTime() && ev.s >= ds)));
	}

	function allDayOf(day) {
		return dayEvents(day).filter(ev => ev.allDay);
	}

	function layoutFor(day) {
		const ds = startOfDay(day), de = addDays(ds, 1);
		const items = [];
		for (const ev of dayEvents(day)) {
			if (ev.allDay)
				continue;
			const s = ev.s < ds ? ds : ev.s;
			const e = ev.e > de ? de : ev.e;
			const sm = (s - ds) / 60000;
			const em = Math.max((e - ds) / 60000, sm + 30);
			items.push({ ev: ev, sm: sm, em: em, lane: 0, lanes: 1 });
		}
		items.sort((a, b) => a.sm - b.sm || b.em - a.em);

		let cluster = [], clusterEnd = -1, laneEnds = [];
		const flush = () => {
			for (const c of cluster)
				c.lanes = laneEnds.length;
			cluster = [];
			laneEnds = [];
		};
		for (const it of items) {
			if (it.sm >= clusterEnd)
				flush();
			let lane = laneEnds.findIndex(end => end <= it.sm);
			if (lane < 0) {
				lane = laneEnds.length;
				laneEnds.push(0);
			}
			laneEnds[lane] = it.em;
			it.lane = lane;
			cluster.push(it);
			clusterEnd = cluster.length === 1 ? it.em : Math.max(clusterEnd, it.em);
		}
		flush();
		return items;
	}

	function timeLabel(ev) {
		if (ev.allDay)
			return "All day";
		return Qt.formatTime(ev.s, "hh:mm") + " – " + Qt.formatTime(ev.e, "hh:mm");
	}

	// ---- navigation ----
	function shiftWeek(n) {
		weekStart = addDays(weekStart, 7 * n);
		refresh();
	}
	function goToday() {
		today = new Date();
		weekStart = startOfWeek(today);
		refresh();
	}

	// ---- editing ----
	signal editFinished(bool ok, string message)

	function pad(n) {
		return (n < 10 ? "0" : "") + n;
	}
	function fmtTime(d) {
		return pad(d.getHours()) + ":" + pad(d.getMinutes());
	}

	// payload: {id?, calendarId, title, location, allDay, start, end}  (start/end: "YYYY-MM-DD" or "YYYY-MM-DDTHH:MM")
	function saveEvent(payload) {
		saving = true;
		saveProc.command = ["python3", script, "save", JSON.stringify(payload)];
		saveProc.running = true;
	}

	function deleteEvent(calendarId, eventId) {
		saving = true;
		deleteProc.command = ["python3", script, "delete", calendarId, eventId];
		deleteProc.running = true;
	}

	function editResult(text) {
		saving = false;
		let msg = "";
		try {
			const r = JSON.parse(text);
			if (r.error)
				msg = r.error === "scope" ? "No write access. Sign out and sign in again." : r.error === "network" ? "Offline." : r.error === "auth" ? "Session expired. Sign in again." : "Failed (" + r.error + ")";
		} catch (e) {
			msg = "Unexpected response.";
		}
		editFinished(msg === "", msg);
		if (msg === "")
			refresh();
	}

	// ---- backend ----
	function refresh() {
		if (authState !== "ready")
			return;
		loading = true;
		eventsProc.command = ["python3", script, "events", iso(addDays(weekStart, -1)), iso(addDays(weekStart, 8))];
		eventsProc.running = true;
		const now = new Date();
		upcomingProc.command = ["python3", script, "events", iso(addDays(now, -1)), iso(addDays(now, 8))];
		upcomingProc.running = true;
	}

	function checkStatus() {
		statusProc.running = true;
	}

	function login() {
		loggingIn = true;
		loginProc.running = true;
	}

	function logout() {
		logoutProc.running = true;
	}

	function handleError(r) {
		if (r.error === "auth") {
			error = "Session expired. Sign in again.";
			authState = "logged-out";
		} else if (r.error === "network") {
			error = "Offline.";
		} else {
			error = "Calendar error: " + r.error;
		}
	}

	Component.onCompleted: checkStatus()

	Timer {
		interval: 600000
		running: root.authState === "ready"
		repeat: true
		onTriggered: {
			root.today = new Date();
			root.refresh();
		}
	}

	Process {
		id: statusProc
		command: ["python3", root.script, "status"]
		stdout: StdioCollector {
			onStreamFinished: {
				try {
					const r = JSON.parse(text);
					if (r.clientFile)
						root.clientFile = r.clientFile;
					root.authState = r.state;
					root.reauth = !!r.reauth;
					if (r.state === "ready")
						root.refresh();
				} catch (e) {
					root.authState = "no-client";
				}
			}
		}
	}

	Process {
		id: eventsProc
		stdout: StdioCollector {
			onStreamFinished: {
				root.loading = false;
				try {
					const r = JSON.parse(text);
					if (r.error)
						return root.handleError(r);
					root.error = "";
					root.events = r.events.map(root.parseEvent);
					root.calendars = r.calendars || [];
				} catch (e) {
					root.error = "Could not read calendar data.";
				}
			}
		}
	}

	Process {
		id: upcomingProc
		stdout: StdioCollector {
			onStreamFinished: {
				try {
					const r = JSON.parse(text);
					if (r.error)
						return;
					const now = new Date();
					root.upcoming = r.events.map(root.parseEvent).filter(ev => ev.e > now).sort((a, b) => a.s - b.s);
				} catch (e) {}
			}
		}
	}

	Process {
		id: loginProc
		command: ["python3", root.script, "login"]
		stdout: StdioCollector {
			onStreamFinished: {
				root.loggingIn = false;
				try {
					const r = JSON.parse(text);
					root.error = r.error ? "Login failed (" + r.error + ")" : "";
				} catch (e) {
					root.error = "Login failed.";
				}
				root.checkStatus();
			}
		}
	}

	Process {
		id: logoutProc
		command: ["python3", root.script, "logout"]
		onExited: {
			root.events = [];
			root.upcoming = [];
			root.checkStatus();
		}
	}

	Process {
		id: saveProc
		stdout: StdioCollector {
			onStreamFinished: root.editResult(text)
		}
	}

	Process {
		id: deleteProc
		stdout: StdioCollector {
			onStreamFinished: root.editResult(text)
		}
	}
}
