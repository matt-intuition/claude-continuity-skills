---
disable-model-invocation: true
---

Start a daily thinking/work session in the Obsidian vault.

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
- Runs the focus pull (step 4d) and proposes the day's plate
- Greets with full context

Light mode skips:
- Creating transcript file
- Adding session entry to daily note

---

## Foundation gate (applies to every step below)

After resolving the vault (step 0), read the **foundation manifest** at `local/journals/_foundation.md`. It declares the user's name, timezone, platforms (task tracker, email, calendar, docs, CRM, share-out channel), whether each has a working MCP connector, and the workstream headings.

- Steps marked **[gated: <capability>]** run only when the foundation declares that capability with a connected MCP. Otherwise run the step's stated fallback — never error, never call an undeclared tool.
- **Server binding:** the platforms table names the exact MCP server each capability uses (e.g. `linear-org-a` — lanes may be authed to different orgs of the same service). Call tools ONLY from that named server. If the named server isn't connected in this session, treat the capability as unavailable: run the fallback and say so in the greeting — never substitute a same-service server bound to another lane.
- **No foundation file →** treat every capability as absent, run the vault-only path throughout, and suggest `/onboard` once in the greeting ("run `/onboard` to connect your task tracker, email, and calendar to this workflow").
- Address the user by the name the foundation declares; timestamps use the foundation's timezone.

## What This Command Does (Full Mode)

0. **Resolve the active vault — CWD-first, hard-scoped (applies to BOTH modes).** Each project lane lives in its own vault; lanes are mutually exclusive and each has its own `local/` subtree (`_open-threads.md`, journals, transcripts).
   - Walk **up** from the current working directory looking for a `.claude-vault.json` marker (CWD, then each parent, stopping at `$HOME`). Read its `vault_path` — that directory is the **ACTIVE VAULT**. (A marker inside a vault points to itself; a marker in a project repo points to that repo's companion vault.)
   - **Every `local/...` path in this command is relative to `<VAULT>`**, NOT to the shell CWD. Never create a `local/` subtree in a project repo, and never read or write another vault's files.
   - **No marker found → STOP and ask.** Search the user's likely vault locations for directories carrying a `.claude-vault.json` (e.g. `~/Documents`, `~/Obsidian`, and on macOS the iCloud Obsidian folder `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/*/`) and ask which lane this session belongs to; offer to drop a repo marker (with `vault_path`) so it resolves automatically next time. Never guess by recency, and never fall through to a different lane's vault.

1. **Create or update today's daily journal** (`local/journals/YYYY-MM-DD.md`):
   - Check if the file exists. If not, create it from the template at `local/templates/Daily Journal Template.md`, replacing `{{date}}` with today's date.
   - If the file exists, read it and check whether the key fields (Mood Check, Gratitude, Today's Focus) are still placeholder text or empty.
   - For any unfilled fields, prompt the user in chat — one message covering all empty fields. Example:
     ```
     Before we dive in, let me get your morning reflections:
     - **Mood Check** — How are you feeling today?
     - **Gratitude** — Anything you're grateful for?
     ```
   - **If a task tracker is declared, do NOT ask the user to free-write "Today's Focus."** Focus comes from the tracker (step 4d) — the greeting proposes a ticket-derived focus list and the user confirms or edits it. Only mood + gratitude are prompted as reflections. After confirmation, write the chosen tickets into the journal's Today's Focus as `ID — short title` lines (e.g. `TEAM-123 — Ship the onboarding flow`). If the user volunteers focus prose anyway, keep it AND map it to tickets in step 4d.
   - **No task tracker declared →** include Today's Focus in the reflections prompt ("What are the 3–6 things you want to move today?").
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
   - **Extract ONLY the "Session Handoff" and "Session Goals" sections — never Read the full transcript.** The rest is the all-day Session Log, which the handoff already distills. Use a sectional extraction, e.g.:
     ```bash
     awk '/^## Session Goals/,/^## Session Log/' <file>   # goals table (shows what did/didn't finish)
     awk '/^## Session Handoff/,0' <file>                 # the handoff itself
     ```
   - The full transcript stays one targeted read away if a specific handoff item needs its backstory — fetch it then, not preemptively.
   - Note how many days ago the last session was (for context)
   - If no previous transcript exists: proceed without handoff context
   - If handoff section is incomplete: use what's available, note the gap
   - **⛔ Verify the handoff's open items before carrying any of them into today's plate.** The handoff is prose written at the end of a long day, and it is wrong often enough that trusting it costs a morning. Specifically:
     - Anything it lists as **unsent, undone, or outstanding** → check the system of record the foundation declares for that claim type before proposing it as today's work. Email sends go against **sent mail** (e.g. `in:sent after:YYYY/MM/DD`), never the drafts folder. Ticket state goes against the task tracker, fetched now. No system of record declared for a claim type → carry the item marked `unverified` rather than trusting the prose.
     - Anything it lists as **done** that today's work depends on → same check, opposite direction.
     - A handoff written by a **parallel window or a subagent** is prose about work the writer did not do, and is the highest-risk kind.
   - **When the handoff and the system of record disagree, the system of record wins.** Say so explicitly in the greeting — name what the handoff claimed and what is actually true — and correct the source record (`_open-threads`, the ticket) in the same pass, so the error dies here instead of propagating into tomorrow's handoff.
   - *Why this rule exists: prose compresses in whichever direction the writer's last memory points. Handoffs have recorded already-sent work as the next day's #1 priority, and draft-only work as done.*

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
   - **Read this live file only** — its companions `_open-threads-archive.md` (completed/superseded) and `_open-threads-changelog.md` (dated narrative history) are NOT loaded each session. The live doc's `## 🗓️ Recent Activity (last 14 days)` window already gives you the recent timeline.
   - **Entries are index-altitude state blocks** (~6 lines each, schema in the file header / `_JOURNAL-SYSTEM.md`) with a `detail:` pointer. Don't expect narrative here, and don't go fetch it for every thread — depth is pulled ONLY for the confirmed plate items (see step 7).
   - Surface it in the greeting and in the transcript's "Open Threads" section.
   - If the doc doesn't exist yet, skip — it's optional infrastructure.
   - Today's daily journal should mirror a snapshot (priorities subset) under `## Open Work Threads` and `## Waiting For` — update if drift is obvious.

4b2. **Read the rolling Artifact Log** (`local/journals/_artifact-log.md`) — the recall index:
   - A 21-day table of every durable doc, write-up, and presentation produced. Rows are pointer-altitude (<=15-word purpose clause), which is what keeps this file cheap enough to hold in context every session — the value is ambient awareness of what already exists.
   - **Read this live file only** — `_artifact-log-archive.md` holds everything older and is NOT loaded each session. Grep the archive only when recall reaches past 21 days.
   - Use it to answer "what did I make about X?" and "where does that deck live?" without walking transcripts. Don't summarize it in the greeting unless it's relevant — it's a lookup table, not a status report.
   - If the file doesn't exist yet, skip — it's optional infrastructure.

4c. **Evaluate the cadence manifest** (`local/journals/_cadence.md`) — the dispatcher:
   - Read the manifest. Evaluate every trigger against: today's date + day-of-week, cycle position (compute from the manifest's cycle anchor), and **[gated: calendar]** today's calendar events (reuse the calendar read if one already happened this session; otherwise fetch today's events). No calendar declared → evaluate date/day-of-week/cycle triggers only and note that calendar-driven rows can't be checked.
   - Collect matching triggers into a **"Today's proposed runs"** list, ordered by time-of-day (morning prep → event-driven → evening).
   - These are PROPOSALS surfaced in the greeting (step 7) — never auto-run a proposed workflow. If the user declines one, don't re-propose it today.
   - **Cadence items are goals, not prose.** Every proposed run ALSO becomes a row in the transcript's Session Goals table (type `cadence`) with its trigger detail spelled out (e.g. `weekly review draft — due before the Thursday 1-1`, not just "weekly review"). This keeps them trackable by /checkpoint, /daily-resume, and /end-day instead of getting lost in the greeting text.
   - If the manifest doesn't exist, skip this step silently.

