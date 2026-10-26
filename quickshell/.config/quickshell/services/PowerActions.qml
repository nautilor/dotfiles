pragma Singleton

import QtQuick
import Quickshell
import qs.config

Singleton {
	function poweroff() {
		Quickshell.execDetached(["systemctl", "poweroff"]);
	}
	function reboot() {
		Quickshell.execDetached(["systemctl", "reboot"]);
	}
	function suspend() {
		Quickshell.execDetached(["systemctl", "suspend"]);
	}
	function logout() {
		// Lua config (Hyprland 0.55+) wants hl.dsp.exit(); the classic config wants the plain dispatcher
		Quickshell.execDetached(["sh", "-c", "case \"$(hyprctl dispatch 'hl.dsp.exit()' 2>&1)\" in ok*) ;; *) hyprctl dispatch exit ;; esac"]);
	}
	function lock() {
		if (Settings.builtinLock)
			LockCtl.lock();
		else
			Quickshell.execDetached(["sh", "-c", "pidof hyprlock || hyprlock"]);
	}
}
