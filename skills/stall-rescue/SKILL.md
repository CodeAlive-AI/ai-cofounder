---
name: stall-rescue
description: "Cron-triggered: detect users who signed up but didn't complete the activation step within 72h, draft personalized founder email to re-engage. Runs automatically."
user-invocable: false
---

# Stall Rescue (72h activation drop-off)

Detect users stalling after signup and send a personalized founder email before they churn.

## Why

Users who don't complete the key activation step within 72h of signup have <15% chance of returning. A personal email from the CEO at this moment has 3-5x higher response rate than generic nurture.

## Workflow

### Step 1: Load State

Read `memory/stall-rescue.json`. If missing, create:
```json
{"last_checked": "2026-03-28T00:00:00Z", "rescued": []}
```

### Step 2: Find Stalled Users

Query PostHog for users who signed up 3-4 days ago but haven't activated:

```bash
posthog__query-generate-hogql-from-question \
  question="Find distinct_id values from User Signup events between 4 days ago and 3 days ago. Then check if those distinct_id values have any primary_resource_action or first_value_delivered events after their signup. Return only those who do NOT have any activation event. Include org_owner_email, org_owner_name, org_name from the signup event properties."
```

### Step 3: Filter

- Skip if `org_owner_email` is null (enricher not deployed yet — respond HEARTBEAT_OK)
- Skip if email already in `rescued` list
- Skip personal emails (gmail, yahoo, hotmail, outlook, mail.ru, yandex.ru)

### Step 4: Research (optional, if business email)

For each stalled user with business email, quick Exa lookup on domain:

```bash
exa-search__web_search_advanced_exa \
  query="DOMAIN company" \
  category=company \
  numResults=3 \
  type=auto
```

### Step 5: Draft Email

Use the context to draft a short, personal email from the CEO. Template:

```
Subject: Quick question about [Company/their use case]

Hi [Name],

I noticed you signed up for [YOUR_PRODUCT] [3 days ago]. I'm the founder, the founder.

[ONE personalized line based on company research — what they do, why [YOUR_PRODUCT] might help]

Most teams get value within minutes of the first activation step — [one-line value moment for your product].

Want me to help you get set up? Happy to do a quick 10-min walkthrough.

Best,
the founder
```

Generate the email via LLM, then present to CEO for approval.

### Step 6: Present to CEO

```
Stall Rescue: [Name] ([email])
[Company] — signed up [N] days ago, no activation event
Draft email ready — reply "send" to approve, "skip" to pass.
```

### Step 7: On "send" → use Composio Gmail to send, log via structured-log.

### Step 8: Update State

Add email to `rescued` list, update `last_checked`. Keep list trimmed to 200 entries.

## Notes

- Depends on `org_owner_email` being present on `User Signup` event (backend enricher task)
- Until enricher is deployed, this cron will return HEARTBEAT_OK
- Only runs on 3-4 day old signups to give users time to activate naturally
- Max 3 rescue emails per day to avoid overwhelming CEO's approval queue

## Related Skills

- **signup-monitor** — catches signups at time of registration
- **pipeline-manager** — rescued users who respond get added to pipeline
- **cold-email** — email writing frameworks
- **humanizer** — polish AI-generated emails
