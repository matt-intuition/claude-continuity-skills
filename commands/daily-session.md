---
disable-model-invocation: true
---

Start a daily thinking/brainstorm session in the Obsidian vault.

## Usage

```
/daily-session          # Full mode (default) - creates transcript, updates daily note
/daily-session --light  # Light mode - context only, no file creation
```

## Modes

### Default (Full Mode)
Creates a transcript file, adds entry to daily note, full archival workflow. Use this for:
- Morning session starts
- Days with planned focused work
- When you want full documentation

### Light Mode (`--light`)
Reads context but skips file creation. Use this for:
- Late starts (afternoon/evening)
- Low-energy days
- Quick check-ins
- When you'll run `/end-day` shortly after

Light mode still:
- Creates today's journal if it doesn't exist and prompts for reflections (step 1)
- Reads today's daily note
- Finds and reads previous handoff
- Scans recent exports
- Evaluates the cadence manifest (step 4c) and proposes today's runs
- Greets with full context

Light mode skips:
- Creating transcript file
- Adding session entry to daily note

---

## What This Command Does (Full Mode)

0. **Resolve the active vault — CWD-first, hard-scoped (applies to BOTH modes).** Each project lane lives in its own vault; lanes are mutually exclusive and each has its own `local/` subtree (`_open-threads.md`, journals, transcripts).
   - Walk **up** from the current working directory looking for a `.claude-vault.json` marker (CWD, then each parent, stopping at `$HOME`). Read its `vault_path` — that directory is the **ACTIVE VAULT**. (A marker inside a vault points to itself; a marker in a project repo points to that repo's companion vault.)
   - **Every `local/...` path in this command is relative to `<VAULT>`**, NOT to the shell CWD. Never create a `local/` subtree in a project repo, and never read or write another vault's files.
   - **No marker found → STOP and ask.** List the vaults on this machine that carry a `.claude-vault.json` (e.g. under your Obsidian documents directory) and ask which lane this session belongs to; offer to drop a repo marker (with `vault_path`) so it resolves automatically next time. Never guess by recency, and never fall through to a different lane's vault.

1. **Create or update today's daily journal** (`local/journals/YYYY-MM-DD.md`):
   - Check if the file exists. If not, create it from the template at `local/templates/Daily Journal Template.md`, replacing `{{date}}` with today's date.
   - If the file exists, read it and check whether the key fields (Mood Check, Gratitude, Today's Focus) are still placeholder text or empty.
   - For any unfilled fields, prompt the user in chat — one message covering all empty fields. Example:
     ```
     Before we dive in, let me get your morning reflections:
     - **Mood Check** — How are you feeling today?
     - **Gratitude** — Anything you're grateful for?
     - **Today's Focus** — What's the main thing you want to accomplish?
     ```
   - Wait for the user's response, then write their answers into the journal file (replacing placeholder text with their actual words).
   - If all key fields are already filled (user wrote in Obsidian before starting the session), skip the prompts and acknowledge what they wrote. Do not overwrite existing content.
   - After the journal is populated, continue to step 2.

2. **Read today's daily note** (`local/journals/YYYY-MM-DD.md`):
   - Extract mood from "Mood Check"
   - Extract focus items from "Today's Focus"
   - Note key reflections or context from their writing
   - Note any existing Claude Sessions entries

3. **Find and read the most recent handoff** (handles gaps gracefully):
   - Search for transcripts: `local/ai-chats/transcripts/*/daily-session-*.md`
   - Sort by date descending, exclude today
   - Read the most recent one's "Session Handoff" section
   - Note how many days ago the last session was (for context)
   - If no previous transcript exists: proceed without handoff context
   - If handoff section is incomplete: use what's available, note the gap

4. **Scan recent Claude Code exports** (cross-session context):
   - Search for summary files: `local/ai-chats/claude-code/**/*-summary.md`
   - **Exclude**: `local/ai-chats/claude-code/seeds/` (daily session exports are redundant with handoff)
   - Filter to files modified since the last daily session date
   - For each summary found:
     - Parse YAML frontmatter (project, tags, duration, files_touched)
     - Extract Overview section (1-2 sentence summary)
     - Extract Next Steps / Open items
   - Group summaries by project for the transcript
   - If no exports found: note this but proceed (not all work generates exports)

4b. **Read the rolling Open Threads doc** (`local/journals/_open-threads.md`):
   - This is the canonical state of in-flight owned work + waiting-for items.
   - **Read this live file only** — its companions `_open-threads-archive.md` (completed/superseded) and `_open-threads-changelog.md` (full dated history) are NOT loaded each session. The live doc's `## 🗓️ Recent Activity (last 14 days)` window already gives you the recent timeline.
   - Surface it in the greeting and in the transcript's "Open Threads" section.
   - If the doc doesn't exist yet, skip — it's optional infrastructure.
   - Today's daily journal should mirror a snapshot (priorities subset) under `## Open Work Threads` and `## Waiting For` — update if drift is obvious.

4c. **Evaluate the cadence manifest** (`local/journals/_cadence.md`) — the dispatcher:
   - Read the manifest. Evaluate every trigger against: today's date + day-of-week, cycle position (compute from the manifest's cycle anchor, if it defines one), and today's calendar events (if a calendar integration is available and a read already happened this session, reuse it; otherwise fetch today's events — or skip if no calendar access).
   - Collect matching triggers into a **"Today's proposed runs"** list, ordered by time-of-day (morning prep → event-driven → evening).
   - These are PROPOSALS surfaced in the greeting (step 7) — never auto-run a proposed workflow. If the user declines one, don't re-propose it today.
   - **Cadence items are goals, not prose.** Every proposed run ALSO becomes a row in the transcript's Session Goals table (type `cadence`) with its trigger detail spelled out (e.g. `prep for <meeting name> at <time>`, not just "meeting prep"). This keeps them trackable by /checkpoint, /daily-resume, and /end-day instead of getting lost in the greeting text.
   - If the manifest doesn't exist, skip this step silently.

