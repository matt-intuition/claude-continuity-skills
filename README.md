# claude-continuity-skills

Session continuity for [Claude Code](https://claude.com/claude-code) + [Obsidian](https://obsidian.md). A set of slash commands, two skills, and hooks that turn your vault into a durable memory layer: every day gets a journal, a session transcript, timestamped checkpoints, and an end-of-day handoff that tomorrow's session reads back — so a new Claude window always knows where you left off. Multiple projects live in separate "lanes" (one vault each) that never cross-contaminate, resolved automatically from wherever you launch Claude. An onboarding interview (`/onboard`) adapts the whole workflow to *your* platforms — task tracker, email, calendar, docs, CRM, share-out channel — through one foundation manifest, with graceful fallbacks for everything you don't use.

## Lineage

Started from and inspired by [jonathanprozzi/claude-utils](https://github.com/jonathanprozzi/claude-utils) (MIT), which established the daily-session / checkpoint / end-day / export loop. This repo evolves that base with:

- **Multi-vault lane isolation** — CWD-first vault resolution via `.claude-vault.json` markers. Each project lane gets its own vault; commands hard-scope every read/write to the active lane and stop-and-ask rather than guess.
- **`/onboard` + the foundation manifest** — an interview that records your platforms, MCP connectors, cadence ceremonies, and workstreams into `_foundation.md`; every downstream command gates its integration steps on it.
- **Write hot, reconcile cold** — `/checkpoint` authors the day's records while context is fresh; `/end-day` reconciles by diff, rolls windows, and enforces budgets. The ownership contract lives in `_JOURNAL-SYSTEM.md`, scaffolded into every vault.
- **Rolling open-threads system** — a three-file `_open-threads` / `-archive` / `-changelog` design: the live doc is a hard-budgeted index (~6-line entries, required `detail:` pointers) and narrative lands in the changelog, so the morning read stays cheap while nothing is lost.
- **Status verification gates** — every "done"/"not done" claim in a handoff or progress table is verified against the declared system of record (sent mail, live ticket state), never against session prose. Unverifiable claims are marked `unverified` instead of guessed.
- **`/daily-resume`** — read-only catch-up for fresh windows mid-day, so parallel terminals share one day-state without re-running setup.
- **Cadence manifest** — a trigger → workflow map (`_cadence.md`) that proposes the day's recurring runs each morning and verifies the evening obligations at `/end-day`.
- **`/vault-init` skill** — one command to scaffold a new vault with all conventions in place.
- Plus: an artifact log (21-day recall index of durable deliverables), opt-in checkpoint archiving, an accomplishment-tracking PostToolUse hook, a PreCompact auto-checkpoint hook, and a two-layer daily wrap-up compiled at `/end-day`.

## The Daily Workflow

```
        MORNING                     DURING THE DAY                    EVENING
  ┌──────────────────┐      ┌────────────────────────────┐      ┌─────────────────┐
  │  /daily-session  │      │  work ... /checkpoint ...  │      │    /end-day     │
  │                  │      │  work ... /checkpoint ...  │      │                 │
  │ · journal +      │ ───> │   (writes thread records   │ ───> │ · reconcile-by- │
  │   reflections    │      │    while context is hot)   │      │   diff + rolls  │
  │ · verified hand- │      │                            │      │ · verification  │
  │   off carry-over │      │  new terminal window?      │      │   gate → handoff│
  │ · focus pull →   │      │  └── /daily-resume         │      │ · daily wrap-up │
  │   today's plate  │      │      (read-only catch-up)  │      │   (share +      │
  │ · cadence runs   │      │  (PreCompact hook auto-    │      │    tracking)    │
  │   proposed       │      │   checkpoints on compact)  │      │ · compliance    │
  └──────────────────┘      └────────────────────────────┘      └─────────────────┘
                                                                        │
                              tomorrow's /daily-session reads the handoff
```

Everything lands in your vault under `local/`:

- `local/journals/YYYY-MM-DD.md` — daily journal (mood, gratitude, focus, day's end)
- `local/ai-chats/transcripts/YYYY-MM-DD/daily-session-YYYY-MM-DD.md` — the day's transcript: goals, session log, checkpoints, handoff
- `local/journals/_open-threads.md` — rolling source of truth for in-flight work + waiting-for asks (live index; archive + changelog companions)
- `local/journals/_artifact-log.md` — 21-day recall index of durable deliverables
- `local/daily-gn/YYYY-MM-DD.md` — human-readable daily wrap-up (share layer + private tracking layer)
- `local/daily-gn/.tracking/YYYY-MM-DD.jsonl` — automatic accomplishment log (written by the PostToolUse hook)

## The four configuration files

Scaffolded by `/vault-init`, filled by `/onboard`, read by every command:

| File | Holds | Written by |
|---|---|---|
| `local/journals/_foundation.md` | **Who you are and what you use** — name, timezone, platforms + MCP availability, system-of-record rules, workstream headings | `/onboard` interview; hand-edit any time |
| `local/journals/_cadence.md` | **When workflows fire** — daily/weekly/cycle/calendar/event triggers, evening verification rows | `/onboard` seeds it; hand-edit |
| `local/journals/_JOURNAL-SYSTEM.md` | **How the rolling files work** — live windows, append-only companions, entry budgets, ownership model | scaffolded; rarely edited |
| `.claude-vault.json` | **Which lane this is** — the vault marker CWD resolution walks up to | `/vault-init` |

**How gating works:** each integration step in the commands is marked `[gated: <capability>]`. If the foundation declares that capability with a connected MCP, the step runs against your tool; otherwise a documented fallback runs. No foundation file at all → everything runs in vault-only mode and the commands suggest `/onboard`.

### What you get with — and without — each integration

| Capability | Declared + MCP | Not declared |
|---|---|---|
| Task tracker (Linear/Jira/GitHub Issues) | Morning plate pulled from your tickets (via a context-cheap subagent digest); ticket-first work capture; evening status/comment sweep | Plate built from open-threads + yesterday's verified handoff; open-threads is the tracking layer |
| Email (e.g. Gmail) | Morning signal scan of the inbox; "sent" claims verified against **sent mail** | No scan; send claims recorded as `unverified` |
| Calendar | Meeting-driven cadence triggers; plate cross-referenced against today's events | Date/day-of-week triggers only |
| Docs / knowledge base | Artifact rows point at doc pages; counts verified by query | Vault paths only |
| CRM | Deal/relationship stage verification at `/end-day` | Stage claims recorded as `unverified` |
| Share-out channel (Slack/Discord/…) | Daily wrap-up share draft formatted for your channel | Wrap-up file still written; plain-text draft |

## Multi-project lanes

Each project lane — work, side project, personal — lives in its **own vault** with its own journals, transcripts, and `_open-threads.md`. Lanes are mutually exclusive: a session in one lane never reads or writes another lane's files.

**How resolution works (CWD-first):**

1. Every command walks **up** from the current working directory looking for a `.claude-vault.json` marker (stopping at `$HOME`).
2. The marker's `vault_path` names the active vault. A marker inside a vault points to itself.
3. **Repo-link markers:** drop a `.claude-vault.json` in a project repo whose `vault_path` points at that repo's companion vault — sessions launched from the repo then journal into the right lane automatically.
4. **No marker found → stop and ask.** Commands list the vaults on your machine that carry a marker and ask which lane the session belongs to (offering to drop a repo marker for next time). They never guess by recency and never fall through to another lane.

`/vault-init` scaffolds a new lane in one step: the `local/` subtree, templates, the open-threads skeleton, the journal-system contract, the cadence skeleton, a vault-local `CLAUDE.md`, and the marker file.

## Prerequisites

- [Claude Code](https://claude.com/claude-code) CLI
- [Obsidian](https://obsidian.md) (optional but recommended — the files are plain markdown either way)
- macOS or Linux, `bash`, `python3` (used by the hooks; some date flags in the hooks are macOS-flavored)
- Optional integrations, declared via `/onboard`: a task tracker (Linear/Jira/GitHub Issues), email, calendar, docs platform, CRM, and a share-out channel — each via MCP. Everything degrades gracefully without them (see the table above).

## Installation

### With setup.sh

```bash
git clone https://github.com/matt-intuition/claude-continuity-skills.git
cd claude-continuity-skills
./setup.sh
```

The installer copies the commands, skills, and hooks to their destinations (backing up anything it would overwrite to `.bak`), then **prints** the settings.json hook-wiring snippet — it never edits your settings for you.

### Manual copy

| What | From | To |
|------|------|----|
| Commands | `commands/*.md` | `~/.claude/commands/` |
| onboard skill | `skills/onboard/` | `~/.claude/skills/onboard/` |
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
2. Run `/vault-init` — it scaffolds `local/`, the templates, the open-threads skeleton, the journal-system contract, the cadence skeleton, and the `.claude-vault.json` marker.
3. Run `/onboard` — a short interview (it pre-fills from the MCPs it detects in your session) that records your name, timezone, platforms, cadence ceremonies, and workstreams into `local/journals/_foundation.md`, seeds `_cadence.md`, and ends with a dry-run readout of exactly what each command will now do.
4. Open the vault in Obsidian (optional) and write your morning reflections in today's journal — or just run `/daily-session` and answer the prompts in chat.
5. Work. Run `/checkpoint` at logical breakpoints; open extra windows freely and run `/daily-resume` in them.
6. Run `/end-day` in the evening. Tomorrow's `/daily-session` picks up exactly where you left off.

Changed tools or rhythm later? Re-run `/onboard` (it updates, never blind-overwrites) or hand-edit `_foundation.md`.

## Command reference

| Command | What it does |
|---------|--------------|
| `/daily-session` | Starts the day: creates/reads today's journal, reads and **verifies** the previous handoff, scans recent exports, reads open-threads + artifact log, evaluates the cadence manifest, pulls the day's plate from your task tracker (or the vault), creates the transcript, greets with full context. `--light` skips file creation. |
| `/checkpoint [note]` | Appends a timestamped checkpoint to the transcript, updates touched open-threads entries + changelog narrative **while context is hot**, logs artifact rows, syncs the tracker, and replies with a verified goal-progress table. `--archive` also exports the full conversation. |
| `/daily-resume` | Read-only: catches a fresh window up on today's session (transcript + journal + open-threads + cadence) and replies with the same goal-progress table. Never writes. |
| `/end-day [--date]` | Wraps the day: reconciles open-threads by diff, enforces the hygiene gate, rolls the 14-day/21-day windows, sweeps the tracker, runs the status verification gate, writes the Session Handoff, compiles the two-layer daily wrap-up, and reports a compliance strip by exception. Handles past-midnight sessions. |
| `/export-conversation` | Exports any Claude Code session (summary and/or full transcript, rich frontmatter, wiki-links) into the vault and links it from today's daily note. |
| `/vault-init` (skill) | Scaffolds a new vault/lane with all conventions in place. |
| `/onboard` (skill) | The configuration interview — writes `_foundation.md`, seeds `_cadence.md`, dry-runs the gates. Re-runnable. |

## Customization

- **Foundation manifest** — `local/journals/_foundation.md` is the single dial for platforms, MCP availability, timezone, workstreams, and optional targets. Every command re-reads it each session; edits take effect immediately.
- **Cadence manifest** — `local/journals/_cadence.md` lists your recurring rituals as triggers (day-of-week, calendar events, cycle position) plus evening verification rows. `/daily-session` proposes matching runs each morning as trackable goals; `/end-day` verifies the evening rows. It is the *only* home of day-of-week rules — the commands never hard-code them.
- **Comms sweeps** — if your routine includes a recurring inbox/messaging triage, list it in the cadence manifest; the commands propose it at the right times and report (rather than silently skip) when its tooling is unavailable.
- **Tracking matchers** — `hooks/track-work.sh` ships with matchers for git commits, file creation, skill runs, and a couple of example MCP tools; add cases for the MCP write tools you actually use.
- **Config file** — `~/.config/claude-code-workflow/config.json` holds the legacy fallback `obsidian_vault_path` and `/export-conversation` preferences. With per-vault markers in place you rarely need it.
- **Safety hook env switches** — `CLAUDE_SAFETY_ALLOW_PUSH=1`, `CLAUDE_SAFETY_ALLOW_FORCE_LEASE=1`, `CLAUDE_SAFETY_ALLOW_BRANCH_DELETE=1` relax specific git guardrails.

## License

MIT — see [LICENSE](LICENSE). Original work copyright Jonathan Prozzi ([claude-utils](https://github.com/jonathanprozzi/claude-utils)); modifications copyright Matt Kaye.
