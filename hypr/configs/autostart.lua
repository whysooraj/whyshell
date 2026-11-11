-- -----------------------------------------------------------------------------
-- Autostart Programs
-- -----------------------------------------------------------------------------

local HOME_DIR = os.getenv("HOME") or ""
local function get_hypr_dir()
    local p = HOME_DIR .. "/.config/revo/hypr"
    local f = io.open(p .. "/hyprland.lua", "r")
    if f then f:close(); return p end
    return HOME_DIR .. "/.config/hypr"
end
local HYPR_DIR = get_hypr_dir()

-- Shell chosen by the installer (marker: ~/.config/hypr/.revo_default_shell or ~/.config/revo/hypr/.revo_default_shell).
-- nil -> no explicit choice, fall back to legacy shells.
local function read_default_shell()
    local ok, fh = pcall(io.open, HYPR_DIR .. "/.revo_default_shell", "r")
    if not ok or not fh then
        ok, fh = pcall(io.open, HOME_DIR .. "/.config/hypr/.revo_default_shell", "r")
    end
    if not ok or not fh then
        return nil
    end
    local line = fh:read("*l")
    fh:close()
    if not line then return nil end
    local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
    return (trimmed ~= "" and trimmed ~= "default") and trimmed or nil
end

local function autostart()
    local shell = read_default_shell()

    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hypridle")
    hl.exec_cmd(HYPR_DIR .. "/scripts/wallpapers/set-random.sh &")
    hl.exec_cmd("hyprshade on vibrance")
    hl.exec_cmd("skwd")
    hl.exec_cmd("~/.config/skwd/scripts/bash/restore-wallpaper")

    -- selected shell (installer marker) vs. legacy default shells
    if shell then
        hl.exec_cmd("bash " .. HYPR_DIR .. "/scripts/toggle_qs_dots.sh " .. shell .. " &")
    else
        hl.exec_cmd("quickshell -p " .. HYPR_DIR .. "/scripts/quickshell/Main.qml")
        hl.exec_cmd("quickshell -p " .. HYPR_DIR .. "/scripts/quickshell/TopBar.qml")
    end

    hl.exec_cmd("python3 " .. HYPR_DIR .. "/scripts/quickshell/focustime/focus_daemon.py &")
    hl.exec_cmd(HYPR_DIR .. "/scripts/init.sh")
    if not shell then
        hl.exec_cmd(HYPR_DIR .. "/scripts/qs_manager.sh toggle guide &")
    end
    hl.exec_cmd("playerctld")
    hl.exec_cmd("swayosd-server --top-margin 0.9")
    hl.exec_cmd(HYPR_DIR .. "/scripts/volume_listener.sh")
    hl.exec_cmd(HYPR_DIR .. "/scripts/settings_watcher.sh &")
    hl.exec_cmd(HYPR_DIR .. "/scripts/update_notifier.sh &")
    hl.exec_cmd("systemctl --user enable --now easyeffects")
    if not shell then
        hl.exec_cmd("quickshell -p " .. HYPR_DIR .. "/scripts/quickshell/Powermenu.qml")
    end
    hl.exec_cmd("powerprofilesctl set performance")
    hl.exec_cmd("hyprctl setcursor QingyiBLZ 24")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'QingyiBLZ'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")
    hl.exec_cmd(HYPR_DIR .. "/sounds/keysound.py")

    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("hyprctl eval 'hl.plugin.hypr3d.toggle()'")
end

autostart()
