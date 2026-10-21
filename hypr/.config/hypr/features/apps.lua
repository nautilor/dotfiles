-- Small launcher-style actions (one shell pipeline each).
local util = require("./lib/util.lua")

local M = {}

--- Toggle a quickshell notch module (launcher, power, clipboard, ...).
function M.notch(module)
    util.with_quickshell(string.format(
        "quickshell ipc call notch %s || notify-send -i error 'Quickshell Error' 'Failed to launch quickshell module %s.'",
        module, module))
end

function M.clear_clipboard()
    util.sh([[
if command -v clipse >/dev/null && command -v wl-copy >/dev/null; then
    clipse -clear-all && notify-send -i clipboard 'Clipboard Cleared' 'All clipboard history has been cleared.'
else
    notify-send -i error 'Clipboard Manager' 'Required dependencies are not installed!'
fi
]])
end

--- Pick a colour, copy it, and show a swatch notification.
function M.color_picker()
    util.sh([[
color=$(hyprpicker) || exit 0
[ -n "$color" ] || exit 0
printf %s "$color" | wl-copy
img=/tmp/colorpicker.png
magick -size 100x100 xc:none -fill "$color" -draw "roundRectangle 0,0 100,100 15,15" "$img"
notify-send -i "$img" 'Color Copied' "$color"
]])
end

--- fzf menu (in a kitty window) over ~/.config/utils/bin.
function M.utils_menu()
    util.sh([[
base="$HOME/.config/utils/bin"; src="$HOME/.config/utils/source.sh"
mkdir -p "$base"; touch "$src"
kitty --class fzf_utils -e env BASE_PATH="$base" SOURCE_FILE="$src" bash -c '
    source "$SOURCE_FILE"
    selected=$(find "$BASE_PATH" -maxdepth 1 -type f -executable -printf "%f\n" | fzf --prompt="Select an option: " --border)
    [ -n "$selected" ] && "$BASE_PATH/$selected"'
]])
end

return M
