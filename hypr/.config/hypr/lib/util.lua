-- Small helpers shared by every module.
local M = {}

M.home = os.getenv("HOME")

--- Run a shell command (async, through the compositor).
function M.sh(cmd)
	hl.exec_cmd(cmd)
end

--- Run a shell command and return true when it exits 0 (blocking: keep it tiny).
function M.ok(cmd)
	local r = os.execute(cmd)
	return r == true or r == 0
end

--- Call a quickshell IPC function without failing when quickshell is down.
function M.qs(args)
	hl.exec_cmd("qs ipc call " .. args .. " >/dev/null 2>&1 || true")
end

--- Make sure quickshell is running before running `then_cmd`.
function M.with_quickshell(then_cmd)
	hl.exec_cmd("pgrep -f quickshell >/dev/null || { quickshell >/dev/null 2>&1 & sleep 0.5; }; " .. then_cmd)
end

--- Desktop notification.
function M.notify(title, body, icon)
	local cmd = "notify-send"
	if icon then cmd = cmd .. " -i '" .. icon .. "'" end
	hl.exec_cmd(string.format("%s %q %q", cmd, title, body or ""))
end

--- Set a dotted config key at runtime, e.g. set_config("decoration.shadow.enabled", false).
function M.set_config(key, value)
	local tbl = value
	local parts = {}
	for part in key:gmatch("[^.]+") do parts[#parts + 1] = part end
	for i = #parts, 1, -1 do tbl = { [parts[i]] = tbl } end
	hl.config(tbl)
end

--- True when `needle` is in the tag list (string or table) of a window.
function M.has_tag(window, needle)
	local tags = window.tags
	if type(tags) == "table" then
		for _, t in ipairs(tags) do
			if t == needle then return true end
		end
		return false
	end
	return tostring(tags or ""):find(needle, 1, true) ~= nil
end

return M
