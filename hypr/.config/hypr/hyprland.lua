-- Hyprland configuration entry point.
-- Settings live in config/, reusable helpers in lib/, and behaviour that
-- used to be shell scripts in features/. Load order matters: monitors and
-- workspaces first, rules and binds last.

require("./config/env.lua")
require("./config/monitors.lua")
require("./config/appearance.lua")
require("./config/layouts.lua")
require("./config/input.lua")
require("./config/misc.lua")
require("./config/rules.lua")
require("./config/binds.lua")
require("./config/autostart.lua")
