#!/usr/bin/env bash
# ##############################################################################
# Systemd Coredump Crash Watcher
# Monitors journalctl for process crashes and offers 1-click AI diagnosis
# ##############################################################################

set -uo pipefail

# Systemd coredump journal MESSAGE_ID
readonly COREDUMP_MESSAGE_ID="fc2e22bc6ee647b6b90729ab34a250b1"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEDUPE_SECONDS=60

declare -A LAST_NOTIFIED

# Check if required tools exist
if ! command -v journalctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "[crash-watch] journalctl or jq missing. Exiting." >&2
    exit 1
fi

handle_crash() {
    local comm="$1"
    local pid="$2"
    local exe="$3"
    local signal="$4"

    # Avoid self-monitoring or shell loops
    if [[ "$comm" =~ (crash-watch|crash-diagnose|notify-send|mako) ]]; then
        return
    fi

    local now
    now=$(date +%s)
    local last=${LAST_NOTIFIED[$comm]:-0}

    # Deduplicate repeated crashes within the dedupe window
    if (( now - last < DEDUPE_SECONDS )); then
        return
    fi
    LAST_NOTIFIED[$comm]=$now

    # Get current default agent name for notification text
    local agent="AI"
    if [[ -f "${HOME}/.config/default-agent" ]]; then
        agent=$(cat "${HOME}/.config/default-agent" | tr -d '[:space:]')
    fi

    # Send desktop notification with clickable action
    # notify-send blocks until clicked or expired
    local action
    action=$(notify-send -u critical -a "Crash Watch" -i dialog-error \
        "Process crashed: ${comm}" \
        "Click to diagnose with ${agent} (PID: ${pid})" \
        --action="diagnose=Diagnose with AI" 2>/dev/null || true)

    if [[ "$action" == "diagnose" || "$action" == "default" ]]; then
        "${SCRIPT_DIR}/crash-diagnose.sh" "$pid" "$comm" "$exe" "$signal" &
    fi
}

echo "[crash-watch] Listening for coredump events..."

journalctl -f -n 0 -o json "MESSAGE_ID=${COREDUMP_MESSAGE_ID}" 2>/dev/null |
while IFS= read -r entry; do
    IFS=$'\t' read -r uid comm pid exe signal < <(
        jq -r 'def f: if . == null or . == "" then "-" else . end;
               [(._UID | f),
                (.COREDUMP_COMM | f),
                (.COREDUMP_PID | f),
                (.COREDUMP_EXE | f),
                (.COREDUMP_SIGNAL_NAME | f)] | @tsv' <<<"$entry" 2>/dev/null
    )

    # Only process current user's crashes with valid numeric PID
    if [[ "$pid" =~ ^[0-9]+$ ]] && [[ "$uid" -eq "$UID" ]]; then
        handle_crash "$comm" "$pid" "$exe" "$signal" &
    fi
done
