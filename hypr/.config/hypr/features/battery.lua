-- Warn when the battery is low (checked periodically, re-alerts at a slower pace).
local util = require("./lib/util.lua")

local M = {}

local BATTERY_PATH   = "/sys/class/power_supply/BAT1/capacity"
local LOW_THRESHOLD  = 15
local CHECK_INTERVAL = 120 * 1000   -- ms
local ALERT_INTERVAL = 1200         -- s

local last_alert = 0
local timer

local function level()
    local f = io.open(BATTERY_PATH, "r")
    if not f then return nil end
    local value = tonumber(f:read("*l"))
    f:close()
    return value
end

local function check()
    local lvl = level()
    if not lvl or lvl > LOW_THRESHOLD then return end

    local now = os.time()
    if now - last_alert < ALERT_INTERVAL then return end
    last_alert = now

    util.sh(string.format(
        "notify-send --urgency=CRITICAL -i battery-caution-symbolic 'Battery Low' 'Level: %d%%'", lvl))
end

function M.start()
    check()
    timer = hl.timer(check, { timeout = CHECK_INTERVAL, type = "repeat" })
end

return M
