import QtQuick
import QtQuick.Shapes
import Quickshell.Io
import Quickshell

PanelWindow {
  id: root
	visible: true
  property color mColor: "#000"
	aboveWindows: false
	margins {
		left: 0
		top: 0
		right: 0
		bottom: 0
	}

  color: "#00000000"
  exclusionMode: ExclusionMode.Ignore
  mask: Region {}
  anchors {
    left: true
    top: true
    right: true
    bottom: true
  }


  Rectangle {
    id: left
		implicitWidth: 0
    implicitHeight: parent.height
    color: "transparent"
		anchors.left: parent.left
  }
  Rectangle {
    id: top
		implicitWidth: parent.width
		implicitHeight: 0
    color: root.mColor
  }
  Rectangle {
    id: right
    implicitWidth: 0
    implicitHeight: parent.height
    color: root.mColor
    anchors.right: parent.right
  }
  Rectangle {
    id: bottom
    implicitWidth: parent.width
    implicitHeight: 0
    color: root.mColor
    anchors.bottom: parent.bottom
  }

	// Top left
  Corner {
    id: leftTopCorner
    x: 0
    y: 0
  }

	// Bottom left
  Corner {
    id: leftBottomCorner
    x: left.implicitWidth - 2
    y: parent.height - (radius + bottom.implicitHeight)
    rotation: -90
  }

	// Top right
  Corner {
    x: parent.width - (radius + bottom.implicitHeight)
    y: 0
    rotation: 90
  }

	// Bottom right
  Corner {
    x: parent.width - (radius + bottom.implicitHeight)
    y: parent.height - (radius + bottom.implicitHeight)
    rotation: 180
  }

  component Corner: Shape {
    id: corner
    preferredRendererType: Shape.CurveRenderer

    property real radius: 10

    ShapePath {
      strokeWidth: 0
      fillColor: root.mColor

      startX: corner.radius

      PathArc {
        relativeX: -corner.radius
        relativeY: corner.radius
        radiusX: corner.radius
        radiusY: corner.radius
        direction: PathArc.Counterclockwise
      }

      PathLine {
        relativeX: 0
        relativeY: -corner.radius
      }

      PathLine {
        relativeX: corner.radius
        relativeY: 0
      }
    }
  }

  Scope {
    PanelWindow {
      anchors.left: true
      implicitWidth: left.implicitWidth
      implicitHeight: 0
			color: "transparent"
    }

    PanelWindow {
      anchors.top: true
      implicitWidth: 0
      implicitHeight: top.implicitHeight
			color: "transparent"
    }

    PanelWindow {
      anchors.right: true
      implicitWidth: right.implicitWidth
      implicitHeight: 0
			color: "transparent"
    }

    PanelWindow {
      anchors.bottom: true
      implicitWidth: 0
      implicitHeight: bottom.implicitHeight
			color: "transparent"
    }
  }
	IpcHandler {
		target: "root"
		function toggle() {
			root.visible = !root.visible
			root.roundingVisible = !root.roundingVisible
		}
	}
}
