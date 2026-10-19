import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.config

// Rounds the corners of one screen: four inverted quarter-circles drawn over everything, click-through.
PanelWindow {
	id: root

	required property var modelData
	screen: modelData

	readonly property real radius: Settings.cornerRadius
	readonly property color fill: Theme.notch

	anchors {
		left: true
		top: true
		right: true
		bottom: true
	}
	color: "transparent"
	exclusionMode: ExclusionMode.Ignore
	mask: Region {}

	WlrLayershell.namespace: "notch-corners"
	WlrLayershell.layer: WlrLayer.Overlay

	component CornerShape: Shape {
		id: shape
		preferredRendererType: Shape.CurveRenderer
		width: root.radius
		height: root.radius

		ShapePath {
			strokeWidth: -1
			fillColor: root.fill
			startX: 0
			startY: 0

			PathLine {
				x: shape.width
				y: 0
			}
			PathArc {
				x: 0
				y: shape.height
				radiusX: shape.width
				radiusY: shape.height
				direction: PathArc.Counterclockwise
			}
			PathLine {
				x: 0
				y: 0
			}
		}
	}

	CornerShape {
		anchors.top: parent.top
		anchors.left: parent.left
	}
	CornerShape {
		anchors.top: parent.top
		anchors.right: parent.right
		rotation: 90
	}
	CornerShape {
		anchors.bottom: parent.bottom
		anchors.right: parent.right
		rotation: 180
	}
	CornerShape {
		anchors.bottom: parent.bottom
		anchors.left: parent.left
		rotation: 270
	}
}
