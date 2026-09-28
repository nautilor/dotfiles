import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

Item {
	id: entry

	required property var modelData
	required property int index
	property var clipboard: null

	width: ListView.view.width
	height: 60

	MouseArea {
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: {
			if (clipboard)
				clipboard.selectedIndex = entry.index
		}
		onDoubleClicked: {
			if (clipboard) {
				clipboard.selectedIndex = entry.index
				clipboard.copySelected()
			}
		}
	}

	function thumbnailSource() {
		const path = String(modelData.imagePath || "")
		if (path === "" || path === "/" || path.endsWith("/"))
			return ""

		return path.startsWith("file:") ? path : `file://${path}`
	}

	Rectangle {
		anchors.fill: parent
		radius: 18
		color: clipboard && clipboard.selectedIndex === entry.index
		? Qt.rgba(clipboard.accent.r, clipboard.accent.g, clipboard.accent.b, 0.20)
		: "transparent"
		border.width: 0

		RowLayout {
			anchors.fill: parent
			anchors.margins: 10
			spacing: 10

			Rectangle {
				Layout.preferredWidth: 40
				Layout.preferredHeight: 40
				radius: 12
				color: Qt.rgba(1, 1, 1, 0.06)

				Image {
					anchors.centerIn: parent
					width: 24
					height: 24
					visible: thumbnailSource() !== ""
					source: thumbnailSource()
					fillMode: Image.PreserveAspectFit
					asynchronous: true
					cache: false
				}

				Text {
					anchors.centerIn: parent
					text: "󰭷"
					color: clipboard ? clipboard.textMuted : "#B0B0B0"
					font.pixelSize: 20
					visible: modelData.imagePath === ""
				}
			}

			ColumnLayout {
				Layout.fillWidth: true
				spacing: 2

				Text {
					Layout.fillWidth: true
					text: modelData.display
					color: clipboard ? clipboard.textPrimary : "#FFFFFF"
					font.pixelSize: 14
					font.weight: Font.Medium
					elide: Text.ElideRight
				}

				Text {
					Layout.fillWidth: true
					text: modelData.imagePath ? "Image clipboard entry" : "Clipboard text"
					color: clipboard ? clipboard.textMuted : "#B0B0B0"
					opacity: 0.9
					font.pixelSize: 12
					elide: Text.ElideRight
				}
			}

			Rectangle {
				Layout.preferredWidth: 30
				Layout.preferredHeight: 30
				radius: 15
				color: removeHover.containsMouse ? (clipboard ? clipboard.bgSecondary : "transparent") : "transparent"
				opacity: removeHover.containsMouse ? 1 : 0.75
				Behavior on color { ColorAnimation { duration: 120 } }

				Text {
					anchors.centerIn: parent
					text: "󰆴"
					color: clipboard ? clipboard.textMuted : "#B0B0B0"
					font.pixelSize: 20
				}

				MouseArea {
					id: removeHover
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: {
						if (clipboard)
							clipboard.removeEntry(entry.modelData)
					}
				}
			}
		}
	}
}
