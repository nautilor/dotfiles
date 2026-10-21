-- qwert-style workspace shortcuts.
-- The same five keys address workspaces 1-5 on the laptop panel and 6-9 on an
-- external display (t is mapped to 9, as before).
local M = {}

M.keys = { "q", "w", "e", "r", "t" }

local internal = { q = 1, w = 2, e = 3, r = 4, t = 5 }
local external = { q = 6, w = 7, e = 8, r = 9, t = 9 }

local function on_laptop()
    local mon = hl.get_active_monitor()
    return mon ~= nil and (mon.name:match("^eDP") ~= nil or mon.name:match("^LVDS") ~= nil)
end

local function target(key)
    return (on_laptop() and internal or external)[key]
end

--- Focus the workspace for `key`; leaving a workspace above 9 carries its windows.
function M.focus(key)
    local ws = target(key)

    if not on_laptop() then
        local current = hl.get_active_workspace()
        if current and current.id > 9 then
            for _, win in ipairs(hl.get_workspace_windows(current.id)) do
                hl.dispatch(hl.dsp.window.move({ workspace = ws, follow = false, window = win }))
            end
        end
    end

    hl.dispatch(hl.dsp.focus({ workspace = ws }))
end

--- Send the active window to the workspace for `key` without following it.
function M.move(key)
    hl.dispatch(hl.dsp.window.move({ workspace = target(key), follow = false }))
end

return M
