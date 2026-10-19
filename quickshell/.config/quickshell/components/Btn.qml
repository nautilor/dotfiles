import QtQuick
import qs.config

// M3 Expressive button: pill/circle at rest, morphs to a rounder-square when toggled, squishes on press.
Item {
	id: root

	property string icon
	property string label
	property bool toggleable: false
	property bool toggled: false
	// 0 tonal, 1 filled, 2 ghost, 3 error
	property int variant: 0
	property real iconSize: 22
	property real toggledRadius: 16
	property real idleRadius: 1000
	property bool vertical: false
	property bool busy: false

	signal clicked
	signal rightClicked

	readonly property bool hovered: mouse.containsMouse
	readonly property bool pressed: mouse.pressed
	readonly property bool on: toggleable && toggled

	readonly property color bgColor: {
		if (variant === 1 || on)
			return Theme.primary;
		if (variant === 3)
			return Theme.errorContainer;
		if (variant === 2)
			return "transparent";
		return Theme.surfaceContainerHigh;
	}
	readonly property color fgColor: {
		if (variant === 1 || on)
			return Theme.primaryFg;
		if (variant === 3)
			return Theme.errorContainerFg;
		return Theme.surfaceVariantFg;
	}

	implicitWidth: (vertical ? Math.max(contentCol.implicitWidth, contentRow.implicitWidth) : contentRow.implicitWidth) + 32
	implicitHeight: 44

	Rectangle {
		id: bg
		anchors.fill: parent
		color: root.bgColor
		radius: root.pressed ? 10 : (root.on ? root.toggledRadius : Math.min(height / 2, root.idleRadius))

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
			color: root.fgColor
			opacity: root.pressed ? 0.14 : root.hovered ? 0.08 : 0
			Behavior on opacity {
				NumberAnimation {
					duration: 100
				}
			}
		}
	}

	scale: pressed ? 0.96 : 1
	Behavior on scale {
		SpringAnimation {
			spring: 5
			damping: 0.4
			epsilon: 0.002
		}
	}

	Row {
		id: contentRow
		visible: !root.vertical
		anchors.centerIn: parent
		spacing: 8
		Icon {
			visible: root.icon !== ""
			name: root.icon
			size: root.iconSize
			color: root.fgColor
			fill: root.on ? 1 : 0
			anchors.verticalCenter: parent.verticalCenter
		}
		Txt {
			visible: root.label !== ""
			text: root.label
			color: root.fgColor
			font.weight: Font.Medium
			anchors.verticalCenter: parent.verticalCenter
		}
	}

	Column {
		id: contentCol
		visible: root.vertical
		anchors.centerIn: parent
		spacing: 4
		Icon {
			visible: root.icon !== ""
			name: root.icon
			size: root.iconSize
			color: root.fgColor
			fill: root.on ? 1 : 0
			anchors.horizontalCenter: parent.horizontalCenter
		}
		Txt {
			visible: root.label !== ""
			text: root.label
			color: root.fgColor
			font.pixelSize: 12
			font.weight: Font.Medium
			anchors.horizontalCenter: parent.horizontalCenter
		}
	}

	MouseArea {
		id: mouse
		anchors.fill: parent
		hoverEnabled: true
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		cursorShape: Qt.PointingHandCursor
		onClicked: mouse => mouse.button === Qt.RightButton ? root.rightClicked() : root.clicked()
	}
}
