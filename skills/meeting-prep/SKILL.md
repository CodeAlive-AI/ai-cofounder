---
name: meeting-prep
description: "Prepare intelligence briefings before sales meetings. Pulls company context, contact background, pipeline history, and generates talking points, objection prep, and demo customization. Run as cron (30min scan) or on-demand. For post-meeting processing, see discovery-debrief."
user-invocable: true
---

## Context

Before preparing, read `MEMORY.md` for: current wedge, ICP, value proposition, competitors.
Read `memory/pipeline.json` for prospect's pipeline history and outreach context.
Follow output preferences from USER.md.
For chat platforms: compact briefing card, max 15 lines.

# Meeting Prep

Automated pre-meeting intelligence briefings that ensure the CEO walks into every call prepared with context, talking points, and a game plan.

## Cron Mode (Every 30 min)

When triggered by cron:

1. **Check calendar** for meetings in the next 2 hours:
```bash
orth run google-calendar /list-events --body '{"timeMin": "NOW_ISO", "timeMax": "NOW_PLUS_2H_ISO", "maxResults": 5}'
```

2. **Filter** — only process meetings with external attendees (not internal team meetings)
3. **Check** if briefing already generated today for this meeting (avoid duplicates)
4. **Generate briefing** for each qualifying meeting
5. **Deliver** to Telegram

## On-Demand Mode

When CEO asks "prepare for meeting with [company/person]":

1. Identify the prospect/company
2. Generate full briefing (see below)
3. Present in Telegram

## Briefing Generation

### Step 1: Company Intelligence

Use `company-intel` skill:
```bash
orth run brand-dev /v1/brand/retrieve -q domain=company.com
orth run fiber /v1/natural-language-search/companies -d '{"query": "company name"}'
```

Key data: size, industry, tech stack, funding, recent news.

### Step 2: Contact Research

Use `person-lookup` skill for each attendee:
- LinkedIn profile, recent posts, background
- Role and likely decision-making authority
- Any shared connections or interests

### Step 3: Pipeline Context

From `memory/pipeline.json`:
- How they entered pipeline (which signal)
- Outreach history (what was sent, what they replied)
- Current score (FIT+INTENT+TIMING)
- Notes from previous interactions

### Step 4: Competitive Landscape

Quick check: are they using or evaluating competitors?
- [COMPETITOR_A], [COMPETITOR_B], [COMPETITOR_C], [COMPETITOR_D], [COMPETITOR_E], [COMPETITOR_F]
- If yes → prepare differentiation talking points

### Step 5: Assemble Briefing

## Briefing Template

```
MEETING PREP: [Company] — [Date, Time]
Attendees: [Name (Title), ...]

COMPANY:
[1-2 lines: what they do, size, funding stage]
[Buying signals: tech stack hints, hiring patterns, recent activity]

CONTACT:
[Name] — [Title], [background snippet]
[Recent post/activity relevant to us]
Authority level: [Champion / Economic Buyer / User / Evaluator]

PIPELINE:
Signal: [what brought them in]
Score: FIT [X] + INTENT [X] + TIMING [X] = [total]
History: [outreach sent, replies, previous calls]

TALKING POINTS:
1. [Pain-specific opener based on their signal]
2. [Value prop tailored to their size/stack]
3. [Social proof: similar company reference]

OBJECTION PREP:
- "We already use [INCUMBENT]" → [differentiation]
- "Too early to evaluate" → [timing response]
- "Need to check with team" → [champion arming strategy]

DEMO PLAN:
[If a prospect-specific demo was generated, reference it]
[Key actions to show, tailored to their use case / pain]

GOAL:
[Primary: book next call / get champion / close pilot]
[Secondary: learn about their evaluation process]
[Discovery Q: What specific question to validate?]
```

## After the Meeting

Remind CEO to use `discovery-debrief` skill to:
1. Capture key learnings
2. Update pipeline.json (stage, notes, next_action)
3. Log insights via structured-log
4. Update hypotheses if relevant

## Related Skills

- **discovery-debrief** — post-meeting processing (the complement to meeting-prep)
- **pipeline-manager** — pipeline context for briefing
- **company-intel** — company research data
- **person-lookup** — contact research data
- **founder-sales** — sales strategy and discovery techniques
- **google-calendar** — calendar access for cron scanning
- **competitive-analysis** — frameworks for competitor positioning
