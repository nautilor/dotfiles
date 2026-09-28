import Quickshell
import QtQuick
import QtQuick.Effects
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.modules.clipboard
import qs.modules.colors
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.osd as OSD
import qs.modules.quickpanel
import qs.modules.bar.components

PanelWindow {
	id: bar
	focusable: false
	WlrLayershell.keyboardFocus: bar.launcherPanelOpen || bar.clipboardPanelOpen

	property bool quickPanelOpen: false
	property bool launcherPanelOpen: false
	property bool clipboardPanelOpen: false
	property bool somethingOpen: quickPanelOpen || launcherPanelOpen || clipboardPanelOpen || notificationPanel.opacity > 0 || volumeOsd.opacity > 0 || brightnessOsd.opacity > 0 || caffeineOsd.opacity > 0 || microphoneOsd.opacity > 0
	property bool osdOpen: volumeOsd.opacity > 0 || brightnessOsd.opacity > 0 || caffeineOsd.opacity > 0 || microphoneOsd.opacity > 0

	readonly property int maxHeight: 700
	readonly property int maxWidth: 700

	readonly property int minHeight: 400

	readonly property int quickPanelHeight: 240
	readonly property int quickPanelWidth: 590

	readonly property int launcherPanelHeight: 285
	readonly property int launcherPanelWidth: 590

	readonly property int clipboardPanelHeight: 460
	readonly property int clipboardPanelWidth: 590

	readonly property int normalHeight: 45
	readonly property int normalWidth: 100

	readonly property int normalRadius: 50
	readonly property int openRadius: 24
	readonly property int osdRadius: 100

	Colors {
		id: colors
	}

	readonly property int exclusiveZoneHeight: 45
	readonly property int shadowOffset: 2

	function activeOsd() {
		if (volumeOsd.opacity > 0)
			return volumeOsd
		if (brightnessOsd.opacity > 0)
			return brightnessOsd
		if (caffeineOsd.opacity > 0)
			return caffeineOsd
		if (microphoneOsd.opacity > 0)
			return microphoneOsd
		return null
	}

	function panelHeight() {
		const osd = activeOsd()
		if (osd) {
			return osd.implicitHeight
		} else if (notificationPanel.opacity > 0) {
			return notificationPanel.implicitHeight
		} else if (bar.clipboardPanelOpen) {
			return bar.clipboardPanelHeight
		} else if (bar.quickPanelOpen) {
			return bar.quickPanelHeight
		} else if (bar.launcherPanelOpen) {
			return bar.launcherPanelHeight
		} else {
			return bar.normalHeight
		}
	}

	function panelWidth() {
		const osd = activeOsd()
		if (osd) {
			return osd.implicitWidth
		} else if (notificationPanel.opacity > 0) {
			return notificationPanel.implicitWidth
		} else if (bar.clipboardPanelOpen) {
			return bar.clipboardPanelWidth
		} else if (bar.quickPanelOpen) {
			return bar.quickPanelWidth
		} else if (bar.launcherPanelOpen) {
			return bar.launcherPanelWidth
		} else {
			return bar.normalWidth
		}
	}

	function closeQuickPanel() {
		bar.quickPanelOpen = false
		bar.focusable = false
	}

	anchors {
		top: true
	}

	margins {
		top: 10
	}

	exclusionMode: ExclusionMode.Normal
	exclusiveZone: bar.exclusiveZoneHeight

	implicitHeight: maxHeight + shadowOffset
	implicitWidth: maxWidth + shadowOffset

	mask: Region {
		item: barContent
	}

	color: "transparent"

	RectangularShadow {
		anchors.fill: barContent
		radius: bar.somethingOpen ? openRadius : normalRadius
		blur: 8
		spread: 0
		offset: Qt.point(0, 2)
		color: Qt.rgba(0, 0, 0, 0.25)
	}

	Rectangle {
		id: barContent

		anchors.horizontalCenter: parent.horizontalCenter
		height: bar.panelHeight()
		width: bar.panelWidth()
		radius: bar.somethingOpen ? (osdOpen ? osdRadius : openRadius) : normalRadius
		color: colors.background

		MouseArea {
			anchors.fill: parent
			enabled: volumeOsd.opacity === 0 && brightnessOsd.opacity === 0 && caffeineOsd.opacity === 0 && microphoneOsd.opacity === 0
			onClicked: {
				if (bar.launcherPanelOpen) {
					bar.launcherPanelOpen = false
					bar.focusable = false
				} else if (bar.clipboardPanelOpen) {
					bar.clipboardPanelOpen = false
					bar.focusable = false
				} else {
					bar.quickPanelOpen = !bar.quickPanelOpen
				}
			}
		}

		Item {
			anchors.centerIn: parent
			width: clock.implicitWidth
			height: clock.implicitHeight
			visible: !bar.somethingOpen

			WorkspaceIndicator {
				anchors.right: clock.left
				anchors.rightMargin: 60
				anchors.verticalCenter: clock.verticalCenter
			}

			Clock {
				id: clock
				anchors.centerIn: parent
			}

			BatteryIndicator {
				anchors.left: clock.right
				anchors.leftMargin: 60
				anchors.verticalCenter: clock.verticalCenter
			}
		}

		Clipboard {
			id: clipboardPanel
			barWindow: bar
			opacity: bar.clipboardPanelOpen ? 1 : 0
			visible: bar.clipboardPanelOpen || opacity > 0
			anchors.fill: parent
			onCloseRequested: {
				bar.clipboardPanelOpen = false
				bar.focusable = false
			}

			Behavior on opacity {
				NumberAnimation {
					duration: bar.clipboardPanelOpen ? 150 : 250
					easing.type: bar.clipboardPanelOpen
					? Easing.OutCubic
					: Easing.InCubic
				}
			}
		}

		Launcher {
			id: launcherPanel
			barWindow: bar
			opacity: bar.launcherPanelOpen ? 1 : 0
			visible: bar.launcherPanelOpen || opacity > 0
			anchors.fill: parent
			onCloseRequested: {
				bar.launcherPanelOpen = false
				bar.focusable = false
			}

			Behavior on opacity {
				NumberAnimation {
					duration: bar.launcherPanelOpen ? 150 : 250
					easing.type: bar.launcherPanelOpen
					? Easing.OutCubic
					: Easing.InCubic
				}
			}
		}

		QuickPanel {
			id: quickPanel
			barWindow: bar
			opacity: bar.quickPanelOpen ? 1 : 0
			visible: bar.quickPanelOpen || opacity > 0
			anchors.fill: parent
			onCloseRequested: bar.closeQuickPanel()

			Behavior on opacity {
				NumberAnimation {
					duration: bar.quickPanelOpen ? 150 : 250
					easing.type: bar.quickPanelOpen
					? Easing.OutCubic
					: Easing.InCubic
				}
			}
		}

		Notifications {
			id: notificationPanel
			barWindow: bar
			opacity: notificationPanel.active ? 1 : 0
			visible: notificationPanel.active || opacity > 0
			anchors.fill: parent

			Behavior on opacity {
				NumberAnimation {
					duration: notificationPanel.active ? 150 : 250
					easing.type: notificationPanel.active
					? Easing.OutCubic
					: Easing.InCubic
				}
			}
		}

		OSD.Volume {
			id: volumeOsd
			anchors.fill: parent
		}

		OSD.Brightness {
			id: brightnessOsd
			anchors.fill: parent
		}

		OSD.Caffeine {
			id: caffeineOsd
			anchors.fill: parent
		}

		OSD.Micprone {
			id: microphoneOsd
			anchors.fill: parent
		}

		Behavior on width {
			NumberAnimation {
				duration: 250
				easing.type: bar.somethingOpen
				? Easing.OutCubic
				: Easing.InCubic
			}
		}

		Behavior on height {
			NumberAnimation {
				duration: 250
				easing.type: bar.somethingOpen
				? Easing.OutCubic
				: Easing.InCubic
			}
		}
	}

	IpcHandler {
		target: "launcher"
		function toggle() {
			bar.focusable = !bar.launcherPanelOpen
			bar.launcherPanelOpen = !bar.launcherPanelOpen
		}
	}

	IpcHandler {
		target: "clipboard"
		function toggle() {
			bar.focusable = !bar.clipboardPanelOpen
			bar.clipboardPanelOpen = !bar.clipboardPanelOpen
		}
	}

	IpcHandler {
		target: "osd"

		function volume() {
			volumeOsd.showVolume()
		}

		function brightness() {
			brightnessOsd.refreshBrightness()
		}

		function caffeine() {
			caffeineOsd.showCaffeine()
		}

		function microphone() {
			microphoneOsd.showMicrophone()
		}

		function mic() {
			microphone()
		}
	}
}
