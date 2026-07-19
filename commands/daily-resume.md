---
disable-model-invocation: true
---

Catch up a fresh Claude Code window on TODAY's already-in-progress daily session — **read-only**, no `/daily-session` rerun.

## Usage

```
/daily-resume          # Auto-detect today's active vault + session, greet with a status summary
```

- Use this when you open a **new terminal window** mid-day and want this session to know what's already happened today, **without** starting a new daily session.
- **Read-only and safe to run in any window, any number of times.** It reads existing files and replies in chat. It does **NOT** create, overwrite, or modify any transcript, journal, or open-threads file.
- It does **not** replace `/daily-session` (which sets up the day) — it ingests the handoff that `/daily-session` + `/checkpoint` have already produced today.

---

## What This Command Does

1. **Compute today's date** with `date +%F` (YYYY-MM-DD). Capture the current time with `date +"%I:%M%p"` for the greeting.

2. **Resolve the active vault — CWD-first, hard-scoped.** Each project lane (work, personal projects, …) lives in its OWN vault with its OWN `local/` subtree (`_open-threads.md`, journals, transcripts). Lanes are **mutually exclusive**: this command must never surface another vault's content. Resolution algorithm:

   **2a. CWD → vault mapping (the normal path):**
   - Walk **up** from the current working directory looking for a `.claude-vault.json` marker (check CWD, then each parent, stopping at `$HOME`).
   - If found, read its `vault_path` field — that directory is the **ACTIVE VAULT**. (A marker inside a vault points to itself; a marker in a project repo points to that repo's companion vault.)
   - **Hard scope:** every glob and read in the remaining steps happens inside `<VAULT>` ONLY. Never glob across all vaults on the machine.
   - Within the active vault, pick the session to sync from:
     1. Today's transcript `<VAULT>/local/ai-chats/transcripts/<TODAY>/daily-session-<TODAY>.md` → use it.
     2. Else today's journal `<VAULT>/local/journals/<TODAY>.md` → light-mode day (see step 6).
     3. Else fall back to the most recent prior session **in this vault only** — most recent `daily-session-*.md` transcript, or, if the vault's latest journal is newer than its latest transcript, that journal (light-mode day). State the fallback clearly: "No session logged today in `<vault>` — showing the most recent (`<DATE>`, N days ago)." Compute N as the day delta from `<TODAY>`.

   **2b. No marker found (e.g. running from `~` or an unmapped directory) — do NOT silently guess:**
   - List the candidate vaults on this machine that have a `.claude-vault.json` (e.g. under your Obsidian documents directory), with each one's most recent session date.
   - **Ask the user which lane to sync from** before reading any session content. Only if they've already named a vault/lane in this conversation may you skip the ask.
   - Also suggest fixing the gap permanently: drop a `.claude-vault.json` marker (with `vault_path`) in the project repo they're working from.

   *(A future metalayer may aggregate across lanes; until then, cross-vault reads are never done implicitly.)*

3. **Read today's transcript (primary source)** — `<VAULT>/local/ai-chats/transcripts/<TODAY>/daily-session-<TODAY>.md`:
   - This is the live record of the day: the **Today's Context** block, the **Session Goals**, the full **Session Log** (Session Start + every Checkpoint, including PreCompact ones).
   - This is the authoritative source for what has actually happened today. Reason over the checkpoints in order.

4. **Read today's daily journal** — `<VAULT>/local/journals/<TODAY>.md`:
   - Extract the **Today's Focus** list from `## Start of Day Reflections` — these are the day's goals for the progress table.
   - Extract **mood / energy / focus** from the Mood Check / reflections.
   - Note the checkpoint count on the Claude Sessions entry.

5. **Read the cadence manifest** — `<VAULT>/local/journals/_cadence.md` (skip silently if absent):
   - Evaluate today's triggers the same way `/daily-session` step 4c does (date + day-of-week, cycle position, today's calendar if already known from the transcript — do NOT make external calls for this; the transcript's Today's Context block usually has the calendar).
   - Today's cadence items (recurring sweeps, meeting prep with meeting name + time, recurring reports, /end-day) get **their own rows in the Goal Progress Table** — never prose-only mentions. Cross-check the transcript's Session Log to mark which already ran.

5b. **Read the rolling Open Threads doc** — `<VAULT>/local/journals/_open-threads.md`:
   - This is the canonical in-flight owned work + waiting-for state.
   - **Read this LIVE file only.** Do NOT read its companions `_open-threads-archive.md` or `_open-threads-changelog.md`.
   - Pull the most recent activity, owned threads' next actions, and any waiting-for items past their `nudge if:` date.
   - If the file doesn't exist, skip it — it's optional infrastructure.

