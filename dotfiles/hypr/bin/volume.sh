#!/usr/bin/env bash
# Keyboard volume controls and a single replacing Mako progress popup.
set -euo pipefail
export LC_ALL=C

# Serialize held/repeated volume keys so an older reading cannot replace a newer one.
exec 9>"${XDG_RUNTIME_DIR:?}/desktop-volume.lock"
flock 9
case "${1:-show}" in
    up)   wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    show) ;;
    *) printf 'Usage: %s {up|down|mute|show}\n' "$0" >&2; exit 2 ;;
esac

state=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
percent=$(awk '{printf "%.0f", $2 * 100}' <<< "$state")
bar=$percent
(( bar > 100 )) && bar=100
if [[ $state == *"[MUTED]"* ]]; then
    label="Muted · ${percent}%"
    icon=audio-volume-muted
    bar=0
else
    label="Volume ${percent}%"
    icon=audio-volume-high
fi
notify-send --app-name=desktop-volume --urgency=low --transient \
    --expire-time=1500 --icon="$icon" \
    --hint=string:x-canonical-private-synchronous:desktop-volume \
    --hint="int:value:$bar" "$label"
