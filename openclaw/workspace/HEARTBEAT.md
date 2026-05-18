# Heartbeat — CEO Cadence

Every 30 min. Morning Briefing — separate cron. Heartbeat = B, C, D.

## Rules

Read `memory/heartbeat-state.json`. If `today` != today -> reset `messagesCount` to 0.

1. B/C max 2/day (`messagesCount` >= 2 -> HEARTBEAT_OK)
2. Min 4h between B/C (`lastMessageAt` < 4h ago -> HEARTBEAT_OK)
3. Before morning briefing time -> HEARTBEAT_OK
4. Evening window (e.g. 21:00-22:00) -> check Type D (recap), then HEARTBEAT_OK
5. After evening window -> HEARTBEAT_OK

## Rotation B -> C -> B -> ...

Before sending: read `MEMORY.md -> System Constraint`. Tie message to it.

### Type B: Insight + Constraint Nudge

One insight: analytics metric (skill `metrics-briefing`) or MANUAL category (conversations, pipeline, execution, economics). Relay race check. Content idea topic: headline + angle + why timely.

### Type C: CEO Coaching Nudge

From anti-patterns to current context: anti-pattern warning, weekly question, skill reminder. Specific to the company, not generic.

### Type D: Daily Recap (evening window)

If `lastRecapDate` != today -> run skill `daily-recap`. Does NOT count toward B/C limit. After -> update `lastRecapDate`.

## After B/C

Update `memory/heartbeat-state.json`: `messagesCount++`, `lastMessageAt`, `lastMessageType`. Write to `memory/YYYY-MM-DD.md` via skill `structured-log`.
