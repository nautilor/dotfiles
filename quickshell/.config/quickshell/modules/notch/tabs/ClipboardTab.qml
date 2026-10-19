import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.components

// Clipboard history from clipse.
FocusScope {
	id: root

	function focusInput() {
		field.forceFocus();
	}

	readonly property var results: Clip.search(field.text)

	function choose(entry) {
		if (!entry)
			return;
		Clip.copy(entry);
		NotchCtl.close();
	}

	Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
	Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
	Keys.onDeletePressed: if (results[list.currentIndex])
		Clip.remove(results[list.currentIndex])

	ColumnLayout {
		anchors.fill: parent
		spacing: 10

		RowLayout {
			Layout.fillWidth: true
			spacing: 8
			Field {
				id: field
				Layout.fillWidth: true
				icon: "search"
				placeholder: "Search clipboard history"
				onEdited: list.currentIndex = 0
				onAccepted: root.choose(root.results[list.currentIndex])
			}
			Btn {
				icon: "delete_sweep"
				label: "Clear"
				variant: 3
				onClicked: Clip.clearUnpinned()
			}
		}

		ListView {
			id: list
			Layout.fillWidth: true
			Layout.fillHeight: true
			clip: true
			spacing: 4
			model: root.results
			currentIndex: 0
			boundsBehavior: Flickable.StopAtBounds
			onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

			Txt {
				visible: list.count === 0
				anchors.centerIn: parent
				text: "Clipboard history is empty"
				color: Theme.surfaceVariantFg
			}

			delegate: Rectangle {
				id: row
				required property var modelData
				required property int index
				readonly property bool current: ListView.isCurrentItem
				readonly property bool image: Clip.isImage(modelData)

				width: list.width
				height: image ? 96 : 56
				radius: 20
				color: current ? Theme.secondaryContainer : Theme.surfaceContainer
				Behavior on color {
					ColorAnimation {
						duration: 100
					}
				}

				Icon {
					id: kind
					name: row.modelData.pinned ? "push_pin" : (row.image ? "image" : "notes")
					fill: row.modelData.pinned ? 1 : 0
					size: 20
					color: row.modelData.pinned ? Theme.primary : Theme.surfaceVariantFg
					anchors.left: parent.left
					anchors.leftMargin: 14
					anchors.verticalCenter: parent.verticalCenter
				}

				Image {
					visible: row.image
					anchors.left: kind.right
					anchors.leftMargin: 12
					anchors.verticalCenter: parent.verticalCenter
					height: 76
					width: 200
					fillMode: Image.PreserveAspectFit
					horizontalAlignment: Image.AlignLeft
					sourceSize.height: 152
					asynchronous: true
					source: row.image ? "file://" + row.modelData.filePath : ""
				}

				Txt {
					visible: !row.image
					anchors.left: kind.right
					anchors.leftMargin: 12
					anchors.right: actions.left
					anchors.rightMargin: 8
					anchors.verticalCenter: parent.verticalCenter
					text: row.modelData.value
					maximumLineCount: 2
					wrapMode: Text.Wrap
					color: row.current ? Theme.secondaryContainerFg : Theme.surfaceFg
				}

				MouseArea {
					anchors.fill: parent
					hoverEnabled: true
					onEntered: list.currentIndex = row.index
					onClicked: root.choose(row.modelData)
				}

				Row {
					id: actions
					anchors.right: parent.right
					anchors.rightMargin: 8
					anchors.verticalCenter: parent.verticalCenter
					spacing: 2
					opacity: row.current || row.modelData.pinned ? 1 : 0
					Btn {
						icon: "push_pin"
						variant: 2
						toggleable: true
						toggled: row.modelData.pinned
						iconSize: 18
						implicitWidth: 36
						implicitHeight: 36
						onClicked: Clip.togglePin(row.modelData)
					}
					Btn {
						icon: "close"
						variant: 2
						iconSize: 18
						implicitWidth: 36
						implicitHeight: 36
						onClicked: Clip.remove(row.modelData)
					}
				}
			}
		}
	}
}
