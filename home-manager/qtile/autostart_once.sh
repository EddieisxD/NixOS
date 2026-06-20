#!/bin/bash

echo "[qtile-autostart] ran at $(date)" >> ~/.cache/qtile-autostart.log

QTILE_DIR="$HOME/.config/qtile"

# Wallpaper — use swaybg on Wayland, feh on X11
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    swaybg -i ~/Pictures/Wallpapers/wallhaven-6lkrow_2560x1440.png &
else
    feh --bg-fill ~/Pictures/Wallpapers/wallhaven-6lkrow_2560x1440.png &
    picom --config "$QTILE_DIR/picom.conf" &
fi

# Notification daemon
dunst -config "$QTILE_DIR/dunstrc" &

# Network manager systray applet
nm-applet &

# Start vicinae daemon
vicinae server &
