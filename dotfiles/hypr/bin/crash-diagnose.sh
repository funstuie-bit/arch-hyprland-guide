#!/usr/bin/env bash
# ##############################################################################
# AI Crash Diagnosis Launcher
# Invoked when user clicks a crash notification
# ##############################################################################

set -euo pipefail

PID="${1:-}"
COMM="${2:-unknown}"
EXE="${3:-unknown}"
SIGNAL="${4:-unknown}"

AGENT_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/default-agent"
AGENT="agy"
if [[ -f "$AGENT_FILE" ]]; then
    AGENT=$(cat "$AGENT_FILE" | tr -d '[:space:]')
fi
if [[ -z "$AGENT" ]]; then
    AGENT="agy"
fi

# Fetch coredump details
CRASH_REPORT_FILE="/tmp/crash-report-${PID:-$(date +%s)}.txt"
{
    echo "=== Crash Diagnostics ==="
    echo "Process:   ${COMM}"
    echo "PID:       ${PID}"
    echo "Binary:    ${EXE}"
    echo "Signal:    ${SIGNAL}"
    echo "Timestamp: $(date)"
    echo ""
    echo "=== Coredumpctl Backtrace ==="
    if command -v coredumpctl >/dev/null 2>&1 && [[ -n "$PID" ]]; then
        coredumpctl info "$PID" 2>/dev/null | tail -n 40 || echo "No coredump info available."
    else
        echo "No coredump available for PID ${PID}."
    fi
} > "$CRASH_REPORT_FILE"

PROMPT="A process crashed on my machine and I need your help diagnosing it.
Process name: ${COMM}
PID: ${PID}
Executable: ${EXE}
Signal: ${SIGNAL}

Full stack trace and coredump info has been saved to: ${CRASH_REPORT_FILE}

Please analyze this crash, check what caused it, check my configuration in ~/.config/ if relevant, and suggest how to resolve it."

PROMPT_FILE="/tmp/crash-prompt-${PID:-$(date +%s)}.txt"
echo "$PROMPT" > "$PROMPT_FILE"

# Launch agent in Foot terminal
launch_cmd=""
case "$AGENT" in
    claude)
        launch_cmd="claude \"\$(cat '$PROMPT_FILE')\""
        ;;
    codex)
        launch_cmd="codex \"\$(cat '$PROMPT_FILE')\""
        ;;
    opencode)
        launch_cmd="opencode \"\$(cat '$PROMPT_FILE')\""
        ;;
    agy|*)
        launch_cmd="agy \"\$(cat '$PROMPT_FILE')\""
        ;;
esac

foot -T "Crash Diagnosis: ${COMM} (PID: ${PID})" -e bash -c "
echo '==================================================='
echo '🤖 Initializing AI Crash Diagnosis with ${AGENT}...'
echo '==================================================='
echo ''
cat '$PROMPT_FILE'
echo ''
echo '==================================================='
if command -v ${AGENT} >/dev/null 2>&1; then
    ${launch_cmd}
else
    echo 'Warning: Default agent \"${AGENT}\" command not found in PATH.'
    echo 'Opening interactive shell so you can run your preferred agent.'
    exec bash
fi
"
