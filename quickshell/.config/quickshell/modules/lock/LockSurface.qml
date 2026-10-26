import QtQuick
import Quickshell.Wayland
import qs.config
import qs.services
import qs.components

// One screen of the lock screen.
WlSessionLockSurface {
	color: Theme.notch

	AuthScreen {
		anchors.fill: parent
		wallpaper: Settings.lockWallpaper
		avatar: Settings.lockAvatar
		name: LockCtl.fullName
		buffer: LockCtl.buffer
		busy: LockCtl.busy
		error: LockCtl.error
		failures: LockCtl.failures
		onEdited: text => {
			LockCtl.buffer = text;
			LockCtl.error = "";
		}
		onSubmitted: LockCtl.submit()
	}
}
