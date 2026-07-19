# claude-continuity-skills

Session continuity for [Claude Code](https://claude.com/claude-code) + [Obsidian](https://obsidian.md). A set of slash commands, a scaffolding skill, and hooks that turn your vault into a durable memory layer: every day gets a journal, a session transcript, timestamped checkpoints, and an end-of-day handoff that tomorrow's session reads back — so a new Claude window always knows where you left off. Multiple projects live in separate "lanes" (one vault each) that never cross-contaminate, resolved automatically from wherever you launch Claude.

## Lineage

Started from and inspired by [jonathanprozzi/claude-utils](https://github.com/jonathanprozzi/claude-utils) (MIT), which established the daily-session / checkpoint / end-day / export loop. This repo evolves that base with:

- **Multi-vault lane isolation** — CWD-first vault resolution via `.claude-vault.json` markers. Each project lane gets its own vault; commands hard-scope every read/write to the active lane and stop-and-ask rather than guess.
- **`/daily-resume`** — read-only catch-up for fresh windows mid-day, so parallel terminals share one day-state without re-running setup.
- **Rolling open-threads system** — a three-file `_open-threads` / `-archive` / `-changelog` design that keeps the live doc small while losing nothing.
- **Cadence manifest** — a trigger → workflow map (`_cadence.md`) that proposes the day's recurring runs each morning.
- **`/vault-init` skill** — one command to scaffold a new vault with all conventions in place.
- Plus: opt-in checkpoint archiving, an accomplishment-tracking PostToolUse hook, a PreCompact auto-checkpoint hook, and a daily wrap-up summary compiled at `/end-day`.

## The Daily Workflow

```
        MORNING                     DURING THE DAY                    EVENING
  ┌──────────────────┐      ┌────────────────────────────┐      ┌─────────────────┐
  │  /daily-session  │      │  work ... /checkpoint ...  │      │    /end-day     │
  │                  │      │  work ... /checkpoint ...  │      │                 │
  │ · journal +      │ ───> │                            │ ───> │ · handoff into  │
  │   reflections    │      │  new terminal window?      │      │   transcript    │
  │ · reads yester-  │      │  └── /daily-resume         │      │ · open-threads  │
  │   day's handoff  │      │      (read-only catch-up)  │      │   roll + archive│
  │ · today's goals  │      │                            │      │ · daily wrap-up │
  │ · cadence runs   │      │  (PreCompact hook auto-    │      │   summary       │
  │   proposed       │      │   checkpoints on compact)  │      │                 │
  └──────────────────┘      └────────────────────────────┘      └─────────────────┘
                                                                        │
                              tomorrow's /daily-session reads the handoff
```

Everything lands in your vault under `local/`:

- `local/journals/YYYY-MM-DD.md` — daily journal (mood, gratitude, focus, day's end)
- `local/ai-chats/transcripts/YYYY-MM-DD/daily-session-YYYY-MM-DD.md` — the day's transcript: goals, session log, checkpoints, handoff
- `local/journals/_open-threads.md` — rolling source of truth for in-flight work + waiting-for asks
- `local/daily-gn/YYYY-MM-DD.md` — human-readable daily wrap-up (share layer + private tracking layer)
- `local/daily-gn/.tracking/YYYY-MM-DD.jsonl` — automatic accomplishment log (written by the PostToolUse hook)

## Multi-project lanes

Each project lane — work, side project, personal — lives in its **own vault** with its own journals, transcripts, and `_open-threads.md`. Lanes are mutually exclusive: a session in one lane never reads or writes another lane's files.

**How resolution works (CWD-first):**

1. Every command walks **up** from the current working directory looking for a `.claude-vault.json` marker (stopping at `$HOME`).
2. The marker's `vault_path` names the active vault. A marker inside a vault points to itself.
3. **Repo-link markers:** drop a `.claude-vault.json` in a project repo whose `vault_path` points at that repo's companion vault — sessions launched from the repo then journal into the right lane automatically.
4. **No marker found → stop and ask.** Commands list the vaults on your machine that carry a marker and ask which lane the session belongs to (offering to drop a repo marker for next time). They never guess by recency and never fall through to another lane.

`/vault-init` scaffolds a new lane in one step: the `local/` subtree, templates, the open-threads skeleton, a vault-local `CLAUDE.md`, and the marker file.

## Prerequisites

- [Claude Code](https://claude.com/claude-code) CLI
- [Obsidian](https://obsidian.md) (optional but recommended — the files are plain markdown either way)
- macOS or Linux, `bash`, `python3` (used by the hooks; some date flags in the hooks are macOS-flavored)
- Optional integrations the commands can use if present: a calendar/email MCP connector, a task tracker (Linear/Jira/GitHub Issues). Everything degrades gracefully without them.

## Installation

### With setup.sh

```bash
git clone https://github.com/matt-intuition/claude-continuity-skills.git
cd claude-continuity-skills
./setup.sh
```

The installer copies the three groups to their destinations (backing up anything it would overwrite to `.bak`), then **prints** the settings.json hook-wiring snippet — it never edits your settings for you.

### Manual copy

| What | From | To |
|------|------|----|
| Commands | `commands/*.md` | `~/.claude/commands/` |
| vault-init skill | `skills/vault-init/` | `~/.claude/skills/vault-init/` |
| Hooks | `hooks/*.sh`, `hooks/lib/*` | `~/.config/claude-code/hooks/`, `~/.config/claude-code/hooks/lib/` (make the scripts executable) |

Then wire the hooks into `~/.claude/settings.json` (merge with any existing `"hooks"` key):

```json
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
```

- **PreCompact** auto-writes a checkpoint (with a full-transcript archive) into today's session transcript before Claude compacts context — nothing is lost to compaction.
- **PostToolUse** silently logs high-signal events (git commits, file creation, skill runs, example MCP writes) to the day's tracking JSONL, which `/end-day` reads.
- **PreToolUse** (optional) is a safety guardrail blocking destructive git/rm/database commands; omit it if you don't want that.

## Getting Started

1. Create (or pick) a directory for your first vault and start Claude Code inside it.
2. Run `/vault-init` — it scaffolds `local/`, the templates, the open-threads skeleton, and the `.claude-vault.json` marker.
3. Open the vault in Obsidian (optional) and write your morning reflections in today's journal — or just run `/daily-session` and answer the prompts in chat.
4. Work. Run `/checkpoint` at logical breakpoints; open extra windows freely and run `/daily-resume` in them.
5. Run `/end-day` in the evening. Tomorrow's `/daily-session` picks up exactly where you left off.

## Command reference

| Command | What it does |
|---------|--------------|
| `/daily-session` | Starts the day: creates/reads today's journal, reads the previous handoff and recent exports, reads open-threads, evaluates the cadence manifest, creates the day's transcript, greets with full context. `--light` skips file creation. |
| `/checkpoint [note]` | Appends a timestamped checkpoint to the transcript, updates the daily note's checkpoint count, and replies with a goal-progress table. `--archive` also exports the full conversation. |
| `/daily-resume` | Read-only: catches a fresh window up on today's session (transcript + journal + open-threads) and replies with the same goal-progress table. Never writes. |
| `/end-day [--date]` | Wraps the day: writes the Session Handoff, rolls the open-threads system, optionally syncs your task tracker, compiles the daily wrap-up summary, and runs a report-by-exception verification strip. Handles past-midnight sessions. |
| `/export-conversation` | Exports any Claude Code session (summary and/or full transcript, rich frontmatter, wiki-links) into the vault and links it from today's daily note. |
| `/vault-init` (skill) | Scaffolds a new vault/lane with all conventions in place. |

## Customization

- **Cadence manifest** — create `local/journals/_cadence.md` in a vault and list your recurring rituals as triggers (day-of-week, calendar events, cycle position). `/daily-session` proposes matching runs each morning as trackable goals; `/end-day` can verify the evening rows. There is no required schema — the commands read it as prose+tables.
- **Task tracker** — the tracker steps in `/daily-session`, `/checkpoint`, and `/end-day` are optional and tool-agnostic (Linear/Jira/GitHub Issues via MCP or CLI). With no tracker configured they skip silently.
- **Comms sweeps** — if your routine includes a recurring inbox/messaging triage, list it in the cadence manifest; the commands will propose it at the right times.
- **Tracking matchers** — `hooks/track-work.sh` ships with matchers for git commits, file creation, skill runs, and a couple of example MCP tools; add cases for the MCP write tools you actually use.
- **Config file** — `~/.config/claude-code-workflow/config.json` holds the legacy fallback `obsidian_vault_path` and `/export-conversation` preferences. With per-vault markers in place you rarely need it.
- **Safety hook env switches** — `CLAUDE_SAFETY_ALLOW_PUSH=1`, `CLAUDE_SAFETY_ALLOW_FORCE_LEASE=1`, `CLAUDE_SAFETY_ALLOW_BRANCH_DELETE=1` relax specific git guardrails.

## License

MIT — see [LICENSE](LICENSE). Original work copyright Jonathan Prozzi ([claude-utils](https://github.com/jonathanprozzi/claude-utils)); modifications copyright Matt Kaye.
