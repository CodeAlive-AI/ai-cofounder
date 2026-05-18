---
name: outreach-sender
description: "Send outreach emails and manage follow-up sequences. Bridges cold-email drafting → humanizer polish → CEO Telegram approval → Gmail send. Tracks sends in pipeline.json. For writing email copy, see cold-email. For lifecycle/nurture emails, see email-sequence."
user-invocable: true
---

## [YOUR_PRODUCT] Context

Before sending, read `MEMORY.md` for: current wedge, value proposition.
Read `memory/pipeline.json` for prospect context and outreach history.
Output in Russian (email content in English unless specified).
For chat platforms: show draft for approval, compact format.

# Outreach Sender

Orchestrates the full outreach flow: draft → polish → approve → send → track → follow-up.

## Outreach Flow (HITL — Human In The Loop)

```
1. Draft         → cold-email skill writes email based on signal + prospect context
2. Polish        → humanizer skill removes AI patterns
3. Present       → Show draft to CEO in Telegram for approval
4. Approve/Edit  → CEO approves, edits, or rejects
5. Send          → Gmail via Orth OAuth
6. Track         → Record in pipeline.json
7. Schedule      → Set next follow-up date
```

### Step 1: Draft Email

Use `cold-email` skill with prospect context:
- Signal that triggered outreach (from pipeline.json)
- Company context (from company-intel enrichment)
- Contact info (from lead-enrichment)
- Choose framework based on signal type:
  - Funding → "Trigger > Insight > Ask"
  - Hiring → "Observation > Problem > Proof > Ask"
  - Pain language → "Question > Value > Ask"
  - Competitor mention → "Story > Bridge > Ask"

### Step 2: Polish

Run through `humanizer` skill to remove AI patterns. Critical for cold email credibility.

### Step 3: Present for Approval

Format for Telegram:
```
Outreach Draft #[N]:

To: [Name] ([Title] @ [Company])
Signal: [type] — [detail]
Score: [FIT+INTENT+TIMING total]

Subject: [subject line]

[email body]

Reply:
 approve — send as-is
 edit: [your changes] — I'll update and re-present
 skip — skip this prospect
 later — defer to tomorrow
```

### Step 4: Send via Gmail

After CEO approval:
```bash
orth run gmail /send-email --body '{
  "recipient_email": "contact@company.com",
  "subject": "subject line",
  "body": "email body (plain text)"
}'
```

### Step 5: Track in Pipeline

Update prospect in pipeline.json:
```json
{
  "outreach": [{
    "type": "email",
    "date": "2026-03-28T10:00:00Z",
    "subject": "subject line",
    "status": "sent",
    "template": "trigger-insight-ask",
    "signal_type": "funding"
  }],
  "stage": "outreach_sent",
  "next_action": {
    "type": "follow_up_1",
    "date": "2026-03-31T10:00:00Z",
    "detail": "Follow-up #1 — new angle (case study)"
  }
}
```

### Step 6: Follow-Up Cadence

| Day | Follow-Up | Angle | Action |
|-----|-----------|-------|--------|
| 0 | Initial email | Signal + pain + value | CEO approves |
| 3 | Follow-up #1 | Case study or data point | Draft → approve → send |
| 5 | Follow-up #2 | Useful resource or insight | Draft → approve → send |
| 7 | Follow-up #3 | Social proof (similar company) | Draft → approve → send |
| 10 | Breakup email | Respect + door open | Draft → approve → send |

**Rules:**
- Each follow-up adds NEW value — never "just checking in"
- If reply at any point → exit sequence, notify CEO, update stage to `meeting_booked` or `nurture`
- If bounce → mark email invalid, try alternate contact via find-email-by-name
- If CEO says "skip" → move to nurture
- After breakup email → move to nurture, re-score in 30 days

## Daily Follow-Up Check (Cron Mode)

When triggered by daily cron:

1. Read pipeline.json
2. Find all prospects where `next_action.date` ≤ today
3. For each due follow-up:
   a. Draft next email in sequence (using previous outreach context)
   b. Present to CEO for approval
4. Report: "[N] follow-ups due today: [Company1], [Company2], ..."

## Batch Mode

When CEO says "send all approved drafts" or when multiple outreach items are ready:

1. List all approved-but-unsent drafts
2. Send each via Gmail with 30-second delay between sends
3. Update pipeline.json for each
4. Report: "Sent [N] emails. Next follow-ups scheduled."

## Reply Handling

When CEO reports a reply:
1. Update prospect stage (meeting_booked, nurture, or closed_lost)
2. Cancel remaining follow-ups in sequence
3. If meeting intent: trigger meeting-prep skill
4. Log via structured-log

## Related Skills

- **cold-email** — writes the email drafts
- **humanizer** — polishes drafts to remove AI patterns
- **email-sequence** — for lifecycle/nurture sequences (not cold outreach)
- **pipeline-manager** — stores all outreach tracking data
- **founder-sales** — overall sales strategy
- **find-email-by-name** — fallback for bounced emails
