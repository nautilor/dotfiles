import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

ColumnLayout {
	spacing: 10

	RowLayout {
		Layout.fillWidth: true
		spacing: 10

		Txt {
			text: Notifs.count + (Notifs.count === 1 ? " notification" : " notifications")
			font.pixelSize: 17
			font.weight: Font.Bold
			Layout.fillWidth: true
		}
		Btn {
			icon: Settings.dnd ? "notifications_off" : "notifications_active"
			label: "Silent"
			toggleable: true
			toggled: Settings.dnd
			implicitHeight: 40
			onClicked: Settings.dnd = !Settings.dnd
		}
		Btn {
			icon: "clear_all"
			label: "Clear all"
			implicitHeight: 40
			enabled: Notifs.count > 0
			onClicked: Notifs.dismissAll()
		}
	}

	ListView {
		id: list
		Layout.fillWidth: true
		Layout.fillHeight: true
		clip: true
		spacing: 8
		boundsBehavior: Flickable.StopAtBounds
		// newest first
		model: Notifs.list.values.slice().reverse()

		Column {
			visible: list.count === 0
			anchors.centerIn: parent
			spacing: 8
			Icon {
				name: "notifications_paused"
				size: 44
				color: Theme.outline
				anchors.horizontalCenter: parent.horizontalCenter
			}
			Txt {
				text: "All caught up"
				color: Theme.surfaceVariantFg
				anchors.horizontalCenter: parent.horizontalCenter
			}
		}

		add: Transition {
			NumberAnimation {
				property: "opacity"
				from: 0
				to: 1
				duration: Theme.durMedium
			}
		}
		displaced: Transition {
			NumberAnimation {
				property: "y"
				duration: Theme.durMedium
				easing.type: Easing.BezierSpline
				easing.bezierCurve: Theme.emphasized
			}
		}

		delegate: Item {
			id: item
			required property var modelData
			width: list.width
			height: visual.implicitHeight

			NotificationVisual {
				id: visual
				anchors.fill: parent
				notification: item.modelData
			}
			Btn {
				icon: "close"
				variant: 2
				iconSize: 18
				implicitWidth: 34
				implicitHeight: 34
				anchors.top: parent.top
				anchors.right: parent.right
				anchors.margins: 6
				onClicked: item.modelData.dismiss()
			}
		}
	}
}
