import Quickshell
import QtQuick
import Quickshell.Hyprland
import qs.modules.bar.components
import qs.modules.colors

Item {
	id: root
	
	Colors {
		id: colors
	}

	readonly property color workspaceBackground: colors.accentColor
	readonly property color workspaceForeground: colors.background

	function focusedWorkspace() {
		const workspaces = Hyprland.workspaces.values || [];
		const focusedWorkspace = workspaces.find(workspace => workspace.focused);
		return focusedWorkspace?.name
	}

	function iconForWorkspace() {
		const workspace = focusedWorkspace();
		const workspaceIcons = {
			"1": "󰲠",
			"2": "󰲢",
			"3": "󰲤",
			"4": "󰲦",
			"5": "󰲨",
			"6": "󰲪",
			"7": "󰲬",
			"8": "󰲮",
			"9": "󰲰",
		};
		return workspaceIcons[workspace] || "󰧞";
	}

	Indicator {
		backgroundColor: root.workspaceBackground
		foregroundColor: root.workspaceForeground
		icon: iconForWorkspace()
		fontSize: 24
		visible: true
	}
}
