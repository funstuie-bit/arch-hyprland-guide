#!/usr/bin/env bash
# ##############################################################################
# Shortcuts Cheatsheet for Hyprland (Super + K)
# Displays a searchable, categorized list of shortcuts in Rofi
# ##############################################################################

SHORTCUTS=(
    "⚙ SETTINGS	Super + ,	Themes, wallpaper, display, sound and connections"
    "📋 CLIPBOARD	Super + C	Universal Copy (Cmd + C)"
    "📋 CLIPBOARD	Super + V	Universal Paste (Cmd + V - no Ctrl+Shift+V needed!)"
    "📋 CLIPBOARD	Super + X	Universal Cut (Cmd + X)"
    "📋 CLIPBOARD	Super + A	Select All (Cmd + A)"
    "📋 CLIPBOARD	Super + Ctrl + V	Open Clipboard History & Paste (Cliphist)"
    "🪟 WINDOWS	Super + T	Swap the two halves of the focused tiled split"
    "🪟 WINDOWS	Super + W	Close focused window"
    "📑 TABS & APPS	Ctrl + T / W	New / Close tab in browser or editor"
    "📑 TABS & APPS	Super + Shift + T	Reopen closed tab in browser"
    "📑 TABS & APPS	Super + L	Focus URL bar in browser (Cmd + L)"
    "🪟 GROUPS/TABS	Super + G	Toggle window into/out of Tab Group"
    "🪟 GROUPS/TABS	Super + Alt + G	Eject window from Tab Group"
    "🪟 GROUPS/TABS	Super + [ / ]	Previous / Next Tab in Group"
    "🪟 WINDOWS	Super + Q	Close focused window (Cmd + Q)"
    "🪟 WINDOWS	Super + Shift + W	Close focused window"
    "🪟 WINDOWS	Super + Shift + Space	Toggle window floating mode"
    "🪟 WINDOWS	Super + Shift + F	Toggle window floating mode"
    "🪟 WINDOWS	Super + F	Toggle fullscreen"
    "🪟 WINDOWS	Super + J	Toggle split direction (horizontal / vertical)"
    "🪟 WINDOWS	Super + Arrow Keys	Navigate focus between windows"
    "🪟 WINDOWS	Alt + Tab	Cycle forward through windows"
    "🪟 WINDOWS	Super + 1..9, 0	Switch to workspace 1 - 10"
    "🪟 WINDOWS	Super + Shift + 1..0	Move active window to workspace"
    "🚀 APPS	Super + Space	Open Application Launcher (Rofi)"
    "🚀 APPS	Super + Return	Open Foot terminal"
    "🚀 APPS	Super + Shift + Return	Open Default Web Browser"
    "🚀 APPS	Super + B	Open Default Web Browser (Firefox/Zen/Chromium)"
    "🚀 APPS	Super + E	Open Thunar file manager"
    "🚀 APPS	Super + Shift + O	Open Obsidian (Markdown Notes)"
    "🚀 APPS	Super + Ctrl + T	Open Activity Monitor (btop)"
    "🚀 APPS	Super + M	Launch Cliamp music player (lo-fi radio)"
    "🤖 AI	Super + Shift + A	Launch Default AI Agent (agy, claude, codex, opencode, omp)"
    "🤖 AI	Super + Alt + A	Choose / Change Default AI Agent"
    "⌨️ HELP	Super + K	Open this Shortcuts Cheatsheet"
    "🖱️ MOUSE	Border Drag	Resize window directly (hover edge/corner & drag)"
    "🖱️ MOUSE	Super + Left-Drag	Move window"
    "🖱️ MOUSE	Super + Right-Drag	Resize window"
    "🖱️ MOUSE	Super + Middle-Click	Toggle window floating"
    "🖱️ MOUSE	Super + Scroll-Wheel	Switch through workspaces"
    "📸 CAPTURE	Super + Shift + S	Select screen area with mouse & copy screenshot"
    "📸 CAPTURE	PrintScreen	Save full screenshot to ~/Pictures/Screenshots/"
    "🔊 AUDIO	Waybar Volume Click	Toggle mute"
    "🔊 AUDIO	Waybar Volume Right-Click	Open Pavucontrol sound mixer"
    "🔊 AUDIO	Waybar Volume Scroll	Increase / decrease volume"
    "🌐 NETWORK	Waybar Network Click	Open Network Manager connection editor"
    "🔒 SYSTEM	Super + Escape	System Power Menu (Lock, Logout, Reboot, Shutdown)"
    "🔒 SYSTEM	Super + Ctrl + Q	Lock screen (Cmd + Ctrl + Q)"
    "🔒 SYSTEM	Super + Ctrl + L	Lock screen (Cmd + Ctrl + L)"
    "🔒 SYSTEM	Super + Shift + Q	Exit Hyprland desktop session"
)

# Format rows for Rofi
format_row() {
    printf "%-14s │  %-24s │  %s\n" "$1" "$2" "$3"
}

MENU_ITEMS=""
for item in "${SHORTCUTS[@]}"; do
    IFS=$'\t' read -r cat key desc <<< "$item"
    MENU_ITEMS+="$(format_row "$cat" "$key" "$desc")"$'\n'
done

# Show in Rofi
echo -e "$MENU_ITEMS" | rofi -dmenu \
    -i \
    -p "⌨️ Shortcuts" \
    -theme-str 'window { width: 850px; } listview { lines: 15; }'