4d. **Task-tracker sync (optional)** — if you track work in an external tool (Linear, Jira, GitHub Issues, etc.):
   - For each Today's Focus item (and each synthesized session goal), determine whether it maps to an existing ticket/issue. Check, in order: ticket IDs already named in the journal/handoff/open-threads, then a targeted search in the tracker (batch the queries).
   - Present a compact mapping table in the greeting: `focus item → ticket (status)` or `focus item → NO TICKET`.
   - For each NO TICKET item, offer one-click creation: propose a project/team, a one-line title, and estimate; create on the user's confirmation (batch the confirmations, don't ask one-by-one). The user can also mark an item **no-ticket** (personal/trivial/out-of-scope) — record that designation in the transcript's Session Goals so /end-day doesn't re-flag it.
   - Write the resulting ticket IDs next to their goals in the transcript's Session Goals section (e.g., `- [ ] Review launch materials → TICKET-123`).
   - Skip this step silently if no tracker integration is configured.

4e. **Morning inbox scan (optional)** — if an email integration (e.g. a Gmail MCP connector) is available; skip silently otherwise:
   - Search for unread messages received since the last daily session (query like `is:unread newer_than:Nd` where N covers the gap; cap at 7d).
   - Filter to signal: known contacts, collaborators, and anything matching active open-threads or waiting-for items. Ignore newsletters/notifications/automated mail — do not list them.
   - For each signal message: one line in the greeting under **Inbox** — sender, ask/topic, and whether it resolves a Waiting For item or creates new work (→ feed it into the step 4d ticket check).
   - Waiting-For resolution: if a reply resolves an open-threads Waiting For item, note it for the update (the actual open-threads edit happens at /end-day unless the user asks now).
   - Never open/read message bodies beyond what's needed to classify; never send, label, or modify anything during the scan.

4f. **Recurring comms sweep (optional)** — if your workflow includes a recurring morning comms sweep or review ritual (e.g. a messaging-app triage, a queue review), list it in your cadence manifest and it will be proposed here. Findings feed the greeting (Inbox-style lines) and the step 4d ticket check.

5. **Create today's transcript file**:
   - Create directory: `local/ai-chats/transcripts/YYYY-MM-DD/`
   - Create file: `daily-session-YYYY-MM-DD.md`
   - Use the template below, merging daily note + previous handoff + other session exports into rich context

6. **Add session entry to daily note**:
   - In the "Claude Sessions" section, add:
     ```markdown
     - ~HH:MMam - [[local/ai-chats/transcripts/YYYY-MM-DD/daily-session-YYYY-MM-DD|Daily Session: Topic]] *(0 checkpoints)* - Brief description
     ```
   - Include the approximate start time for continuity with checkpoint entries

