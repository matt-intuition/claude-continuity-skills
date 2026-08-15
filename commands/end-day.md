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

## Foundation gate

After resolving the vault (step 0), read `local/journals/_foundation.md`. Steps marked **[gated: <capability>]** run only when the foundation declares that capability with a connected MCP; otherwise use the stated fallback. **Server binding:** call tools only from the MCP server the platforms table names for each capability (lanes may be authed to different orgs of the same service); a named-but-unconnected server means the capability is unavailable — run the fallback, and mark affected claims `unverified — <server> not connected` rather than verifying against another lane's server. The foundation also supplies the **workstream headings** (step 5d) and the **share-out channel** the daily wrap-up draft is formatted for. No foundation file → vault-only behavior throughout.

## What This Command Does

0. **Resolve the active vault — CWD-first, hard-scoped.** Walk **up** from the current working directory looking for a `.claude-vault.json` marker (CWD, then each parent, stopping at `$HOME`); its `vault_path` is the **ACTIVE VAULT**. Every `local/...` path in this command — including the date-detection globs above — is relative to `<VAULT>`, not the shell CWD. Lanes are mutually exclusive: the handoff, `_open-threads.md` roll, and daily wrap-up must all land in THIS vault only. **No marker found → STOP and ask** which lane's vault to wrap up (offer to drop a repo marker); never guess by recency.

1. **Determine session date** (via auto-detection or `--date` flag)

1b. **Evening sweeps [gated: per-vault skills]** — if the cadence manifest declares evening sweeps (e.g. a chat-platform or inbox delta sweep), run them BEFORE compiling the day's records so their outputs land in today's wrap-up/handoff. A sweep that can't run (missing tooling) is noted in the recap ("PM sweep skipped: no browser") rather than failing silently. No evening sweeps declared → skip.

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
   - **Compile from written records, don't author from memory:** the handoff summarizes the day's checkpoint entries + the reconciled thread/artifact records — it never introduces status claims that exist only in end-of-session recall (the 5f gate still verifies every claim). Records that were authored at end-day without a checkpoint behind them carry their lower-confidence flag into the handoff.
   - Summarize what was accomplished (this session)
   - Include "Other Sessions Today" table with cross-session work
   - Create "Unified Open Threads" merging all session next steps
   - Note key files touched or created
   - Add context for tomorrow's session

5. **Update the session date's daily note** (`local/journals/YYYY-MM-DD.md`):
   - Finalize the Claude Sessions entry with accurate checkpoint count
   - Ensure description reflects what was actually done
   - Optionally add key learnings to "Learning Points" section

