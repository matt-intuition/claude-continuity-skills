---
name: vault-init
description: Scaffold a new Obsidian vault to support the daily-session / checkpoint / end-day workflows. Use when the user wants to "set up this vault", "init this vault for workflows", "make this work as a Claude journaling vault", or invokes `/vault-init`. Creates the canonical `local/` subtree (journals, daily-gn, ai-chats/transcripts, ai-chats/claude-code, templates, local-projects), seeds the Daily Journal template and an empty `_open-threads.md` skeleton, writes a `.claude-vault.json` marker so the hooks auto-detect the vault from CWD, and drops a vault-local `CLAUDE.md` describing the conventions.
---

# vault-init

End-to-end skill for initializing a new Obsidian vault so the user-level workflow commands (`/daily-session`, `/checkpoint`, `/end-day`, `/daily-resume`) write into it automatically.

## When to trigger

- User says "set up this vault" / "init this vault for workflows" / "make this a journaling vault"
- User invokes `/vault-init`
- User has manually created a new Obsidian vault, launched a Claude session inside it, and wants the daily-session workflow available
- User pastes a path and says "scaffold the journaling workflow at this vault"

## When NOT to trigger

- The directory already contains a `local/journals/` tree — it's already initialized
- The directory is not the intended vault root (looks like a project directory, a code repo, or a tmp folder)
- Skip if `.claude-vault.json` already exists unless user explicitly asks to re-init

## What this does

Creates this structure at the target vault root (default: CWD):

```
<vault>/
├── local/
│   ├── journals/
│   │   └── _open-threads.md          # Rolling threads doc (skeleton, no personal threads)
│   ├── daily-gn/
│   │   └── .tracking/                # JSONL accomplishment tracking (hook writes here)
│   ├── ai-chats/
│   │   ├── transcripts/              # Daily session transcripts per date
│   │   └── claude-code/              # Cross-session Claude Code export summaries
│   ├── templates/
│   │   └── Daily Journal Template.md # Obsidian template for daily journal pages
│   └── local-projects/               # Personal scratch projects
├── .claude-vault.json                # Vault marker — read by hooks/commands for auto-detect
└── CLAUDE.md                          # Vault-level instructions inheritable by any Claude session here
```

## Step-by-step

### 1. Confirm target

- Default target = current working directory.
- Run `pwd` and present the path back to the user. Ask "Initialize the vault at `<path>`? (Y/n)"
- If the user passed a path as an argument, use that instead and confirm.
- **Refuse** if the target looks like a project directory (contains `.git/`, `package.json`, `Cargo.toml`, etc.) UNLESS the user explicitly overrides — a vault should be its own directory.
- **Stop and warn** if `<target>/local/journals/` or `<target>/.claude-vault.json` already exists. Ask whether to (a) skip, (b) re-init only missing pieces, or (c) overwrite (destructive).

### 2. Scaffold

Run the bundled scaffolder script with the confirmed target path:

```bash
bash "$HOME/.claude/skills/vault-init/scripts/scaffold.sh" "<target-path>"
```

The script is idempotent — it creates missing directories, copies missing templates, but does NOT overwrite existing files unless `--force` is passed.

What the script creates:
- All directories listed above (`mkdir -p`)
- `local/templates/Daily Journal Template.md` — copied from `~/.claude/skills/vault-init/assets/Daily Journal Template.md`
- `local/journals/_open-threads.md` — copied from `assets/_open-threads.template.md` with today's date filled into the `last_updated` frontmatter
- `CLAUDE.md` — copied from `assets/CLAUDE.md.template`
- `.claude-vault.json` — copied from `assets/.claude-vault.json.template` with `name`, `created`, and `vault_path` filled in

### 3. Verify auto-detect works

After scaffolding, run a one-liner to confirm the hook config will pick up the new vault:

```bash
bash -c 'source "$HOME/.config/claude-code/hooks/lib/config.sh" && get_vault_path "<target-path>"'
```

Expected output: `<target-path>/local`

If output is empty or points to a different vault, the installed `config.sh` doesn't include the CWD walk-up logic yet. The install-instructions are in `~/.claude/skills/vault-init/scripts/patch-config.sh` — the user can review and apply it manually, OR you can apply it for them with their permission. (The `config.sh` shipped with this repo already includes the walk-up, so a fresh install needs no patching.)

### 4. Report back

Tell the user:
- The exact path that was scaffolded
- What `/daily-session`, `/checkpoint`, `/end-day` will now write here (because auto-detect picks up the vault marker)
- The path to `_open-threads.md` — they should review and populate it before their first `/end-day` runs
- That Obsidian will create its own `.obsidian/` config the first time they open the dir as a vault

### 5. Offer a first-run

Ask: "Want me to run `/daily-session --light` now to verify the workflow is wired up?" — light mode skips file creation but exercises the read path, confirming the vault is detected.

## File details

### `Daily Journal Template.md`

The canonical daily journal template. Sections: Mood Check, Gratitude, Today's Focus, Notes and Ideas, Open Work Threads (mirrored from `_open-threads`), Waiting For, Claude Sessions, Seeds for Publishing, Day's End.

### `_open-threads.md` skeleton

Structural skeleton only — the live working doc of a **three-file system** (`_open-threads.md` + `_open-threads-archive.md` + `_open-threads-changelog.md`; the latter two are created lazily by `/end-day`). Frontmatter conventions, a `## 🗓️ Recent Activity (last 14 days)` window, section headers (`## ⏰ Time-Critical — This Week`, `## Owned — Open Work Threads`, `## Waiting For`), and inline comments explaining how to use each section. NO personal threads from any other vault.

### `CLAUDE.md` (vault-local)

Tells any Claude session launched in this vault:
- This is an Obsidian vault initialized for the daily-session workflow
- Workflow content lives in `local/`
- `/daily-session`, `/checkpoint`, `/end-day` are the primary commands
- The `_open-threads.md` doc is the source of truth for in-flight work
- Wikilinks (`[[name]]`) are the linking convention

### `.claude-vault.json`

Marker file with metadata:
```json
{
  "name": "<vault-name>",
  "created": "<ISO-8601-date>",
  "vault_path": "<absolute-path>",
  "conventions_version": "1.0",
  "workflow": "daily-session"
}
```

The hook's `get_vault_path()` walks up from CWD looking for this file to identify the vault root.

## Notes

- The skill does NOT modify the global `~/.config/claude-code-workflow/config.json` — that stays pointing at whatever primary vault you configured. The new vault is picked up via CWD walk-up.
- The skill does NOT touch the user-level slash commands. They work unchanged because they use relative `local/...` paths that resolve correctly once the vault is auto-detected.
- The skill is self-contained — all templates ship in `assets/`, no dependency on any other vault being mounted.
- Re-running the skill on an already-initialized vault is safe (idempotent); pass `--force` only to overwrite templates.
- **Repo-link markers:** to bind a project repo to its companion vault, drop a `.claude-vault.json` in the repo root whose `vault_path` points at the vault. The workflow commands walk up from CWD, find the marker, and scope all reads/writes to that vault.
