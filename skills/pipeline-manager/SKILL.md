---
name: pipeline-manager
description: "Manage the sales pipeline: add/update prospects, score with FIT+INTENT+TIMING, track stage transitions, generate status reports. Central orchestrator for all pipeline skills. For signal detection, see signal-scanner. For outreach execution, see outreach-sender."
user-invocable: true
---

## [YOUR_PRODUCT] Context

Before helping, read `MEMORY.md` for: current wedge, ICP, competitors, PMF stage.
Pipeline state lives in `memory/pipeline.json`. Read it at the start of every pipeline operation.
Output in Russian (company names, emails, scores in original).
For chat platforms: compact pipeline card, max 15 lines.

# Pipeline Manager

Central orchestrator for the full-cycle sales pipeline. Manages prospect state, scoring, stage transitions, and reporting.

## Pipeline State

All prospect data lives in `memory/pipeline.json`. Structure:

```json
{
  "prospects": [{
    "id": "company-slug",
    "company": "Company Name",
    "domain": "company.com",
    "contact": {
      "name": "Full Name",
      "title": "VP Engineering",
      "email": "name@company.com",
      "linkedin": "linkedin.com/in/username"
    },
    "scores": {
      "fit": 0,
      "intent": 0,
      "timing": 0,
      "total": 0
    },
    "stage": "signal_detected",
    "signals": [],
    "outreach": [],
    "next_action": { "type": "", "date": "", "detail": "" },
    "notes": "",
    "created": "ISO",
    "updated": "ISO"
  }],
  "stats": {
    "total": 0,
    "by_stage": {},
    "last_scan": "",
    "last_review": ""
  }
}
```

## Operations

### 1. Add Prospect

When a new prospect is identified (via signal-scanner, manual, or inbound):

1. Check if prospect already exists in pipeline.json (match by domain)
2. If new: create entry with initial data, set stage = `signal_detected`
3. Score using FIT+INTENT+TIMING (see Scoring below)
4. Route based on score:
   - **75+**: Notify CEO immediately via Telegram. Tag as priority.
   - **50-74**: Queue for agent-drafted outreach
   - **25-49**: Add to nurture list
   - **<25**: Monitor, re-score next month
5. Log via `structured-log`

### 2. Update Prospect

When new information arrives (enrichment, reply, meeting):

1. Read current prospect state from pipeline.json
2. Update relevant fields
3. Re-score if new signals detected
4. Advance stage if transition criteria met
5. Set next_action with date and detail
6. Write back to pipeline.json

### 3. Stage Transitions

```
signal_detected → researched → qualified → outreach_sent →
follow_up_1 → follow_up_2 → follow_up_3 →
meeting_booked → discovery_done → proposal_sent →
closed_won | closed_lost | nurture
```

Transition triggers:
- `signal_detected` → `researched`: company-intel + person-lookup + lead-enrichment completed
- `researched` → `qualified`: FIT+INTENT+TIMING score calculated, ≥25
- `qualified` → `outreach_sent`: CEO approved draft, email sent via outreach-sender
- `outreach_sent` → `follow_up_N`: Automatic by cadence (Day 3/5/7/10)
- Any → `meeting_booked`: Reply with meeting intent received
- `meeting_booked` → `discovery_done`: After call + discovery-debrief completed
- `discovery_done` → `proposal_sent`: Proposal or demo delivered
- Terminal: `closed_won`, `closed_lost`, `nurture`

### 4. Pipeline Report

Generate a pipeline status report. Use for weekly reviews or on-demand.

**Report contents:**
- Total prospects by stage (funnel visualization)
- Top 5 highest-scored prospects with next actions
- Stale prospects (>7 days without activity)
- Conversion rates between stages (if enough data)
- Signals detected this week vs last week
- Outreach stats: sent, replied, bounced, meetings booked

**Telegram format:**
```
Pipeline Report [date]:
[N] total | [N] active | [N] stale

Top prospects:
1. Company (score) — stage — next action
2. ...

This week: [N] signals, [N] outreach, [N] replies
Conversion: signal→meeting [X]%
```

## FIT+INTENT+TIMING Scoring

### FIT (0-40) — ICP Match

| Factor | Points | Criteria |
|--------|--------|----------|
| Company size | 0-10 | Score against the size bands in your ICP from MEMORY.md (e.g. sweet spot=10, adjacent=5, edge=2) |
| Use-case complexity | 0-10 | Score against the complexity profile that matches your wedge (e.g. high=10, medium=7, low=3) |
| Tool maturity | 0-10 | Active in the category=10, evaluating=7, greenfield=3 |
| Budget authority | 0-10 | VP+ contact=10, team lead=7, IC=3 |

### INTENT (0-40) — Active Buying Signals

| Signal | Points |
|--------|--------|
| Pain language (public) | 8-10 |
| Competitor evaluation | 8-10 |
| Active hiring (AI/DevTools) | 6-8 |
| Tech stack changes | 6-8 |
| Published content on pain | 5-6 |
| Event attendance | 3-5 |

### TIMING (0-20) — Window Open

| Factor | Points |
|--------|--------|
| Funding (<90 days) | 8-10 |
| Hiring surge | 5-8 |
| Leadership change | 5-7 |
| Quarter start | 3-5 |
| Signal freshness (<7d) | 5 |

### Score Routing

| Score | Action |
|-------|--------|
| 75-100 | CEO direct outreach, personalized demo |
| 50-74 | Agent drafts, CEO approves |
| 25-49 | Nurture sequence |
| 0-24 | Monitor, re-score monthly |

## Self-Optimization (Weekly Review)

During weekly pipeline-review:
1. Calculate conversion rates by stage
2. Identify which signal types → highest reply rates
3. Identify which outreach templates → highest reply rates
4. Flag patterns: "Funding signal + CTO contact → 3x better than hiring signal + IC"
5. Recommend weight adjustments for next week
6. Log insights via structured-log, promote to MEMORY.md if confirmed 2+ times

## Related Skills

- **signal-scanner** — detects signals that feed into pipeline
- **outreach-sender** — executes outreach from pipeline
- **meeting-prep** — prepares for meetings with pipeline prospects
- **prospect-demo** — generates [YOUR_PRODUCT] demos for prospects
- **founder-sales** — sales strategy and discovery framework
- **sales-qualification** — qualification framework
- **structured-log** — logging pipeline events
- **hypothesis-tracker** — tracking outreach template hypotheses
