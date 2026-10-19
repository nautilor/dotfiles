import QtQuick
import qs.config

// M3 switch: thumb grows on press, track is a pill.
Item {
	id: root

	property bool checked: false
	signal toggled(bool value)

	implicitWidth: 52
	implicitHeight: 32

	Rectangle {
		anchors.fill: parent
		radius: height / 2
		color: root.checked ? Theme.primary : Theme.surfaceContainerHighest
		border.width: root.checked ? 0 : 2
		border.color: Theme.outline
		Behavior on color {
			ColorAnimation {
				duration: Theme.durShort
			}
		}
	}

	Rectangle {
		id: thumb
		property real size: mouse.pressed ? 28 : (root.checked ? 24 : 16)
		width: size
		height: size
		radius: size / 2
		anchors.verticalCenter: parent.verticalCenter
		x: root.checked ? parent.width - width - 4 : 8 - (size - 16) / 2
		color: root.checked ? Theme.primaryFg : Theme.outline

		Behavior on x {
			SpringAnimation {
				spring: Theme.springBouncy
				damping: Theme.dampBouncy
				epsilon: 0.25
			}
		}
		Behavior on size {
			NumberAnimation {
				duration: Theme.durShort
			}
		}
		Behavior on color {
			ColorAnimation {
				duration: Theme.durShort
			}
		}
	}

	MouseArea {
		id: mouse
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: root.toggled(!root.checked)
	}
}
