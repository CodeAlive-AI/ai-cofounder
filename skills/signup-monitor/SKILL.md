---
name: signup-monitor
description: "Cron-triggered: query PostHog for new signups, research each by email domain via Exa, alert the CEO when someone interesting signs up. Not for manual use — runs automatically."
user-invocable: false
---

# Signup Monitor

Automatic lead research on every new [YOUR_PRODUCT] signup. Runs as a cron job.

## Workflow

### Step 1: Load State

Read `memory/signup-monitor.json`. If missing, create with:
```json
{"last_checked": "2026-03-28T00:00:00Z", "processed": []}
```

### Step 2: Query New Signups

```bash
posthog__query-generate-hogql-from-question \
  question="Show User Signup events after TIMESTAMP with properties org_owner_email, org_owner_name, org_name, org_member_count, organisation_id, signup_source, referrer, acquisition_channel. Order by timestamp desc, limit 50"
```

Replace TIMESTAMP with `last_checked` value from state.

If zero results — update `last_checked` to now, save state, respond `HEARTBEAT_OK`.

### Step 3: Filter & Deduplicate

For each signup:
1. Skip if `org_owner_email` is null/empty
2. Skip if email already in `processed` list
3. Extract domain from email (part after @)
4. **Skip personal emails**: gmail.com, yahoo.com, hotmail.com, outlook.com, mail.ru, yandex.ru, icloud.com, protonmail.com, live.com, aol.com
5. Remaining signups = candidates for research

If no candidates after filtering — update state, respond `HEARTBEAT_OK`.

### Step 4: Research Each Candidate

For each candidate, run ONE Exa search on the email domain:

```bash
exa-search__web_search_advanced_exa \
  query="DOMAIN company" \
  category=company \
  numResults=5 \
  type=auto
```

From results, extract:
- Company name and what they do
- Approximate team size (if available)
- Industry / tech stack signals
- Funding stage (if available)

### Step 5: Qualify

Score each candidate as HOT / WARM / SKIP:

**HOT** (alert immediately):
- Known tech company (>100 employees)
- Company matches your ICP profile from MEMORY.md (industry, tech stack, team type)
- Person title suggests decision-maker (VP, CTO, Director, Head of, Lead, Manager)
- Recent funding or hiring signals

**WARM** (log, include in daily recap):
- Business email but small/unknown company
- Relevant industry but no strong signals

**SKIP** (log only):
- Unresearchable domain
- No relevant signals found

### Step 6: Alert

For each HOT candidate, send a chat alert:

```
Signup: [Name] ([email])
[Company Name] — [one-line description]
[Team size if known] | [Industry] | [Funding if known]
Signal: [why this is interesting — 1 line]
Source: [signup_source] / [referrer]

Reply "research [email]" for full dossier.
```

For WARM candidates, append a summary line at the end:
```
Also signed up: [N] warm leads ([domain1], [domain2]...)
```

### Step 7: Update State

Write `memory/signup-monitor.json`:
```json
{
  "last_checked": "CURRENT_TIMESTAMP",
  "processed": ["email1@domain.com", "email2@domain.com", ...],
  "stats": {
    "total_checked": N,
    "hot": N,
    "warm": N,
    "skip": N,
    "last_run": "CURRENT_TIMESTAMP"
  }
}
```

Keep `processed` list trimmed to last 500 entries to avoid bloat.

Log results via `structured-log`.

## Notes

- Research costs 1 Exa call per candidate (~$0.01). At current volume (3/week) this is negligible.
- If volume grows past 20/day, batch research into subagents.
- When CEO replies "research [email]", use exa-company-research + exa-people-research + lead-enrichment for full dossier, then add to pipeline via pipeline-manager.

## Related Skills

- **posthog-analytics** — PostHog query patterns and event catalog
- **exa-company-research** — deep company research
- **exa-people-research** — people research by name/role
- **lead-enrichment** — full contact profile (email, phone, LinkedIn)
- **pipeline-manager** — add qualified leads to pipeline
- **signal-scanner** — complementary signal detection
