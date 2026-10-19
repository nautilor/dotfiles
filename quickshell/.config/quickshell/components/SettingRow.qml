import QtQuick
import QtQuick.Layouts
import qs.config

// Label (+ optional subtitle) on the left, controls on the right.
RowLayout {
	id: root

	property string title
	property string subtitle
	default property alias content: slot.data

	Layout.fillWidth: true
	spacing: 12

	ColumnLayout {
		Layout.fillWidth: true
		spacing: 0
		Txt {
			Layout.fillWidth: true
			text: root.title
			font.weight: Font.Medium
		}
		Txt {
			Layout.fillWidth: true
			visible: root.subtitle !== ""
			text: root.subtitle
			font.pixelSize: 12
			color: Theme.surfaceVariantFg
		}
	}
	RowLayout {
		id: slot
		spacing: 8
	}
}
