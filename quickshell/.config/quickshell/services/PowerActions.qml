pragma Singleton

import QtQuick
import Quickshell

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
		Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
	}
	function lock() {
		Quickshell.execDetached(["sh", "-c", "pidof hyprlock || hyprlock"]);
	}
}
