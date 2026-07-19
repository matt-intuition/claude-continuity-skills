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

**Source of truth** for in-flight work I own + asks I've made of others. The daily journal mirrors a snapshot of this; this doc is canonical. Update **here first**, then the daily snapshot derives from it.

**Three-file system:**
- **This file** — live working threads + a 14-day Recent Activity window. The only file read each session.
- **`_open-threads-archive.md`** — completed / superseded threads (each with a `closed:` date). Append-only; never read in full. Created lazily by `/end-day` on first archive.
- **`_open-threads-changelog.md`** — the full dated history (timeline). Entries older than 14 days roll here. Created lazily by `/end-day` on first roll-off.

**Conventions:**
- `status:` `not-started` · `in-progress` · `blocked` · `done` (move to archive when done)
- `opened:` ISO date the thread was first owned
- `next:` the single concrete next action (one sentence)
- `blocker:` what's holding it up, or `none`
- `ETA:` optional target completion
- `links:` `[[wiki]]`, ticket IDs, URLs

---

## 🗓️ Recent Activity (last 14 days)

<!--
The running timeline, capped to 14 days. /end-day prepends one concise dated entry per day (newest-first)
and rolls entries older than 14 days off into _open-threads-changelog.md so nothing is lost.
Format:  - **YYYY-MM-DD** — <one or two lines: what changed, what shipped, what opened/closed>
-->

_(no activity yet)_

---

## ⏰ Time-Critical — This Week

<!--
Threads with a hard deadline inside the current week. Move here from Owned when the deadline crosses into "this week"; move to the archive file when resolved.
Template for a new thread:

### <emoji optional> <Short thread name>
- **status:** <not-started · in-progress · blocked> — <one-line context>
- **opened:** YYYY-MM-DD
- **next:** <single concrete next action>
- **blocker:** <what's blocking, or `none`>
- **ETA:** **<deadline>**
- **deliverable:** <what "done" looks like>
- **links:** <wikilinks / ticket IDs / URLs>
- **notes:** <optional — context worth carrying forward>
-->

_(no time-critical threads yet)_

---

## Owned — Open Work Threads

<!--
In-flight work I own that doesn't have a this-week deadline. Same template as above.
Group by project/area if it gets long. Otherwise flat.
-->

_(no owned threads yet)_

---

## Waiting For

<!--
Asks I've made of others that block my own work. Surface to the daily handoff when aging past `nudge if`.
Template:

### <who> — <what>
- **asked:** YYYY-MM-DD
- **what:** <one-line ask>
- **who:** <person / team>
- **nudge if:** YYYY-MM-DD  (the date past which I should follow up)
- **links:** <wikilinks / ticket IDs>
-->

_(nothing waiting yet)_

---

*Completed & superseded threads → `_open-threads-archive.md` · full dated history → `_open-threads-changelog.md`*
