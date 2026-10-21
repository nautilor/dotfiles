-- Monitors and the workspaces they own.
--   * Workspaces 1-5  live on the laptop panel.
--   * Workspaces 6-10 live on whichever external display is attached.
-- `owner` is the monitor the external workspaces are pinned to.
local laptop = "eDP-1"

local monitors = {
    { output = laptop,     mode = "highres@highrr",  position = "0x0",     scale = 2, workspaces = { 1, 5 },  owner = laptop },
    { output = "DP-1",     mode = "3840x2400@60.00", position = "auto-up",   scale = 2, workspaces = { 6, 10 }, owner = "DP-1" },
    { output = "DP-2",     mode = "3840x2400@60.00", position = "auto-up",   scale = 2, workspaces = { 6, 10 }, owner = "DP-2" },
    { output = "DP-3",     mode = "3840x2400@60.00", position = "auto-up",   scale = 2, workspaces = { 6, 10 }, owner = "DP-2" },
    { output = "DP-9",     mode = "3840x2400@60.00", position = "auto-down", scale = 2, workspaces = { 6, 10 }, owner = "DP-1" },
    { output = "HDMI-A-1", mode = "highres@highrr",  position = "auto-up",   scale = 1, workspaces = { 6, 10 }, owner = "HDMI-A-1" },
}

for _, m in ipairs(monitors) do
    hl.monitor({
        output   = m.output,
        mode     = m.mode,
        position = m.position,
        scale    = m.scale,
    })
    for ws = m.workspaces[1], m.workspaces[2] do
        hl.workspace_rule({ workspace = tostring(ws), monitor = m.owner })
    end
end

hl.workspace_rule({ workspace = "1", monitor = laptop, default = true })
