import qs.modules.launcher
import qs.modules.corner
import qs.modules.notifications
import qs.modules.clipboard
import qs.modules.windowswitcher
import Quickshell

ShellRoot {
	Launcher {}
	Clipboard {}
	WindowSwitcher {}
	Variants {
		model: Quickshell.screens

		RoundCorner {
			required property var modelData
			screen: modelData
		}
	}
	Notifications {}
}
