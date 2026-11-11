local HOME = os.getenv("HOME") or ""
local function get_hypr_dir()
    local p = HOME .. "/.config/revo/hypr"
    local f = io.open(p .. "/hyprland.lua", "r")
    if f then f:close(); return p end
    return HOME .. "/.config/hypr"
end

local function get_qs_dir()
    local p = HOME .. "/.config/revo/quickshell"
    local f = io.open(p .. "/macos/shell.qml", "r")
    if f then f:close(); return p end
    return HOME .. "/.config/quickshell"
end

local hypr_dir = get_hypr_dir()
local qs_dir = get_qs_dir()

local terminal = "kitty"
local fileManager = "thunar"
local menu = "wofi --show drun"
local clipboard = "cliphist list"
local shiftMod = "SHIFT"
local wallpapers = "bash " .. hypr_dir .. "/scripts/wallpapers/wallpaper-matugen.sh"
local mainMod = "SUPER"

-- Terminal
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))

-- App launchers & menus
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("quickshell -p " .. qs_dir .. "/macos/shell.qml ipc call launchpad toggle"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus"))
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("bash " .. hypr_dir .. "/scripts/quickshell/toggle_wallpaper_browser.sh"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("bash " .. hypr_dir .. "/scripts/macos_lock.sh"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("quickshell -p " .. qs_dir .. "/macos/shell.qml ipc call launchpad toggle"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("quickshell -p " .. qs_dir .. "/macos/shell.qml ipc call spotlight toggle"))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("bash " .. hypr_dir .. "/scripts/qs_manager.sh toggle music"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("bash " .. hypr_dir .. "/scripts/ryoku_settings.sh"))
hl.bind("ALT + TAB", hl.dsp.exec_cmd("bash " .. hypr_dir .. "/scripts/rofi_show.sh window"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("bash " .. hypr_dir .. "/scripts/wallpapers/wallpaper-matugen.sh"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("systemsettings wallpaper"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("systemsettings shortcuts"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("swaync-client -t"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("bash " .. hypr_dir .. "/scripts/quickshell/toggle_wallpaper_engine_browser.sh"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("bash " .. hypr_dir .. "/scripts/quickshell/toggle_dots_browser.sh"))

-- Window management
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("/usr/bin/python3 " .. hypr_dir .. "/scripts/minimize_window.py min"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("/usr/bin/python3 " .. hypr_dir .. "/scripts/minimize_window.py restore"))
hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))

-- Focus movements
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Workspaces
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mainMod .. " + ALT + left", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.focus({ workspace = "+1" }))

-- Move window to workspace
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ workspace = "-1" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ workspace = "+1" }))

-- Scratchpad (special workspace)
hl.bind(mainMod .. " + grave", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + ALT + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + ALT + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Mouse bindings
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media & Brightness keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"), { locked = true, repeating = true })

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("grimblast --notify copysave output"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grimblast --notify copysave area"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("grimblast --notify copysave active"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("grimblast --notify copysave area"))
hl.bind(mainMod .. " + minus", hl.dsp.exec_cmd("grimblast --notify copysave active"))
hl.bind(shiftMod .. " + K", hl.dsp.exec_cmd("grimblast --notify copysave area"))

-- Extra shortcuts
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("bash " .. hypr_dir .. "/scripts/show_desktop.sh"))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("bash -c 'echo powermenu > ${XDG_RUNTIME_DIR}/skwd/cmd'"))
hl.bind(mainMod .. " + N", hl.dsp.global("quickshell:wallpaperSelectorToggle"))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("systemsettings"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd(hypr_dir .. "/scripts/qs_manager.sh toggle movies"))
hl.bind(mainMod .. " + J", hl.dsp.exec_cmd(hypr_dir .. "/scripts/qs_manager.sh toggle anime"))
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("bash " .. hypr_dir .. "/scripts/qs_manager.sh toggle focustime"))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("quickshell -p " .. qs_dir .. "/TypewriterSplash.qml"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("quickshell -p " .. qs_dir .. "/macos/shell.qml ipc call spotlight toggle"))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("~/.local/bin/steam-gamescope"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("bash " .. hypr_dir .. "/scripts/quickshell/toggle_screenshot_browser.sh"))
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("bash " .. hypr_dir .. "/scripts/macos_lock.sh"), { locked = true })

-- Hypr3D mode
hl.bind(mainMod .. " + BackSpace", hl.dsp.exec_cmd("hyprctl hypr3d"))
