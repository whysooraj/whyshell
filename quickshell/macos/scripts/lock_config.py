#!/usr/bin/env python3
"""
whyshell-lock-config: Customize whyShell macOS Lock Screen
"""

import os
import sys
import json
import argparse

CFG_PATH = os.path.expanduser("~/.config/quickshell/macos/userconfig.json")
PRESET_WALLPAPERS = {
    "sonoma-light": os.path.expanduser("~/Pictures/Wallpapers/14-Sonoma-Light.jpg"),
    "sonoma-dark": os.path.expanduser("~/Pictures/Wallpapers/14-Sonoma-Dark.jpg"),
    "sequoia": os.path.expanduser("~/Pictures/Wallpapers/Sequoia-Sunrise-wallpaper-macos.jpg"),
    "macbook-m3": os.path.expanduser("~/Pictures/Wallpapers/M3-MacBook-Pro-Wallpaper-8K.png"),
    "lake-tahoe": os.path.expanduser("~/.config/revo/quickshell/macos/assets/wall.jpg"),
    "system": "system",
}

DEFAULT_LOCK_CONFIG = {
    "wallpaper": os.path.expanduser("~/Pictures/Wallpapers/14-Sonoma-Light.jpg"),
    "avatar": os.path.expanduser("~/.local/share/systemsettings/avatar-1790780655549.png"),
    "clockFormat": "12h",
    "showDate": True,
    "showPowerButton": True,
    "dimOpacity": 0.12,
}

def load_config():
    if not os.path.exists(CFG_PATH):
        return {}
    try:
        with open(CFG_PATH, "r") as f:
            return json.load(f)
    except Exception as e:
        print(f"Warning: Failed to read userconfig.json ({e})", file=sys.stderr)
        return {}

def save_config(cfg):
    try:
        os.makedirs(os.path.dirname(CFG_PATH), exist_ok=True)
        with open(CFG_PATH, "w") as f:
            json.dump(cfg, f, indent=2)
            f.write("\n")
        return True
    except Exception as e:
        print(f"Error saving config: {e}", file=sys.stderr)
        return False

def show_status(cfg):
    lock_cfg = cfg.get("lockScreen", {})
    wall = lock_cfg.get("wallpaper", DEFAULT_LOCK_CONFIG["wallpaper"])
    avatar = lock_cfg.get("avatar", cfg.get("avatarPath", DEFAULT_LOCK_CONFIG["avatar"]))
    clock = lock_cfg.get("clockFormat", DEFAULT_LOCK_CONFIG["clockFormat"])
    date = lock_cfg.get("showDate", DEFAULT_LOCK_CONFIG["showDate"])
    power = lock_cfg.get("showPowerButton", DEFAULT_LOCK_CONFIG["showPowerButton"])
    dim = lock_cfg.get("dimOpacity", DEFAULT_LOCK_CONFIG["dimOpacity"])

    print("=== whyShell macOS Lock Screen Configuration ===")
    print(f"  Wallpaper:         {wall}")
    print(f"  Avatar:            {avatar}")
    print(f"  Clock Format:      {clock}")
    print(f"  Show Date:         {date}")
    print(f"  Show Power Button: {power}")
    print(f"  Dim Opacity:       {dim}")
    print("============================================")

def main():
    parser = argparse.ArgumentParser(
        description="Configure Revo macOS Lock Screen settings",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""Presets for --wallpaper:
  sonoma-light  Official macOS Sonoma Light Graphic (default)
  sonoma-dark   Official macOS Sonoma Dark Graphic
  sequoia       macOS Sequoia Sunrise
  macbook-m3    MacBook Pro M3 8K wallpaper
  lake-tahoe    Classic Lake Tahoe
  system        Follow current active desktop wallpaper
"""
    )
    parser.add_argument("--status", action="store_true", help="Show current lockscreen settings")
    parser.add_argument("--wallpaper", metavar="PATH_OR_PRESET", help="Set lockscreen wallpaper")
    parser.add_argument("--avatar", metavar="PATH", help="Set lockscreen avatar image path")
    parser.add_argument("--clock", choices=["12h", "24h"], help="Clock format (12h or 24h)")
    parser.add_argument("--dim", type=float, metavar="OPACITY", help="Backdrop dimming opacity (0.0 to 1.0, default 0.12)")
    parser.add_argument("--date", choices=["on", "off"], help="Toggle date display above clock")
    parser.add_argument("--power", choices=["on", "off"], help="Toggle power button visibility")
    parser.add_argument("--reset", action="store_true", help="Reset lockscreen to macOS Sonoma defaults")

    args = parser.parse_args()

    cfg = load_config()
    if "lockScreen" not in cfg or not isinstance(cfg["lockScreen"], dict):
        cfg["lockScreen"] = dict(DEFAULT_LOCK_CONFIG)

    lock_cfg = cfg["lockScreen"]
    modified = False

    if args.reset:
        cfg["lockScreen"] = dict(DEFAULT_LOCK_CONFIG)
        modified = True
        print("Reset lockscreen to Sonoma defaults.")

    if args.wallpaper:
        target = PRESET_WALLPAPERS.get(args.wallpaper.lower(), os.path.abspath(os.path.expanduser(args.wallpaper)))
        if target != "system" and not os.path.exists(target):
            print(f"Warning: File '{target}' does not exist, setting anyway.", file=sys.stderr)
        lock_cfg["wallpaper"] = target
        modified = True
        print(f"Lockscreen wallpaper set to: {target}")

    if args.avatar:
        target = os.path.abspath(os.path.expanduser(args.avatar)) if args.avatar.lower() != "default" else DEFAULT_LOCK_CONFIG["avatar"]
        if not os.path.exists(target):
            print(f"Warning: Avatar '{target}' not found, setting anyway.", file=sys.stderr)
        lock_cfg["avatar"] = target
        modified = True
        print(f"Lockscreen avatar set to: {target}")

    if args.clock:
        lock_cfg["clockFormat"] = args.clock
        modified = True
        print(f"Clock format set to: {args.clock}")

    if args.dim is not None:
        dim_val = max(0.0, min(1.0, args.dim))
        lock_cfg["dimOpacity"] = dim_val
        modified = True
        print(f"Dim opacity set to: {dim_val}")

    if args.date:
        lock_cfg["showDate"] = (args.date == "on")
        modified = True
        print(f"Show date set to: {lock_cfg['showDate']}")

    if args.power:
        lock_cfg["showPowerButton"] = (args.power == "on")
        modified = True
        print(f"Show power button set to: {lock_cfg['showPowerButton']}")

    if modified:
        save_config(cfg)
        print("Settings saved! Quickshell will reload dynamically.")
    else:
        show_status(cfg)

if __name__ == "__main__":
    main()
