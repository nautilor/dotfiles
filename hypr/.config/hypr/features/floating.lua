-- Toggle floating; freshly floated windows get a sensible size and are centered.
local util = require("./lib/util.lua")

local M = {}

function M.toggle()
    local win = hl.get_active_window()
    if not win then return end

    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))

    win = hl.get_active_window()
    if not win or not win.floating then return end

    local w, h = 1300, 800
    if util.has_tag(win, "terminal") then w, h = 800, 600 end

    hl.dispatch(hl.dsp.window.resize({ x = w, y = h }))
    hl.dispatch(hl.dsp.window.center())
end

return M
