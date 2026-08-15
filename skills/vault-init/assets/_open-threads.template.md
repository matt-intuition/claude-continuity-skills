---
type: rolling-threads
last_updated: {{date}}
companions:
  - "[[_open-threads-archive]]"
  - "[[_open-threads-changelog]]"
tags:
  - OpenThreads
  - WaitingFor
---

# Open Threads (rolling)

**Source of truth** for in-flight work I own + asks I've made of others. The daily journal mirrors a snapshot of this; this doc is canonical. Update **here first**, then the daily snapshot derives from it. Full architecture: [[_JOURNAL-SYSTEM]].

**Three-file system:**
- **This file** — live working threads + a 14-day Recent Activity window. The only file read each session. **This is an INDEX, not a journal** — entries are state blocks, max ~6 lines each.
- **`_open-threads-archive.md`** — completed / superseded threads (each with a `closed:` date). Append-only; never read in full. Created lazily on first archive.
- **`_open-threads-changelog.md`** — the dated narrative history. Checkpoint-time narrative lands here (under `## YYYY-MM-DD` headers) AND Recent Activity entries older than 14 days roll here. Created lazily on first write.

**Entry schema (hard budget — max ~6 lines per entry):**
```
### <Who / what> — <one-line state>
- **state:** <waiting / owed-ours / blocked / in-progress> · asked/opened YYYY-MM-DD · nudge/due YYYY-MM-DD
- **next:** <the single concrete next action>
- **why (1 line):** <the one sentence that justifies the thread's existence>
- **channel:** <email · chat · slack · call>   (Waiting For items only — inbox scans match replies on it)
- **links:** <ticket IDs · URLs> · **detail:** [[_open-threads-changelog#YYYY-MM-DD]] / transcript YYYY-MM-DD
```
- The **`detail:` pointer is required** — quotes, precedent, why-it-matters paragraphs live in the changelog (written at checkpoint time), the linked ticket, or the day's transcript. An entry without a pointer fails /end-day's hygiene gate.
- **Who writes:** `/checkpoint` updates touched threads while context is hot (live entry + changelog narrative). `/end-day` reconciles what checkpoints missed, rolls the 14-day window, and enforces this schema.
- **Closures:** move the block to the archive (with `closed: YYYY-MM-DD`) at the checkpoint that closed it — never leave closed items inline.

---

## 🗓️ Recent Activity (last 14 days)

<!--
The running timeline, capped to 14 days. /end-day prepends one concise dated entry per day (newest-first,
compiled from the day's checkpoints) and rolls entries older than 14 days off into _open-threads-changelog.md.
Format:  - **YYYY-MM-DD** — <one or two lines: what changed, what shipped, what opened/closed>
-->

_(no activity yet)_

---

## ⏰ Time-Critical — This Week

<!--
Threads with a hard deadline inside the current week. Move here from Owned when the deadline crosses
into "this week"; move to the archive file when resolved. Use the entry schema from the header.
-->

_(no time-critical threads yet)_

---

## Owned — Open Work Threads

<!--
In-flight work I own that doesn't have a this-week deadline. Entry schema from the header.
Group by project/area if it gets long. Otherwise flat.
-->

_(no owned threads yet)_

---

## Waiting For

<!--
Asks I've made of others that block my own work. Surface to the daily handoff when aging past `nudge if:`.
Entry schema from the header — include `channel:` so inbox scans can auto-match replies to open asks.
-->

_(nothing waiting yet)_

---

*Completed & superseded threads → `_open-threads-archive.md` · dated narrative history → `_open-threads-changelog.md` · architecture → `_JOURNAL-SYSTEM.md`*
