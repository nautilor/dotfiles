-- Cycle the asusctl keyboard backlight: off -> low -> med -> high -> off.
local util = require("./lib/util.lua")

local M = {}

local next_level = { off = "low", low = "med", med = "high", high = "off" }
local current = "off"

function M.cycle()
    current = next_level[current]
    util.sh(string.format(
        "command -v asusctl >/dev/null || { notify-send -i error asusctl 'asusctl is not installed'; exit 1; }; " ..
        "asusctl leds set %s", current))
end

return M
