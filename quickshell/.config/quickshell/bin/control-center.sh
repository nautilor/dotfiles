#!/usr/bin/env bash

set -euo pipefail

state_file="${XDG_RUNTIME_DIR:-/tmp}/quickshell-dnd.state"

sanitize() {
	local value="${1:-}"
	value="${value//$'\t'/ }"
	value="${value//$'\n'/ }"
	value="${value//$'\r'/ }"
	printf '%s' "$value"
}

bool_text() {
	if [[ "${1:-}" == "1" || "${1:-}" == "true" || "${1:-}" == "yes" || "${1:-}" == "on" ]]; then
		printf 'true'
	else
		printf 'false'
	fi
}

clamp_percent() {
	local value="${1:-0}"
	value="${value%%.*}"
	if [[ -z "$value" || ! "$value" =~ ^-?[0-9]+$ ]]; then
		value=0
	fi
	if (( value < 0 )); then
		value=0
	elif (( value > 100 )); then
		value=100
	fi
	printf '%s' "$value"
}

dnd_status() {
	if [[ -f "$state_file" ]]; then
		local value
		value="$(<"$state_file")"
		if [[ "$value" == "on" ]]; then
			printf 'on\n'
			return
		fi
	fi
	printf 'off\n'
}

set_dnd_status() {
	local next="${1:-off}"
	mkdir -p "$(dirname "$state_file")"
	printf '%s\n' "$next" > "$state_file"
}

wifi_enabled() {
	[[ "$(nmcli -t -f WIFI general status 2>/dev/null | head -n1)" == "enabled" ]]
}

wifi_saved_connections() {
	nmcli -t -f NAME,TYPE connection show 2>/dev/null | awk -F: '$2 == "802-11-wireless" { print $1 }' | sort -u
}

wifi_label() {
	if ! wifi_enabled; then
		printf 'Wi-Fi off\n'
		return
	fi

	local ssid
	ssid="$(nmcli -t -f active,ssid dev wifi 2>/dev/null | awk -F: '$1 == "yes" { print substr($0, 5); exit }')"
	if [[ -n "$ssid" ]]; then
		printf '%s\n' "$(sanitize "$ssid")"
	else
		printf 'Not connected\n'
	fi
}

wifi_list() {
	local saved_networks
	saved_networks="$(wifi_saved_connections || true)"

	if ! wifi_enabled; then
		exit 0
	fi

	nmcli -t --escape no -f active,ssid,security,signal dev wifi list 2>/dev/null \
		| awk -F: '
			NF >= 4 {
				active = $1
				signal = $NF
				security = $(NF - 1)
				ssid = $2
				for (i = 3; i <= NF - 2; ++i) ssid = ssid ":" $i
				if (ssid != "" && !(ssid in seen)) {
					seen[ssid] = 1
					printf "%s\t%s\t%s\t%s\n", active, ssid, security, signal
				}
			}
		' \
		| while IFS=$'\t' read -r active ssid security signal; do
			local saved=false
			if grep -Fxq "$ssid" <<<"$saved_networks"; then
				saved=true
			fi

			printf '%s\t%s\t%s\t%s\t%s\n' \
				"$(bool_text "$([[ "$active" == "yes" ]] && printf true || printf false)")" \
				"$(bool_text "$saved")" \
				"$(sanitize "$security")" \
				"$(sanitize "$signal")" \
				"$(sanitize "$ssid")"
		done
}

bluetooth_enabled_value() {
	local powered
	powered="$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ { print tolower($2); exit }')"
	if [[ "$powered" == "yes" || "$powered" == "true" || "$powered" == "on" ]]; then
		printf 'true\n'
	else
		printf 'false\n'
	fi
}

bluetooth_enabled() {
	[[ "$(bluetooth_enabled_value)" == "true" ]]
}

bluetooth_connected_count() {
	bluetoothctl devices Connected 2>/dev/null | wc -l | tr -d ' '
}

bluetooth_label() {
	if ! bluetooth_enabled; then
		printf 'Bluetooth off\n'
		return
	fi

	local connected
	connected="$(bluetooth_connected_count)"
	if [[ "$connected" != "0" ]]; then
		printf '%s connected\n' "$connected"
	else
		printf 'Ready to pair\n'
	fi
}

bluetooth_list() {
	if ! bluetooth_enabled; then
		exit 0
	fi

	bluetoothctl devices Paired 2>/dev/null | while read -r _ address rest; do
		[[ -n "${address:-}" ]] || continue

		local info name connected trusted paired
		info="$(bluetoothctl info "$address" 2>/dev/null || true)"
		name="$(sed -n 's/^[[:space:]]*Name: //p' <<<"$info" | head -n1)"
		connected="$(sed -n 's/^[[:space:]]*Connected: //p' <<<"$info" | head -n1)"
		trusted="$(sed -n 's/^[[:space:]]*Trusted: //p' <<<"$info" | head -n1)"
		paired="$(sed -n 's/^[[:space:]]*Paired: //p' <<<"$info" | head -n1)"

		if [[ -z "$name" ]]; then
			name="${rest:-$address}"
		fi

		printf '%s\t%s\t%s\t%s\t%s\n' \
			"$(bool_text "$connected")" \
			"$(bool_text "$paired")" \
			"$(bool_text "$trusted")" \
			"$(sanitize "$address")" \
			"$(sanitize "$name")"
	done
}

