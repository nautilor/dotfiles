pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config

Singleton {
	id: root

	readonly property alias list: server.trackedNotifications
	readonly property int count: server.trackedNotifications.values.length
	property var peek: null
	// true while the pointer is over the peek, so it does not vanish under the cursor
	property bool hold: false

	function dismissAll() {
		const all = server.trackedNotifications.values.slice();
		for (const n of all)
			n.dismiss();
		peek = null;
	}

	function hidePeek() {
		peek = null;
	}

	NotificationServer {
		id: server
		keepOnReload: true
		bodySupported: true
		bodyMarkupSupported: true
		bodyHyperlinksSupported: false
		actionsSupported: true
		imageSupported: true
		persistenceSupported: true

		onNotification: n => {
			n.tracked = true;
			if (Settings.dnd)
				return;
			root.peek = n;
			peekTimer.interval = n.urgency === NotificationUrgency.Critical ? 9000 : Settings.notifTimeout;
			peekTimer.restart();
		}
	}

	Timer {
		id: peekTimer
		onTriggered: {
			if (root.hold)
				restart();
			else
				root.peek = null;
		}
	}
}
