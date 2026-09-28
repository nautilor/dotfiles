import Quickshell
import QtQuick
import QtQuick.Effects
import qs.modules.colors

Item {
	id: root

Colors {
	id: colors
}

	// ─────────────────────────────────────────────
	// State
	// ─────────────────────────────────────────────

	property bool checked: false
	property bool enabled: true

	signal toggled()

	// ─────────────────────────────────────────────
	// Content
	// ─────────────────────────────────────────────

	property string activeIcon: "󰂯"
	property string inactiveIcon: "󰂲"

	property string label: "Quick Toggle"
	property string subLabel: checked ? "On" : "Off"

	// ─────────────────────────────────────────────
	// Colors
	// ─────────────────────────────────────────────

	property color backgroundColor: colors.quickToggleBackground
	property color foregroundColor: colors.quickToggleForeground

	property color activeBackgroundColor: colors.quickToggleActiveBackground
	property color activeForegroundColor: colors.quickToggleActiveForeground

	property color inactiveHoverColor: Qt.lighter(
		backgroundColor,
		1.50
	)

	property color activeHoverColor: Qt.lighter(
		activeBackgroundColor,
		1.12
	)

	// ─────────────────────────────────────────────
	// Size
	// ─────────────────────────────────────────────

	implicitWidth: 180
	implicitHeight: 64

	// ─────────────────────────────────────────────
	// Shadow
	// ─────────────────────────────────────────────

	RectangularShadow {
		anchors.fill: tile

		radius: tile.radius
		blur: 8
		spread: 0

		offset: Qt.point(0, 2)

		color: Qt.rgba(
			0,
			0,
			0,
			0.25
		)
	}

	// ─────────────────────────────────────────────
	// Tile
	// ─────────────────────────────────────────────

	Rectangle {
		id: tile

		anchors.fill: parent

		radius: 16

		color: {
			if (!root.enabled)
			return Qt.darker(
				root.backgroundColor,
				1.15
			)

			if (root.checked) {
				return tileArea.containsMouse
				? root.activeHoverColor
				: root.activeBackgroundColor
			}

			return tileArea.containsMouse
			? root.inactiveHoverColor
			: root.backgroundColor
		}

		// ─────────────────────────────────────────
		// Animations
		// ─────────────────────────────────────────

		Behavior on scale {
			NumberAnimation {
				duration: 250
				easing.type: barMouseArea.containsMouse
				? Easing.OutCubic
				: Easing.InCubic
			}
		}

		Behavior on color {
			ColorAnimation {
				duration: 250
				easing.type: Easing.OutCubic
			}
		}

		Behavior on height {
			NumberAnimation {
				duration: 250
				easing.type: barMouseArea.containsMouse
				? Easing.OutCubic
				: Easing.InCubic
			}
		}

		// ─────────────────────────────────────────
		// Icon
		// ─────────────────────────────────────────

		Rectangle {
			id: iconBackground

			width: 44
			height: 44

			radius: 50

			anchors.left: parent.left
			anchors.leftMargin: 10

			anchors.verticalCenter: parent.verticalCenter

			color: root.checked
			? Qt.rgba(1, 1, 1, 0.16)
			: Qt.rgba(1, 1, 1, 0.06)

			Behavior on color {
				ColorAnimation {
					duration: 180
					easing.type: Easing.OutCubic
				}
			}

			Text {
				id: tileIcon

				anchors.centerIn: parent

				text: root.checked
				? root.activeIcon
				: root.inactiveIcon

				font.pixelSize: 22
				font.weight: Font.Medium

				color: root.checked
				? root.activeForegroundColor
				: root.foregroundColor

				Behavior on color {
					ColorAnimation {
						duration: 180
						easing.type: Easing.OutCubic
					}
				}
			}
		}

		// ─────────────────────────────────────────
		// Labels
		// ─────────────────────────────────────────

		Column {
			id: tileLabels

			anchors.left: iconBackground.right
			anchors.leftMargin: 12

			anchors.right: parent.right
			anchors.rightMargin: 12

			anchors.verticalCenter: parent.verticalCenter

			spacing: 2

			Text {
				width: parent.width

				text: root.label

				color: root.checked
				? root.activeForegroundColor
				: root.foregroundColor

				font.pixelSize: 14
				font.weight: Font.Medium

				elide: Text.ElideRight

				Behavior on color {
					ColorAnimation {
						duration: 180
						easing.type: Easing.OutCubic
					}
				}
			}

			Text {
				width: parent.width

				text: root.subLabel

				color: root.checked
				? Qt.rgba(
					root.activeForegroundColor.r,
					root.activeForegroundColor.g,
					root.activeForegroundColor.b,
					0.70
				)
				: Qt.rgba(
					root.foregroundColor.r,
					root.foregroundColor.g,
					root.foregroundColor.b,
					0.65
				)

				font.pixelSize: 11

				elide: Text.ElideRight

				Behavior on color {
					ColorAnimation {
						duration: 180
						easing.type: Easing.OutCubic
					}
				}
			}
		}

		// ─────────────────────────────────────────
		// Hover
		// ─────────────────────────────────────────

		MouseArea {
			id: tileArea
			anchors.fill: parent
			hoverEnabled: true
			onClicked: {
				root.toggled()
			}
		}
	}
}
