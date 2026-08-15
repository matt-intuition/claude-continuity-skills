---
type: cadence-manifest
created: {{date}}
updated: {{date}}
purpose: trigger → workflow map. /daily-session reads this and PROPOSES the day's runs in the greeting — you never have to remember command names.
tags:
  - Cadence
---

# Cadence Manifest

**How this is used:** during `/daily-session`, every trigger below is evaluated against (a) today's date + day-of-week, (b) cycle position, (c) today's calendar events (if a calendar is declared in `_foundation.md`). Matches are collected into a **"Today's proposed runs"** list in the greeting, ordered by time-of-day. Propose — never auto-run. If a proposed run is declined, it isn't re-proposed the same day.

In the evening, `/end-day` (compliance strip) evaluates the **Evening verification** section against today's day-of-week — the morning proposes, the evening verifies. This file is the single home of day-of-week rules; commands never hard-code them.

## Cycle anchor

- **Current cycle starts:** <!-- e.g. Monday YYYY-MM-DD --> · **length:** <!-- e.g. 2 weeks --> (update this line each kickoff)
- Cycle day = weekdays elapsed since cycle start (day 1 = kickoff Monday)

## Daily (unconditional)

| Trigger | Run | Notes |
|---------|-----|-------|
| Every working morning | `/daily-session` | You're in it — self-evidently satisfied |
| Every working evening | `/end-day` | Compiles the daily wrap-up |

## Day-of-week

<!-- Weekly ceremonies from the foundation manifest, e.g.:
| Monday | weekly planning sync prep | Draft before the 10am sync |
| Thursday | weekly review draft | Due in <manager>'s hands before the Friday 1-1 |
-->

| Trigger | Run | Notes |
|---------|-----|-------|
| | | |

## Evening verification (read by /end-day's compliance strip)

<!-- One row per day-of-week obligation the evening should verify actually happened, e.g.:
| Monday | planning sync prep existed before the sync | Do it now if quick, else tomorrow's first action |
-->

| Day | Check | If missed |
|-----|-------|-----------|
| | | |

## Cycle position

<!-- e.g.:
| Cycle day 1 (kickoff Monday) | sprint planning | |
| Last Friday of cycle | retro | |
-->

| Trigger | Run | Notes |
|---------|-----|-------|
| | | |

## Calendar-driven (check today's events — requires a declared calendar)

<!-- e.g.:
| External call on today's calendar | prep doc before it | Morning proposal if the call is today |
| Meeting completed (or transcript arrived) | follow-up notes | |
-->

| Trigger | Run | Notes |
|---------|-----|-------|
| | | |

## Event-driven (no schedule — fire on the event)

| Trigger | Run |
|---------|-----|
| Significant work in a non-daily session | `/export-conversation` at session end |
<!-- Add your own: new lead arrives → intake workflow, deal signed → kickoff checklist, etc. -->
