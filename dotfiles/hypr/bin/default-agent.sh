#!/usr/bin/env bash
# ##############################################################################
# Default AI Agent Selector & Launcher
# Manages ~/.config/default-agent and launches agents in Foot terminal
# ##############################################################################

AGENT_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/default-agent"

get_default_agent() {
    if [[ -f "$AGENT_FILE" ]]; then
        cat "$AGENT_FILE" | tr -d '[:space:]'
    else
        echo ""
    fi
}

pick_agent() {
    local options=(
        "agy       (Google Antigravity CLI)"
        "claude    (Claude Code)"
        "codex     (OpenAI Codex CLI)"
        "opencode  (OpenCode)"
    )

    local choice
    choice=$(printf "%s\n" "${options[@]}" | rofi -dmenu -i -p "🤖 Select Default AI Agent" -theme-str 'window { width: 500px; }')

    if [[ -n "$choice" ]]; then
        local agent
        agent=$(echo "$choice" | awk '{print $1}')
        echo "$agent" > "$AGENT_FILE"
        notify-send -a "AI Agent" "Default Agent Set" "Default agent is now: ${agent}"
        echo "$agent"
    fi
}

launch_agent() {
    local agent
    agent=$(get_default_agent)

    if [[ -z "$agent" ]]; then
        agent=$(pick_agent)
    fi

    if [[ -n "$agent" ]]; then
        foot -T "AI Agent (${agent})" -e bash -c "command -v ${agent} >/dev/null 2>&1 && exec ${agent} || { echo 'Command ${agent} not found. Please install it or select another agent.'; exec bash; }"
    fi
}

case "${1:-}" in
    --launch)
        launch_agent
        ;;
    --pick)
        pick_agent
        ;;
    --get)
        get_default_agent
        ;;
    *)
        agent=$(get_default_agent)
        if [[ -z "$agent" ]]; then
            pick_agent
        else
            launch_agent
        fi
        ;;
esac
