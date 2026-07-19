---
disable-model-invocation: true
---

Wrap up the daily session and generate handoff for tomorrow.

## Usage

```
/end-day              # Auto-detect session date from most recent incomplete transcript
/end-day --date 2025-12-16   # Explicitly specify the session date
```

## Date Detection (handles late-night sessions)

When running `/end-day` after midnight, the system date is technically "tomorrow" but you're conceptually wrapping up "yesterday." This command handles this automatically:

1. **If `--date YYYY-MM-DD` is provided**: Use that date explicitly
2. **Otherwise, auto-detect**:
   - Search for recent daily session transcripts: `local/ai-chats/transcripts/*/daily-session-*.md`
   - Find transcripts with an **incomplete handoff** (contains placeholder text: `*To be generated at end of session`)
   - Use the most recent incomplete transcript's date
   - If no incomplete transcript found, fall back to today's system date

This means running `/end-day` at 1am on 12/17 will correctly find and complete the 12/16 transcript if it's still open.

## What This Command Does

0. **Resolve the active vault — CWD-first, hard-scoped.** Walk **up** from the current working directory looking for a `.claude-vault.json` marker (CWD, then each parent, stopping at `$HOME`); its `vault_path` is the **ACTIVE VAULT**. Every `local/...` path in this command — including the date-detection globs above — is relative to `<VAULT>`, not the shell CWD. Lanes are mutually exclusive: the handoff, `_open-threads.md` roll, and daily wrap-up must all land in THIS vault only. **No marker found → STOP and ask** which lane's vault to wrap up (offer to drop a repo marker); never guess by recency.

1. **Determine session date** (via auto-detection or `--date` flag)

1b. **Evening comms sweep (optional)** — if your cadence manifest defines a recurring evening comms sweep or review ritual, run it BEFORE compiling the day's records so its outputs land in today's wrap-up/handoff. If the sweep can't run (e.g. a required tool is unavailable), note "evening sweep skipped: <reason>" in the recap rather than failing silently.

2. **Read the session's transcript** (`local/ai-chats/transcripts/YYYY-MM-DD/daily-session-YYYY-MM-DD.md`):
   - Review the Session Log entries and checkpoints
   - Identify key accomplishments, decisions, and open threads

3. **Scan the session date's Claude Code exports** (cross-session aggregation):
   - Search for summary files: `local/ai-chats/claude-code/**/*-summary.md`
   - Filter to files with the session date in the filename (YYYY-MM-DD pattern)
   - For each summary found:
     - Parse YAML frontmatter (project, duration, files_touched)
     - Extract key accomplishments from Overview
     - Extract Next Steps / Open items
   - Group by project for the handoff

4. **Update the Session Handoff section** in the transcript:
   - Summarize what was accomplished (this session)
   - Include "Other Sessions Today" table with cross-session work
   - Create "Unified Open Threads" merging all session next steps
   - Note key files touched or created
   - Add context for tomorrow's session

5. **Update the session date's daily note** (`local/journals/YYYY-MM-DD.md`):
   - Finalize the Claude Sessions entry with accurate checkpoint count
   - Ensure description reflects what was actually done
   - Optionally add key learnings to "Learning Points" section

