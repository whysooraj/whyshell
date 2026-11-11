#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
WALLPAPERS_DIR="$HOME/.config/wallpapers"
NEW_WALL=$(find -L "$WALLPAPERS_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | shuf -n 1)

if [[ -n "$NEW_WALL" ]]; then
    "$SCRIPT_DIR/set.sh" "$NEW_WALL"
fi
