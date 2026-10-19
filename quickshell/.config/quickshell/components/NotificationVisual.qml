import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config
import qs.components

// One notification row: icon/image, app name, summary, body (+ actions when not compact).
Item {
	id: root

	property var notification
	property bool compact: false
	property real rightPad: 0

	readonly property var n: notification
	readonly property string imageSource: {
		if (!n)
			return "";
		if (n.image)
			return n.image;
		if (n.appIcon)
			return n.appIcon.startsWith("/") ? "file://" + n.appIcon : Quickshell.iconPath(n.appIcon, true);
		return "";
	}
	readonly property bool critical: n && n.urgency === NotificationUrgency.Critical

	implicitHeight: compact ? 52 : col.implicitHeight + 16

	Rectangle {
		visible: !root.compact
		anchors.fill: parent
		radius: Theme.radiusMedium
		color: root.critical ? Theme.errorContainer : Theme.surfaceContainer
	}

	Rectangle {
		id: icon
		width: 40
		height: 40
		radius: 14
		color: Theme.secondaryContainer
		anchors.left: parent.left
		anchors.leftMargin: root.compact ? 0 : 8
		anchors.verticalCenter: root.compact ? parent.verticalCenter : undefined
		anchors.top: root.compact ? undefined : parent.top
		anchors.topMargin: 8
		clip: true

		Image {
			anchors.fill: parent
			source: root.imageSource
			fillMode: Image.PreserveAspectCrop
			sourceSize: Qt.size(96, 96)
			visible: status === Image.Ready
		}
		Icon {
			anchors.centerIn: parent
			name: "notifications"
			fill: 1
			size: 24
			color: Theme.secondaryContainerFg
			visible: root.imageSource === ""
		}
	}

	Column {
		id: col
		anchors.left: icon.right
		anchors.leftMargin: 10
		anchors.right: parent.right
		anchors.rightMargin: (root.compact ? 0 : 8) + root.rightPad
		anchors.verticalCenter: root.compact ? parent.verticalCenter : undefined
		anchors.top: root.compact ? undefined : parent.top
		anchors.topMargin: 8
		spacing: 2

		Txt {
			width: parent.width
			text: root.n ? root.n.appName : ""
			font.pixelSize: 11
			font.weight: Font.Medium
			color: root.critical ? Theme.errorContainerFg : Theme.primary
		}
		Txt {
			width: parent.width
			text: root.n ? root.n.summary : ""
			font.pixelSize: 15
			font.weight: Font.Bold
		}
		Txt {
			width: parent.width
			visible: text !== ""
			text: root.n ? root.n.body : ""
			textFormat: Text.StyledText
			font.pixelSize: 13
			color: Theme.surfaceVariantFg
			wrapMode: root.compact ? Text.NoWrap : Text.Wrap
			maximumLineCount: root.compact ? 1 : 4
			elide: Text.ElideRight
		}

		Row {
			visible: !root.compact && root.n && root.n.actions.length > 0
			spacing: 8
			topPadding: 4
			Repeater {
				model: root.n ? root.n.actions : []
				Btn {
					required property var modelData
					label: modelData.text
					implicitHeight: 28
					onClicked: modelData.invoke()
				}
			}
		}
	}
}
