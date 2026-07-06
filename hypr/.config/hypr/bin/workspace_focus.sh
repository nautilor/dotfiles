#!/usr/bin/env bash
#
# Switch workspace via qwert-key shortcut, respecting which monitor is
# active (laptop panel vs external), and carry windows to a new monitor
# when jumping from a workspace above 9.
#
set -euo pipefail

if [[ -z "${1:-}" ]]; then
	echo "Usage: $0 <q|w|e|r|t>" >&2
	exit 1
fi

current=$(hyprctl activeworkspace -j)
monitors=$(hyprctl monitors -j)

default_monitor=$(jq -r '.[] | select(.name | test("^(eDP|LVDS)")) | .name' <<< "$monitors")
current_monitor=$(jq -r '.monitor' <<< "$current")
current_workspace=$(jq -r '.id' <<< "$current")

if [[ "$default_monitor" == "$current_monitor" ]]; then
	next_workspace=$(sed 'y/qwert/12345/' <<< "$1")
	hyprctl dispatch workspace "$next_workspace"
else
	next_workspace=$(sed 'y/qwert/67899/' <<< "$1")

	if (( current_workspace > 9 )); then
		clients=$(jq -r ".[] | select(.workspace.id == ${current_workspace}) | .address" <<< "$(hyprctl clients -j)")
		while read -r client; do
			[[ -n "$client" ]] || continue
			hyprctl dispatch movetoworkspacesilent "${next_workspace},address:${client}"
		done <<< "$clients"
	fi

	hyprctl dispatch workspace "$next_workspace"
fi
