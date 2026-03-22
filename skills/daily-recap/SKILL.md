---
name: daily-recap
description: End-of-day consolidation — summarize daily log, promote durable facts to MEMORY.md, identify open threads
---

# Daily Recap

End-of-day consolidation. Triggered by heartbeat at 21:00-22:00 or manually ("recap the day").

## Algorithm

### 1. Read today's log

Open `memory/YYYY-MM-DD.md`. If empty or no entries — write "No entries today" and `HEARTBEAT_OK`.

### 2. Extract key items

From all entries of the day, compile:

```markdown
## Daily Recap

**Decisions:** (decisions made today)
- [decision]: [why] -> [what changes]

**New facts:** (new confirmed facts)
- [fact] (source: [where from])

**Belief changes:** (what shifted in understanding)
- [was] -> [became] (evidence: [what showed it])

**Open threads:** (started but not finished)
- [topic]: [what remains to be done]

**Constraint check:** [current constraint] — today [exploit/subordinate/ignore]?
```

### 3. Check for promotion to MEMORY.md

For each new fact and belief change, ask:
- Does this change something in MEMORY.md sections? (Company, Wedge, PMF Stage, Metrics, Constraint)
- Is it sufficiently confirmed? (not a single data point)

If yes — update MEMORY.md:
- Replace outdated info (don't duplicate)
- Update review timestamp if Constraint or PMF Stage changed
- Keep MEMORY.md < 3KB

### 4. Write recap to daily log

Append the `## Daily Recap` block to the end of `memory/YYYY-MM-DD.md`.

### 5. Update heartbeat state

In `memory/heartbeat-state.json` set `"lastRecapDate": "YYYY-MM-DD"`.

## Telegram Output Format

```
Day recap:

Decisions: X
- brief description of each

New facts: Y
- brief description of each

Open: Z threads
[list if any]

Constraint: [exploit/subordinate/ignore today]
```

If the day was empty: "Quiet day. No entries."

Follow output preferences from USER.md (language, format, platform constraints).

## Rules

- Max 15 lines for Telegram
- Don't fabricate — only from today's entries
- Belief changes > facts > tasks by importance
- If MEMORY.md was updated — mention: "MEMORY.md updated: [what exactly]"
