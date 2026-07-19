---
disable-model-invocation: true
---

Create a timestamped checkpoint in the current daily session transcript.

## Command Usage
- `/checkpoint` - Create checkpoint with auto-generated summary
- `/checkpoint [note]` - Create checkpoint with specific note/context
- `/checkpoint --archive` - Also archive the full conversation to `archives/` (heavier; off by default)

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

5b. **Task-tracker sync (optional)** — if you track work in an external tool (Linear, Jira, GitHub Issues, etc.):
   - Identify the ticket(s) this checkpoint's work belongs to: the ticket IDs recorded next to Session Goals in the transcript (written by `/daily-session` step 4d), plus any IDs named in the checkpoint note or open-threads.
   - **Status (auto):** any linked ticket still in Todo/Backlog whose work just started → flip to In Progress. Status flips are pre-authorized; just report them.
   - **Comments (draft + approve):** for each linked ticket where this checkpoint represents knowledge-worthy movement (decision, deliverable, blocker, scope change — not routine progress), draft a one-to-three-line comment. Present all drafts in one batch for approval; post only what the user approves. Skip drafting entirely for minor increments — /end-day's sweep will catch the day's narrative.
   - **Unticketed work check:** if this checkpoint's work maps to NO known ticket and wasn't designated no-ticket at session start, flag it in the chat reply ("this work has no ticket — create one?") and offer creation (project + title + estimate). Record a no-ticket designation if the user declines, so it isn't re-flagged.
   - Skip this step silently if no tracker integration is configured.

6. **Always reply with a goal-progress table (chat only):**
   - After the file writes are done, end the response with a table showing how the day is tracking against today's goals. This is a **chat reply only** — do NOT write it into the transcript or daily note.
   - Source the goals from today's daily journal `## Start of Day Reflections` → **Today's Focus** list (`local/journals/YYYY-MM-DD.md`). If that list is empty/missing, fall back to the owned items in `local/journals/_open-threads.md` (or the session's stated goals) and note that you did so.
   - Reason over the session so far + task-tracker state to assign each goal a status. Keep one row per goal, in the original order.
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
- `Created [[Personal World Model PRD]], researched [[knowledge graph]] architecture`
- `[[Project A]] transaction queue implementation, [[XState]] machine setup`

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
- ✅ **Done** — completed and verified this session (cite the ticket/artifact, e.g. `TICKET-123`)
- 🔄 **In progress** — actively moving, has a ticket/draft behind it (cite it)
- ⏳ **Not started** — no movement yet today
- 🚧 **Blocked** — waiting on someone/something (name it)
- ➕ **Bonus** — meaningful work done that wasn't one of the morning goals (optional extra rows at the bottom)

**Guidelines:**
- One row per Today's Focus goal, preserving their original order and wording (compress long goals to a short label).
- Be honest — don't mark something Done unless it actually is. Half-done → 🔄 with what's left.
- Keep notes terse (a ticket ID, a one-clause status). Tie to your task tracker where there's a record.
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
- Projects: [[Project A]], [[Claude Code Daily Session]]
- Technologies: [[Python]], [[Bash]], [[TypeScript]], [[XState]]
- Concepts: [[knowledge graph]], [[world model]], [[dogfooding]]
- Tools: [[Obsidian]], [[Claude Code]], [[pgvector]]
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
- Read: [[ai-experiments-knowledge-graph-for-agents]] (research export)
- Read: [[Research Notes]]

**Summary:**
- Created [[Personal World Model PRD]] with three-phase architecture
- Integrated prior research on [[knowledge graph]] / [[world model]]
- Validated cross-tool workflow: research → Web Clipper → Obsidian → Claude Code

---
```

**Result in daily note:**
```markdown
- ~8:38am - [[daily-session-2025-12-02|Daily Session: Workflow & KG]] *(4 checkpoints)* - Testing workflow, knowledge graph planning
	- [[...#~8:49am - Checkpoint|~8:49am]]: Config fix, rich transcript template with [[YAML]] frontmatter
	- [[...#~10:20am - Checkpoint|~10:20am]]: Created [[Personal World Model PRD]], [[knowledge graph]] research integration
```
