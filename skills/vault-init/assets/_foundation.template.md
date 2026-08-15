---
type: foundation-manifest
created: {{date}}
updated: {{date}}
---

# Foundation Manifest

The centralized configuration every workflow command reads right after resolving the vault. `/onboard` writes this file from an interview; edit it by hand any time — the commands re-read it every session. **One fact, one home:** this file declares *what you use*; `_cadence.md` declares *when workflows fire*; the commands hold the *how*.

**How commands use this file:** every step marked `[gated: <capability>]` in `/daily-session`, `/checkpoint`, and `/end-day` checks the Platforms table below. A capability declared with a connected MCP → the step runs against that tool. Declared as `none`, or MCP unavailable → the step's documented fallback runs instead. Nothing here ever *enables* an outward-facing send — gates only decide what gets read and verified.

## Identity

- **Name:** <!-- what Claude should call you, e.g. Sam -->
- **Timezone:** <!-- IANA name, e.g. America/New_York — timestamps and "late" judgments use this -->
- **Working hours:** <!-- e.g. 9am–6pm weekdays -->
- **Company / domain:** <!-- e.g. example.com — inbox scans treat mail from this domain as signal -->

## Platforms & sources of truth

<!-- Tool column: name the product you actually use, or `none`.
     MCP server column: the EXACT server name this lane's tools come from (as shown in /mcp), e.g.
     `linear`, `linear-org-a`. This is the per-vault auth binding — a lane authed to org A names
     `linear-org-a`; a sibling lane names `linear-org-b`. Write `none` for no MCP, or
     `account-level` for connectors that follow your account everywhere (claude.ai-hosted).
     The system-of-record rule is what /end-day's verification gate enforces for that claim type. -->

| Capability | Tool | MCP server | System-of-record rule |
|---|---|---|---|
| Task tracker | <!-- Linear / Jira / GitHub Issues / none --> | <!-- e.g. linear-org-a --> | Ticket status is verified against the tracker, fetched live — never from session prose |
| Email | <!-- Gmail / none --> | | "Sent" claims are verified against **sent mail**, never the drafts folder |
| Calendar | <!-- Google Calendar / none --> | | Today's events feed cadence evaluation and the day's plate |
| Docs / knowledge base | <!-- Notion / Google Docs / vault-only --> | | Durable docs and counts are verified by querying the platform |
| CRM | <!-- HubSpot / none --> | | Deal/relationship stages are verified against the CRM, fetched live |
| Share-out channel | <!-- Slack / Discord / email / none --> | | The daily wrap-up's share draft is formatted for this channel |

**Server binding rule:** commands call tools ONLY from the server named in this table. If that server isn't connected in the current session, the capability counts as unavailable (the step's fallback runs and the gap is reported) — a same-service server belonging to another lane is never a substitute.

## Cadence ceremonies

<!-- The human summary of your recurring rhythm. /onboard translates these rows into trigger rows
     in _cadence.md (the dispatcher /daily-session evaluates each morning). Keep the two in sync:
     this table answers "what's my rhythm?", _cadence.md answers "what fires today?". -->

| Cadence | Ceremony | Detail |
|---|---|---|
| daily (morning) | /daily-session | Start of every working day |
| daily (evening) | /end-day | Compiles the daily wrap-up |
| weekly (<!-- day -->) | <!-- e.g. team sync prep, weekly review draft --> | <!-- when it's due, who reads it --> |
| monthly | <!-- e.g. retro, planning --> | |

## Workstreams

<!-- The stable headings the daily wrap-up's tracking layer groups work under. Keep names verbatim
     day to day — they key the weekly rollup. 2–5 headings is typical. -->

- <!-- Workstream 1 -->
- <!-- Workstream 2 -->
- Ops / Other

## Targets (optional)

<!-- Measured counters the daily wrap-up's scoreboard tracks, e.g. "Outreach: conversations opened /10 per month".
     Delete this section if you don't run against numeric targets. -->