7. **Greet with context**:
   - Summarize what you captured from their daily note and previous handoff
   - Highlight any notable work from other exported sessions
   - Mention open threads and priorities (including from other sessions)
   - **Today's proposed runs** — surface the cadence matches from step 4c as a short checklist (e.g., "Monday → weekly reconciliation · meeting at 2pm → prep this morning · evening → /end-day"). One line per run with the why. Skip the section if nothing matched beyond the daily defaults.
   - Ask what they'd like to focus on first

## Transcript Template

```markdown
---
date: YYYY-MM-DD
type: daily-session
days_since_last: N
previous_session: "[[local/ai-chats/transcripts/PREV-DATE/daily-session-PREV-DATE]]"
projects: []
tags:
  - DailySession
  - ClaudeCode
---

# Daily Session Transcript - YYYY-MM-DD

## Today's Context

**From daily note reflections:**

| Field | Value |
|-------|-------|
| **Mood** | [extracted from Mood Check] |
| **Energy** | [inferred from their writing - e.g., "tired but motivated"] |
| **Focus** | [extracted from Today's Focus] |

**Key thoughts from morning reflections:**
- [Notable points from their Mood Check writing]
- [Ideas or context they mentioned]
- [Anything relevant to today's work]

---

## Previous Session Context

**Last session:** [[previous-session-link]] (N days ago)

### What We Accomplished
- [Items from previous handoff]

### Open Threads
1. [Priority items from previous handoff]
2. [Continuing work]

### Key Files from Last Session
- [Important files mentioned in handoff]

---

## Other Sessions Since Last Daily

*Exported Claude Code sessions since last daily session (from `local/ai-chats/claude-code/`, excluding `seeds/`):*

### [[Project Name]] (N sessions)

**[[...-summary|Session Title]]** (~duration)
- [1-2 sentence overview from summary]
- Open: [Next steps extracted from summary]

### [[Another Project]] (N sessions)

**[[...-summary|Session Title]]** (~duration)
- [Overview]
- Open: [Next steps]

*If no exports found: "No exported sessions since last daily session."*

---

## Session Goals

*Unified table: work items AND today's cadence/ritual items in one place. Cadence rows carry the concrete trigger detail (which meeting, what time, which batch) so reminders can't get lost in prose.*

| # | Goal | Type | Ticket / Trigger | Status |
|---|------|------|------------------|--------|
| 1 | [Work goal 1] | work | [TICKET-ID or no-ticket] | ☐ |
| 2 | [Work goal 2] | work | [TICKET-ID] | ☐ |
| 3 | [prep for <meeting> at <time>] | cadence (calendar) | [ticket] | ☐ |
| 4 | [AM comms sweep] | cadence (daily) | — | ☐ |
| 5 | [Evening /end-day] | cadence (evening) | — | ☐ |

---

## Session Log

### ~[TIME] - Session Start

[Brief note about session initialization and context merge]

---

## Session Handoff

*To be generated at end of session via `/end-day` or manually*

---
```

## Template Field Guidelines

### Projects Array
Populate `projects` frontmatter by identifying:
- Explicit project mentions (e.g., "Project A", "Claude Code Daily Session")
- Wiki-linked project references
- Work contexts mentioned in daily note

### Mood/Energy Extraction
Parse the Mood Check section for:
- Explicit mood statements ("I'm feeling...")
- Energy indicators ("tired", "energized", "motivated")
- Blockers or concerns mentioned

### Session Goals Synthesis
Combine:
- Today's Focus items from daily note
- Priority items from previous session's open threads
- Any explicit "I want to..." statements
- **Today's cadence proposals from step 4c** — one row per proposed run, type `cadence`, with concrete trigger detail (meeting name + time, batch name, etc.)

## Notes

- This command merges human context (daily note) with collaboration context (previous handoff)
- The transcript becomes the rich, queryable record of the session
- Daily note stays clean with just links; transcript has full detail
- YAML frontmatter enables Dataview queries and future knowledge graph parsing
- Use `/checkpoint` throughout the session to capture progress
- Use `/end-day` to wrap up and generate handoff for tomorrow
- Use `date +"%I:%M%p"` for accurate timestamps (session start, log entries)
- The "Other Sessions" scan excludes `seeds/` since daily session handoffs are the authoritative source
- **Light mode** (`--light`) is ideal for late starts, low-energy days, or when you just need context without archival overhead
- Running `/end-day` after a light mode session is fine — it will note that no transcript exists for today
