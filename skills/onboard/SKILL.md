---
name: onboard
description: Guided onboarding interview for the continuity workflow. Use when the user invokes `/onboard`, says "set up my workflow", "configure my platforms", "connect my tools to the daily workflow", or has just scaffolded a vault with `/vault-init` and needs a foundation manifest. Detects which MCP connectors are actually available in the session, interviews the user about their platforms (task tracker, email, calendar, docs, CRM, share-out channel), identity, timezone, and daily/weekly/monthly cadence ceremonies, then writes `local/journals/_foundation.md` and seeds `_cadence.md` in the active vault. Re-runnable to reconfigure — it updates, never blind-overwrites.
---

# onboard

The intelligent first-run (and re-run) configurator. Everything the workflow commands need to know about *this user's* system lands in one place — the **foundation manifest** (`local/journals/_foundation.md`) — so the commands stay generic and the configuration stays personal.

## When to trigger

- User invokes `/onboard`
- User says "set up my workflow" / "configure my platforms" / "help me connect my tools"
- `/vault-init` just finished and offered onboarding as the next step
- A workflow command reported "no foundation file — running vault-only" and the user wants to fix that

## When NOT to trigger

- No vault is resolvable (no `.claude-vault.json` walking up from CWD) → run `/vault-init` first; say so and stop.
- The user only wants to change one value ("switch my share-out channel to Discord") → just edit `_foundation.md` directly; the full interview is overkill.

## Principles

- **Interview, don't interrogate.** Batch related questions into a handful of messages (identity → platforms → cadence → workstreams). Use the ask-user question tool with concrete options where available; free-text otherwise. Never ask one question per message for ten messages.
- **Detect before asking.** Pre-fill the platform table from what's actually connected (step 2) and present it for confirmation — "I can see Linear and Gmail MCPs connected; want them as your task tracker and email?" beats a blank questionnaire.
- **"None" is always a valid answer.** Every capability degrades gracefully (the commands document their fallbacks). Never pressure the user toward a tool.
- **Update, never blind-overwrite.** On re-run, read the existing `_foundation.md` first, present current values, and change only what the user changes. Same for `_cadence.md` rows.
- **One fact, one home.** The foundation holds *what you use* and *your rhythm*; `_cadence.md` holds the *dispatch rules* derived from that rhythm; the commands hold the *procedure*. Don't restate command behavior into the foundation file.

## Step-by-step

### 1. Resolve the vault

Walk up from CWD for `.claude-vault.json` (same algorithm as every workflow command). No marker → stop and point at `/vault-init`. If `local/journals/_foundation.md` already exists, read it — this is a **reconfigure run**: show the current settings compactly and ask what to change; skip straight to the sections being changed.

### 2. Detect available MCP connectors

Inspect which MCP tools are actually present in this session (tool listings / a tool search for the common servers — Linear, Jira, GitHub, Gmail, Google Calendar, Notion, Google Drive, HubSpot, Slack). Build a short detected-list **with the exact server names** (the prefix in the tool names, e.g. `linear-server`, `linear-org-a`) — the foundation records the name, not just the product. Do not call any of them yet — presence is enough. Note that MCP servers configured on the user's account but not loaded in this session may not appear; the user can override detection.

### 3. Interview — identity

