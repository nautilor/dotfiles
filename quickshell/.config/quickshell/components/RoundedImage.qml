import QtQuick
import QtQuick.Effects

// Image clipped to a rounded rectangle (Item.clip only clips to a plain rectangle).
Item {
	id: root

	property url source
	property real radius: 20
	property int fillMode: Image.PreserveAspectCrop
	readonly property int status: img.status

	Image {
		id: img
		anchors.fill: parent
		source: root.source
		fillMode: root.fillMode
		sourceSize: Qt.size(root.width * 2, root.height * 2)
		asynchronous: true
		layer.enabled: true
		layer.effect: MultiEffect {
			maskEnabled: true
			maskSource: mask
			maskThresholdMin: 0.5
			maskSpreadAtMin: 1.0
		}
	}

	Item {
		id: mask
		anchors.fill: parent
		visible: false
		layer.enabled: true
		Rectangle {
			anchors.fill: parent
			radius: root.radius
		}
	}
}
