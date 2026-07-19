#!/bin/bash
# Shared config loader for Claude Code workflow hooks
# Source this file to get access to config values

CONFIG_FILE="$HOME/.config/claude-code-workflow/config.json"

# Read a value from the config file
# Usage: get_config "key"
get_config() {
    local key="$1"
    if [[ -f "$CONFIG_FILE" ]]; then
        python3 -c "
import json
with open('$CONFIG_FILE') as f:
    config = json.load(f)
print(config.get('$key', ''))
" 2>/dev/null
    fi
}

# Get vault path with fallbacks:
# 1. CWD walk-up to find a vault marker (.claude-vault.json or local/journals/)
#    — a marker in a project repo may point at a companion vault via vault_path
# 2. Config file (obsidian_vault_path)
# 3. Environment variable (legacy)
# 4. CWD direct check (legacy fallback)
get_vault_path() {
    local cwd="${1:-$(pwd)}"
    local vault_path=""

    # ----- (1) CWD walk-up: look for a vault marker upward from cwd
    local dir="$cwd"
    while [[ -n "$dir" && "$dir" != "/" ]]; do
        if [[ -f "$dir/.claude-vault.json" ]]; then
            # If the marker declares a vault_path (repo-link marker), follow it
            local declared
            declared=$(python3 -c "
import json
try:
    with open('$dir/.claude-vault.json') as f:
        print(json.load(f).get('vault_path', ''))
except Exception:
    print('')
" 2>/dev/null)
            if [[ -n "$declared" && -d "$declared" ]]; then
                vault_path="$declared/local"
            else
                vault_path="$dir/local"
            fi
            break
        fi
        if [[ -d "$dir/local/journals" && -d "$dir/local/daily-gn" ]]; then
            vault_path="$dir/local"
            break
        fi
        dir="$(dirname "$dir")"
    done

    # ----- (2) Config file
    if [[ -z "$vault_path" ]]; then
        vault_path=$(get_config "obsidian_vault_path")
    fi

    # ----- (3) Legacy env var
    if [[ -z "$vault_path" ]]; then
        vault_path="${OBSIDIAN_VAULT_PATH:-}"
    fi

    # ----- (4) CWD direct check (legacy)
    if [[ -z "$vault_path" && -d "$cwd/local/ai-chats/transcripts" ]]; then
        vault_path="$cwd"
    fi

    echo "$vault_path"
}

# Export for convenience
export CONFIG_FILE
