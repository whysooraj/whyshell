#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
for _ in $(seq 1 50); do
    [[ -S "$runtime/$WAYLAND_DISPLAY" ]] && break
    sleep 0.1
done

if ! pgrep -x "awww-daemon" >/dev/null 2>&1; then
    awww-daemon &
    sleep 0.5
fi

bash "$SCRIPT_DIR/random.sh"
