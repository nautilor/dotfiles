import QtQuick
import qs.config
import qs.services
import qs.components

// Loads a user-written QML file from ~/.config/quickshell-notch/widgets/.
// The file's root item is sized to the widget and gets `cfg` (this widget's settings) if it declares `property var cfg`.
Rectangle {
	id: root

	property var cfg: ({})
	property bool editing: false

	readonly property var c: WidgetTypes.resolve("qml", cfg)
	readonly property string path: c.file === "" ? "" : Settings.configDir + "/widgets/" + c.file

	radius: Theme.radiusMedium
	color: loader.status === Loader.Ready ? "transparent" : Theme.surfaceContainer
	clip: true

	Loader {
		id: loader
		anchors.fill: parent
		source: root.path === "" ? "" : "file://" + root.path
		onLoaded: {
			try {
				item.cfg = root.cfg;
			} catch (e) {}
		}
	}

	Txt {
		visible: loader.status !== Loader.Ready
		anchors.fill: parent
		anchors.margins: 12
		wrapMode: Text.Wrap
		color: Theme.surfaceVariantFg
		font.pixelSize: 12
		text: root.path === "" ? "Set a file name in this widget's settings." : loader.status === Loader.Error ? "Could not load " + root.path : "Loading…"
	}
}
