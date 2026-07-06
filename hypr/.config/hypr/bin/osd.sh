#!/usr/bin/env bash
set -euo pipefail

qs_ipc() {
	# If quickshell isn't running yet, don't fail the keybind.
	qs ipc --newest call "$@" >/dev/null 2>&1 || true
}

volume_info() {
	wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || printf 'Volume: 0.00\n'
}

volume_percent() {
	local raw value
	raw="$(volume_info)"
	value="$(awk '{ print $2 }' <<<"$raw")"
	awk -v value="${value:-0}" 'BEGIN { printf "%d\n", (value * 100) + 0.5 }'
}

volume_muted() {
	local raw
	raw="$(volume_info)"
	if [[ "$raw" == *"[MUTED]"* ]]; then
		printf 'true\n'
	else
		printf 'false\n'
	fi
}

brightness_percent() {
	brightnessctl -m 2>/dev/null | awk -F, 'NR == 1 { gsub(/%/, "", $4); print int($4); found = 1 } END { if (!found) print "0" }'
}

usage() {
	cat <<'EOF'
Usage:
  osd.sh volume raise|lower|mute-toggle
  osd.sh brightness raise|lower
EOF
}

main() {
	local kind="${1:-}" action="${2:-}"

	if [[ -z "$kind" || -z "$action" ]]; then
		usage
		exit 2
	fi

	case "$kind" in
		volume)
			case "$action" in
				raise)
					wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ || true
					;;
				lower)
					wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- || true
					;;
				mute-toggle)
					wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle || true
					;;
				*)
					usage
					exit 2
					;;
			esac
			qs_ipc osd volume
			;;
		brightness)
			case "$action" in
				raise)
					brightnessctl set 5%+ -q 2>/dev/null || true
					;;
				lower)
					brightnessctl set 5%- -q 2>/dev/null || true
					;;
				*)
					usage
					exit 2
					;;
			esac
			qs_ipc osd brightness
			;;
		*)
			usage
			exit 2
			;;
	esac
}

main "$@"
