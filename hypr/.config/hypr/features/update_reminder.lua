-- Remind (at most weekly) that the system should be updated.
local util = require("./lib/util.lua")

local M = {}

local WEEK = 7 * 24 * 60 * 60
local state_dir  = os.getenv("XDG_STATE_HOME") or (util.home .. "/.local/state")
local state_file = state_dir .. "/update-reminder.last"
local timer

local function read_last()
    local f = io.open(state_file, "r")
    if not f then return 0 end
    local value = tonumber(f:read("*l")) or 0
    f:close()
    return value
end

local function remind()
    local now = os.time()
    if now - read_last() < WEEK then return end

    util.sh(string.format("mkdir -p %q", state_dir))
    local f = io.open(state_file, "w")
    if f then
        f:write(now, "\n")
        f:close()
    end

    util.notify("NixOS Update Reminder", "It's been a week since your last update.",
        util.home .. "/.config/hypr/assets/logo.png")
end

function M.start()
    -- give quickshell (notification daemon) time to come up
    timer = hl.timer(remind, { timeout = 10 * 1000, type = "oneshot" })
end

return M
