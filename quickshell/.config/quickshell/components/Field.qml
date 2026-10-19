import QtQuick
import qs.config

// Single-line text field in a rounded container.
Rectangle {
	id: root

	property alias text: input.text
	property string placeholder
	property string icon
	property alias input: input

	signal accepted
	signal edited(string value)

	implicitHeight: 44
	radius: height / 2
	color: Theme.surfaceContainerHigh
	border.width: input.activeFocus ? 2 : 0
	border.color: Theme.primary

	Icon {
		id: leading
		visible: root.icon !== ""
		name: root.icon
		size: 20
		color: Theme.surfaceVariantFg
		anchors.left: parent.left
		anchors.leftMargin: 14
		anchors.verticalCenter: parent.verticalCenter
	}

	TextInput {
		id: input
		anchors.left: leading.visible ? leading.right : parent.left
		anchors.leftMargin: leading.visible ? 10 : 16
		anchors.right: parent.right
		anchors.rightMargin: 16
		anchors.verticalCenter: parent.verticalCenter
		color: Theme.surfaceFg
		selectionColor: Theme.primaryContainer
		selectedTextColor: Theme.primaryContainerFg
		font.family: Theme.font
		font.pixelSize: 15
		clip: true
		selectByMouse: true
		onAccepted: root.accepted()
		onTextEdited: root.edited(text)

		Txt {
			visible: input.text === "" && !input.preeditText
			text: root.placeholder
			color: Theme.outline
			font.pixelSize: 15
			anchors.verticalCenter: parent.verticalCenter
		}
	}

	function forceFocus() {
		input.forceActiveFocus();
	}
}
