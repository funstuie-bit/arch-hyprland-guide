#!/usr/bin/env bash
# Plain Hyprland does not launch XDG autostart entries on its own.
# Read this app's preference without executing arbitrary desktop-entry commands.
set -euo pipefail
codexbar_app="$HOME/.local/bin/codexbar-linux"
codexbar_autostart="${XDG_CONFIG_HOME:-$HOME/.config}/autostart/com.steipete.CodexBar.desktop"
[[ -x "$codexbar_app" && -f "$codexbar_autostart" ]] || exit 0
if ! rg -qi '^Hidden\s*=\s*true\s*$' "$codexbar_autostart"; then
    exec "$codexbar_app" --background
fi
