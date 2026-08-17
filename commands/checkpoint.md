---
disable-model-invocation: true
model: opus
---

Create a timestamped checkpoint in the current daily session transcript.

## Model & cost note

`/checkpoint` fires when session context is at its largest and re-sends that full context on every tool round-trip, which makes it one of the most expensive commands in the workflow — yet everything in it is procedural writing plus verification against systems of record, not frontier reasoning. The `model:` frontmatter pins execution to a strong-but-cheaper model; the checkpoint's fidelity comes from the session context, which the override does not change. Adjust the pin to taste.

## Command Usage
- `/checkpoint` - Create checkpoint with auto-generated summary
- `/checkpoint [note]` - Create checkpoint with specific note/context
- `/checkpoint --archive` - Also archive the full conversation to `archives/` (heavier; off by default)

## Foundation gate

After resolving the vault (step 0), read `local/journals/_foundation.md`. Steps marked **[gated: <capability>]** run only when the foundation declares that capability with a connected MCP; otherwise use the stated fallback. No foundation file → vault-only behavior throughout.

## What This Command Does

0. **Resolve the active vault — CWD-first, hard-scoped.** Walk **up** from the current working directory looking for a `.claude-vault.json` marker (CWD, then each parent, stopping at `$HOME`); its `vault_path` is the **ACTIVE VAULT**. Every `local/...` path in this command is relative to `<VAULT>`, not the shell CWD. Lanes are mutually exclusive — never write a checkpoint into another vault's transcript. **No marker found → STOP and ask** which lane's vault this session belongs to (offer to drop a repo marker); never guess by recency.

1. **Identify the current transcript file:**
   - Look for `<VAULT>/local/ai-chats/transcripts/YYYY-MM-DD/daily-session-YYYY-MM-DD.md` in the active vault resolved in step 0
   - Use today's date

2. **Archive the current conversation** (opt-in — only when `--archive` is passed):
   - By **default, SKIP this step** — the transcript entry below plus the PreCompact hook already preserve enough context, and full-conversation archiving on every checkpoint is the heaviest part of the workflow.
   - When `--archive` is passed: create `local/ai-chats/transcripts/YYYY-MM-DD/archives/` and export the full transcript to `session-YYYY-MM-DD-HHMM-full.md`.
   - When `--archive` is NOT used, omit the "Full transcript" archive link from the checkpoint entry (or link to the transcript file itself instead).

3. **Generate checkpoint entry:**
   - Current timestamp (e.g., `### ~3:45pm - Checkpoint`)
   - Link to the archived full transcript
   - If user provided a note, use that as the summary line
   - Otherwise, generate a brief summary of what's been accomplished
   - Include structured data matching PreCompact format

4. **Append to transcript:**
   - Add the checkpoint entry to the "Session Log" section (before "## Session Handoff")
   - Include key activities with [[wiki-links]]
   - Include summary points

5. **Update daily note:**
   - Find today's daily note at `local/journals/YYYY-MM-DD.md`
   - Increment the checkpoint count (e.g., `*(2 checkpoints)*` → `*(3 checkpoints)*`)
   - Add a nested bullet with deep link to the checkpoint section

5a2. **Append to the rolling Artifact Log** (`local/journals/_artifact-log.md`) — the recall index:
   - Walk this checkpoint's **Key Activities** Created/Modified lines. For each entry that is a **durable deliverable**, append a row to the table (newest-first, so insert directly under the header row).
   - **Row shape:** `| YYYY-MM-DD | Artifact name | Type | Where | What it's for | Ticket |`
     - **Type:** name the artifact's home per the foundation's docs platform — e.g. `Notion` · `Vault` · `Deck` · `Doc` (combine when one artifact has two homes, e.g. `Vault + Notion`).
     - **Where:** the vault-relative path, and/or a markdown link to the external page. Keep URLs inside `[link](url)` so rows stay readable.
     - **What it's for:** one clause, **<=15 words**, that makes it findable three weeks later when the user remembers the problem but not the filename. This is the load-bearing column — never leave it generic, and never let it grow into a summary. **The row is a pointer, not a summary** — the artifact holds its own detail; narrative paragraphs in rows kill the table's read-every-morning economics.
     - **Ticket:** the tracker ID from step 5b, or `—`.
   - **What counts:** external doc pages, vault docs/memos/write-ups, decks and presentations, durable logs and registries **on creation**, skills and commands, research packs and one-pagers.
   - **What doesn't:** transcripts, daily journals, `_open-threads.md` hygiene edits, tracker/CRM/database rows, code and tooling, individual message drafts. Rolling logs get a row on creation and on a substantive batch append — not on every touch.
   - **The filter is the point:** if the user would go looking for it three weeks later, it goes in; if it's session bookkeeping, it doesn't. Logging everything turns this into a git log and kills its recall value.
   - A checkpoint with no durable deliverables appends nothing — that's a normal outcome, not a miss.
   - If the file doesn't exist, create it from the vault-init skeleton. Roll-off past 21 days is `/end-day`'s job, never this command's.

