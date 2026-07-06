#!/usr/bin/env bash
set -euo pipefail

qs_ipc() {
	qs ipc --any-display --newest call "$@" >/dev/null 2>&1 || true
}

sources() {
	pactl list short sources 2>/dev/null | awk '!/monitor/ {print $1}'
}

is_any_unmuted() {
	local id
	while read -r id; do
		[[ -n "${id:-}" ]] || continue
		if [[ "$(pactl get-source-mute "$id" | awk '{print $2}')" == "no" ]]; then
			return 0
		fi
	done < <(sources)
	return 1
}

state() {
	if is_any_unmuted; then
		printf 'unmuted\n'
	else
		printf 'muted\n'
	fi
}

toggle() {
	local target
	if is_any_unmuted; then
		target=1
	else
		target=0
	fi

	local id
	while read -r id; do
		[[ -n "${id:-}" ]] || continue
		pactl set-source-mute "$id" "$target"
	done < <(sources)

	qs_ipc osd mic
}

case "${1:-toggle}" in
	state)  state ;;
	toggle) toggle ;;
	*)
		echo "Usage: $0 {toggle|state}" >&2
		exit 2
		;;
esac
