---
type: journal-system-contract
created: {{date}}
tags:
  - JournalSystem
  - Contract
---

# The Journal System — Architecture Contract

How the rolling journal files in `local/journals/` work together. Every rolling file's header links here; the commands (`/daily-session`, `/checkpoint`, `/end-day`, `/daily-resume`, the sweeps) reference this contract instead of each carrying its own copy of the rules.

## The one convention

Every rolling file follows the same shape:

1. **Live window** — the only part read at session start. Kept small by a hard time window (days) and/or a hard per-entry budget (lines).
2. **Append-only companions** — archive and/or changelog. Rolled to, **never deleted from** ("move, never delete"). A vault may declare a deliberate exception for a file whose durable record lives in an external system — name the exception and its external record here if you add one.
3. **Required pointers** — a live entry is index-altitude and MUST name where its detail lives: a changelog date-anchor, a ticket, a transcript date, an artifact path. Detail is one deterministic hop away, never "somewhere in a transcript".
4. **Schema in the file header** — each file's header states its own entry schema and budget, so any agent that opens the file reads the rules in the same breath. The header is the contract; this doc is the map.

## Ownership model: write hot, reconcile cold

**Records are written when context is hot. Day's end reconciles, rolls, and compiles — it does not author.**

- **`/checkpoint` is the primary record writer.** At each checkpoint (a natural stopping point, context fresh) it: updates the live entries of threads touched since the last checkpoint, appends their narrative to the changelog under today's date, records Waiting For resolutions the moment they're observed, appends artifact rows, and syncs the task tracker (if `_foundation.md` declares one).
- **`/end-day` is the reconciler + roller.** It diffs the day's checkpoints against the systems of record and writes only what checkpoints missed; runs the rolls; enforces the hygiene gate (entry budgets, required pointers, no closed items inline); and compiles the Recent Activity daily line + the handoff FROM checkpoint-written records. When end-day must author a record from recall (un-checkpointed work), it flags that record in the handoff as lower-confidence.
- **Why:** prose compresses in whichever direction the writer's last memory points. The writer closest to the event writes the record.

## File roster

| File | Live window / budget | Companions | Written by | Read at session start? |
|---|---|---|---|---|
| `_open-threads.md` | entries at <=6 lines; Recent Activity 14 days | `-archive` (closed) · `-changelog` (narrative) | /checkpoint (hot) · /end-day (reconcile + roll + gate) | Yes — live file only |
| `_open-threads-changelog.md` | append-only, newest-first | — | /checkpoint (today's narrative) · /end-day (Recent Activity roll-off) | No — fetched via entry pointers |
| `_open-threads-archive.md` | append-only | — | whoever closes a thread | No — grep on demand |
| `_artifact-log.md` | 21 days; rows at pointer altitude (<=15-word purpose) | `-archive` | /checkpoint (rows) · /end-day (reconcile + roll) | Yes — cheap at pointer altitude |
| `_cadence.md` | small by nature | — | manual · seeded by /onboard | Yes |
| `_foundation.md` | small by nature | — | /onboard (interview) · manual edits | Yes — it gates every platform/MCP step |
| Daily transcript | one day | — | /daily-session · /checkpoint · /end-day | Yesterday's **Session Handoff + Session Goals** sections only (extracted, never the full file) |

## Open-threads entry schema (the budget)

A live entry is a state block, **max ~6 lines**:

```markdown
### <Who / what> — <one-line state>
- **state:** <waiting / owed-ours / blocked / in-progress> · asked/opened YYYY-MM-DD · nudge/due YYYY-MM-DD
- **next:** <the single concrete next action>
- **why (1 line):** <the one sentence that justifies the thread's existence>
- **channel:** <email · chat · slack · call>   <!-- Waiting For items only; inbox scans match on it -->
- **links:** <ticket IDs · deal IDs> · **detail:** [[_open-threads-changelog#YYYY-MM-DD]] / transcript YYYY-MM-DD
```

Everything else — quotes, precedent stories, why-it-matters paragraphs, pattern commentary — goes to the **changelog under today's `## YYYY-MM-DD` header with a `### <thread name>` subheader**, written at checkpoint time while it's still accurate. An entry without a `detail:` pointer fails /end-day's hygiene gate.

## Reader escalation path

When *working* a thread (not merely listing it): live entry → follow its `detail:` pointer (changelog date-anchor · ticket · transcript) → grep archive/changelog for the thread name. Never load an archive or changelog in full at session start. `/daily-session` fetches changelog detail ONLY for the confirmed plate items (the threads actually being worked today), after the plate is confirmed.

## Why this exists

An August 2026 audit of the original vault found the morning load at ~110k tokens because every index file had inflated into the narrative it was designed to point at (the live open-threads doc alone: 292KB). The file architecture was right; the altitude drifted. This contract pins the altitude and names the enforcement points.
