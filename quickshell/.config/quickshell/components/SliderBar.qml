import QtQuick
import qs.services

// The volume / brightness slider widget, for layouts that are not on the Home grid.
Loader {
	property string kind: "volume"
	source: WidgetTypes.types.slider.source
	onLoaded: item.cfg = ({ kind: kind })
	onKindChanged: if (item)
		item.cfg = ({ kind: kind })
}
