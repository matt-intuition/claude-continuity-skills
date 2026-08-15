#!/bin/bash
# Setup script for claude-continuity-skills
# Installs commands, the vault-init skill, and workflow hooks to their standard locations.
#
# Idempotent: existing files are backed up to <file>.bak before being overwritten.
# It does NOT edit your Claude Code settings.json — it prints the hook-wiring
# snippet for you to add yourself.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CLAUDE_COMMANDS="$HOME/.claude/commands"
CLAUDE_SKILLS="$HOME/.claude/skills"
HOOKS_DIR="$HOME/.config/claude-code/hooks"
CONFIG_DIR="$HOME/.config/claude-code-workflow"

echo "=== claude-continuity-skills setup ==="
echo ""

mkdir -p "$CLAUDE_COMMANDS" "$CLAUDE_SKILLS" "$HOOKS_DIR/lib" "$CONFIG_DIR"

# Copy a file, backing up any existing destination to .bak first
install_file() {
    local src="$1" dst="$2"
    if [[ -f "$dst" ]] && ! cmp -s "$src" "$dst"; then
        cp "$dst" "$dst.bak"
        echo "  backup:  ${dst/#$HOME/~}.bak"
    fi
    cp "$src" "$dst"
    echo "  install: ${dst/#$HOME/~}"
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------
echo "Installing commands -> ~/.claude/commands/"
for cmd in "$SCRIPT_DIR/commands/"*.md; do
    [[ -f "$cmd" ]] && install_file "$cmd" "$CLAUDE_COMMANDS/$(basename "$cmd")"
done

# ---------------------------------------------------------------------------
# Skills
# ---------------------------------------------------------------------------
echo ""
echo "Installing onboard skill -> ~/.claude/skills/onboard/"
mkdir -p "$CLAUDE_SKILLS/onboard"
install_file "$SCRIPT_DIR/skills/onboard/SKILL.md" "$CLAUDE_SKILLS/onboard/SKILL.md"

echo ""
echo "Installing vault-init skill -> ~/.claude/skills/vault-init/"
mkdir -p "$CLAUDE_SKILLS/vault-init/scripts" "$CLAUDE_SKILLS/vault-init/assets"
install_file "$SCRIPT_DIR/skills/vault-init/SKILL.md" "$CLAUDE_SKILLS/vault-init/SKILL.md"
for f in "$SCRIPT_DIR/skills/vault-init/scripts/"*; do
    [[ -f "$f" ]] || continue
    install_file "$f" "$CLAUDE_SKILLS/vault-init/scripts/$(basename "$f")"
    chmod +x "$CLAUDE_SKILLS/vault-init/scripts/$(basename "$f")"
done
# assets include a dotfile template — copy explicitly
for f in "$SCRIPT_DIR/skills/vault-init/assets/"* "$SCRIPT_DIR/skills/vault-init/assets/".claude-vault.json.template; do
    [[ -f "$f" ]] || continue
    install_file "$f" "$CLAUDE_SKILLS/vault-init/assets/$(basename "$f")"
done

# ---------------------------------------------------------------------------
# Hooks
# ---------------------------------------------------------------------------
echo ""
echo "Installing hooks -> ~/.config/claude-code/hooks/"
for hook in "$SCRIPT_DIR/hooks/"*.sh; do
    [[ -f "$hook" ]] || continue
    install_file "$hook" "$HOOKS_DIR/$(basename "$hook")"
    chmod +x "$HOOKS_DIR/$(basename "$hook")"
done
for lib in "$SCRIPT_DIR/hooks/lib/"*; do
    [[ -f "$lib" ]] || continue
    install_file "$lib" "$HOOKS_DIR/lib/$(basename "$lib")"
    chmod +x "$HOOKS_DIR/lib/$(basename "$lib")"
done

# ---------------------------------------------------------------------------
# Done — print the settings.json wiring
# ---------------------------------------------------------------------------
echo ""
echo "=== Setup complete ==="
echo ""
echo "One manual step left: wire the hooks into Claude Code."
echo "Add this to ~/.claude/settings.json (merge with any existing \"hooks\" key):"
echo ""
cat <<'EOF'
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "~/.config/claude-code/hooks/pre-compact-checkpoint.sh" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "~/.config/claude-code/hooks/track-work.sh" }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "~/.config/claude-code/hooks/safety-check.sh" }
        ]
      }
    ]
  }
}
EOF
echo ""
echo "(The PreToolUse safety-check hook is optional — omit it if you don't want"
echo " git/rm guardrails.)"
echo ""
echo "Next steps:"
echo "  1. Restart or open a new Claude Code session"
echo "  2. cd into (or create) your vault directory and run /vault-init"
echo "  3. Run /onboard — a short interview that records your platforms (task"
echo "     tracker, email, calendar, docs, CRM, share-out channel) and cadence"
echo "     ceremonies into local/journals/_foundation.md. Every command reads it."
echo "  4. Write your morning reflections, then run /daily-session"
echo ""
echo "Available commands & skills:"
echo "  /vault-init           - Scaffold a vault (local/ tree, templates, marker)"
echo "  /onboard              - Configure platforms + cadence (foundation manifest)"
echo "  /daily-session        - Start the day (reads yesterday's handoff)"
echo "  /daily-resume         - Catch a fresh window up on today (read-only)"
echo "  /checkpoint           - Timestamped progress checkpoint"
echo "  /end-day              - Wrap up: handoff, open-threads roll, daily summary"
echo "  /export-conversation  - Export any session to your vault"