4d. **Task-tracker focus pull [gated: task tracker]** — when the foundation declares a task tracker, it is the task source of truth and the day's focus is PULLED from it, not free-written:
   - Pull the user's open tickets **via ONE subagent** — raw task-tracker list output is often 15-20k tokens and must stay out of the main context. Spawn a single agent (run_in_background: false) that queries the tracker for tickets assigned to the user in active + backlog states, and returns ONLY a compact digest: one line per ticket (`ID — title · due · priority · project · team`), pre-grouped into **Due today / Due ≤3 days / Overdue+High / rest**, plus a stale-date list (due dates >2 weeks past). The main session works from the digest (~2k tokens) and never sees the raw output.
   - Build **"Today's plate"** from the pull, cross-referenced against today's calendar events (step 4c, if calendar declared) and open-threads priorities:
     - **Due today** · **Due ≤3 days** · **Overdue + High priority** · tickets matching today's calendar events (e.g. a meeting on the calendar → its related ticket)
     - Propose a realistic focus list (3–6 items) for the day's available hours; the user confirms or edits. The confirmed list becomes the journal's Today's Focus and the transcript's Session Goals rows.
   - **Ticket IDs are never shown bare.** Always render as `ID — short title` (e.g. `TEAM-123 — Ship the onboarding flow`), in the greeting, the journal, the goals table, and any status output. IDs alone are not recallable.
   - **New-work capture (standing rule):** anything that surfaces during the session — inbox, calls, conversation — that is significant enough to track gets a ticket before (or immediately after) work starts. Propose team/project, a one-line title, and estimate; create on the user's confirmation (batch confirmations, don't ask one-by-one). The user can mark an item **no-ticket** (personal/trivial/out-of-scope) — record that in Session Goals so /end-day doesn't re-flag it.
   - **Stale-date hygiene:** if the pull surfaces overdue tickets that are clearly no longer dated right (weeks-old due dates), flag the worst offenders in the greeting and offer a re-date/close sweep — a due-date view is only useful if dates are honest.
   - Tracker-specific notes (Linear): `save_issue` needs the full team UUID or exact team name (short IDs fail); labels must be passed by ID, never name.
   - Write the resulting ticket IDs next to their goals in the transcript's Session Goals section (e.g., `- [ ] TEAM-123 — Ship the onboarding flow`).
   - **Fallback (no task tracker):** build "Today's plate" from the verified handoff open items (step 3), the open-threads Time-Critical + Owned sections (step 4b), and the journal's Today's Focus. Same 3–6 item proposal, same confirm-or-edit flow — sourced from the vault instead of a tracker.

