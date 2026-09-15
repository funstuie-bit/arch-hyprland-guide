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
        # Keep the intended window even though Rofi temporarily takes focus.
        target=$(hyprctl -j activewindow | jq -r '.address // empty')
        if [[ -z "$target" ]]; then
            target=$(hyprctl -j activeworkspace | jq -r '.lastwindow // empty')
        fi
        choice=$(printf '%s\n' \
            'Split side-by-side / top-bottom (Super+J)' \
            'Tab with window on the left' \
            'Tab with window on the right' \
            'Tab with window above' \
            'Tab with window below' \
            'Remove focused window from tabs' \
            'Next tab in group' \
            'Previous tab in group' \
            'Float / tile focused window (Super+T)' \
            'Switch dwindle / scrolling layout (Super+L)' \
            'Maximize with application tabs (Super+Alt+F)' \
            'Pin / unpin floating window (Super+O)' \
            'Settings' 'Theme' 'Wallpaper' 'Display' 'Sound' 'Bluetooth' \
            'Keyboard shortcuts' 'Power menu' | rofi -dmenu -i -p 'Window layout and desktop' \
                -theme-str 'window { width: 850px; } listview { lines: 14; }') || exit 0
        if [[ -n "$target" && "$target" != 0x0 ]]; then
            dispatch focuswindow "address:$target"
        fi
        case "$choice" in
            'Tab with window on the left') dispatch moveintoorcreategroup l ;;
            'Tab with window on the right') dispatch moveintoorcreategroup r ;;
            'Tab with window above') dispatch moveintoorcreategroup u ;;
            'Tab with window below') dispatch moveintoorcreategroup d ;;
            'Remove focused window from tabs') dispatch moveoutofgroup ;;
            'Next tab in group') dispatch changegroupactive f ;;
            'Previous tab in group') dispatch changegroupactive b ;;
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
