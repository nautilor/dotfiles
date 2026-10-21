pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Layout of the Home dashboard: widgets on a fixed grid, persisted in settings.json.
// Items live in a ListModel so delegates (and the widgets inside) survive edits instead of being rebuilt.
Singleton {
	id: root

	readonly property int cols: 8
	readonly property int cellW: 82
	readonly property int cellH: 66
	readonly property int gap: 8
	readonly property int maxRows: 6
	readonly property real gridW: cols * cellW + (cols - 1) * gap

	property bool editing: false
	property string panel: ""        // "" | "add" | "config"
	property string selected: ""     // widget being configured
	property var trayItem: null      // tray item whose menu is open
	property string message: ""

	property int usedRows: 4
	// bumped on every change, so bindings that read ListModel rows refresh
	property int revision: 0
	readonly property int rows: editing ? Math.min(maxRows, Math.max(usedRows, 2) + 1) : Math.max(usedRows, 2)
	readonly property real gridH: rows * cellH + (rows - 1) * gap

	readonly property ListModel items: ListModel {}
	property string lastJson: ""

	// ---- geometry ----
	function indexOf(wid) {
		for (let i = 0; i < items.count; i++)
			if (items.get(i).wid === wid)
				return i;
		return -1;
	}

	function canPlace(wid, x, y, w, h) {
		if (x < 0 || y < 0 || w < 1 || h < 1 || x + w > cols || y + h > maxRows)
			return false;
		for (let i = 0; i < items.count; i++) {
			const it = items.get(i);
			if (it.wid === wid)
				continue;
			if (x < it.x + it.w && x + w > it.x && y < it.y + it.h && y + h > it.y)
				return false;
		}
		return true;
	}

	function firstFree(w, h) {
		for (let y = 0; y + h <= maxRows; y++)
			for (let x = 0; x + w <= cols; x++)
				if (canPlace("", x, y, w, h))
					return { x: x, y: y };
		return null;
	}

	function recompute() {
		let m = 0;
		for (let i = 0; i < items.count; i++) {
			const it = items.get(i);
			m = Math.max(m, it.y + it.h);
		}
		usedRows = m;
	}

	// ---- persistence ----
	function serialize() {
		const out = [];
		for (let i = 0; i < items.count; i++) {
			const it = items.get(i);
			out.push({ id: it.wid, type: it.type, x: it.x, y: it.y, w: it.w, h: it.h, cfg: JSON.parse(it.cfgJson) });
		}
		return out;
	}

	function persist() {
		const s = serialize();
		lastJson = JSON.stringify(s);
		recompute();
		revision++;
		Settings.homeLayout = { v: 1, items: s };
	}

	function load(list) {
		items.clear();
		for (const w of list) {
			if (!WidgetTypes.types[w.type])
				continue;
			items.append({ wid: w.id, type: w.type, x: w.x, y: w.y, w: w.w, h: w.h, cfgJson: JSON.stringify(w.cfg || {}) });
		}
		recompute();
		revision++;
	}

	function defaults() {
		const mk = (id, type, x, y, w, h, cfg) => ({ id: id, type: type, x: x, y: y, w: w, h: h, cfg: cfg || {} });
		return [
			mk("media", "media", 0, 0, 4, 4),
			mk("ws", "workspaces", 4, 0, 3, 1),
			mk("tray", "tray", 7, 0, 1, 1),
			mk("t-wifi", "toggle", 4, 1, 1, 1, { kind: "wifi" }),
			mk("t-bt", "toggle", 5, 1, 1, 1, { kind: "bluetooth" }),
			mk("t-caf", "toggle", 6, 1, 1, 1, { kind: "caffeine" }),
			mk("t-mic", "toggle", 7, 1, 1, 1, { kind: "mic" }),
			mk("t-dnd", "toggle", 4, 2, 1, 1, { kind: "dnd" }),
			mk("profile", "profile", 5, 2, 3, 1),
			mk("event", "event", 4, 3, 4, 1)
		];
	}

	function reset() {
		Settings.homeLayout = {};
		lastJson = "";
		load(defaults());
		panel = "";
		selected = "";
	}

	Component.onCompleted: load(defaults())

	// the settings file loads asynchronously: replace the defaults once the saved layout arrives
	Connections {
		target: Settings
		function onHomeLayoutChanged() {
			const hl = Settings.homeLayout;
			if (hl && hl.items && JSON.stringify(hl.items) !== root.lastJson) {
				root.lastJson = JSON.stringify(hl.items);
				root.load(hl.items);
			}
		}
	}

	// ---- edits ----
	function add(type) {
		const t = WidgetTypes.types[type];
		const spot = firstFree(t.w, t.h);
		if (!spot) {
			message = "No free space on the grid. Remove or shrink something first.";
			return false;
		}
		message = "";
		const wid = type + "-" + Date.now().toString(36) + Math.floor(Math.random() * 1000).toString(36);
		items.append({ wid: wid, type: type, x: spot.x, y: spot.y, w: t.w, h: t.h, cfgJson: JSON.stringify(WidgetTypes.resolve(type, {})) });
		persist();
		return true;
	}

	function remove(wid) {
		const i = indexOf(wid);
		if (i >= 0) {
			items.remove(i);
			if (selected === wid) {
				selected = "";
				panel = "";
			}
			persist();
		}
	}

	function place(wid, x, y, w, h) {
		const i = indexOf(wid);
		if (i < 0 || !canPlace(wid, x, y, w, h))
			return false;
		items.setProperty(i, "x", x);
		items.setProperty(i, "y", y);
		items.setProperty(i, "w", w);
		items.setProperty(i, "h", h);
		persist();
		return true;
	}

	// Work out how to fit widget `wid` at x,y,w,h when other widgets are in the way.
	// Returns {moves: {wid: {x, y}}} (empty when nothing is in the way) or null if impossible.
	// One blocker that fits the dragged widget's old spot is swapped; otherwise blockers are pushed to the nearest free spot.
	function plan(wid, x, y, w, h) {
		if (x < 0 || y < 0 || w < 1 || h < 1 || x + w > cols || y + h > maxRows)
			return null;
		const rects = [];
		let a = null;
		for (let i = 0; i < items.count; i++) {
			const it = items.get(i);
			const r = { id: it.wid, x: it.x, y: it.y, w: it.w, h: it.h };
			if (it.wid === wid)
				a = r;
			else
				rects.push(r);
		}
		if (!a)
			return null;
		const fits = (r, nx, ny, others) => {
			if (nx < 0 || ny < 0 || nx + r.w > cols || ny + r.h > maxRows)
				return false;
			for (const o of others)
				if (o !== r && nx < o.x + o.w && nx + r.w > o.x && ny < o.y + o.h && ny + r.h > o.y)
					return false;
			return true;
		};
		const ox = a.x, oy = a.y;
		const blockers = rects.filter(o => x < o.x + o.w && x + w > o.x && y < o.y + o.h && y + h > o.y);
		if (blockers.length === 0)
			return { moves: {} };

		a.x = x; a.y = y; a.w = w; a.h = h;
		const all = rects.concat([a]);

		if (blockers.length === 1 && (ox !== x || oy !== y)) {
			const b = blockers[0];
			if (fits(b, ox, oy, all))
				return { moves: { [b.id]: { x: ox, y: oy } } };
		}

		blockers.sort((p, q) => (Math.abs(p.x - x) + Math.abs(p.y - y)) - (Math.abs(q.x - x) + Math.abs(q.y - y)));
		const moves = {};
		for (const b of blockers) {
			let best = null, bestD = 1e9;
			for (let ny = 0; ny + b.h <= maxRows; ny++)
				for (let nx = 0; nx + b.w <= cols; nx++) {
					if (!fits(b, nx, ny, all))
						continue;
					const d = Math.abs(nx - b.x) + Math.abs(ny - b.y);
					if (d < bestD) {
						bestD = d;
						best = { x: nx, y: ny };
					}
				}
			if (!best)
				return null;
			b.x = best.x;
			b.y = best.y;
			moves[b.id] = best;
		}
		return { moves: moves };
	}

	// apply a plan: place wid, then move the displaced widgets
	function commit(wid, x, y, w, h, moves) {
		const i = indexOf(wid);
		if (i < 0)
			return false;
		items.setProperty(i, "x", x);
		items.setProperty(i, "y", y);
		items.setProperty(i, "w", w);
		items.setProperty(i, "h", h);
		for (const id in moves) {
			const j = indexOf(id);
			if (j >= 0) {
				items.setProperty(j, "x", moves[id].x);
				items.setProperty(j, "y", moves[id].y);
			}
		}
		persist();
		return true;
	}

	function setConfig(wid, key, value) {
		const i = indexOf(wid);
		if (i < 0)
			return;
		const cfg = JSON.parse(items.get(i).cfgJson);
		cfg[key] = value;
		items.setProperty(i, "cfgJson", JSON.stringify(cfg));
		persist();
	}

	function configure(wid) {
		selected = wid;
		panel = "config";
	}
}
