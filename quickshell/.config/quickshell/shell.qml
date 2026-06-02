//@ pragma UseQApplication
import qs.modules.bar
import qs.modules.launcher
import qs.modules.corner
import qs.modules.notifications
import qs.modules.clipboard
import qs.modules.windowswitcher
import qs.modules.osd
import qs.modules.powermenu
import Quickshell

ShellRoot {
	Bar {}
	Launcher {}
	Clipboard {}
	WindowSwitcher {}
	PowerMenu {}
	Osd {}
	Variants {
		model: Quickshell.screens

		RoundCorner {
			required property var modelData
			screen: modelData
		}
	}
	Notifications {}
}
