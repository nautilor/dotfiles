#!/usr/bin/env bash

set -euo pipefail

mode="${1:-list}"
entry_id="${2:-}"

python3 - "$mode" "$entry_id" <<'PY'
import json
import mimetypes
import os
import subprocess
import sys


def config_path():
    xdg = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    return os.path.join(xdg, "clipse", "config.json")


def expand_path(path: str, base_dir: str) -> str:
    path = os.path.expandvars(os.path.expanduser(path))
    if os.path.isabs(path):
        return path
    return os.path.join(base_dir, path)


def paths():
    cfg_path = config_path()
    cfg_dir = os.path.dirname(cfg_path)
    config = {}

    if os.path.exists(cfg_path):
        with open(cfg_path, "r", encoding="utf-8") as handle:
            config = json.load(handle)

    history = expand_path(config.get("historyFile", "clipboard_history.json"), cfg_dir)
    temp_dir = expand_path(config.get("tempDir", "tmp_files"), cfg_dir)
    return history, temp_dir


def load_history(history_path: str):
    if not os.path.exists(history_path):
        return {"clipboardHistory": []}

    with open(history_path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def save_history(history_path: str, data):
    os.makedirs(os.path.dirname(history_path), exist_ok=True)
    with open(history_path, "w", encoding="utf-8") as handle:
        json.dump(data, handle, ensure_ascii=False)


def sanitize_display(item):
    value = str(item.get("value", ""))
    value = value.replace("\t", " ").replace("\n", " ").replace("\r", " ").strip()
    if len(value) > 160:
        value = value[:157] + "..."

    file_path = str(item.get("filePath", "null"))
    if file_path != "null":
        if value:
            return f"[image] {value}"
        return "[image]"

    return value


def list_items(history_path: str):
    data = load_history(history_path)
    for item in data.get("clipboardHistory", []):
        entry_id = str(item.get("recorded", ""))
        display = sanitize_display(item)
        file_path = str(item.get("filePath", ""))
        if file_path == "null":
            file_path = ""
        print(f"{entry_id}\t{display}\t{file_path}")


def find_item(data, entry_id: str):
    for item in data.get("clipboardHistory", []):
        if str(item.get("recorded", "")) == entry_id:
            return item
    raise SystemExit(1)


def copy_item(history_path: str, entry_id: str):
    item = find_item(load_history(history_path), entry_id)
    file_path = str(item.get("filePath", "null"))

    if file_path != "null":
        mime = mimetypes.guess_type(file_path)[0] or "application/octet-stream"
        with open(file_path, "rb") as handle:
            subprocess.run(["wl-copy", "--type", mime], stdin=handle, check=True)
        return

    value = str(item.get("value", ""))
    subprocess.run(["wl-copy"], input=value.encode(), check=True)


def delete_item(history_path: str, entry_id: str):
    data = load_history(history_path)
    updated = []

    for item in data.get("clipboardHistory", []):
        if str(item.get("recorded", "")) == entry_id:
            file_path = str(item.get("filePath", "null"))
            if file_path != "null" and os.path.exists(file_path):
                os.remove(file_path)
            continue
        updated.append(item)

    data["clipboardHistory"] = updated
    save_history(history_path, data)


def clear_items(history_path: str, temp_dir: str):
    data = load_history(history_path)

    for item in data.get("clipboardHistory", []):
        file_path = str(item.get("filePath", "null"))
        if file_path != "null" and os.path.exists(file_path):
            os.remove(file_path)

    if os.path.isdir(temp_dir):
        for name in os.listdir(temp_dir):
            path = os.path.join(temp_dir, name)
            if os.path.isfile(path):
                os.remove(path)

    data["clipboardHistory"] = []
    save_history(history_path, data)


mode = sys.argv[1]
entry_id = sys.argv[2]
history_path, temp_dir = paths()

if mode == "list":
    list_items(history_path)
elif mode == "copy":
    copy_item(history_path, entry_id)
elif mode == "delete":
    delete_item(history_path, entry_id)
elif mode == "clear":
    clear_items(history_path, temp_dir)
else:
    raise SystemExit(2)
PY
