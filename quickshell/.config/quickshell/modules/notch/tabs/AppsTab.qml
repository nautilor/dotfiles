import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components

FocusScope {
	id: root

	function focusInput() {
		field.forceFocus();
	}

	readonly property var results: Apps.search(field.text)

	function launch(entry) {
		if (!entry)
			return;
		Apps.launch(entry);
		NotchCtl.close();
	}

	Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
	Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)

	ColumnLayout {
		anchors.fill: parent
		spacing: 10

		Field {
			id: field
			Layout.fillWidth: true
			icon: "search"
			placeholder: "Search applications"
			onEdited: list.currentIndex = 0
			onAccepted: root.launch(root.results[list.currentIndex])
		}

		ListView {
			id: list
			Layout.fillWidth: true
			Layout.fillHeight: true
			clip: true
			spacing: 2
			model: root.results
			currentIndex: 0
			boundsBehavior: Flickable.StopAtBounds
			highlightMoveDuration: 120
			onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

			delegate: Rectangle {
				id: row
				required property var modelData
				required property int index
				readonly property bool current: ListView.isCurrentItem

				width: list.width
				height: 52
				radius: 26
				color: current ? Theme.secondaryContainer : "transparent"
				Behavior on color {
					ColorAnimation {
						duration: 100
					}
				}

				Image {
					id: appIcon
					width: 34
					height: 34
					anchors.left: parent.left
					anchors.leftMargin: 12
					anchors.verticalCenter: parent.verticalCenter
					sourceSize: Qt.size(68, 68)
					source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
				}
				Column {
					anchors.left: appIcon.right
					anchors.leftMargin: 12
					anchors.right: parent.right
					anchors.rightMargin: 16
					anchors.verticalCenter: parent.verticalCenter
					Txt {
						width: parent.width
						text: row.modelData.name
						font.weight: Font.Medium
						color: row.current ? Theme.secondaryContainerFg : Theme.surfaceFg
					}
					Txt {
						width: parent.width
						visible: text !== ""
						text: row.modelData.comment || row.modelData.genericName
						font.pixelSize: 12
						color: Theme.surfaceVariantFg
					}
				}
				MouseArea {
					anchors.fill: parent
					hoverEnabled: true
					onEntered: list.currentIndex = row.index
					onClicked: root.launch(row.modelData)
				}
			}
		}
	}
}
