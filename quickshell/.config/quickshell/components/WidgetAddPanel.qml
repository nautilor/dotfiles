import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

// Catalog of widgets that can be added to the Home dashboard.
Rectangle {
	id: root

	radius: Theme.radiusLarge
	color: Theme.surfaceContainerHigh

	MouseArea {
		anchors.fill: parent
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: 12
		spacing: 8

		RowLayout {
			Layout.fillWidth: true
			Txt {
				text: "Add a widget"
				font.pixelSize: 17
				font.weight: Font.Bold
				Layout.fillWidth: true
			}
			Txt {
				visible: HomeLayout.message !== ""
				text: HomeLayout.message
				color: Theme.error
				font.pixelSize: 12
			}
			Btn {
				icon: "close"
				variant: 2
				iconSize: 18
				implicitWidth: 34
				implicitHeight: 34
				onClicked: {
					HomeLayout.panel = "";
					HomeLayout.message = "";
				}
			}
		}

		Flickable {
			Layout.fillWidth: true
			Layout.fillHeight: true
			contentHeight: flow.height
			clip: true
			boundsBehavior: Flickable.StopAtBounds

			Flow {
				id: flow
				width: parent.width
				spacing: 8

				Repeater {
					model: WidgetTypes.order

					Rectangle {
						id: card
						required property string modelData
						readonly property var def: WidgetTypes.types[modelData]
						width: (flow.width - 16) / 3
						height: 66
						radius: 20
						color: Theme.surfaceContainer

						Rectangle {
							anchors.fill: parent
							radius: parent.radius
							color: Theme.surfaceFg
							opacity: area.pressed ? 0.12 : area.containsMouse ? 0.08 : 0
						}
						Rectangle {
							id: badge
							width: 40
							height: 40
							radius: 14
							color: Theme.primaryContainer
							anchors.left: parent.left
							anchors.leftMargin: 12
							anchors.verticalCenter: parent.verticalCenter
							Icon {
								anchors.centerIn: parent
								name: card.def.icon
								size: 22
								fill: 1
								color: Theme.primaryContainerFg
							}
						}
						Column {
							anchors.left: badge.right
							anchors.leftMargin: 10
							anchors.right: parent.right
							anchors.rightMargin: 8
							anchors.verticalCenter: parent.verticalCenter
							Txt {
								width: parent.width
								text: card.def.title
								font.weight: Font.Bold
							}
							Txt {
								width: parent.width
								text: card.def.desc
								font.pixelSize: 10
								color: Theme.surfaceVariantFg
							}
						}
						MouseArea {
							id: area
							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: {
								if (HomeLayout.add(card.modelData))
									HomeLayout.panel = "";
							}
						}
					}
				}
			}
		}
	}
}
