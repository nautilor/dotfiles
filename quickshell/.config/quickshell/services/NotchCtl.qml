pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// Shared notch state; driven by hover, clicks and IPC.
Singleton {
	id: root

	readonly property var tabs: ["home", "apps", "clipboard", "calendar", "notifications", "power", "settings"]

	property bool open: false
	property string tab: "home"
	// sticky: opened explicitly (keyboard/IPC/click), so leaving with the pointer does not close it
	property bool sticky: false
	property bool keyboard: false
	// screen the notch is open on ("" = any)
	property string screen: ""

	function show(name, scr) {
		// with a single notch there is nothing to pick; otherwise open on the screen the user is working on
		screen = !Settings.allScreens ? "" : (scr || (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""));
		if (name && tabs.indexOf(name) >= 0)
			tab = name;
		sticky = true;
		keyboard = true;
		open = true;
	}

	function close() {
		open = false;
		sticky = false;
		keyboard = false;
	}

	function toggle(name) {
		if (open && (!name || tab === name))
			close();
		else
			show(name);
	}
}
