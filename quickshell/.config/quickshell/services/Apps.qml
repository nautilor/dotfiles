pragma Singleton

import QtQuick
import Quickshell
import qs.config

Singleton {
	id: root

	function score(entry, q) {
		const name = (entry.name || "").toLowerCase();
		let s = 0;
		if (name === q)
			s = 200;
		else if (name.startsWith(q))
			s = 120;
		else if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
			s = 90;
		else if (name.includes(q))
			s = 60;
		else {
			// subsequence match
			let i = 0;
			for (const c of name) {
				if (c === q[i])
					i++;
				if (i === q.length)
					break;
			}
			if (i === q.length)
				s = 25;
		}
		if (s === 0) {
			const extra = ((entry.genericName || "") + " " + (entry.comment || "") + " " + (entry.keywords || []).join(" ")).toLowerCase();
			if (extra.includes(q))
				s = 15;
		}
		return s;
	}

	function search(query) {
		const q = (query || "").trim().toLowerCase();
		const counts = Settings.launchCounts || {};
		const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay);
		const scored = [];
		for (const a of apps) {
			const bonus = Math.min(30, (counts[a.id] || 0) * 3);
			if (q === "")
				scored.push({ a: a, s: bonus });
			else {
				const s = score(a, q);
				if (s > 0)
					scored.push({ a: a, s: s + bonus });
			}
		}
		scored.sort((x, y) => y.s - x.s || x.a.name.localeCompare(y.a.name));
		return scored.slice(0, 60).map(x => x.a);
	}

	function launch(entry) {
		const counts = Object.assign({}, Settings.launchCounts || {});
		counts[entry.id] = (counts[entry.id] || 0) + 1;
		Settings.launchCounts = counts;
		entry.execute();
	}
}
