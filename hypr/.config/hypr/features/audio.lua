-- Volume / microphone / brightness actions plus their quickshell OSD.
local util = require("./lib/util.lua")

local M = {}

local SINK = "@DEFAULT_AUDIO_SINK@"

function M.volume(action)
    local cmds = {
        raise         = "wpctl set-volume -l 1.0 " .. SINK .. " 5%+",
        lower         = "wpctl set-volume " .. SINK .. " 5%-",
        ["mute-toggle"] = "wpctl set-mute " .. SINK .. " toggle",
    }
    util.sh(cmds[action] .. " || true; qs ipc --newest call osd volume >/dev/null 2>&1 || true")
end

function M.brightness(action)
    local step = action == "raise" and "5%+" or "5%-"
    util.sh("brightnessctl set " .. step .. " -q 2>/dev/null || true; " ..
            "qs ipc --newest call osd brightness >/dev/null 2>&1 || true")
end

--- Mute every real microphone when any is live, otherwise unmute them all.
function M.mic_toggle()
    util.sh([[
ids=$(pactl list short sources 2>/dev/null | awk '!/monitor/ {print $1}')
target=0
for id in $ids; do
    [ "$(pactl get-source-mute "$id" | awk '{print $2}')" = no ] && target=1
done
for id in $ids; do pactl set-source-mute "$id" "$target"; done
]])
end

return M
