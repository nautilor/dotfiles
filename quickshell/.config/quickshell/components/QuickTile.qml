import QtQuick
import qs.config
import qs.components

// Control Center tile: icon in a round chip, title and a state line, all inside a pill that squares up when on.
Item {
	id: root

	property string icon
	property string title
	property string subtitle
	property bool toggled: false

	signal clicked

	implicitHeight: 64

	Rectangle {
		id: bg
		anchors.fill: parent
		color: root.toggled ? Theme.primaryContainer : Theme.surfaceContainerHigh
		radius: mouse.pressed ? 14 : root.toggled ? 22 : height / 2
		Behavior on color {
			ColorAnimation {
				duration: Theme.durShort
			}
		}
		Behavior on radius {
			SpringAnimation {
				spring: Theme.springBouncy
				damping: Theme.dampBouncy
				epsilon: 0.25
			}
		}
		Rectangle {
			anchors.fill: parent
			radius: parent.radius
			color: Theme.surfaceFg
			opacity: mouse.pressed ? 0.12 : mouse.containsMouse ? 0.06 : 0
		}
	}

	Rectangle {
		id: chip
		width: Math.min(root.height - 16, 44)
		height: width
		radius: root.toggled ? 14 : width / 2
		anchors.left: parent.left
		anchors.leftMargin: 8
		anchors.verticalCenter: parent.verticalCenter
		color: root.toggled ? Theme.primary : "transparent"
		Behavior on color {
			ColorAnimation {
				duration: Theme.durShort
			}
		}
		Behavior on radius {
			NumberAnimation {
				duration: Theme.durShort
			}
		}
		Icon {
			anchors.centerIn: parent
			name: root.icon
			size: 22
			fill: root.toggled ? 1 : 0
			color: root.toggled ? Theme.primaryFg : Theme.surfaceVariantFg
		}
	}

	Column {
		anchors.left: chip.right
		anchors.leftMargin: 10
		anchors.right: parent.right
		anchors.rightMargin: 14
		anchors.verticalCenter: parent.verticalCenter
		Txt {
			width: parent.width
			text: root.title
			font.weight: Font.Medium
			color: root.toggled ? Theme.primaryContainerFg : Theme.surfaceFg
		}
		Txt {
			width: parent.width
			visible: root.subtitle !== ""
			text: root.subtitle
			font.pixelSize: 11
			color: root.toggled ? Theme.primaryContainerFg : Theme.surfaceVariantFg
			opacity: 0.8
		}
	}

	scale: mouse.pressed ? 0.97 : 1
	Behavior on scale {
		SpringAnimation {
			spring: 5
			damping: 0.4
			epsilon: 0.002
		}
	}

	MouseArea {
		id: mouse
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}
}
