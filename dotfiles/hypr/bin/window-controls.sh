#!/usr/bin/env bash
# Local controls implemented with stock Hyprland, Rofi and existing Settings.
set -euo pipefail

dispatch() {
    local reply
    reply=$(hyprctl dispatch "$@")
    [[ "$reply" == "ok" ]] || { printf '%s\n' "$reply" >&2; return 1; }
}

case "${1:-menu}" in
    tiled-fullscreen)
        current=$(hyprctl -j activewindow | jq -r '.fullscreenClient // 0')
        if [[ "$current" == 2 ]]; then
            dispatch fullscreenstate '0 0'
        else
            dispatch fullscreenstate '0 2'
        fi
        ;;
    layout)
        workspace=$(hyprctl -j activeworkspace)
        id=$(jq -er '.id' <<< "$workspace")
        current=$(jq -er '.tiledLayout' <<< "$workspace")
        if [[ "$current" == dwindle ]]; then next=scrolling; else next=dwindle; fi
        reply=$(hyprctl keyword workspace "$id, layout:$next")
        [[ "$reply" == ok ]] || { printf '%s\n' "$reply" >&2; exit 1; }
        actual=$(hyprctl -j activeworkspace | jq -r '.tiledLayout')
        [[ "$actual" == "$next" ]] || { notify-send "Layout change failed" "$actual"; exit 1; }
        notify-send -t 2500 "Workspace layout: $next" "Super+L switches back. Super+T toggles floating."
        ;;
    pop)
        window=$(hyprctl -j activewindow)
        address=$(jq -er '.address // empty' <<< "$window") || exit 0
        target="address:$address"
        if [[ $(jq -r '.pinned' <<< "$window") == true ]]; then
            dispatch pin "$target"
            dispatch settiled "$target"
        else
            dispatch setfloating "$target"
            dispatch resizewindowpixel "exact 1300 900,$target"
            dispatch pin "$target"
        fi
        ;;
    menu)
        choice=$(printf '%s\n' \
            'Float / tile focused window (Super+T)' \
            'Split side-by-side / top-bottom (Super+J)' \
            'Switch dwindle / scrolling layout (Super+L)' \
            'Maximize with application tabs (Super+Alt+F)' \
            'Pin / unpin floating window (Super+O)' \
            'Settings' 'Theme' 'Wallpaper' 'Display' 'Sound' 'Bluetooth' \
            'Keyboard shortcuts' 'Power menu' | rofi -dmenu -i -p 'Desktop controls') || exit 0
        case "$choice" in
            Float*) dispatch togglefloating ;;
            Split*) dispatch layoutmsg togglesplit ;;
            Switch*) exec "$0" layout ;;
            Maximize*) dispatch fullscreen 1 ;;
            Pin*) exec "$0" pop ;;
            Settings) exec "$HOME/.local/bin/desktop-settings" ;;
            Theme) exec "$HOME/.local/bin/desktop-settings" --page appearance ;;
            Wallpaper) exec "$HOME/.local/bin/desktop-settings" --page wallpaper ;;
            Display) exec "$HOME/.local/bin/desktop-settings" --page display ;;
            Sound) exec pavucontrol ;;
            Bluetooth) exec blueman-manager ;;
            'Keyboard shortcuts') exec "$HOME/.config/hypr/bin/shortcuts-menu.sh" ;;
            'Power menu') exec "$HOME/.config/hypr/bin/system-menu.sh" ;;
        esac
        ;;
    *) printf 'Usage: %s [menu|layout|pop|tiled-fullscreen]\n' "$0" >&2; exit 2 ;;
esac