5b. **Update the rolling Open Threads system** — this is the daily hygiene engine. The system is **three files** in `local/journals/`:
   - `_open-threads.md` — the live working doc (read each session): a 14-day **Recent Activity** window on top, then live threads (⏰ Time-Critical / Owned / Waiting For).
   - `_open-threads-archive.md` — completed / superseded threads (append-only).
   - `_open-threads-changelog.md` — the full dated history (append-only).

   Update `_open-threads.md` **before** finalizing the handoff so the handoff reflects current truth. Do all of this:
   - **Threads changed today:** update `status`, `next`, `blocker`, `ETA` in place.
   - **New threads:** add to the right section (with `opened: YYYY-MM-DD`).
   - **Completed / superseded today:** **move** the whole block to `_open-threads-archive.md` (append under a `## Migrated YYYY-MM-DD` subheader, or the existing `## Archive`), stamping a `closed: YYYY-MM-DD`. Don't leave closed threads inline. Delete only if truly low-signal.
   - **Waiting-for items:** add new ones (`asked: YYYY-MM-DD` + `nudge if:` date). If one is past its `nudge if:`, surface it in the handoff as a "nudge X" action.
   - **Recent Activity window:** prepend a concise 1–2 line entry for today (`**YYYY-MM-DD** — …`) at the top of the `## 🗓️ Recent Activity (last 14 days)` section. Then **roll off** any entries older than 14 days: cut them from Recent Activity and append the corresponding full/old detail to `_open-threads-changelog.md` (newest-first) so nothing is lost.
   - **Frontmatter:** set `last_updated:` to today's plain date (just `YYYY-MM-DD` — do not let it grow into a run-on summary line).
   - If `_open-threads.md` doesn't exist, create it from the vault-init skeleton — it's the source of truth. The archive/changelog files are created lazily on first roll-off.

5c. **Task-tracker sweep (optional)** — if you track work in an external tool (Linear, Jira, GitHub Issues, etc.), reconcile it with the day's work:
   - Identify tickets touched today (from the transcript, checkpoints, and `_open-threads.md` deltas).
   - **Status (auto):** flip each ticket to its correct state (In Progress → In Review → Done / Blocked) to match reality; collect the changes for the recap.
   - **Comments (approval):** for any ticket with a knowledge-worthy update (decision / blocker / scope change / handoff), draft a comment and get the user's approval before posting. Important parts only — not every edit. Read existing comments before drafting.
   - **Project updates (approval):** for owned projects with notable progress, draft a project status update for the user's approval.
   - **Ticket coverage check:** walk today's checkpoints and accomplishments; every piece of work should be either (a) attributed to a ticket or (b) explicitly designated no-ticket during the session. Anything uncovered → list it and offer batch ticket creation (project + title + estimate) before the handoff is finalized. Report the coverage result in the recap (e.g., "6/6 work items ticketed, 1 designated no-ticket").
   - Skip this step silently if no tracker integration is configured.

