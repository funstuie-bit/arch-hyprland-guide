#!/usr/bin/env bash
# ##############################################################################
# Omarchy-style System Power Menu (Super + Escape)
# ##############################################################################

CHOICE=$(printf "🔒 Lock Screen\n🚪 Log Out\n🔄 Reboot\n🛑 Shut Down\n💤 Suspend" | rofi -dmenu -i -p "⏻ System" -theme-str 'window { width: 400px; } listview { lines: 5; }')

case "$CHOICE" in
    *"Lock"*)
        hyprlock || swaylock
        ;;
    *"Log Out"*)
        hyprctl dispatch exit
        ;;
    *"Reboot"*)
        systemctl reboot
        ;;
    *"Shut Down"*)
        systemctl poweroff
        ;;
    *"Suspend"*)
        systemctl suspend
        ;;
esac