5a3. **Open-threads record sync — write while hot** (`local/journals/_open-threads.md` + `_open-threads-changelog.md`). Records are written at the checkpoint, while the quotes, rationale, and outcomes are still in context — never parked "for /end-day", whose cold-context authoring is the workflow's most repeated defect source. Contract: the files' own headers + `local/journals/_JOURNAL-SYSTEM.md`.
   - **Scope: ONLY threads this stretch of work touched** (typically 1-3). Never rewrite the whole board — full-board reconciliation is /end-day's job. This scoping also keeps parallel windows from colliding: each window edits only the threads it worked; the changelog is append-only and safe.
   - For each touched thread, a **two-layer write**:
     - **Live entry** (`_open-threads.md`): update the state block in place — state, dates, `next:`, `nudge if:` — keeping it within the ~6-line schema in the file header. New threads get a new state block in the right section, **including the required `detail:` pointer**.
     - **Narrative** (`_open-threads-changelog.md`): append the substance — what happened, quotes, rationale, why-it-matters — under today's `## YYYY-MM-DD` header (create it if this is the day's first write; newest day first) with a `### <thread name>` subheader. This is prose the checkpoint summary would have contained anyway; it lives in the changelog so the live doc stays at index altitude.
   - **Waiting For resolutions land NOW:** a reply arrived, a send was verified, an ask was answered → update the WF entry + changelog note at this checkpoint, not at midnight.
   - **Closures land NOW:** a thread that finished moves to `_open-threads-archive.md` (stamped `closed: YYYY-MM-DD`) at the checkpoint that closed it.
   - A checkpoint that touched no tracked threads writes nothing here — normal outcome, not a miss.
   - Record-keeping follow-through is pre-authorized — just do it and summarize in the checkpoint reply. Outward-facing sends still get surfaced first.

5b. **Task-tracker ticket sync [gated: task tracker] (ticket-first rule):**
   - Identify the ticket(s) this checkpoint's work belongs to: the ticket IDs recorded next to Session Goals in the transcript (written by `/daily-session` step 4d), plus any IDs named in the checkpoint note or open-threads.
   - **Status (auto):** any linked ticket still in Todo/Backlog whose work just started → flip to In Progress. Status flips are pre-authorized; just report them.
   - **Comments (draft + approve):** for each linked ticket where this checkpoint represents knowledge-worthy movement (decision, deliverable, blocker, scope change — not routine progress), draft a one-to-three-line comment. Present all drafts in one batch for approval; post only what the user approves. Skip drafting entirely for minor increments — /end-day's sweep will catch the day's narrative.
   - **Unticketed work check:** if this checkpoint's work maps to NO known ticket and wasn't designated no-ticket at session start, flag it in the chat reply ("this work has no ticket — create one?") and offer creation (team/project + title + estimate). Record a no-ticket designation if the user declines, so it isn't re-flagged.
   - **No task tracker declared →** skip this step; the open-threads sync (5a3) is the tracking layer.

