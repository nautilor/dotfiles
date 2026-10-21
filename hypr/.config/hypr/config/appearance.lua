-- Look and feel: general layout, decoration, animations.
hl.config({
    general = {
        gaps_in          = 3,
        gaps_out         = 10,
        border_size      = 0,
        col = {
            active_border   = "rgba(65,72,104,0.3)",
            inactive_border = "rgba(65,72,104,0.1)",
        },
        resize_on_border = true,
        allow_tearing    = false,
        layout           = "scrolling",
    },

    decoration = {
        rounding         = 16,
        rounding_power   = 9,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        dim_inactive     = true,
        dim_strength     = 0.3,

        shadow = {
            enabled      = true,
            range        = 10,
            render_power = 5,
            color        = "rgba(0,0,0,0.1)",
        },

        blur = {
            enabled        = true,
            size           = 3,
            passes         = 3,
            ignore_opacity = true,
            new_optimizations = true,
            noise          = 0.0,
            contrast       = 0.9,
            brightness     = 0.8,
            vibrancy       = 0.0,
            popups         = false,
        },
    },

    animations = { enabled = true },
})

hl.curve("quart", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })

hl.animation({ leaf = "windows",     enabled = true, speed = 4, bezier = "quart", style = "slide" })
hl.animation({ leaf = "border",      enabled = true, speed = 4, bezier = "quart" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 4, bezier = "quart" })
hl.animation({ leaf = "fade",        enabled = true, speed = 4, bezier = "quart" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 4, bezier = "quart", style = "slidevert" })
