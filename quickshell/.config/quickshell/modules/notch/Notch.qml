import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.components

PanelWindow {
	id: win

	required property var modelData
	screen: modelData

	// the shared open state only applies to the screen it was opened on
	readonly property bool isOpen: NotchCtl.open && (NotchCtl.screen === "" || NotchCtl.screen === screen.name)

	anchors.top: true
	implicitWidth: 960
	implicitHeight: 620
	color: "transparent"
	exclusionMode: ExclusionMode.Ignore
	mask: Region {
		item: hit
	}

	WlrLayershell.namespace: "notch"
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.keyboardFocus: isOpen ? (NotchCtl.keyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand) : WlrKeyboardFocus.None

	// ---- state ----
	readonly property string mode: isOpen ? "open" : (Notifs.peek ? "notif" : (Hud.active ? "hud" : "idle"))
	readonly property var sizes: ({
			"home": [800, 380],
			"apps": [640, 410],
			"clipboard": [700, 430],
			"calendar": [920, 580],
			"notifications": [660, 400],
			"power": [600, 260],
			"settings": [720, 500]
		})
	readonly property var openSize: sizes[NotchCtl.tab] ?? sizes.home

	readonly property real targetW: {
		switch (mode) {
		case "open":
			return openSize[0];
		case "notif":
			return peek.implicitWidth + 2 * topR + 12;
		case "hud":
			return Math.max(hudView.implicitWidth + 2 * topR + 16, 250);
		default:
			return closedView.implicitWidth + 2 * topR;
		}
	}
	readonly property real targetH: {
		switch (mode) {
		case "open":
			return openSize[1];
		case "notif":
			return peek.implicitHeight + 8;
		case "hud":
			return hudView.implicitHeight;
		default:
			return closedView.implicitHeight;
		}
	}
	readonly property real topR: mode === "open" ? 24 : mode === "idle" ? 8 : 16
	readonly property real botR: mode === "open" ? 34 : mode === "idle" ? 14 : 26

	// ---- open/close by hover ----
	Timer {
		id: openTimer
		interval: 140
		onTriggered: if (hover.hovered && Settings.hoverOpen && !win.isOpen && win.mode !== "notif") {
			NotchCtl.screen = win.screen.name;
			if (Settings.homeOnHover)
				NotchCtl.tab = "home";
			NotchCtl.open = true;
		}
	}
	Timer {
		id: closeTimer
		interval: 380
		onTriggered: if (!hover.hovered && win.isOpen && !NotchCtl.sticky)
			NotchCtl.open = false
	}

	// ---- autohide: slide the idle notch off the top edge, leaving a thin hover strip ----
	property bool hidden: false
	readonly property bool wantHidden: Settings.autohide && mode === "idle" && !hover.hovered
	onWantHiddenChanged: {
		if (wantHidden)
			hideTimer.restart();
		else
			hidden = false;
	}
	Timer {
		id: hideTimer
		interval: 900
		onTriggered: win.hidden = win.wantHidden
	}

	// input mask: the shape plus a small forgiving margin (just a strip while hidden)
	Item {
		id: hit
		anchors.top: parent.top
		anchors.horizontalCenter: parent.horizontalCenter
		width: stage.width + 20
		height: win.hidden ? 6 : stage.height + 8
	}

	// click-outside dismissal; armed shortly after opening so the initial focus change does not trigger it
	property bool grabArmed: false
	Timer {
		id: armTimer
		interval: 400
		onTriggered: win.grabArmed = true
	}
	Connections {
		target: NotchCtl
		function onOpenChanged() {
			win.grabArmed = false;
			if (win.isOpen)
				armTimer.restart();
		}
	}
	HyprlandFocusGrab {
		windows: [win]
		active: win.grabArmed && win.isOpen && NotchCtl.sticky
		onCleared: NotchCtl.close()
	}

	FocusScope {
		anchors.fill: parent
		focus: true
		Keys.onEscapePressed: NotchCtl.close()

		// on the root of the scene so hover stays true over child items with their own mouse areas
		HoverHandler {
			id: hover
			onHoveredChanged: {
				if (hovered)
					openTimer.restart();
				else
					closeTimer.restart();
			}
		}

		Item {
			id: stage
			anchors.top: parent.top
			anchors.topMargin: win.hidden ? 4 - height : 0
			anchors.horizontalCenter: parent.horizontalCenter
			width: win.targetW
			height: win.targetH

			Behavior on anchors.topMargin {
				SpringAnimation {
					spring: Theme.springSoft
					damping: Theme.dampSoft
					epsilon: 0.5
				}
			}

			Behavior on width {
				SpringAnimation {
					spring: Theme.springBouncy
					damping: Theme.dampBouncy
					epsilon: 0.5
				}
			}
			Behavior on height {
				SpringAnimation {
					spring: Theme.springBouncy
					damping: Theme.dampBouncy
					epsilon: 0.5
				}
			}

			property real tr: win.topR
			property real br: win.botR
			Behavior on tr {
				NumberAnimation {
					duration: Theme.durMedium
					easing.type: Easing.BezierSpline
					easing.bezierCurve: Theme.emphasized
				}
			}
			Behavior on br {
				NumberAnimation {
					duration: Theme.durMedium
					easing.type: Easing.BezierSpline
					easing.bezierCurve: Theme.emphasized
				}
			}

			// notch silhouette: concave ears at the top corners, rounded bottom corners
			Shape {
				anchors.fill: parent
				preferredRendererType: Shape.CurveRenderer

				ShapePath {
					fillColor: Theme.notch
					strokeWidth: -1
					startX: 0
					startY: 0

					PathArc {
						x: stage.tr
						y: stage.tr
						radiusX: stage.tr
						radiusY: stage.tr
						direction: PathArc.Clockwise
					}
					PathLine {
						x: stage.tr
						y: stage.height - stage.br
					}
					PathArc {
						x: stage.tr + stage.br
						y: stage.height
						radiusX: stage.br
						radiusY: stage.br
						direction: PathArc.Counterclockwise
					}
					PathLine {
						x: stage.width - stage.tr - stage.br
						y: stage.height
					}
					PathArc {
						x: stage.width - stage.tr
						y: stage.height - stage.br
						radiusX: stage.br
						radiusY: stage.br
						direction: PathArc.Counterclockwise
					}
					PathLine {
						x: stage.width - stage.tr
						y: stage.tr
					}
					PathArc {
						x: stage.width
						y: 0
						radiusX: stage.tr
						radiusY: stage.tr
						direction: PathArc.Clockwise
					}
					PathLine {
						x: 0
						y: 0
					}
				}
			}

			// content area (inside the ears)
			Item {
				id: content
				x: stage.tr
				width: stage.width - 2 * stage.tr
				height: stage.height
				clip: true

				ClosedContent {
					id: closedView
					anchors.fill: parent
					anchors.leftMargin: 10
					anchors.rightMargin: 10
					opacity: win.mode === "idle" ? 1 : 0
					visible: opacity > 0.01
					Behavior on opacity {
						NumberAnimation {
							duration: Theme.durShort
						}
					}
				}

				HudContent {
					id: hudView
					anchors.fill: parent
					opacity: win.mode === "hud" ? 1 : 0
					visible: opacity > 0.01
					Behavior on opacity {
						NumberAnimation {
							duration: Theme.durShort
						}
					}
				}

				PeekContent {
					id: peek
					anchors.fill: parent
					anchors.leftMargin: 8
					anchors.rightMargin: 8
					opacity: win.mode === "notif" ? 1 : 0
					visible: opacity > 0.01
					Behavior on opacity {
						NumberAnimation {
							duration: Theme.durShort
						}
					}
				}

				OpenContent {
					id: openView
					anchors.fill: parent
					anchors.leftMargin: 8
					anchors.rightMargin: 8
					opacity: win.mode === "open" ? 1 : 0
					visible: opacity > 0.01
					active: visible
					Behavior on opacity {
						NumberAnimation {
							duration: win.mode === "open" ? Theme.durMedium : Theme.durShort
						}
					}
				}
			}

			// clicking the idle notch opens it explicitly
			MouseArea {
				anchors.fill: parent
				enabled: win.mode !== "open" && win.mode !== "notif"
				onClicked: NotchCtl.show(undefined, win.screen.name)
				z: -1
			}
		}
	}
}
