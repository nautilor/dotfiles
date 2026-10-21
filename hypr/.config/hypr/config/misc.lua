-- Everything that does not fit elsewhere.
hl.config({
    debug = {
        disable_logs    = false,
        damage_tracking = false,
    },

    render = {
        cm_sdr_eotf = 2,
    },

    xwayland = {
        force_zero_scaling = true,
    },

    misc = {
        vrr                            = 0,
        on_focus_under_fullscreen      = true,
        force_default_wallpaper        = false,
        exit_window_retains_fullscreen = true,
        focus_on_activate              = true,
        disable_hyprland_logo          = true,
    },
})
