import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.config
import qs.services
import qs.components

// Incoming notification shown by the notch.
// Click the text: open the list. Eye: hide the peek but keep it in the list. Bin: dismiss it completely.
Item {
	id: root

	readonly property var n: Notifs.peek
	property var last: null
	onNChanged: if (n)
		last = n

	readonly property int actionCount: last && last.actions ? last.actions.length : 0

	implicitWidth: 440
	implicitHeight: 60 + (actionCount > 0 ? 34 : 0)

	HoverHandler {
		onHoveredChanged: Notifs.hold = hovered
	}

	NotificationVisual {
		id: visual
		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.topMargin: 6
		height: 52
		notification: root.last
		compact: true
		rightPad: 70

		MouseArea {
			anchors.fill: parent
			anchors.rightMargin: 70
			cursorShape: Qt.PointingHandCursor
			onClicked: {
				Notifs.hidePeek();
				NotchCtl.show("notifications");
			}
		}
	}

	Row {
		anchors.top: parent.top
		anchors.topMargin: 15
		anchors.right: parent.right
		spacing: 4
		Btn {
			icon: "visibility_off"
			iconSize: 18
			implicitWidth: 32
			implicitHeight: 32
			onClicked: Notifs.hidePeek()
		}
		Btn {
			icon: "delete"
			iconSize: 18
			variant: 3
			implicitWidth: 32
			implicitHeight: 32
			onClicked: {
				const n = root.last;
				Notifs.hidePeek();
				if (n)
					n.dismiss();
			}
		}
	}

	Row {
		visible: root.actionCount > 0
		anchors.left: parent.left
		anchors.leftMargin: 50
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 4
		spacing: 8
		Repeater {
			model: root.last ? root.last.actions : []
			Btn {
				required property var modelData
				label: modelData.text
				implicitHeight: 28
				onClicked: {
					modelData.invoke();
					Notifs.hidePeek();
				}
			}
		}
	}
}
