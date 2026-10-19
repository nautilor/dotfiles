pragma Singleton

import QtQuick
import Quickshell

// Transient message shown inside the closed notch (caffeine, mic, workspace...).
Singleton {
	id: root

	property bool active: false
	property string kind: ""
	property string icon: ""
	property string text: ""
	property bool warn: false
	// 0..1 draws an OSD slider; -1 for a plain message
	property real value: -1

	function show(kind, icon, text, warn, ms, value) {
		root.value = value === undefined ? -1 : value;
		root.kind = kind;
		root.icon = icon;
		root.text = text;
		root.warn = !!warn;
		root.active = true;
		timer.interval = ms || 2400;
		timer.restart();
	}

	Timer {
		id: timer
		onTriggered: root.active = false
	}
}
