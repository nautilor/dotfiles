import Quickshell
import QtQuick
import QtQuick.Effects

Item {
	id: indicator
	property string backgroundColor: ""
	property string foregroundColor: ""
	property string icon: ""
	property int fontSize: 20
	property int indicatorSize: 40

	RectangularShadow {
		anchors.fill: parent
		radius: 20
		blur: 8
		spread: 0
		offset: Qt.point(0, 2)
		color: Qt.rgba(0, 0, 0, 0.25)
	}

	Rectangle {
		anchors.centerIn: parent
		width: indicatorSize
		height: indicatorSize
		radius: 100
		color: backgroundColor

		Text {
			anchors.centerIn: parent
			text: icon
			color: foregroundColor
			font.pixelSize: fontSize
			font.weight: Font.Medium
		}
	}
}
