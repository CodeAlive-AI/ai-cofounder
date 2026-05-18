---
name: value-moment-email
description: "Cron-triggered: when a user gets first value (key activation event), draft a personalized founder email referencing their specific use case. Runs automatically."
user-invocable: false
---

# Value Moment Email

Send a personalized founder email at the moment of first value — when the user has just hit the key activation event and is most engaged.

## Why

The moment after first value is when users are most engaged. A personal email from the CEO that references their specific use case (input they just processed, output they just got) has the highest open and reply rate of any outreach.

## Workflow

### Step 1: Load State

Read `memory/value-moment.json`. If missing, create:
```json
{"last_checked": "2026-03-28T00:00:00Z", "emailed": []}
```

### Step 2: Find First-Value Users

Query PostHog for users who hit their first value event in the last 6 hours:

```bash
posthog__query-generate-hogql-from-question \
  question="Find primary_resource_ready events from the last 6 hours where is_first_time_processed is true. Include properties: primary_resource_name, provider_type, org_owner_email, org_owner_name, org_name, processing_duration_ms, distinct_id. Order by timestamp desc, limit 20."
```

Fallback: if `is_first_time_processed` is not available, use `first_value_delivered` or `first_key_action_executed` events.

### Step 3: Filter

- Skip if `org_owner_email` is null (enricher not deployed — respond HEARTBEAT_OK)
- Skip if email already in `emailed` list
- Skip personal emails
- Skip repeated activations (only first-time matters)

### Step 4: Research Company (if business email)

Quick Exa lookup:
```bash
exa-search__web_search_advanced_exa \
  query="DOMAIN company" \
  category=company \
  numResults=3 \
  type=auto
```

### Step 5: Draft Email

Personalized email referencing the specific input/output:

```
Subject: Your [primary_resource_name] is ready

Hi [Name],

I saw you just ran [YOUR_PRODUCT] on [primary_resource_name] — [one inferred line about what they're doing based on the resource name/provider].

A few things to try right away:
1. [Action 1 tied to your core value prop]
2. [Action 2 — a follow-on workflow]
3. [Action 3 — a way to expand usage]

[IF company research available: One line connecting their company's domain to how [YOUR_PRODUCT] helps]

Questions? Just reply — I read every email.

[Founder name], [YOUR_PRODUCT] founder
```

### Step 6: Present to CEO

```
Value Moment: [Name] ([email])
Input: [primary_resource_name] ([provider]) — just processed
[Company context if available]
Draft email ready — reply "send" / "skip"
```

### Step 7: On "send" → Composio Gmail, log via structured-log.

### Step 8: Update State

Add email to `emailed` list, update `last_checked`.

## Timing

- Runs every 4 hours (aligned with signup-monitor)
- Email arrives within hours of first value — not days later
- This urgency matters: response rate drops 50% after 24h

## Notes

- Depends on `org_owner_email` on activation events (backend enricher)
- Map `primary_resource_ready` / `is_first_time_processed` to whatever event in your product marks the moment a user has gotten initial value
- Switch to canonical `first_value_delivered` once it's fully deployed in your funnel

## Related Skills

- **signup-monitor** — catches at signup
- **stall-rescue** — catches 72h stalls
- **pipeline-manager** — responders become pipeline prospects
- **cold-email** — email frameworks
