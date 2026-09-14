#!/usr/bin/env bash
# ##############################################################################
# Shortcuts Cheatsheet for Hyprland (Super + K)
# Displays a searchable, categorized list of shortcuts in Rofi
# ##############################################################################

SHORTCUTS=(
    "🚀 APPS	Super + Return	Open Foot terminal"
    "🚀 APPS	Super + Space	Open Application Launcher (Rofi)"
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
    "🪟 WINDOWS	Super + Q	Close active window"
    "🪟 WINDOWS	Super + V	Toggle floating mode"
    "🪟 WINDOWS	Super + F	Toggle fullscreen"
    "🪟 WINDOWS	Super + Arrow Keys	Navigate focus between windows"
    "🪟 WINDOWS	Super + 1..9, 0	Switch to workspace 1 - 10"
    "🪟 WINDOWS	Super + Shift + 1..0	Move active window to workspace"
    "📸 CAPTURE	Super + Shift + S	Select screen area with mouse & copy screenshot"
    "📸 CAPTURE	PrintScreen	Save full screenshot to ~/Pictures/Screenshots/"
    "🔊 AUDIO	Waybar Volume Click	Toggle mute"
    "🔊 AUDIO	Waybar Volume Right-Click	Open Pavucontrol sound mixer"
    "🔊 AUDIO	Waybar Volume Scroll	Increase / decrease volume"
    "🌐 NETWORK	Waybar Network Click	Open Network Manager connection editor"
    "🔒 SYSTEM	Super + L	Lock screen (hyprlock)"
    "🔒 SYSTEM	Super + Shift + Q	Exit Hyprland desktop session"
    "💻 SHELL	z <dir>	Smart jump to directory (zoxide)"
    "💻 SHELL	Ctrl + R	Fuzzy search command history (fzf)"
    "💻 SHELL	dua i	Interactive disk usage analyzer"
    "💻 SHELL	tmux	Terminal workspace / session multiplexer"
)

# Format rows for Rofi
format_row() {
    printf "%-12s │  %-26s │  %s\n" "$1" "$2" "$3"
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
    -theme-str 'window { width: 800px; } listview { lines: 15; }'
