#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys

HOME = os.path.expanduser("~")

def get_config_paths():
    candidates = [
        os.path.join(HOME, ".config/revo/hypr/configs/general.lua"),
        os.path.join(HOME, ".config/hypr/configs/general.lua"),
        os.path.join(HOME, ".local/share/revo-shell/src/hypr/configs/general.lua"),
    ]
    return [p for p in candidates if os.path.exists(p)]

def get_hypr_option(name):
    try:
        out = subprocess.check_output(["hyprctl", "getoption", name], stderr=subprocess.DEVNULL).decode()
        for line in out.splitlines():
            line = line.strip()
            if line.startswith("int:"):
                return int(line.split(":", 1)[1].strip())
            if line.startswith("float:"):
                return round(float(line.split(":", 1)[1].strip()), 2)
            if line.startswith("bool:"):
                return "true" in line.lower()
            if line.startswith("css gap data:"):
                return int(line.split(":", 1)[1].strip().split()[0])
            if line.startswith("gradient data:"):
                return line.split(":", 1)[1].strip().split()[0]
    except Exception:
        pass
    return None

def get_all():
    data = {
        "gaps_in": get_hypr_option("general:gaps_in") or 6,
        "gaps_out": get_hypr_option("general:gaps_out") or 10,
        "border_size": get_hypr_option("general:border_size") if get_hypr_option("general:border_size") is not None else 0,
        "rounding": get_hypr_option("decoration:rounding") or 12,
        "active_opacity": get_hypr_option("decoration:active_opacity") or 0.95,
        "inactive_opacity": get_hypr_option("decoration:inactive_opacity") or 0.88,
        "blur_enabled": get_hypr_option("decoration:blur:enabled") if get_hypr_option("decoration:blur:enabled") is not None else True,
        "shadow_enabled": get_hypr_option("decoration:shadow:enabled") if get_hypr_option("decoration:shadow:enabled") is not None else True,
        "active_border": get_hypr_option("general:col.active_border") or "15ffffff",
        "inactive_border": get_hypr_option("general:col.inactive_border") or "00000000",
    }
    return data

def set_option(key, val):
    # Apply live to Hyprland
    hypr_key_map = {
        "gaps_in": "general:gaps_in",
        "gaps_out": "general:gaps_out",
        "border_size": "general:border_size",
        "rounding": "decoration:rounding",
        "active_opacity": "decoration:active_opacity",
        "inactive_opacity": "decoration:inactive_opacity",
        "blur_enabled": "decoration:blur:enabled",
        "shadow_enabled": "decoration:shadow:enabled",
        "active_border": "general:col.active_border",
        "inactive_border": "general:col.inactive_border",
    }

    hkey = hypr_key_map.get(key, key)
    try:
        subprocess.run(["hyprctl", "keyword", hkey, str(val)], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        sys.stderr.write(f"hyprctl error: {e}\n")

    # Persist to general.lua files
    for path in get_config_paths():
        try:
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            if key == "gaps_in":
                content = re.sub(r'gaps_in\s*=\s*\d+', f'gaps_in = {val}', content)
            elif key == "gaps_out":
                content = re.sub(r'gaps_out\s*=\s*\d+', f'gaps_out = {val}', content)
            elif key == "border_size":
                content = re.sub(r'border_size\s*=\s*\d+', f'border_size = {val}', content)
            elif key == "rounding":
                content = re.sub(r'rounding\s*=\s*\d+', f'rounding = {val}', content)
            elif key == "active_opacity":
                content = re.sub(r'active_opacity\s*=\s*[\d.]+', f'active_opacity = {val}', content)
            elif key == "inactive_opacity":
                content = re.sub(r'inactive_opacity\s*=\s*[\d.]+', f'inactive_opacity = {val}', content)
            elif key == "blur_enabled":
                content = re.sub(r'(blur\s*=\s*\{[^}]*?enabled\s*=\s*)(true|false)', rf'\g<1>{str(val).lower()}', content, flags=re.DOTALL)
            elif key == "shadow_enabled":
                content = re.sub(r'(shadow\s*=\s*\{[^}]*?enabled\s*=\s*)(true|false)', rf'\g<1>{str(val).lower()}', content, flags=re.DOTALL)
            elif key == "active_border":
                content = re.sub(r'active_border\s*=\s*"[^"]*"', f'active_border = "{val}"', content)
            elif key == "inactive_border":
                content = re.sub(r'inactive_border\s*=\s*"[^"]*"', f'inactive_border = "{val}"', content)

            with open(path, "w", encoding="utf-8") as f:
                f.write(content)
        except Exception as e:
            sys.stderr.write(f"Error persisting to {path}: {e}\n")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "get":
        print(json.dumps(get_all()))
    elif len(sys.argv) > 3 and sys.argv[1] == "set":
        set_option(sys.argv[2], sys.argv[3])
    else:
        print("Usage: hypr_settings.py get | set <key> <value>")