5d. **Compile the daily wrap-up summary (optional but recommended)** — a human-readable summary of the day:
   - **This is a reader-facing summary, NOT a work log.** Write so someone with zero context understands what you focused on, what you got done, what you're working through, and what you're stuck on. If you post a daily update to a team channel, this is what you paste.
   - Sources: the daily journal's "Today's Focus", the transcript checkpoints + Session Log, and the `.jsonl` tracking log (`local/daily-gn/.tracking/YYYY-MM-DD.jsonl`) — but **synthesize, don't transcribe.** Omit file-level minutia; consolidate related work into single outcome-focused bullets.
   - The wrap-up file has TWO layers — a **Share layer** (the subset you'd copy-paste to a team channel) and a **Tracking layer** (private, feeds any recurring reports your cadence manifest defines; never pasted to a channel):
   - **Share layer** (four classic sections):
     - **Focus** — the 1–3 things you centered the day on (the headlines; from Today's Focus + what actually got worked).
     - **Accomplished** — the important work that got done, as outcomes not steps. 3–6 bullets, plain language.
     - **Troubleshooting** — what you're actively working through / debugging. "None" is fine.
     - **Blocked** — what you're stuck on or waiting on (who/what), from `_open-threads.md` Waiting For + today's blockers. "None" is fine.
   - **Tracking layer** (below a `---` divider, under `## Tracking (private)`):
     - **Progress by workstream** — the same day's work regrouped under your active workstream headings (keep the names stable day to day; adjust as workstreams change), with the ticket ID in-line where one exists (e.g., "… (TICKET-123)").
     - **Metrics (optional)** — if your current plan defines measured-outcome counters with targets, one compact line per workstream showing `current → target`. Only include lines whose counter moved today or is newly at risk. Counters only — never editorialize.
     - **Capture prompts (ask the user, every night — these cannot be reconstructed later):** (1) *"What did you say no to today?"* (net-new asks declined/deferred + where they landed) and (2) *"Any new risk or changed assumption?"* Record the answers as the Tracking layer's last two lines ("None" is a fine answer). They feed any recurring review reports your cadence manifest defines.
   - Write the markdown to `local/daily-gn/YYYY-MM-DD.md` and display a share-ready draft inline for copy-paste (see the Daily Wrap-Up Template below). **The share draft contains ONLY the Share layer.**
   - **Recurring-report feed:** these wrap-ups are the raw material for any weekly/periodic reports your cadence manifest defines — consistent workstream keys + metric lines make those reports assemble without rework.

5e. **Nightly verification strip (optional)** — report-by-exception verification that today's recurring obligations were met. Do NOT re-run any checks; read the outputs the earlier steps already produced tonight and assert each is clean:

   | Check | Source |
   |---|---|
   | Daily wrap-up compiled, both layers + capture prompts answered | step 5d |
   | Evening sweep ran (if the manifest defines one) | step 1b report ("skipped: <reason>" counts as an exception) |
   | Open-threads hygiene done; Waiting-For items past `nudge if:` actioned or queued for tomorrow | step 5b |
   | Ticket coverage clean (every work item ticketed or explicitly no-ticket) | step 5c |
   | Evening cadence rows for today satisfied | `local/journals/_cadence.md` → "Evening verification" section (if defined) |

   - **Evening cadence rows:** if your manifest has an Evening verification section, evaluate it against today's day-of-week (e.g. "Monday: weekly reconciliation ran · Thursday: report draft exists"). A missed row gets fixed now if quick, otherwise becomes tomorrow's first action in the handoff.
   - **Log the strip** so the week rolls up without archaeology:
     `~/.config/claude-code/hooks/lib/track-accomplishment.sh "compliance" "strip YYYY-MM-DD: N/M green" "<exception list, or 'clean'>"`
   - **Report by exception in the recap:** a clean night is one line ("Verification: 5/5 green"). Each exception gets one sentence — what, why, when it gets fixed — and lands in the handoff's tomorrow-top-3 if it needs morning action.
   - Any recurring report your manifest defines can read the `compliance` rows from `local/daily-gn/.tracking/*.jsonl` instead of reconstructing the week.

6. **Summarize and sign off**:
   - Provide a brief recap of the session
   - Mention what's ready for tomorrow

## Handoff Section Template

```markdown
## Session Handoff

*End of YYYY-MM-DD session*

### What We Accomplished (This Session)
- [x] [Completed item from daily session]
- [x] [Another completed item]

### Other Sessions Today

*From exported Claude Code sessions (`local/ai-chats/claude-code/`):*

| Project | Sessions | Key Accomplishments |
|---------|----------|---------------------|
| [[Project A]] | 2 | Brief highlights from summaries |
| [[Project B]] | 1 | Brief highlights |

*If no exports: "No other exported sessions today."*

### Open Threads Delta (today's changes to [[_open-threads]])

**Closed today:** [thread name(s) moved to Archive, or deleted]
**Opened today:** [new threads added, with opened-date]
**Status changes:** [thread name → new status; what next step changed]

### Unified Open Threads (snapshot)

*Owned (from [[_open-threads]]):*
1. [Top-priority thread — status + next action]
2. [Next thread]

*Waiting For (from [[_open-threads]]):*
- [who/what — asked DATE — nudge-if status]

*Tomorrow's top-3 (user-prioritized):*
1. …
2. …
3. …

### Key Files
- [File paths that were created or modified - from all sessions]

### Session Stats

| Metric | Daily Session | All Sessions Today |
|--------|---------------|-------------------|
| Duration | ~X hours | ~Y hours total |
| Projects | N | M |
| Exports | - | N summaries |

### Context for Next Session
[1-2 sentences of unified context covering all work done today - this helps tomorrow's /daily-session greet effectively]
```

## Daily Wrap-Up Template (produced in step 5d)

A human-readable summary — the important work, not the minutia. Readers should understand what you focused on, accomplished, are troubleshooting, and are blocked on.

```markdown
---
date: YYYY-MM-DD
day: DayOfWeek
week: NN
---

# Daily Wrap-Up - YYYY-MM-DD

## Focus
- [The 1–3 headlines you centered the day on — the story of the day in plain language]

## Accomplished
- [Important outcome 1 — what it means, not which files changed]
- [Important outcome 2]
- [Important outcome 3]

## Troubleshooting
- [What you're actively working through]
- None

## Blocked
- [What you're stuck on or waiting on + who can unblock it]
- None

---

## Tracking (private)

### Progress by workstream

**Workstream A**
- [Outcome, plain language (TICKET-123)]

**Workstream B**
- [Outcome (TICKET-456)]

**Ops / Other**
- [Outcome]

*(Only include workstreams that had movement today.)*

### Metrics (optional)
- Workstream A: [N]/[target] <counter name>
- Workstream B: [N]/[target] <counter name>

*(Only lines that moved today or are newly at risk; omit if none.)*

### Said no to
- [Net-new ask declined or deferred today + where it landed — or "None"]

### New risks / changed assumptions
- [Anything newly visible that changes a plan, goal, or assumption — or "None"]
```

### Share Draft Format

The share draft is the **Share layer only** — Focus / Accomplished / Troubleshooting / Blocked. The Tracking layer (Progress by workstream + Metrics) never goes to a team channel; it feeds your private recurring reports.

```
*Daily Wrap-Up - Month DD*

*Focus*
• [headline]

*Accomplished*
• [outcome]
• [outcome]

*Troubleshooting*
• None

*Blocked*
• None
```

### Writing Guidelines

- **Reader-friendly** — write for people who don't know your work. Outcomes, not tools or filenames. "Scoped the whole next cycle with effort estimates" not "edited TICKET-371, TICKET-354…".
- **Summary, not minutia** — consolidate related work into one bullet; 3–6 progress bullets max; skip routine admin.
- **Focus** is the day's story in 1–3 lines — what you chose to spend the day on.
- **Workstream keys are stable** (Tracking layer) — use the same workstream names verbatim every day (they key your recurring reports). A ticket ID in-line per bullet where one exists; the ID is a pointer, not the story.
- **Metrics are counters only** (Tracking layer) — moved-today or newly-at-risk lines; never editorialize.
- **Share draft = Share layer only** — never include the Tracking section in the copy-paste draft.
- **Blocked** should be specific (who/what), so a reader can actually help.
- **"None"** is a perfectly good answer for Troubleshooting and Blocked.

## Notes

- This pairs with `/daily-session` to complete the daily loop
- The handoff lives in the transcript (not a separate file) - single source of truth
- Tomorrow's `/daily-session` will read this handoff section AND scan for exports
- The "Other Sessions Today" aggregation ensures nothing falls through the cracks
- "Unified Open Threads" gives tomorrow a prioritized starting point across all work
- Keep the handoff concise but complete enough to resume context
- **No `/export-conversation` needed after this** — the handoff IS the export for the daily session
- **Daily wrap-up is produced here** (step 5d): compiled from the `.jsonl` tracking log + transcript and written to `local/daily-gn/YYYY-MM-DD.md` + a share draft. The work-tracking hooks populate the `.jsonl` automatically.
- **Task-tracker sweep** (step 5c): reconciles your tracker with the day's work — status auto-applied, comments + project updates require approval.
- **Verification strip** (step 5e): the nightly "did anyone have to chase me today" answer. It verifies outputs, never re-runs checks; reports by exception; logs a `compliance` event to the tracking `.jsonl` so recurring reports are a read, not an investigation.
- Use `date +"%I:%M%p"` for accurate timestamps when writing handoff
- **Late-night sessions**: Auto-detection handles sessions that span past midnight. Use `--date` flag if you need explicit control.
