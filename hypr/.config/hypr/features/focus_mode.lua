-- Focus mode: strip visual clutter and sync quickshell's DND / round corners.
local util = require("./lib/util.lua")

local M = {}

local CONTROL_CENTER = util.home .. "/.config/quickshell/bin/control-center.sh"

local overrides = {
    ["general.gaps_in"]              = 0,
    ["general.gaps_out"]             = 0,
    ["general.border_size"]         = 0,
    ["decoration.rounding"]         = 0,
    ["decoration.shadow.enabled"]   = false,
    ["decoration.dim_inactive"]     = true,
    ["animations.enabled"]          = false,
}

local enabled = false
local saved = {}

local function sync_dnd(desired)
    util.sh(string.format(
        '[ -x %q ] && [ "$(bash %q dnd-status)" != %s ] && bash %q dnd-toggle >/dev/null 2>&1 || true',
        CONTROL_CENTER, CONTROL_CENTER, desired, CONTROL_CENTER))
end

local function toggle_quickshell_module()
    util.with_quickshell("qs ipc --any-display --newest call root toggle >/dev/null 2>&1 || true")
end

function M.toggle()
    if enabled then
        for key, value in pairs(saved) do util.set_config(key, value) end
        saved = {}
        enabled = false
        sync_dnd("off")
    else
        for key, value in pairs(overrides) do
            saved[key] = hl.get_config(key)
            util.set_config(key, value)
        end
        enabled = true
        sync_dnd("on")
    end
    toggle_quickshell_module()
end

return M
