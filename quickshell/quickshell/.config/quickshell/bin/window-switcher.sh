#!/usr/bin/env bash

set -euo pipefail

sanitize() {
    local value="${1:-}"
    value="${value//$'\t'/ }"
    value="${value//$'\n'/ }"
    value="${value//$'\r'/ }"
    printf '%s' "$value"
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        printf 'Missing command: %s\n' "$1" >&2
        exit 1
    }
}

list_windows() {
    require_cmd hyprctl
    require_cmd jq

    local clients_json active_address
    clients_json="$(hyprctl -j clients)"
    active_address="$(hyprctl -j activewindow 2>/dev/null | jq -r '.address // empty')"

    while IFS=$'\t' read -r address workspace_id workspace_name class_name title monitor_name; do
        [[ -n "$address" ]] || continue

        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$(sanitize "$address")" \
            "$(sanitize "$workspace_id")" \
            "$(sanitize "$workspace_name")" \
            "$(sanitize "$class_name")" \
            "$(sanitize "$title")" \
            "$(sanitize "$monitor_name")" \
            "$([[ "$address" == "$active_address" ]] && printf 'true' || printf 'false')"
    done < <(
        jq -r '
            map(select(.mapped == true and (.workspace.id != null) and (.workspace.id > -100)))
            | sort_by(.workspace.id, (.title // ""), (.class // ""))
            | .[]
            | [
                .address,
                (.workspace.id | tostring),
                (.workspace.name // ""),
                (.class // ""),
                (.title // ""),
                (.monitor | tostring)
            ]
            | @tsv
        ' <<<"$clients_json"
    )
}

focus_window() {
    require_cmd hyprctl
    require_cmd jq

    local address="${1:-}"
    [[ -n "$address" ]] || {
        printf 'Missing window address\n' >&2
        exit 1
    }

    local clients_json workspace_name
    clients_json="$(hyprctl -j clients)"
    workspace_name="$(jq -r --arg address "$address" '.[] | select(.address == $address) | .workspace.name // empty' <<<"$clients_json" | head -n1)"

    [[ -n "$workspace_name" ]] || {
        printf 'Window not found: %s\n' "$address" >&2
        exit 1
    }

    if [[ "$workspace_name" == special:* ]]; then
        hyprctl dispatch togglespecialworkspace "${workspace_name#special:}" >/dev/null
    else
        hyprctl dispatch workspace "$workspace_name" >/dev/null
    fi

    hyprctl dispatch focuswindow "address:$address" >/dev/null
}

case "${1:-list}" in
    list)
        list_windows
        ;;
    focus)
        focus_window "${2:-}"
        ;;
    *)
        printf 'Unknown command: %s\n' "${1:-}" >&2
        exit 1
        ;;
esac
