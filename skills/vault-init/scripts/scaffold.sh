#!/usr/bin/env bash
# scaffold.sh — Initialize an Obsidian vault for the daily-session / checkpoint / end-day / daily-gn workflow.
#
# Usage:
#   scaffold.sh <vault-path> [--force]
#
# Idempotent: skips existing files unless --force is passed. Always creates missing directories.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$(cd "$SCRIPT_DIR/../assets" && pwd)"

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
VAULT_PATH=""
FORCE=0

for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        -h|--help)
            sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        --*) echo "unknown flag: $arg" >&2; exit 2 ;;
        *)
            if [[ -z "$VAULT_PATH" ]]; then
                VAULT_PATH="$arg"
            else
                echo "unexpected extra arg: $arg" >&2; exit 2
            fi
            ;;
    esac
done

if [[ -z "$VAULT_PATH" ]]; then
    echo "usage: scaffold.sh <vault-path> [--force]" >&2
    exit 2
fi

# Resolve to absolute path (works on macOS; -m means file doesn't need to exist)
mkdir -p "$VAULT_PATH"
VAULT_PATH="$(cd "$VAULT_PATH" && pwd)"

# ---------------------------------------------------------------------------
# Safety
# ---------------------------------------------------------------------------
# Refuse to scaffold inside a code project unless --force
for marker in ".git" "package.json" "Cargo.toml" "pyproject.toml" "go.mod"; do
    if [[ -e "$VAULT_PATH/$marker" && $FORCE -eq 0 ]]; then
        echo "refusing: $VAULT_PATH contains $marker — this looks like a code project, not a vault." >&2
        echo "pass --force to override." >&2
        exit 3
    fi
done

# ---------------------------------------------------------------------------
# Directories
# ---------------------------------------------------------------------------
mkdir -p "$VAULT_PATH/local/journals"
mkdir -p "$VAULT_PATH/local/daily-gn/.tracking"
mkdir -p "$VAULT_PATH/local/ai-chats/transcripts"
mkdir -p "$VAULT_PATH/local/ai-chats/claude-code"
mkdir -p "$VAULT_PATH/local/templates"
mkdir -p "$VAULT_PATH/local/local-projects"

# ---------------------------------------------------------------------------
# Files (idempotent unless --force)
# ---------------------------------------------------------------------------
TODAY="$(date +%Y-%m-%d)"
VAULT_NAME="$(basename "$VAULT_PATH")"

# escape for safe sed replacement (slashes only — these strings shouldn't have
# special sed chars beyond /)
sed_esc() { printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'; }
TODAY_ESC="$(sed_esc "$TODAY")"
VAULT_PATH_ESC="$(sed_esc "$VAULT_PATH")"
VAULT_NAME_ESC="$(sed_esc "$VAULT_NAME")"

write_file() {
    local src="$1" dst="$2"
    if [[ -e "$dst" && $FORCE -eq 0 ]]; then
        echo "  skip (exists):  ${dst#$VAULT_PATH/}"
        return
    fi
    cp "$src" "$dst"
    # template substitution (only files using {{...}} placeholders)
    sed -i.bak \
        -e "s/{{date}}/$TODAY_ESC/g" \
        -e "s/{{created_date}}/$TODAY_ESC/g" \
        -e "s/{{vault_path}}/$VAULT_PATH_ESC/g" \
        -e "s/{{vault_name}}/$VAULT_NAME_ESC/g" \
        "$dst"
    rm -f "$dst.bak"
    echo "  wrote:          ${dst#$VAULT_PATH/}"
}

echo "Scaffolding vault at: $VAULT_PATH"
echo

write_file "$ASSETS_DIR/Daily Journal Template.md"  "$VAULT_PATH/local/templates/Daily Journal Template.md"
write_file "$ASSETS_DIR/_open-threads.template.md"  "$VAULT_PATH/local/journals/_open-threads.md"
write_file "$ASSETS_DIR/CLAUDE.md.template"         "$VAULT_PATH/CLAUDE.md"
write_file "$ASSETS_DIR/.claude-vault.json.template" "$VAULT_PATH/.claude-vault.json"

# ---------------------------------------------------------------------------
# .gitignore for the vault (so future git init doesn't track tracking JSONL etc.)
# Only created if missing — never overwrite a user's existing one.
# ---------------------------------------------------------------------------
GITIGNORE="$VAULT_PATH/.gitignore"
if [[ ! -e "$GITIGNORE" ]]; then
    cat > "$GITIGNORE" <<'EOF'
# Obsidian internal state
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.obsidian/cache

# Tracking JSONL is regenerable from transcripts
local/daily-gn/.tracking/

# macOS
.DS_Store
EOF
    echo "  wrote:          .gitignore"
fi

echo
echo "Done."
echo
echo "Next:"
echo "  - Verify auto-detect:    bash -c 'source \"\$HOME/.config/claude-code/hooks/lib/config.sh\" && get_vault_path \"$VAULT_PATH\"'"
echo "  - Expected output:       $VAULT_PATH/local"
echo "  - First daily session:   /daily-session --light"
