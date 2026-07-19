#!/usr/bin/env bash
# patch-config.sh — Patch ~/.config/claude-code/hooks/lib/config.sh to walk up
# from CWD looking for a vault marker (`.claude-vault.json` or `local/journals/`)
# BEFORE consulting the global config file. This makes new vaults auto-detected
# without rewriting the global config.
#
# Idempotent: detects if the patch is already applied and exits cleanly.
#
# Usage:
#   patch-config.sh              # dry-run: print the diff that would be applied
#   patch-config.sh --apply      # apply the patch in place (creates a .bak backup)
#   patch-config.sh --revert     # restore from the .bak backup

set -euo pipefail

CONFIG_SH="$HOME/.config/claude-code/hooks/lib/config.sh"
BACKUP="$CONFIG_SH.preinit.bak"
SENTINEL="# vault-init: CWD walk-up patch v1"

MODE="dry-run"
for arg in "$@"; do
    case "$arg" in
        --apply)  MODE="apply" ;;
        --revert) MODE="revert" ;;
        -h|--help)
            sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "unknown arg: $arg" >&2; exit 2 ;;
    esac
done

if [[ ! -f "$CONFIG_SH" ]]; then
    echo "config.sh not found at $CONFIG_SH" >&2
    echo "This script patches the hooks shipped with claude-code-workflow." >&2
    echo "If the path is different on your system, edit CONFIG_SH at the top of this script." >&2
    exit 3
fi

# ---------------------------------------------------------------------------
# Revert
# ---------------------------------------------------------------------------
if [[ "$MODE" == "revert" ]]; then
    if [[ ! -f "$BACKUP" ]]; then
        echo "no backup at $BACKUP — nothing to revert" >&2
        exit 1
    fi
    cp "$BACKUP" "$CONFIG_SH"
    echo "reverted $CONFIG_SH from $BACKUP"
    exit 0
fi

# ---------------------------------------------------------------------------
# Already-applied check
# ---------------------------------------------------------------------------
if grep -qF "$SENTINEL" "$CONFIG_SH"; then
    echo "patch already applied to $CONFIG_SH"
    exit 0
fi

# ---------------------------------------------------------------------------
# The new function body, written into a temp file then spliced in.
# ---------------------------------------------------------------------------
NEW_FUNC="$(cat <<'PATCH'
# Get vault path with fallbacks:
# 1. CWD walk-up to find a vault marker (.claude-vault.json or local/journals/) — vault-init: CWD walk-up patch v1
# 2. Config file
# 3. Environment variable (legacy)
# 4. CWD direct check (legacy fallback)
get_vault_path() {
    local cwd="${1:-$(pwd)}"
    local vault_path=""

    # ----- (1) CWD walk-up: look for a vault marker upward from cwd
    local dir="$cwd"
    while [[ -n "$dir" && "$dir" != "/" ]]; do
        if [[ -f "$dir/.claude-vault.json" ]]; then
            vault_path="$dir/local"
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
PATCH
)"

# ---------------------------------------------------------------------------
# Build the patched file in memory by splicing in the new function block.
# Uses Python for sane multi-line string handling.
# ---------------------------------------------------------------------------
PATCHED="$(NEW_FUNC="$NEW_FUNC" python3 - "$CONFIG_SH" <<'PY'
import os, sys, re

src_path = sys.argv[1]
new_func = os.environ["NEW_FUNC"]

with open(src_path) as f:
    src = f.read()

# Match the existing function block: the leading "# Get vault path with fallbacks:"
# comment through the closing "}" at the start of a line.
pattern = re.compile(
    r"^# Get vault path with fallbacks:.*?\n}\n",
    flags=re.DOTALL | re.MULTILINE,
)

if not pattern.search(src):
    sys.stderr.write("could not locate get_vault_path() block to replace\n")
    sys.exit(4)

patched = pattern.sub(new_func.rstrip() + "\n", src, count=1)
sys.stdout.write(patched)
PY
)"
PY_RC=$?
if [[ $PY_RC -ne 0 ]]; then
    exit $PY_RC
fi

# Did we actually emit the sentinel?
if ! grep -qF "vault-init: CWD walk-up patch v1" <<<"$PATCHED"; then
    echo "patch did not include the sentinel — aborting." >&2
    exit 4
fi

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
if [[ "$MODE" == "dry-run" ]]; then
    echo "--- dry-run: showing diff (use --apply to write) ---"
    diff -u "$CONFIG_SH" <(printf '%s\n' "$PATCHED") || true
    exit 0
fi

# Apply
cp "$CONFIG_SH" "$BACKUP"
printf '%s\n' "$PATCHED" > "$CONFIG_SH"
echo "patched $CONFIG_SH"
echo "backup at $BACKUP"
echo
echo "verify:  source \"$CONFIG_SH\" && get_vault_path /some/vault/path"
echo "revert:  $0 --revert"
