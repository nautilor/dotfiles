import Quickshell
import QtQuick
import qs.modules.colors

Item {
	id: clock

	Colors {
		id: colors
	}

	property string time: Qt.formatDateTime(new Date(), "hh:mm")

	implicitWidth: clockText.implicitWidth
	implicitHeight: clockText.implicitHeight

	Text {
		id: clockText
		anchors.centerIn: parent
		text: clock.time
		color: colors.windowForeground
	}

	Behavior {
		NumberAnimation {
			duration: 100
			easing.type: barMouseArea.containsMouse ? Easing.OutCubic : Easing.InCubic
		}
	}

	Timer {
		interval: 1000
		repeat: true
		running: true
		onTriggered: {
			clock.time = Qt.formatDateTime(new Date(), "hh:mm")
		}
	}
}
