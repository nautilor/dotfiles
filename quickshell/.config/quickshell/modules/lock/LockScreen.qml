import QtQuick
import Quickshell.Wayland
import qs.services

// Session lock: the compositor shows only these surfaces until the user authenticates.
Item {
	WlSessionLock {
		id: lock
		locked: LockCtl.locked

		// if the compositor ends the lock (or it is denied), follow it
		onLockedChanged: LockCtl.locked = locked

		surface: Component {
			LockSurface {}
		}
	}
}
