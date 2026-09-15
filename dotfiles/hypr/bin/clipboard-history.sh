#!/usr/bin/env bash
# ##############################################################################
# Omarchy-style Clipboard History Manager (Super + Ctrl + V)
# ##############################################################################

# Ensure cliphist is running
if ! pgrep -x cliphist > /dev/null; then
    wl-paste --type text --watch cliphist store &
    wl-paste --type image --watch cliphist store &
fi

selected=$(cliphist list | rofi -dmenu -i -p "󰅍 Clipboard" -theme-str 'window { width: 750px; } listview { lines: 12; }')

if [[ -n "$selected" ]]; then
    echo "$selected" | cliphist decode | wl-copy
    # Simulate paste to active window after copying
    sleep 0.05
    wtype -M ctrl -k v -m ctrl 2>/dev/null || true
fi
