---
name: feedback-tracker
description: "Track outreach outcomes: sent → replied → meeting → learning. Runs via cron to check 48h and 7d marks. Feeds data back into channel-scores and hypothesis-tracker. For sending outreach, see outreach-sender."
user-invocable: true
---

## [YOUR_PRODUCT] Context

Read `memory/outreach-feedback.jsonl` for tracking state.
Read `memory/pipeline.json` for prospect context.
Follow output preferences from USER.md. Telegram: max 10 lines.

# Feedback Tracker

Closes the learning loop: tracks what happened AFTER outreach was sent.

## State File: memory/outreach-feedback.jsonl

Each line is one outreach event:
```json
{"id":"uuid","ts":"ISO","prospect":"Name (Company)","channel":"email|linkedin|reddit|hn|devto","type":"cold|warm|community_reply|follow_up","status":"sent|replied|meeting_booked|no_reply_48h|no_reply_7d|closed_won|closed_lost","sent_at":"ISO","checked_48h":false,"checked_7d":false,"reply_at":null,"meeting_at":null,"learning":null}
```

## Cron Mode (automatic, twice daily)

Runs at 10:00 and 16:00 via feedback-checker-001 cron.

### Algorithm

1. Read `outreach-feedback.jsonl`
2. For each entry where `status == "sent"`:
   - If `sent_at` > 48h ago AND `checked_48h == false`:
     - Check via Composio/Gmail if reply received
     - If reply → update status to "replied", set reply_at
     - If no reply → update status to "no_reply_48h", set checked_48h = true
   - If `sent_at` > 7d ago AND `checked_7d == false`:
     - Final check for reply
     - If still no reply → update status to "no_reply_7d", set checked_7d = true
3. Update `memory/channel-scores.json`:
   - Track per-channel: sent_count, reply_count, reply_rate, meeting_count
4. If any new replies detected → include in next Evening Recap
5. Output: HEARTBEAT_OK (silent) unless new reply detected → alert CEO

### On-Demand Mode

When CEO says "check outreach" or "any replies?":
1. Run full check immediately
2. Report all pending outreach with status
3. Format:

```
Outreach Status:
- [Name] (email, 3d ago): no reply
- [Name] (reddit, 1d ago): replied! [snippet]
- [Name] (linkedin, 5d ago): no reply (7d mark)

Reply rate (30d): N/M = X%
Best channel: [channel] (Y% reply rate)
```

## Adding New Outreach

When outreach-sender or CEO sends outreach, append to outreach-feedback.jsonl:
```json
{"id":"uuid","ts":"now","prospect":"Name","channel":"email","type":"cold","status":"sent","sent_at":"now","checked_48h":false,"checked_7d":false}
```

## Learning Capture

When a reply leads to a meeting or insight, update the entry:
```json
{"learning": "Prospect interested in MCP integration, wants demo next week"}
```

Feed learnings into hypothesis-tracker if they validate/invalidate active hypotheses.

## Channel Scoring

Update `memory/channel-scores.json` after each check:
```json
{
  "channels": {
    "email": {"sent": 10, "replied": 2, "meetings": 1, "rate": 0.2},
    "reddit": {"sent": 5, "replied": 3, "meetings": 0, "rate": 0.6},
    "linkedin": {"sent": 8, "replied": 0, "meetings": 0, "rate": 0.0}
  },
  "last_updated": "ISO"
}
```

## Related Skills

- **outreach-sender** — sends outreach (creates entries here)
- **pipeline-manager** — prospect data
- **morning-brief** — surfaces new replies
- **evening-recap** — includes reply stats
- **hypothesis-tracker** — receives learnings
