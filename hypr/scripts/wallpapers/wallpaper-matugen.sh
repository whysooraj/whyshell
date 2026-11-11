#!/bin/bash

SCRIPTS="$HOME/.config/revo/hypr/scripts"
QS_DIR="$SCRIPTS/quickshell"
MATUGEN_RELOAD="$QS_DIR/wallpaper/matugen_reload.sh"
MAIN_QML="$QS_DIR/Main.qml"
TOPBAR_QML="$QS_DIR/TopBar.qml"

# ─── 1. Run random.sh (change wallpaper + pywal) ─────
bash "$SCRIPTS/wallpapers/random.sh"

# ─── 2. Get last wallpaper used by wal ─────────────────
WALLPAPER=$(cat ~/.cache/wal/wal 2>/dev/null)
[ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ] && exit 1

# ─── 3. Generate matugen colors from wallpaper ─────────
matugen image "$WALLPAPER" --source-color-index 0

# ─── 4. reload ──────────────────────────────────────
[ -f "$MATUGEN_RELOAD" ] && bash "$MATUGEN_RELOAD"

sleep 0.5

# ─── 5. Restart quickshell ────────────────────────────
kill $(pgrep -f "Main.qml") 2>/dev/null || true
kill $(pgrep -f "TopBar.qml") 2>/dev/null || true

sleep 0.5

nohup quickshell -p "$MAIN_QML" >/dev/null 2>&1 &
nohup quickshell -p "$TOPBAR_QML" >/dev/null 2>&1 &
