pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history backed by clipse (~/.config/clipse/clipboard_history.json).
// clipse's listener records new copies; this reads the file, and edits it for pin/delete.
Singleton {
	id: root

	readonly property string historyPath: Quickshell.env("HOME") + "/.config/clipse/clipboard_history.json"
	property var entries: []

	function parse() {
		try {
			const data = JSON.parse(file.text());
			root.entries = data.clipboardHistory || [];
		} catch (e) {
			root.entries = [];
		}
	}

	function isImage(e) {
		return e.filePath && e.filePath !== "null";
	}

	function search(query) {
		const q = (query || "").trim().toLowerCase();
		const out = entries.filter(e => q === "" || (e.value || "").toLowerCase().includes(q));
		// pinned first, then recency (file order is newest first)
		return out.filter(e => e.pinned).concat(out.filter(e => !e.pinned));
	}

	function copy(entry) {
		if (isImage(entry))
			Quickshell.execDetached(["sh", "-c", "wl-copy --type image/png < \"$1\"", "sh", entry.filePath]);
		else
			Quickshell.execDetached(["wl-copy", "--", entry.value]);
	}

	function save(list) {
		root.entries = list;
		file.setText(JSON.stringify({ clipboardHistory: list }, null, 2));
	}

	function indexOfEntry(entry) {
		return entries.findIndex(e => e.recorded === entry.recorded && e.value === entry.value);
	}

	function togglePin(entry) {
		const list = entries.map(e => Object.assign({}, e));
		const i = indexOfEntry(entry);
		if (i >= 0) {
			list[i].pinned = !list[i].pinned;
			save(list);
		}
	}

	function remove(entry) {
		const list = entries.slice();
		const i = indexOfEntry(entry);
		if (i >= 0) {
			list.splice(i, 1);
			save(list);
		}
	}

	function clearUnpinned() {
		save(entries.filter(e => e.pinned));
	}

	FileView {
		id: file
		path: root.historyPath
		watchChanges: true
		onFileChanged: reload()
		onLoaded: root.parse()
		onLoadFailed: root.entries = []
	}

	// make sure a clipse listener is running so history keeps being recorded
	Process {
		running: true
		command: ["pgrep", "-f", "clipse"]
		onExited: code => {
			if (code !== 0)
				Quickshell.execDetached(["clipse", "-listen"]);
		}
	}
}