5b. **Open Threads reconciliation + rolls + hygiene gate** — /end-day RECONCILES this system; it does not author it. `/checkpoint` step 5a3 writes thread records during the day while context is hot; this step catches what checkpoints missed and keeps the files within their budgets. The system is **three files** in `local/journals/` (schema + ownership contract: the file headers + `_JOURNAL-SYSTEM.md`):
   - `_open-threads.md` — the live INDEX (read each session): a 14-day **Recent Activity** window on top, then live threads (⏰ Time-Critical / Owned / Waiting For) as state blocks, **max ~6 lines each with a required `detail:` pointer**.
   - `_open-threads-archive.md` — completed / superseded threads (append-only).
   - `_open-threads-changelog.md` — the dated narrative history (append-only; checkpoints write today's narrative here under `## YYYY-MM-DD`).

   Run all of this **before** finalizing the handoff so it reflects current truth:
   - **Reconcile by diff, not recall:** walk today's checkpoint entries in the transcript, verify their thread-state claims against the systems of record (step 5f table), and write **only the deltas the checkpoints missed** — un-checkpointed work, light-mode stretches, parallel-window gaps. Any record this step must author with no checkpoint behind it gets flagged in the handoff: *"updated at end-day without a checkpoint — lower confidence."* Cold-context authoring is the failure mode this whole design exists to avoid; when it's unavoidable, mark it.
   - **New threads / Waiting For items that surfaced un-checkpointed:** add them per the schema (`asked:`/`opened:` + `nudge if:` + `detail:` pointer). Items past `nudge if:` → surface in the handoff as "nudge X" actions.
   - **Recent Activity window:** prepend a concise 1–2 line entry for today (`**YYYY-MM-DD** — …`), **compiled from the day's checkpoints**, at the top of `## 🗓️ Recent Activity (last 14 days)`. Then roll off entries older than 14 days: cut them and append to `_open-threads-changelog.md` (newest-first) so nothing is lost.
   - **⛔ Hygiene gate (the budget enforcer):** scan every live entry — (a) over ~6 lines → compress to the schema, moving the displaced narrative to the changelog under today's date; (b) missing its `detail:` pointer → add one (changelog anchor, ticket, or transcript date); (c) closed/answered but still inline (✅/CLOSED markers) → move to `_open-threads-archive.md` with `closed: YYYY-MM-DD` stamped. Report the gate result in the recap (e.g. "hygiene: 2 compressed, 1 archived, pointers clean").
   - **Frontmatter:** set `last_updated:` to today's plain date (just `YYYY-MM-DD` — do not let it grow into a run-on summary line).
   - If `_open-threads.md` doesn't exist, create it from the vault-init skeleton — it's the source of truth. The archive/changelog files are created lazily on first write.

5b1. **Artifact log reconciliation + 21-day roll** (`local/journals/_artifact-log.md`) — the recall index. Two jobs:
   - **Reconcile:** diff today's durable deliverables (from the transcript checkpoints, plus anything produced outside a checkpoint — decks built ad hoc, doc pages written mid-call) against today's rows in `_artifact-log.md`. Missing rows get written now, using the row shape and the log/don't-log filter documented in `/checkpoint` step 5a2 and in the file's own header. **Row-altitude enforcement:** any row (today's or older) whose "What it's for" has grown past ~15 words into a summary gets trimmed back to a pointer clause — the artifact holds its own detail.
   - **Roll:** move every row dated more than **21 days** before today out of `_artifact-log.md` and append it to `_artifact-log-archive.md` under a `## Rolled YYYY-MM-DD` header (newest batch on top). This is a **move, never a delete** — the 21 days is a recall window, not a retention limit. Keep the columns identical so the archive stays greppable with the same patterns.
   - **Frontmatter:** set `last_updated:` on both files to today's plain date.
   - Report the result in the recap as one line (e.g. "Artifact log: +4 today, 2 rolled to archive").

5c. **Final task-tracker sweep [gated: task tracker]** — reconcile the tracker with the day's work:
   - Identify tickets touched today (from the transcript, checkpoints, and `_open-threads.md` deltas).
   - **Status (auto):** flip each ticket to its correct state (In Progress → In Review → Done / Blocked) to match reality; collect the changes for the recap.
   - **Comments (approval):** for any ticket with a knowledge-worthy update (decision / blocker / scope change / handoff), draft a comment and get the user's approval before posting. Important parts only — not every edit. Read existing comments before drafting.
   - **Project updates (approval):** for owned projects with notable progress, draft a project status update for the user's approval.
   - **Ticket coverage check (ticket-first rule):** walk today's checkpoints and accomplishments; every piece of work must be either (a) attributed to a ticket or (b) explicitly designated no-ticket during the session. Anything uncovered → list it and offer batch ticket creation (team/project + title + estimate) before the handoff is finalized. Report the coverage result in the recap (e.g., "6/6 work items ticketed, 1 designated no-ticket").
   - **No task tracker declared →** skip; the open-threads reconciliation (5b) is the coverage record.

5d. **Compile the daily wrap-up ("Daily GN")** — a human-readable summary for colleagues:
   - **This is a colleague-facing summary, NOT a work log.** Write so someone with zero context understands what you focused on, what you got done, what you're working through, and what you're stuck on.
   - Sources: the daily journal's "Today's Focus", the transcript checkpoints + Session Log, and the `.jsonl` tracking log (`local/daily-gn/.tracking/YYYY-MM-DD.jsonl`) — but **synthesize, don't transcribe.** Omit file-level minutia; consolidate related work into single outcome-focused bullets.
   - The wrap-up file has TWO layers — a **share layer** (the subset the user copy-pastes to their team's share-out channel, per the foundation) and a **tracking layer** (user-facing, feeds weekly reviews and other reporting; never pasted to the channel):
   - **Share layer** (four classic sections):
     - **Focus** — the 1–3 things you centered the day on (the headlines; from Today's Focus + what actually got worked).
     - **Accomplished** — the important work that got done, as outcomes not steps. 3–6 bullets, plain language.
     - **Troubleshooting** — what you're actively working through / debugging. "None" is fine.
     - **Blocked** — what you're stuck on or waiting on (who/what), from `_open-threads.md` Waiting For + today's blockers. "None" is fine.
   - **Tracking layer** (below a `---` divider, under `## Tracking (not for sharing)`):
     - **Progress by workstream** — the same day's work regrouped under the workstream headings the foundation declares, with the ticket ID in-line where one exists (e.g., "… (TEAM-123)"). Keep the workstream names verbatim day to day — they key the weekly rollup.
     - **Scoreboard (optional)** — if the foundation or cadence manifest declares measured targets, one compact line per workstream showing `current → target` for counters that moved today or are newly at risk. Counters only; never editorialize.
     - **Capture prompts (ask the user, every night — these cannot be reconstructed later):** (1) *"What did you say no to today?"* (net-new asks declined/deferred + where they landed) and (2) *"Any new risk or changed assumption?"* Record the answers as the tracking layer's last two lines ("None" is a fine answer). They feed weekly reviews; a real risk also gets reflected wherever the user tracks risks.
   - Write the markdown to `local/daily-gn/YYYY-MM-DD.md` and display a share-ready draft inline for copy-paste, formatted for the declared channel (see the template below). **The share draft contains ONLY the share layer.**
   - **Weekly-review feed:** these wrap-ups are the raw material for any weekly review the cadence manifest declares — consistent workstream keys make the weekly rollup assemble without rework.

5e. **Nightly compliance strip** — report-by-exception verification that today's enforcers fired. Do NOT re-run any checks; read the outputs the earlier steps already produced tonight and assert each is clean:

   | Check | Source |
   |---|---|
   | Daily wrap-up compiled, both layers + capture prompts answered | step 5d |
   | Declared evening sweeps ran (or their skip was reported) | step 1b report |
   | Open-threads hygiene done; WF items past `nudge if:` actioned or queued for the morning | step 5b |
   | Ticket coverage clean (every work item ticketed or explicitly no-ticket) — if a tracker is declared | step 5c |
   | Evening cadence rows for today satisfied | `local/journals/_cadence.md` → "Evening verification" section |

   - **Evening cadence rows:** evaluate the manifest's Evening verification section against today's day-of-week. The manifest is the single source of these rules — never hard-code day-of-week checks here. A missed row gets fixed now if quick, otherwise becomes tomorrow's first action in the handoff.
   - **Log the strip** so the week rolls up without archaeology:
     `~/.config/claude-code/hooks/lib/track-accomplishment.sh "compliance" "strip YYYY-MM-DD: N/M green" "<exception list, or 'clean'>"`
   - **Report by exception in the recap:** a clean night is one line ("Compliance: 5/5 green"). Each exception gets one sentence — what, why, when it gets fixed — and lands in the handoff's tomorrow-top-3 if it needs morning action.
   - Weekly reviews can read the `compliance` rows from `local/daily-gn/.tracking/*.jsonl` instead of reconstructing the week.

5f. **⛔ STATUS VERIFICATION GATE — run before writing a single line of the handoff.**

   **The rule: every claim that work is done, or not done, must be verified against the system of record. Never from transcript prose, drafting notes, or your own memory of the session.**

   This exists because the failure happens repeatedly and in both directions:
   - A handoff once recorded a batch of replies as *"drafted but NONE SENT"* and made sending them the next day's #1 priority — they had all been sent that evening. A morning was nearly spent re-doing finished work.
   - The same handoff warned that prose *"compresses toward more complete than reality"* — and then compressed the other way. **Prose compresses in whichever direction the writer's last memory points.**
   - Status fields and row notes in external databases drift apart — a field query can over-report by 2× against what the notes record.

   **Systems of record, by claim type — as declared in the foundation manifest. No declared system for a claim type → the claim is written as `unverified`.**

   | Claim | Verify against |
   |---|---|
   | "Sent" / "not sent" (email) | The email platform's **sent mail** (e.g. `in:sent after:YYYY/MM/DD`). The absence of a draft is *not* evidence of a send; the presence of a draft is *not* evidence of a non-send |
   | "Sent" / "not sent" (chat/messaging) | The thread itself — never a drafts ledger alone |
   | Ticket status / done / closed | The **task tracker**, fetched now. Not what a checkpoint said earlier today |
   | Counts / pipeline / database state | The declared **docs/database platform**, queried now; cross-read row notes against status fields — those drift apart |
   | CRM stage or deal movement | The declared **CRM**, fetched now |
   | Artifact exists | `ls` / `Read` the actual path. An agent reporting a file was written is not proof |

   **Procedure:**
   1. Take every candidate line for *What We Accomplished*, *Not done*, and *Tomorrow's top-3*.
   2. For each, name its system of record and check it. Batch the checks — one sent-mail query and one tracker pull usually cover most of the list.
   3. Anything you could not verify goes in as **`unverified —`** with the reason. That is always acceptable; a confident wrong status is not.
   4. If a verification **contradicts** the session's own narrative, the system of record wins. Write the correction into the handoff explicitly, naming what was believed and what was true — the correction is more useful to tomorrow than the tidy version.

   **Work you did not personally do is the highest-risk category.** Parallel windows, subagents, and prior sessions all report through prose. Verify their claims before repeating them.

6. **Summarize and sign off**:
   - Provide a brief recap of the session
   - Mention what's ready for tomorrow
   - **Never state a status in the recap that step 5f did not verify.**

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

A human-readable, colleague-facing summary — the important work, not the minutia. Colleagues read this to understand what you focused on, accomplished, are troubleshooting, and are blocked on.

```markdown
---
date: YYYY-MM-DD
day: DayOfWeek
week: NN
---

# Daily GN - YYYY-MM-DD

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

## Tracking (not for sharing)

### Progress by workstream

**[Workstream heading 1 — from the foundation manifest]**
- [Outcome, plain language (TEAM-123)]

**[Workstream heading 2]**
- [Outcome]

*(Only include workstreams that had movement today.)*

### Scoreboard
- [Workstream]: [current]/[target] [counter name] — only if targets are declared

*(Only lines that moved today or are newly at risk; omit the section if no targets are declared.)*

### Said no to
- [Net-new ask declined or deferred today + where it landed — or "None"]

### New risks / changed assumptions
- [Anything newly visible that changes a plan or assumption — or "None"]
```

### Share Draft Format

The share draft is the **share layer only** — Focus / Accomplished / Troubleshooting / Blocked — formatted for the foundation's declared share-out channel (Slack `*bold*` + `•` bullets, Discord/markdown `**bold**` + `-` bullets, or plain text). The tracking layer never goes to the channel.

```
*Daily GN - Month DD*

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

- **Colleague-readable** — write for people who don't know your work. Outcomes, not tools or filenames. "Scoped the full cycle in the tracker with effort estimates" not "edited TEAM-123, TEAM-124…".
- **Summary, not minutia** — consolidate related work into one bullet; 3–6 progress bullets max; skip routine admin.
- **Focus** is the day's story in 1–3 lines — what you chose to spend the day on.
- **Workstream keys are stable** (tracking layer) — use the same workstream names verbatim every day (they key the weekly rollup). A ticket ID in-line per bullet where one exists; the ID is a pointer, not the story.
- **Share draft = share layer only** — never include the Tracking section in the copy-paste draft.
- **Blocked** should be specific (who/what), so a colleague can actually help.
- **"None"** is a perfectly good answer for Troubleshooting and Blocked.

## Notes

- This pairs with `/daily-session` to complete the daily loop
- The handoff lives in the transcript (not a separate file) - single source of truth
- Tomorrow's `/daily-session` will read this handoff section AND scan for exports
- The "Other Sessions Today" aggregation ensures nothing falls through the cracks
- "Unified Open Threads" gives tomorrow a prioritized starting point across all work
- Keep the handoff concise but complete enough to resume context
- **No `/export-conversation` needed after this** — the handoff IS the export for the daily session
- **The daily wrap-up is produced here**: step 5d compiles it from the `.jsonl` tracking log + transcript and writes `local/daily-gn/YYYY-MM-DD.md` + a share draft. The work-tracking hooks populate the `.jsonl` automatically.
- **Task-tracker sweep** (step 5c): reconciles the tracker with the day's work — status auto-applied, comments + project updates require approval.
- **Compliance strip** (step 5e): the nightly "did anyone have to chase me today" answer. It verifies outputs, never re-runs checks; reports by exception; logs a `compliance` event to the tracking `.jsonl` so weekly reviews are a read, not an investigation.
- Use `date +"%I:%M%p"` for accurate timestamps when writing handoff
- **Late-night sessions**: Auto-detection handles sessions that span past midnight. Use `--date` flag if you need explicit control.
