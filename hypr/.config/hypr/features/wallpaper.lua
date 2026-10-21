-- Wallpaper via awww (starts the daemon if needed).
local util = require("./lib/util.lua")

local M = {}

local wallpaper = util.home .. "/.config/hypr/assets/wallpaper.png"

function M.init()
    util.sh(string.format(
        "command -v awww >/dev/null || { notify-send -i error awww 'awww is not installed'; exit 1; }; " ..
        "pgrep -f awww-daemon >/dev/null || { awww-daemon & disown; sleep 0.3; }; " ..
        "awww img %q --transition-type=fade --transition-duration=0.5", wallpaper))
end

return M
