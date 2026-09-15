#!/usr/bin/env bash
# Universal Mac Copy Dispatcher (Cmd + C)
# - In terminals (foot, kitty, alacritty): Send Ctrl+Shift+C (copies without sending SIGINT ^C)
#   and sync primary selection to clipboard
# - In GUI applications (browsers, text editors): Send standard Ctrl+C

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    SOCKET=$(ls -t "/run/user/$(id -u)/hypr/" 2>/dev/null | head -n 1 || true)
    if [[ -n "$SOCKET" ]]; then
        export HYPRLAND_INSTANCE_SIGNATURE="$SOCKET"
    fi
fi

WINDOW_JSON=$(hyprctl activewindow -j 2>/dev/null || true)
CLASS=""
if [[ -n "$WINDOW_JSON" && "$WINDOW_JSON" =~ ^\{ ]]; then
    CLASS=$(echo "$WINDOW_JSON" | jq -r '.class // empty' 2>/dev/null || true)
fi

if [[ "$CLASS" =~ ^(foot|footclient|kitty|Alacritty|wezterm)$ ]]; then
    hyprctl dispatch sendshortcut "CTRL SHIFT, C, activewindow" >/dev/null 2>&1 || true
    # Fallback: if primary selection has text, copy to system clipboard
    if PRIMARY=$(wl-paste --primary --no-newline 2>/dev/null) && [[ -n "$PRIMARY" ]]; then
        printf "%s" "$PRIMARY" | wl-copy 2>/dev/null || true
    fi
else
    hyprctl dispatch sendshortcut "CTRL, C, activewindow" >/dev/null 2>&1 || true
fi
