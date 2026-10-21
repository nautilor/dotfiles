-- Focus helpers.
local M = {}

--- SUPER+LEFT/RIGHT: scroll columns when maximized, otherwise move focus.
function M.smart(dir)
    local win = hl.get_active_window()
    if win == nil or win.fullscreen == 1 then
        hl.dispatch(hl.dsp.layout("move " .. (dir == "left" and "-col" or "+col")))
    else
        hl.dispatch(hl.dsp.focus({ direction = dir }))
    end
end

--- Focus the first window whose class matches any "||"-separated pattern.
function M.by_class(patterns)
    for pattern in patterns:gmatch("[^|]+") do
        for _, win in ipairs(hl.get_windows({ mapped = true })) do
            if win.class:find(pattern) then
                hl.dispatch(hl.dsp.focus({ window = win }))
                return
            end
        end
    end
end

return M
