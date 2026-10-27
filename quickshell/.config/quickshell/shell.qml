import Quickshell
import Quickshell.Io
import qs.modules.notch
import qs.modules.corner
import qs.modules.lock
import qs.services
import qs.config

ShellRoot {
	// singletons are lazy: touch the ones that must react to system events from startup
	readonly property var keepAlive: [Audio.armed, Brightness.armed, Mic.armed, Caffeine.active, Notifs.count, Clip.entries]

	LockScreen {}

	Variants {
		model: Settings.screenCorners ? Quickshell.screens : []

		ScreenCorners {}
	}

	Variants {
		model: Settings.allScreens ? Quickshell.screens : [Quickshell.screens.find(s => s.name === Settings.screenName) ?? Quickshell.screens[0]]

		Notch {}
	}

	// Bind these in hyprland.conf, e.g.:  bind = SUPER, Space, exec, qs ipc -p ~/Sources/PERSONAL/quickshell-notch call notch launcher
	IpcHandler {
		target: "notch"

		function toggle(): void {
			NotchCtl.toggle();
		}
		function close(): void {
			NotchCtl.close();
		}
		function open(tab: string): void {
			NotchCtl.show(tab);
		}
		function launcher(): void {
			NotchCtl.toggle("apps");
		}
		function clipboard(): void {
			NotchCtl.toggle("clipboard");
		}
		function calendar(): void {
			NotchCtl.toggle("calendar");
		}
		function notifications(): void {
			NotchCtl.toggle("notifications");
		}
		function power(): void {
			NotchCtl.toggle("power");
		}
		function caffeine(): void {
			Caffeine.toggle();
		}
		function mic(): void {
			Mic.toggle();
		}
		function volumeUp(): void {
			Audio.step(0.05);
		}
		function volumeDown(): void {
			Audio.step(-0.05);
		}
		function volumeMute(): void {
			Audio.toggleMute();
		}
		function brightnessUp(): void {
			Brightness.step(5);
		}
		function brightnessDown(): void {
			Brightness.step(-5);
		}
		function homeEdit(): void {
			NotchCtl.show("home");
			if (!HomeStyles.isGrid)
				return;
			HomeLayout.editing = !HomeLayout.editing;
			HomeLayout.panel = "";
		}
		// lock the session (for hypridle's lock_cmd and keybinds)
		function lock(): void {
			LockCtl.lock();
		}
		function dnd(): void {
			Settings.dnd = !Settings.dnd;
		}
	}
}