6. **Handle light-mode / missing-file days gracefully** (a session may have been run with `/daily-session --light`, which creates **no transcript**):
   - If there is **no transcript** but there **is** a journal for today → read the journal (+ open-threads) and say so: "Today looks like a light-mode day — no transcript exists, working from the journal."
   - If there is **only** a transcript and no journal → use the transcript; note the journal is absent.
   - If **neither** exists for today → you're in the step-2 fallback case; report it as above and summarize the most recent prior session instead.
   - Read whatever exists; never error out for a missing optional file.

7. **Greet with a catch-up summary — IN CHAT ONLY. Write NOTHING to disk.** The greeting includes, in this order:
   - **Synced from:** which vault + date you pulled from. Flag if it was a **fallback** (no session today) or **ambiguous** (multiple vaults matched today).
   - **Day's mood / energy / focus:** from the journal's `## Start of Day Reflections`.
   - **Goal Progress Table:** the exact table format + status conventions from `/checkpoint` (see below). One row per **Today's Focus** goal, in original order, with a status reasoned from the transcript's checkpoints.
   - **Since the last checkpoint / loose ends:** a short section drawn from the **most recent checkpoint** + open-threads — parked items, manual steps still pending, and aging waiting-fors (past `nudge if:`).
   - **End by asking what they want to focus on next.**

## Goal Progress Table (chat reply — identical to `/checkpoint`)

Reuse the exact format and status conventions from `/checkpoint`. Reason over today's transcript checkpoints (+ task-tracker state if relevant) to assign each goal a status.

```markdown
Here's where the day's goals stand:

| # | Goal | Status |
|---|------|--------|
| 1 | <Today's Focus item 1> | ✅ Done <short note / ticket> |
| 2 | <Today's Focus item 2> | 🔄 In progress <short note / ticket> |
| 3 | <Today's Focus item 3> | ⏳ Not started |
| … | … | … |
| ⏰ | AM comms sweep | ✅ Done (ran in morning session) |
| ⏰ | prep for <meeting> at <time> | ⏳ Not started |
| ⏰ | Evening /end-day | ⏳ Not started (evening) |

<One-line read on overall progress (e.g. "3 done, 2 in motion, 1 not started").>
```

**Status conventions:**
- ✅ **Done** — completed and verified per the transcript (cite the ticket/artifact, e.g. `TICKET-123`)
- 🔄 **In progress** — actively moving, has a ticket/draft behind it (cite it)
- ⏳ **Not started** — no movement yet today
- 🚧 **Blocked** — waiting on someone/something (name it)
- ➕ **Bonus** — meaningful work done that wasn't a morning goal (optional extra rows at the bottom)

**Guidelines:**
- One row per Today's Focus goal, preserving original order and wording (compress long goals to a short label).
- **Cadence rows are mandatory** (marked `⏰` in the # column, listed after the focus goals): one per cadence item due today per `_cadence.md` + the transcript's Session Goals, each with concrete trigger detail (which meeting, what time, which batch). Status from the Session Log (ran / pending / declined-today).
- Be honest — don't mark Done unless the transcript shows it's actually done. Half-done → 🔄 with what's left.
- Keep notes terse (a ticket ID, a one-clause status). Tie to your task tracker where there's a record.
- If Today's Focus is empty/missing, fall back to the owned items in `_open-threads.md` (or the transcript's Session Goals) and note that you did so.
- End with a single summary line (the tally) so progress is legible in one glance.

## Notes

- **Read-only by design.** This command never writes, creates, or modifies any file — it only reads today's transcript, journal, and `_open-threads.md`, then replies in chat. To capture progress, use `/checkpoint`; to wrap up, use `/end-day`.
- **Vault resolution is CWD-first and hard-scoped (the load-bearing part):** the lane you're standing in (via the nearest `.claude-vault.json` marker's `vault_path`) decides the vault — never date-based guessing across vaults, never cross-vault globs. Lanes are mutually exclusive; each vault has its own `_open-threads.md` and session files. No marker → list lanes and ask, don't guess.
- The **transcript is the primary source**; the journal supplies the day's goals + mood; `_open-threads.md` supplies loose ends and waiting-fors.
- Read the **live `_open-threads.md` only** — not the `-archive` / `-changelog` companions.
- Use `date +%F` and `date +"%I:%M%p"`, consistent with `/daily-session`, `/checkpoint`, and `/end-day`.
- Gracefully handles **light-mode days** (journal but no transcript) and **no-session-today days** (falls back to the most recent prior session, clearly labeled).
- Safe to run in any new window, repeatedly — it's a pure catch-up / handoff-ingest.
