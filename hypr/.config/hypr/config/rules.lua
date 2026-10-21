-- Window rules.
local VIEW_SIZE = "(monitor_w*.60) (monitor_h*.65)"
local TOOL_SIZE = "(monitor_w*.45) (monitor_h*.45)"

--- Register a rule; `match` and `props` are plain tables.
local function rule(name, match, props)
    props.name  = name
    props.match = match
    hl.window_rule(props)
end

-- Floating, centered file/save dialogs (matched on title).
local dialog_titles = {
    "^(Open File)(.*)$",
    "^(Select a File)(.*)$",
    "^(Open Folder)(.*)$",
    "^(Save As)(.*)$",
    "^(Library)(.*)$",
    "^(File Upload)(.*)$",
    "^(.*)(wants to save)$",
    "^(.*)(wants to open)$",
}
for i, title in ipairs(dialog_titles) do
    rule("dialog-" .. i, { title = title }, { float = true, center = true })
end

rule("choose-wallpaper", { title = "^(Choose wallpaper)(.*)$" }, { float = true, center = true, size = VIEW_SIZE })
rule("share-screen",     { title = "^(.*Select\\swhat\\sto\\sshare)$" },
    { float = true, center = true, keep_aspect_ratio = true, size = "800 450" })

-- Floating apps (matched on class).
rule("reminder",     { class = "^(.*com.nautilor.reminder.*)$" }, { float = true })
rule("satty",        { class = "^(.*com.gabm.satty.*)$" },        { float = true, center = true, size = VIEW_SIZE })
rule("blueberry",    { class = "^(blueberry\\.py)$" },            { float = true })
rule("pavucontrol",  { class = "^(pavucontrol)$" },               { float = true, center = true, size = TOOL_SIZE })
rule("pavucontrol-pulse", { class = "^(org.pulseaudio.pavucontrol)$" }, { float = true, center = true, size = TOOL_SIZE })
rule("nm-editor",    { class = "^(nm-connection-editor)$" },      { float = true, center = true, size = TOOL_SIZE })
rule("plasmawindowed", { class = ".*plasmawindowed.*" },          { float = true })
rule("kcm",          { class = "kcm_.*" },                        { float = true })
rule("bluedevil",    { class = ".*bluedevilwizard" },             { float = true })
rule("welcome",      { title = ".*Welcome" },                     { float = true })
rule("illogical-settings", { title = "^(illogical-impulse Settings)$" }, { float = true })
rule("shell-conflicts",    { title = ".*Shell conflicts.*" },     { float = true })
rule("portal-kde",   { class = "org.freedesktop.impl.portal.desktop.kde" }, { float = true, size = VIEW_SIZE })
rule("utils",        { class = "^(.*utils)$" },                   { float = true, center = true, keep_aspect_ratio = true, size = "800 450" })
rule("image-viewer", { class = "^(.*ImageRoll)$" },               { float = true, center = true, keep_aspect_ratio = true })
rule("askpass",      { class = "^(.*askpass.*)$" },               { float = true, center = true })

-- Dank calendar and its event dialogs.
rule("calendar",           { class = "^(.*com.danklinux.dankcalendar)$" }, { float = true, center = true, size = "1600 800" })
rule("calendar-event",     { class = "^(.*com.danklinux.dankcalendar)$", title = "^(.*Event.*Dank Calendar.*)$" }, { float = true, center = true, size = "800 600" })
rule("calendar-new-event", { class = "^(.*com.danklinux.dankcalendar)$", title = "^(.*New event.*)$" },           { float = true, center = true, size = "800 600" })

-- Tags / placement.
rule("terminal-tag", { class = "^(.*kitty)$" }, { tag = "+terminal" })
rule("spotify",      { class = "^((s|S)potify)$" }, { workspace = "special silent", opacity = 1 })

-- Behaviour fixes.
rule("suppress-maximize", { class = ".*" }, { suppress_event = "maximize" })

rule("fix-xwayland-drags",
    { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    { no_focus = true })

rule("jetbrains-no-fullscreen", { class = "^(jetbrains-.*)$" }, { fullscreen = false })
rule("jetbrains-search-everywhere-fix",
    { class = "^(jetbrains-.*)$", title = "^$", float = true },
    { focus_on_activate = true, stay_focused = true, keep_aspect_ratio = true })
