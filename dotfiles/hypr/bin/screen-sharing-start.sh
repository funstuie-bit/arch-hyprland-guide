#!/usr/bin/env bash
# Start only after this Hyprland session supplies its Wayland environment.
set -euo pipefail
[[ -f "$HOME/.config/wayvnc/config" ]] || exit 0
systemctl --user is-enabled --quiet wayvnc.service || exit 0
systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP
exec systemctl --user start wayvnc.service
