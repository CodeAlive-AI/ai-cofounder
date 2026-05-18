---
name: evening-recap
description: "Daily Evening Recap for CEO (21:00 cron). Reports what bot did today, outreach results, pipeline changes, belief updates. Replaces old daily-recap skill. Output = one Telegram message, max 15 lines."
user-invocable: true
---

## [YOUR_PRODUCT] Context

Read MEMORY.md for: constraint, ICP, current hypotheses.
Read today's memory files.
Follow output preferences from USER.md. For chat platforms: keep under ~15 lines.

# Evening Recap

The CEO's second daily touchpoint. Runs at 21:00 via cron. Pure report — no asks, no actions.

## Data Sources

1. `memory/autonomous-actions.jsonl` — everything bot did today
2. `memory/outreach-feedback.jsonl` — responses to outreach
3. `memory/pipeline.json` — pipeline changes today
4. `memory/focus-state.json` — was GTM minimum completed?
5. `memory/initiatives.json` — initiative progress
6. `memory/hypotheses.json` — hypothesis status
7. `memory/channel-scores.json` — which channels performing
8. Today's `memory/YYYY-MM-DD.md` — conversation log

## Compose the Recap

### Section 1: Today's Actions (3-5 lines)
What happened today (bot actions + CEO actions):
- Outreach sent (and responses if any)
- Content published (with metrics if available: views, reactions)
- Enrichments and research completed
- Pipeline changes
- PR opportunities acted on
- Meetings prepped/completed

### Section 1.5: Win (1 line, conditional)
If `daily_minimum.done == true` today — one line of specific process praise (same library as focus-keeper). If no GTM today — **omit entirely** (no "0 wins", no shaming).

### Section 2: Learning (1-2 lines)
- Belief changes: N (if 0, just say "0")
- Hypothesis updates
- Outreach response rate trends (if enough data)

### Section 3: Tomorrow Preview (1-2 lines)
If calendar has meetings tomorrow → mention prep status.
If pipeline has due follow-ups → mention count.
Otherwise skip.

### Section 4: Week Board
```
{week_board} ({N}/7) | Pipeline: N prospects
```

**Week board:** `●●●○○○○` — one symbol per day Mon→Sun, ● = GTM completed, ○ = not yet. Derive from `focus-history.jsonl` for current week. Shows accumulation (partial progress visible), not just streak. Never show streak when it's 0.

## Output Template

```
Вечер.

Сегодня:
- [action 1 + result]
- [action 2 + result]

{Win: [specific process praise] — only if GTM done today}

Beliefs changed: N

Завтра: [meeting prep / follow-ups due / nothing special]

●●○○○○○ (2/7) | Pipeline: N
```

## Rules

- Max 15 lines
- Pure report — no questions, no asks, no approvals
- If nothing happened today: "Сегодня без GTM-активности." (no streak mention, no shaming)
- Neutral tone — no shaming if CEO did nothing, no "0 wins", no streak when it's 0
- Log recap delivery to autonomous-actions.jsonl
- Update focus-state.json: daily recap delivered

## Related Skills

- **morning-brief** — the other daily touchpoint
- **daily-recap** — legacy skill (evening-recap replaces it)
- **structured-log** — logging
