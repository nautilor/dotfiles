import QtQuick
import qs.config
import qs.services
import qs.components

// Next calendar event; click opens the week view.
Rectangle {
	id: root

	readonly property var next: Gcal.upcoming.length > 0 ? Gcal.upcoming[0] : null

	function when(ev) {
		const now = new Date();
		const day = Gcal.sameDay(ev.s, now) || ev.s < now ? "Today" : Gcal.sameDay(ev.s, Gcal.addDays(now, 1)) ? "Tomorrow" : Qt.formatDate(ev.s, "ddd d MMM");
		return day + " · " + Gcal.timeLabel(ev);
	}

	radius: Theme.radiusMedium
	color: Theme.tertiaryContainer

	Rectangle {
		anchors.fill: parent
		radius: parent.radius
		color: Theme.tertiaryContainerFg
		opacity: area.pressed ? 0.12 : area.containsMouse ? 0.08 : 0
	}

	Rectangle {
		id: badge
		width: 40
		height: 40
		radius: 14
		color: Theme.tertiary
		anchors.left: parent.left
		anchors.leftMargin: 12
		anchors.verticalCenter: parent.verticalCenter
		Icon {
			anchors.centerIn: parent
			name: "event"
			fill: 1
			size: 22
			color: Theme.tertiaryFg
		}
	}

	Column {
		anchors.left: badge.right
		anchors.leftMargin: 12
		anchors.right: parent.right
		anchors.rightMargin: 12
		anchors.verticalCenter: parent.verticalCenter
		spacing: 1
		Txt {
			width: parent.width
			text: Gcal.authState !== "ready" ? "Google Calendar" : root.next ? root.next.title : "No upcoming events"
			font.weight: Font.Bold
			color: Theme.tertiaryContainerFg
		}
		Txt {
			width: parent.width
			text: Gcal.authState !== "ready" ? "Tap to connect" : root.next ? root.when(root.next) : "Enjoy the quiet"
			font.pixelSize: 12
			color: Theme.tertiaryContainerFg
			opacity: 0.8
		}
	}

	MouseArea {
		id: area
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: NotchCtl.tab = "calendar"
	}
}
