hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
        },
    },

    gestures = {
        workspace_swipe_distance = 300,
        workspace_swipe_invert = true,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_create_new = true,
        workspace_swipe_forever = true,
    },
})

-- 3-finger and 4-finger touchpad workspace swipe (macOS style)
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.gesture({
    fingers = 4,
    direction = "horizontal",
    action = "workspace",
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})