brightness_percent() {
	brightnessctl -m 2>/dev/null | awk -F, 'NR == 1 { gsub(/%/, "", $4); print int($4); found = 1 } END { if (!found) print "0" }'
}

volume_raw() {
	wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || printf 'Volume: 0.00\n'
}

volume_percent() {
	local raw value
	raw="$(volume_raw)"
	value="$(awk '{ print $2 }' <<<"$raw")"
	awk -v value="${value:-0}" 'BEGIN { printf "%d\n", (value * 100) + 0.5 }'
}

volume_muted() {
	local raw
	raw="$(volume_raw)"
	if [[ "$raw" == *"[MUTED]"* ]]; then
		printf 'true\n'
	else
		printf 'false\n'
	fi
}

default_player() {
	playerctl -l 2>/dev/null | head -n1 || true
}

media_available() {
	[[ -n "$(default_player)" ]]
}

media_status() {
	local player
	player="$(default_player)"
	if [[ -z "$player" ]]; then
		printf 'Stopped\n'
	else
		playerctl status -p "$player" 2>/dev/null || printf 'Stopped\n'
	fi
}

media_title() {
	local player title
	player="$(default_player)"
	if [[ -z "$player" ]]; then
		printf 'Nothing playing\n'
		return
	fi

	title="$(playerctl metadata -p "$player" --format '{{xesam:title}}' 2>/dev/null || true)"
	if [[ -n "$title" ]]; then
		printf '%s\n' "$(sanitize "$title")"
	else
		printf '%s\n' "$(sanitize "$player")"
	fi
}

media_artist() {
	local player artist
	player="$(default_player)"
	if [[ -z "$player" ]]; then
		printf 'Start media to show controls\n'
		return
	fi

	artist="$(playerctl metadata -p "$player" --format '{{xesam:artist}}' 2>/dev/null || true)"
	if [[ -n "$artist" ]]; then
		printf '%s\n' "$(sanitize "$artist")"
	else
		printf 'Media controls ready\n'
	fi
}

print_status() {
	local wifi_state bluetooth_state brightness volume muted dnd media_state media_flag
	wifi_state=false
	bluetooth_state="$(bluetooth_enabled_value)"
	brightness="$(brightness_percent)"
	volume="$(volume_percent)"
	muted="$(volume_muted)"
	dnd=off
	media_state="$(media_status)"
	media_flag=false

	if wifi_enabled; then
		wifi_state=true
	fi
	if [[ "$(dnd_status)" == "on" ]]; then
		dnd=on
	fi
	if media_available; then
		media_flag=true
	fi

	printf 'wifiEnabled\t%s\n' "$wifi_state"
	printf 'wifiLabel\t%s\n' "$(wifi_label)"
	printf 'bluetoothEnabled\t%s\n' "$bluetooth_state"
	printf 'bluetoothLabel\t%s\n' "$(bluetooth_label)"
	printf 'brightnessPercent\t%s\n' "$brightness"
	printf 'volumePercent\t%s\n' "$volume"
	printf 'volumeMuted\t%s\n' "$muted"
	printf 'dndEnabled\t%s\n' "$([[ "$dnd" == "on" ]] && printf true || printf false)"
	printf 'mediaAvailable\t%s\n' "$media_flag"
	printf 'mediaStatus\t%s\n' "$(sanitize "$media_state")"
	printf 'mediaTitle\t%s\n' "$(media_title)"
	printf 'mediaArtist\t%s\n' "$(media_artist)"
}

case "${1:-status}" in
	status)
		print_status
		;;
	dnd-status)
		dnd_status
		;;
	wifi-list)
		wifi_list
		;;
	bluetooth-list)
		bluetooth_list
		;;
	wifi-toggle)
		if wifi_enabled; then
			nmcli radio wifi off
		else
			nmcli radio wifi on
		fi
		;;
	wifi-rescan)
		nmcli device wifi rescan
		;;
	wifi-connect)
		nmcli device wifi connect "${2:-}"
		;;
	bluetooth-toggle)
		if bluetooth_enabled; then
			bluetoothctl power off >/dev/null
		else
			bluetoothctl power on >/dev/null
		fi
		;;
	bluetooth-device-toggle)
		if bluetoothctl info "${2:-}" 2>/dev/null | grep -q 'Connected: yes'; then
			bluetoothctl disconnect "${2:-}" >/dev/null
		else
			bluetoothctl connect "${2:-}" >/dev/null
		fi
		;;
	dnd-toggle)
		if [[ "$(dnd_status)" == "on" ]]; then
			set_dnd_status off
		else
			set_dnd_status on
		fi
		;;
	volume-toggle-mute)
		wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
		;;
	volume-set)
		wpctl set-volume @DEFAULT_AUDIO_SINK@ "$(clamp_percent "${2:-0}")%"
		;;
	brightness-set)
		brightnessctl set "$(clamp_percent "${2:-0}")%" -q
		;;
	media-play-pause)
		playerctl play-pause >/dev/null 2>&1 || true
		;;
	media-next)
		playerctl next >/dev/null 2>&1 || true
		;;
	media-previous)
		playerctl previous >/dev/null 2>&1 || true
		;;
	*)
		printf 'Unknown command: %s\n' "${1:-}" >&2
		exit 1
		;;
esac
