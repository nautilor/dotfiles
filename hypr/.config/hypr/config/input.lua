-- Keyboard, pointer, touchpad and gestures.
hl.config({
    input = {
        kb_layout    = "us,it",
        kb_options   = "grp:win_space_toggle,ctrl:nocaps,fkeys:basic_13-24",
        follow_mouse = 2,
        sensitivity  = 0.5,
        touchpad = {
            natural_scroll = true,
            scroll_factor  = 0.7,
        },
    },

    gestures = {
        workspace_swipe_use_r                     = true,
        workspace_swipe_distance                  = 700,
        workspace_swipe_cancel_ratio              = 0.15,
        workspace_swipe_min_speed_to_force        = 5,
        workspace_swipe_direction_lock            = true,
        workspace_swipe_direction_lock_threshold  = 10,
        workspace_swipe_create_new                = true,
    },

    binds = {
        movefocus_cycles_fullscreen = true,
    },
})

hl.gesture({ fingers = 3, direction = "vertical",   action = "workspace", scale = 0.5 })
hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })
hl.gesture({
    fingers   = 4,
    direction = "vertical",
    action    = function() hl.dispatch(hl.dsp.exec_cmd("qs ipc call windowSwitcher toggle")) end,
})
