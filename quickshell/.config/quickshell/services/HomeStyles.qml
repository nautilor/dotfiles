pragma Singleton

import QtQuick
import Quickshell
import qs.config

// The Home tab layouts the user can pick (Settings.homeStyle).
// "grid" is the editable dashboard, built in HomeTab; the others are fixed layouts in modules/notch/homes/.
// w and h are the size of the whole open notch.
Singleton {
	id: root

	function src(name) {
		return Qt.resolvedUrl("../modules/notch/homes/" + name + ".qml");
	}

	readonly property var list: [
		{ id: "grid", name: "Grid", icon: "dashboard", desc: "Your own widgets, editable", source: "", w: 0, h: 0 },
		{ id: "control", name: "Control Center", icon: "tune", desc: "Sliders and pill tiles", source: src("ControlCenterHome"), w: 700, h: 440 },
		{ id: "strip", name: "Strip", icon: "widgets", desc: "One wide dock-bar row", source: src("StripHome"), w: 950, h: 250 },
		{ id: "compact", name: "Compact", icon: "home", desc: "Small, everything in three rows", source: src("CompactHome"), w: 720, h: 270 },
		{ id: "glance", name: "Glance", icon: "schedule", desc: "Big clock, player and tiles", source: src("GlanceHome"), w: 820, h: 330 }
	]

	readonly property var current: list.find(s => s.id === Settings.homeStyle) ?? list[0]
	readonly property bool isGrid: current.id === "grid"
}