4e. **Morning inbox scan [gated: email]** — skip silently if no email MCP is declared or available:
   - Search the inbox for unread messages received since the last daily session (e.g. Gmail `search_threads`, query like `is:unread newer_than:Nd` where N covers the gap; cap at 7d).
   - Filter to signal: known contacts, colleagues at the user's own domain (from the foundation's identity section), and anything matching active open-threads or waiting-for items. Ignore newsletters/notifications/automated mail — do not list them.
   - For each signal message: one line in the greeting under **Inbox** — sender, ask/topic, and whether it resolves a Waiting For item (e.g., "Alex replied re: the API review → clears the nudge") or creates new work (→ feed it into the step 4d ticket-first check).
   - Waiting-For resolution: if a reply resolves an open-threads Waiting For item, note it for the update (the actual open-threads edit happens at /end-day unless the user asks now).
   - Never open/read message bodies beyond what's needed to classify; never send, label, or modify anything during the scan.

4f. **Extra morning sweeps [gated: per-vault skills]** — if the cadence manifest declares additional morning sweeps (e.g. a chat-platform sweep skill installed in this vault's repo), propose them as cadence rows. A required sweep that needs unavailable tooling (e.g. browser automation) is proposed as the first action after restart — never skipped silently.

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
   - **Today's plate** — the focus proposal from step 4d: due today / due ≤3 days / overdue-High / calendar-matched items, every ticket rendered `ID — short title`, trimmed to a realistic 3–6 item focus list for the day's hours.
   - **Today's proposed runs** — surface the cadence matches from step 4c as a short checklist (e.g., "Monday → weekly sync ceremony · call at 2pm → prep this morning · evening → /end-day"). One line per run with the why. Skip the section if nothing matched beyond the daily defaults.
   - Ask the user to confirm or edit the proposed plate (not "what do you want to focus on?" from a blank page)
   - **After the user confirms the plate, fetch depth for the confirmed items only:** for each plate thread, follow its `detail:` pointer — the `_open-threads-changelog.md` date-anchors (grep the thread name / read the anchored `## YYYY-MM-DD` section), the linked ticket, or the named transcript. The day starts with full context on the 3–6 threads actually being worked — never with narrative for the whole board.

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

*If no exports found: "No exported sessions since last daily session."*

---

## Session Goals

*Unified table: work items AND today's cadence/ritual items in one place. Cadence rows carry the concrete trigger detail (which meeting, what time, which batch) so reminders can't get lost in prose.*

| # | Goal | Type | Ticket / Trigger | Status |
|---|------|------|------------------|--------|
| 1 | [Work goal 1] | work | [TICKET-ID or no-ticket] | ☐ |
| 2 | [Work goal 2] | work | [TICKET-ID] | ☐ |
| 3 | [meeting prep — <who> call <time>] | cadence (calendar) | [ticket] | ☐ |
| 4 | [weekly ceremony per _cadence.md] | cadence (weekly) | — | ☐ |
| 5 | [/end-day] | cadence (evening) | — | ☐ |

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
- Explicit project mentions
- Wiki-linked project references
- Work contexts mentioned in daily note

### Mood/Energy Extraction
Parse the Mood Check section for:
- Explicit mood statements ("I'm feeling...")
- Energy indicators ("tired", "energized", "motivated")
- Blockers or concerns mentioned

### Session Goals Synthesis
Combine:
- **The confirmed plate from step 4d** — the primary source; one row per item, tickets rendered `ID — short title`
- Priority items from previous session's open threads
- Any explicit "I want to..." statements (mapped to tickets per the new-work capture rule, when a tracker is declared)
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
