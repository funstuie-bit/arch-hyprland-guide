#!/usr/bin/env bash
# ##############################################################################
# Screenshot Utility for Hyprland
# Saves to ~/Pictures/Screenshots and copies to clipboard (Omarchy style)
# ##############################################################################

SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOTS_DIR"

TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
TARGET_FILE="$SCREENSHOTS_DIR/screenshot-${TIMESTAMP}.png"

MODE="${1:-area}"

if [[ "$MODE" == "area" ]]; then
    GEOM=$(slurp 2>/dev/null)
    # If user cancelled selection, exit cleanly
    [[ -z "$GEOM" ]] && exit 0
    grim -g "$GEOM" "$TARGET_FILE"
elif [[ "$MODE" == "full" ]]; then
    grim "$TARGET_FILE"
fi

if [[ -f "$TARGET_FILE" ]]; then
    wl-copy < "$TARGET_FILE"
    notify-send -i "$TARGET_FILE" "Screenshot Captured" "Saved to Screenshots and copied to clipboard.\nReady to paste with Cmd+V."
fi
