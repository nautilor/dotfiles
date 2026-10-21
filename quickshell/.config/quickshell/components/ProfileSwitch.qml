import QtQuick
import Quickshell.Services.UPower
import qs.config

// power-profiles-daemon as a single segmented control with a sliding highlight.
Item {
	id: root

	readonly property var all: [
		{ p: PowerProfile.PowerSaver, icon: "eco", label: "Saver" },
		{ p: PowerProfile.Balanced, icon: "balance", label: "Balanced" },
		{ p: PowerProfile.Performance, icon: "bolt", label: "Performance" }
	]
	readonly property var options: all.filter(o => o.p !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)
	readonly property int index: Math.max(0, options.findIndex(o => o.p === PowerProfiles.profile))
	// only the selected segment shows its label and is wider, so "Performance" never touches the edge
	readonly property real activeWeight: 1.9
	readonly property real unit: width / (options.length - 1 + activeWeight)
	function segX(i) {
		return i * unit + (i > index ? (activeWeight - 1) * unit : 0);
	}
	function segW(i) {
		return i === index ? activeWeight * unit : unit;
	}

	implicitHeight: 44

	Rectangle {
		anchors.fill: parent
		radius: height / 2
		color: Theme.surfaceContainerHigh
	}

	Rectangle {
		x: root.segX(root.index) + 3
		y: 3
		width: root.segW(root.index) - 6
		height: parent.height - 6
		radius: height / 2
		color: Theme.primary
		Behavior on x {
			SpringAnimation {
				spring: Theme.springBouncy
				damping: Theme.dampBouncy
				epsilon: 0.25
			}
		}
		Behavior on width {
			SpringAnimation {
				spring: Theme.springBouncy
				damping: Theme.dampBouncy
				epsilon: 0.25
			}
		}
	}

	Repeater {
		model: root.options

		Item {
			id: seg
			required property var modelData
			required property int index
			readonly property bool current: root.index === index
			x: root.segX(index)
			width: root.segW(index)
			Behavior on x {
				SpringAnimation {
					spring: Theme.springBouncy
					damping: Theme.dampBouncy
					epsilon: 0.25
				}
			}
			Behavior on width {
				SpringAnimation {
					spring: Theme.springBouncy
					damping: Theme.dampBouncy
					epsilon: 0.25
				}
			}
			height: root.height

			Row {
				anchors.centerIn: parent
				spacing: 6
				Icon {
					name: seg.modelData.icon
					size: 18
					color: seg.current ? Theme.primaryFg : Theme.surfaceVariantFg
					anchors.verticalCenter: parent.verticalCenter
				}
				Txt {
					visible: seg.current
					text: seg.modelData.label
					elide: Text.ElideNone
					font.pixelSize: 13
					font.weight: Font.Medium
					color: seg.current ? Theme.primaryFg : Theme.surfaceVariantFg
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: PowerProfiles.profile = seg.modelData.p
			}
		}
	}
}
