-- Caffeine: hold an idle/sleep inhibitor while active.
local util    = require("./lib/util.lua")

local M       = {}

local REASON  = "Caffeine active"
-- [x] trick: the pattern must not match the shell running the check itself
local PATTERN = "[s]ystemd-inhibit.*" .. REASON

local function active()
	return util.ok(string.format("pgrep -f '%s' >/dev/null", PATTERN))
end

function M.start()
	if not active() then
		util.sh(string.format(
			"systemd-inhibit --what=idle:sleep --mode=block --why=%q sleep infinity", REASON))
	end
	util.qs("notch caffeine")
end

function M.stop()
	if active() then
		util.sh(string.format("pkill -f '%s'", PATTERN))
	end
	util.qs("notch caffeine")
end

function M.toggle()
	if active() then M.stop() else M.start() end
end

return M
