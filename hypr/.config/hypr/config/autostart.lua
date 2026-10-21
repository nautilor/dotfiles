-- Programs started once with the compositor.
local wallpaper       = require("./features/wallpaper.lua")
local battery         = require("./features/battery.lua")
local update_reminder = require("./features/update_reminder.lua")
local services        = {
	"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
	"$POLKIT_GNOME_AGENT",
	"hypridle",
	"hyprsunset",
	"nm-applet",
	"awww-daemon",
	"clipse -listen",
	"quickshell",
	"wl-clip-persist --clipboard regular",
	"~/.config/hypr/bin/xdg-portal-restart.sh",
	"spotify",
}

hl.on("hyprland.start", function()
	for _, cmd in ipairs(services) do
		hl.exec_cmd(cmd)
	end

	wallpaper.init()
	battery.start()
	update_reminder.start()
end)
