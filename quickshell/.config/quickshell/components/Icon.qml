import QtQuick
import qs.config

// Material Design Icons glyph from JetBrainsMono Nerd Font, addressed by Material-style name (see Glyphs.qml).
Text {
	id: root

	property string name
	property real size: 22
	property real fill: 0
	property int weight: 400

	text: Glyphs.get(name)
	color: Theme.surfaceFg
	font.family: Theme.iconFont
	font.pixelSize: size
	horizontalAlignment: Text.AlignHCenter
	verticalAlignment: Text.AlignVCenter
	width: size
	height: size

	Behavior on fill {
		NumberAnimation {
			duration: Theme.durMedium
			easing.type: Easing.BezierSpline
			easing.bezierCurve: Theme.emphasized
		}
	}
	Behavior on color {
		ColorAnimation {
			duration: Theme.durShort
		}
	}
}
