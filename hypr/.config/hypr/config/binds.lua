-- Keybindings, grouped by purpose.
local workspaces       = require("./features/workspaces.lua")
local focus            = require("./features/focus.lua")
local floating         = require("./features/floating.lua")
local audio            = require("./features/audio.lua")
local caffeine         = require("./features/caffeine.lua")
local backlight        = require("./features/backlight.lua")
local focus_mode       = require("./features/focus_mode.lua")
local wallpaper        = require("./features/wallpaper.lua")
local apps             = require("./features/apps.lua")

local dsp              = hl.dsp
local MOD, SHIFT, CTRL = "SUPER", "SUPER + SHIFT", "SUPER + CTRL"
local bin              = "~/.config/hypr/bin/"

local function bind(keys, action, opts) return hl.bind(keys, action, opts) end
local function run(cmd) return dsp.exec_cmd(cmd) end

local directions = {
	{ key = "H", arrow = "LEFT",  dir = "left" },
	{ key = "J", arrow = "DOWN",  dir = "down" },
	{ key = "K", arrow = "UP",    dir = "up" },
	{ key = "L", arrow = "RIGHT", dir = "right" },
}

---------------------------------------------------------------- windows
bind(SHIFT .. " + Q", dsp.window.close())
bind(CTRL .. " + C", dsp.window.center())
bind(MOD .. " + S", dsp.window.swap({ next = true }))
bind(MOD .. " + F", dsp.window.fullscreen({ mode = "maximized" }))
bind(SHIFT .. " + F", dsp.window.fullscreen({ mode = "fullscreen" }))
bind(MOD .. " + C", floating.toggle)

for _, d in ipairs(directions) do
	local step = ({ left = { -60, 0 }, right = { 60, 0 }, up = { 0, -60 }, down = { 0, 60 } })[d.dir]

	-- focus (vim keys; LEFT/RIGHT are "smart" and scroll columns when maximized)
	bind(MOD .. " + " .. d.key, dsp.focus({ direction = d.dir }))
	if d.dir == "left" or d.dir == "right" then
		bind(MOD .. " + " .. d.arrow, function() focus.smart(d.dir) end)
	else
		bind(MOD .. " + " .. d.arrow, dsp.focus({ direction = d.dir }))
	end

	-- move window (or group member)
	bind(SHIFT .. " + " .. d.key, dsp.window.move({ direction = d.dir, group_aware = true }))
	bind(SHIFT .. " + " .. d.arrow, dsp.window.move({ direction = d.dir, group_aware = true }))

	-- resize
	local resize = dsp.window.resize({ x = step[1], y = step[2], relative = true })
	bind(CTRL .. " + " .. d.key, resize)
	bind(CTRL .. " + " .. d.arrow, resize)
end

-- scrolling layout columns
bind(MOD .. " + period", dsp.layout("move +col"))
bind(MOD .. " + comma", dsp.layout("move -col"))
bind(SHIFT .. " + period", dsp.layout("swapcol r"))
bind(SHIFT .. " + comma", dsp.layout("swapcol l"))

-- focus by app
bind(MOD .. " + F1", function() focus.by_class("kitty") end)
bind(MOD .. " + F2", function() focus.by_class("zen||google-chrome") end)

------------------------------------------------------------- workspaces
for i, key in ipairs(workspaces.keys) do
	local function focus_ws() workspaces.focus(key) end
	local function move_ws() workspaces.move(key) end

	bind(MOD .. " + " .. i, focus_ws)
	bind(MOD .. " + " .. key:upper(), focus_ws)
	bind(CTRL .. " + " .. i, move_ws)
	bind(CTRL .. " + " .. key:upper(), move_ws)
end

-- special workspace (scratchpad, currently Spotify)
bind(MOD .. " + P", dsp.workspace.toggle_special(""))
bind(CTRL .. " + P", dsp.window.move({ workspace = "special", follow = false }))

-- monitors
bind(MOD .. " + BACKSPACE", dsp.focus({ monitor = "+1" }))
bind(CTRL .. " + BACKSPACE", dsp.window.move({ monitor = "+1" }))

---------------------------------------------------------------- programs
bind(MOD .. " + RETURN", run("kitty"))
bind(SHIFT .. " + D", run("rofi -show run -theme application"))
bind(SHIFT .. " + M", run("hyprlock"))
bind(MOD .. " + D", function() apps.notch("launcher") end)
bind(SHIFT .. " + X", function() apps.notch("power") end)
bind(CTRL .. " + X", function() apps.notch("power") end)
bind("XF86PowerOff", function() apps.notch("power") end)
bind(MOD .. " + V", function() apps.notch("clipboard") end)
bind(SHIFT .. " + V", apps.clear_clipboard)
bind(CTRL .. " + D", apps.utils_menu)
bind(SHIFT .. " + W", wallpaper.init)

---------------------------------------------------------------- utilities
bind(CTRL .. " + M", caffeine.toggle)
bind(MOD .. " + B", focus_mode.toggle)
bind(MOD .. " + F4", backlight.cycle)
bind(MOD .. " + F11", apps.color_picker)
bind(SHIFT .. " + S", run(bin .. "screenshot.sh"))
bind("Print", run(bin .. "screenshot.sh"))
bind(SHIFT .. " + R", run(bin .. "recorder.sh"))

-------------------------------------------------------------------- media
bind(SHIFT .. " + P", run("playerctl -p spotify play-pause"))
bind(SHIFT .. " + I", run("playerctl -p spotify previous"))
bind(SHIFT .. " + O", run("playerctl -p spotify next"))

local function volume(action) return function() audio.volume(action) end end
local function brightness(action) return function() audio.brightness(action) end end

bind(MOD .. " + bracketleft", volume("lower"))
bind(MOD .. " + bracketright", volume("raise"))
bind("XF86AudioLowerVolume", volume("lower"))
bind("XF86AudioRaiseVolume", volume("raise"))
bind("XF86AudioMute", volume("mute-toggle"))

bind("XF86AudioMicMute", audio.mic_toggle)
bind(CTRL .. " + S", audio.mic_toggle)

bind("XF86MonBrightnessDown", brightness("lower"))
bind("XF86MonBrightnessUp", brightness("raise"))
