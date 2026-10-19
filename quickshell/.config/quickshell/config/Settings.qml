pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Persistent user settings, stored as JSON in ~/.config/quickshell-notch/settings.json.
Singleton {
	id: root

	readonly property string configDir: Quickshell.env("HOME") + "/.config/quickshell-notch"

	property alias hue: adapter.hue
	property alias hoverOpen: adapter.hoverOpen
	property alias dnd: adapter.dnd
	property alias homeOnHover: adapter.homeOnHover
	property alias screenCorners: adapter.screenCorners
	property alias cornerRadius: adapter.cornerRadius
	property alias autohide: adapter.autohide
	property alias notifTimeout: adapter.notifTimeout
	property alias screenName: adapter.screenName
	property alias allScreens: adapter.allScreens
	property alias weekStartsMonday: adapter.weekStartsMonday
	property alias use24h: adapter.use24h
	property alias showClock: adapter.showClock
	property alias caffeineOnMessage: adapter.caffeineOnMessage
	property alias caffeineOffMessage: adapter.caffeineOffMessage
	property alias micOnMessage: adapter.micOnMessage
	property alias micOffMessage: adapter.micOffMessage
	property alias launchCounts: adapter.launchCounts

	property bool dirReady: false

	Process {
		running: true
		command: ["mkdir", "-p", root.configDir]
		onExited: root.dirReady = true
	}

	FileView {
		path: root.dirReady ? root.configDir + "/settings.json" : ""
		watchChanges: true
		onFileChanged: reload()
		onAdapterUpdated: writeAdapter()
		onLoadFailed: error => {
			if (error === FileViewError.FileNotFound)
				writeAdapter();
		}

		adapter: JsonAdapter {
			id: adapter

			property real hue: 0.53
			property bool hoverOpen: true
			property bool dnd: false
			property bool homeOnHover: true
			property bool screenCorners: true
			property real cornerRadius: 20
			property bool autohide: false
			property int notifTimeout: 5000
			property string screenName: ""
			property bool allScreens: false
			property bool weekStartsMonday: true
			property bool use24h: true
			property bool showClock: false
			property string caffeineOnMessage: "Caffeine on · staying awake"
			property string caffeineOffMessage: "Caffeine off"
			property string micOnMessage: "Microphone live"
			property string micOffMessage: "Microphone muted"
			property var launchCounts: ({})
		}
	}
}