6. **Always reply with a goal-progress table (chat only):**
   - After the file writes are done, end the response with a table showing how the day is tracking against today's goals. This is a **chat reply only** — do NOT write it into the transcript or daily note.
   - Source the goals from today's daily journal `## Start of Day Reflections` → **Today's Focus** list (`local/journals/YYYY-MM-DD.md`). If that list is empty/missing, fall back to the owned items in `local/journals/_open-threads.md` (or the session's stated goals) and note that you did so.
   - Reason over the session so far + declared systems of record to assign each goal a status. Keep one row per goal, in the original order.
   - See **Goal Progress Table** format below. Always include this, whether or not a `[note]` argument was passed.

## Checkpoint Entry Format (Transcript)

```markdown
### ~[TIME] - Checkpoint
[Summary line - user note or auto-generated]. [[local/ai-chats/transcripts/YYYY-MM-DD/archives/session-YYYY-MM-DD-HHMM-full|Full transcript]]

**Session:** [[Session Type]] | [N] messages | [N] tool calls | [N] created | [N] modified

**Key Activities:**
- Created: `path/to/file` ([[Language]])
- Modified: `path/to/file` ([[Language]])
- [Other notable activities with wiki-links]

**Summary:**
- Key accomplishment 1 with [[wiki-links]]
- Key accomplishment 2
- Decisions or insights

---
```

## Daily Note Entry Format

The nested bullet under the session entry should follow this format:

```markdown
- ~HH:MMam - [[transcript-link|Daily Session: Topic]] *(N checkpoints)* - Description
	- [[transcript#~TIME - Checkpoint|~TIME]]: Brief summary with key [[wiki-links]]
```

**Format guidelines for the summary:**
- Start with the main topic/accomplishment (not "Checkpoint:" prefix)
- Include 1-2 key wiki-links for graph connectivity
- Keep under 100 characters
- Be semantic (describe WHAT was done, not file paths)

**Good examples:**
- `Config fix complete, rich transcript template with [[YAML]] frontmatter`
- `Created [[Product PRD]], researched [[knowledge graph]] architecture`

**Bad examples:**
- `.../transaction-executor/transaction-...` (truncated file path)
- `Pre-compaction (579 msgs)` (no semantic content)
- `Working on stuff` (too vague)

## Goal Progress Table (chat reply)

Every `/checkpoint` ends with this table in the chat response so the user can see progress against the day's goals at a glance. It is **not** persisted to any file.

**Format:**

```markdown
Here's where the day's goals stand:

| # | Goal | Status |
|---|------|--------|
| 1 | <Today's Focus item 1> | ✅ Done <short note / ticket> |
| 2 | <Today's Focus item 2> | 🔄 In progress <short note / ticket> |
| 3 | <Today's Focus item 3> | ⏳ Not started |
| … | … | … |

<One-line read on overall progress (e.g. "3 done, 2 in motion, 1 not started").>
```

**Status conventions:**
- ✅ **Done** — completed and verified this session (cite the ticket/artifact)
- 🔄 **In progress** — actively moving, has a ticket/draft behind it (cite it)
- ⏳ **Not started** — no movement yet today
- 🚧 **Blocked** — waiting on someone/something (name it)
- ➕ **Bonus** — meaningful work done that wasn't one of the morning goals (optional extra rows at the bottom)

**⛔ Verification gate — run before assigning any status.**

**Every ✅ Done and every ⏳ Not started must be verified against the system of record the foundation declares for that claim type, not recalled from the session.** Sent mail for email sends (e.g. `in:sent after:YYYY/MM/DD`), the task tracker fetched now for ticket state, the declared docs/CRM platform for counts and stages, an actual file read for artifacts. **The absence of a draft is not evidence of a send, and the presence of one is not evidence of a non-send.** A claim type with no declared system of record is written as `unverified` with the reason.

This is the most repeated defect in this workflow and it runs in *both* directions — work marked outstanding that was finished hours earlier, and work marked done that only ever reached draft. Prose compresses in whichever direction the writer's last memory points. A row you cannot verify is written as `unverified` with the reason, which is always better than a confident wrong one.

**Highest-risk category: anything you did not personally do** — a parallel window, a subagent, an earlier checkpoint in the same session. Verify before repeating it. Two windows once produced contradictory goal tables at the same timestamp because one read the other's prose instead of the tracker.

**How to run the lookups (evidence-collection protocol):**

1. **Compose an evidence checklist first.** From the day's goals, touched threads, and linked tickets, list every item needing verification with its exact source: the sent-mail query (`in:sent after:YYYY/MM/DD <recipient/subject>`), the tracker ticket ID, the docs/CRM page. Precision here is load-bearing — the checklist is the handoff.
2. **Delegate the remote lookups to ONE subagent** (general-purpose; pick a strong model — MCP query construction is where this silently goes wrong) carrying the full checklist. One large-batch agent, never one per lookup. Its brief: run every lookup (parallelize where possible) against the foundation-declared servers and return a compact evidence table — item | source + exact query used | raw finding (message ID, timestamp, status field, stage name). **"No results for query X" is itself a finding and must be reported as such, never omitted.**
3. **The subagent returns evidence, never verdicts.** Status assignment (✅/🔄/⏳/🚧) happens back here, in full session context, by applying the gate rules to the evidence table. Ambiguous evidence → re-query in-context before assigning; still ambiguous → `unverified` with the reason.
4. **Fallback, never skip:** if the subagent fails or an MCP is unreachable from it, run the same checklist in-context with the lookups batched in parallel (one block, not sequential). The gate is never skipped and never downgraded to session memory.
5. **Local file reads stay in-context** (artifact existence, transcript state) — they're cheap and need no hop.

Why delegate: the lookups' raw payloads (mail search results, tracker JSON) otherwise enter the main conversation and are re-billed by every subsequent turn of the session — the subagent keeps them permanently out of context, which also delays compaction. Vault-only foundations (no remote MCPs declared) skip the subagent entirely; file reads are the whole gate.

**Guidelines:**
- One row per Today's Focus goal, preserving their original order and wording (compress long goals to a short label).
- Be honest — don't mark something Done unless it actually is. Half-done → 🔄 with what's left.
- Keep notes terse (a ticket ID, a one-clause status). Tie to the tracker/docs platform where there's a record.
- End with a single summary line (the tally) so progress is legible in one glance.

## Alignment with PreCompact Hook

This command produces output aligned with the PreCompact auto-checkpoint hook:

| Element | Manual `/checkpoint` | PreCompact Auto |
|---------|---------------------|-----------------|
| Transcript header | `### ~TIME - Checkpoint` | `### ~TIME - Checkpoint (Pre-Compaction)` |
| Archive link | Yes | Yes |
| Session stats | Yes | Yes |
| Key Activities | Yes | Yes |
| Summary section | `**Summary:**` bullets | `**User Requests:**` excerpts |
| Daily note format | Semantic summary | `Pre-compaction (N msgs). Type - topic` |

The header distinction (`Checkpoint` vs `Checkpoint (Pre-Compaction)`) makes it clear which are manual vs automatic.

## Wiki-Link Integration

Use [[wiki-links]] liberally for:
- Projects: [[Your Project]], [[Claude Code Daily Session]]
- Technologies: [[Python]], [[Bash]], [[TypeScript]]
- Concepts: [[knowledge graph]], [[world model]], [[dogfooding]]
- Tools: [[Obsidian]], [[Claude Code]]
- Your notes: [[PRD]], [[Research Notes]]

## Tracking Integration

After creating the checkpoint entry, also log the accomplishment for daily wrap-up tracking:

```bash
~/.config/claude-code/hooks/lib/track-accomplishment.sh "checkpoint" "<summary line>" "<key activities>"
```

This ensures the checkpoint's summary appears in the daily tracking log at `local/daily-gn/.tracking/YYYY-MM-DD.jsonl`, which `/end-day` uses to compile the day's accomplishments.

## Implementation Notes

- Transcript file should already exist (created by `/daily-session`)
- Checkpoints are append-only - never modify previous entries
- Archive is created BEFORE the checkpoint entry (so link is valid)
- Deep link format: `[[path#Header Text|Display Text]]`
- Timestamps use `~` prefix to indicate approximate time
- Focus on semantic summaries, not file paths
- **Always end the chat reply with the Goal Progress Table** (step 6) — it's the part the user fires `/checkpoint` to see. Never persist it to a file; it's a chat-only readout.

## Example

User: `/checkpoint Finished knowledge graph PRD and research integration`

**Result in transcript:**
```markdown
### ~10:20am - Checkpoint
Finished knowledge graph PRD and research integration. [[local/ai-chats/transcripts/2025-12-02/archives/session-2025-12-02-1020-full|Full transcript]]

**Session:** [[Planning]] + [[Research]] | ~80 messages | ~40 tool calls | 2 created | 3 modified

**Key Activities:**
- Created: `Personal World Model PRD.md` ([[Markdown]])
- Read: [[knowledge-graph-for-agents]] (research export)

**Summary:**
- Created [[Personal World Model PRD]] with three-phase architecture
- Integrated prior research on [[knowledge graph]] / [[world model]]
- Validated cross-tool workflow: research → Obsidian → Claude Code

---
```

**Result in daily note:**
```markdown
- ~8:38am - [[daily-session-2025-12-02|Daily Session: Workflow & KG]] *(4 checkpoints)* - Testing workflow, knowledge graph planning
	- [[...#~8:49am - Checkpoint|~8:49am]]: Config fix, rich transcript template with [[YAML]] frontmatter
	- [[...#~10:20am - Checkpoint|~10:20am]]: Created [[Personal World Model PRD]], [[knowledge graph]] research integration
```