Ask in one message: preferred name, timezone (IANA name; offer the system timezone as the default), working hours, and company/domain (used by the inbox scan's signal filter; optional).

### 4. Interview — platforms & sources of truth

Present one capability table, pre-filled from step 2, and confirm/correct each row:

| Capability | What it powers | Typical options |
|---|---|---|
| Task tracker | Morning focus pull, ticket-first work capture, evening reconciliation sweep | Linear · Jira · GitHub Issues · none |
| Email | Morning inbox scan; **sent-mail verification** of "sent" claims | Gmail · none |
| Calendar | Cadence evaluation (meeting-driven triggers), day's plate cross-referencing | Google Calendar · none |
| Docs / knowledge base | Where durable docs live; count/state verification | Notion · Google Docs · vault-only |
| CRM | Deal/relationship stage verification | HubSpot · none |
| Share-out channel | The format of the daily wrap-up's copy-paste draft | Slack · Discord · email · none |

For each declared platform, record the **MCP server name** this lane should use (from the step-2 detected list, or `none` / `account-level`). A platform the user uses but has no MCP for is recorded as `none` — commands will treat claims against it as `unverified` rather than silently skipping the concept.

**Multi-org check (per-vault auth):** ask whether any declared service spans more than one organization/workspace across the user's lanes (e.g. Linear org A for work, Linear org B for a client). If yes, walk them through the isolation pattern before writing the table:

1. From this vault (or the project repo the lane launches from), add a **locally-scoped, org-named server**:
   `claude mcp add --transport http --scope local linear-<org> https://mcp.linear.app/sse`
2. Run `/mcp` and complete that org's OAuth flow once.
3. Record `linear-<org>` in this lane's foundation table; the sibling lane repeats with its own name.

Two caveats to state: local scope is **per launch directory** — a lane started from both its vault and a linked repo needs the server added in each (or a `.mcp.json` committed to the repo); and claude.ai-hosted account connectors follow the account everywhere, so they cannot be org-split per lane — record those as `account-level`. Never rely on two lanes OAuth-ing the *same* server name into different orgs; token isolation for that case is undocumented.

Briefly state the consequence of each choice as it's made ("no task tracker → your morning plate builds from open-threads and yesterday's handoff instead").

### 5. Interview — cadence ceremonies

Ask about the rhythm in one batch: weekly ceremonies (which day, what's due, who reads it), any sprint/cycle structure (anchor date + length), monthly ceremonies, and meeting-driven rituals (prep docs before external calls? follow-up notes after?). Daily morning/evening rows are standing defaults — mention them, don't ask.

### 6. Interview — workstreams (and optional targets)

Ask for 2–5 stable workstream headings for the daily wrap-up's tracking layer ("the buckets your work falls into — keep the names stable, they key the weekly rollup"). Optionally: measured targets per workstream for the scoreboard; skip freely.

### 7. Write the files

- **`local/journals/_foundation.md`** — from `~/.claude/skills/vault-init/assets/_foundation.template.md`, with every interviewed value filled in and the HTML comments removed from filled rows. On a reconfigure run, edit the existing file in place.
- **`local/journals/_cadence.md`** — create from the template if missing (vault-init normally already did). Translate the step-5 answers into rows: day-of-week table, evening-verification rows for anything with a hard "due" (each check needs an "if missed" action), cycle anchor, calendar-driven rows (only if a calendar is declared). Keep the standing daily rows. On re-run, reconcile rows — update changed ones, keep manual rows the user added.

### 8. Dry-run the gates (the payoff)

Close with a concrete readout of what the configuration means — one line per command, derived from the actual declarations, e.g.:

Verify the bindings as part of the readout: for each declared MCP server name, confirm it is actually connected in this session and flag any that aren't ("`linear-org-b` is named but not connected here — run `claude mcp add --scope local` from this directory").

```
With this setup:
- /daily-session will pull your morning plate from Jira (server: jira-acme), scan Gmail
  for signal mail, and check Google Calendar for meeting-driven cadence rows.
- /checkpoint will sync ticket status to Jira and verify "sent" claims against Gmail sent mail.
- /end-day will format your daily wrap-up share draft for Discord, grouped under:
  Product · Customers · Ops/Other.
- No CRM declared — deal-stage claims will be written as unverified if they ever come up.
Change anything any time: edit local/journals/_foundation.md or re-run /onboard.
```

- Offer `/daily-session --light` as the immediate next step to see the configuration in action.

## Notes

- This skill writes ONLY inside the active vault (`local/journals/`). It never edits the user-level commands, hooks, or any global config.
- The foundation gates control what gets **read and verified** — they never authorize outward-facing sends; those keep their own approval flows in the commands.
- Deleting `_foundation.md` is a safe reset: every command degrades to vault-only behavior and re-suggests `/onboard`.
