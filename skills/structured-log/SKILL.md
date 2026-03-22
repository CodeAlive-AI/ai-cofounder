---
name: structured-log
description: Write structured entries to daily memory log with facts, concepts, and files — use after any meaningful work, research, or decision
---

# Structured Log

Write structured entries to `memory/YYYY-MM-DD.md` instead of free-form text. This improves recall via `memory_search`.

## When to Use

After any meaningful action:
- Made a decision or received a decision from the founder
- Discovered a new fact (via Exa, PostHog, web, conversation)
- Found an insight or pattern
- Completed a task with a result
- Updated a hypothesis

## Entry Format

```markdown
### HH:MM — [TYPE] Title

What happened (1-2 sentences).

**Facts:**
- concrete fact 1
- concrete fact 2

**Concepts:** keyword1, keyword2, keyword3
**Files:** path/to/file (if changed)
```

## Types (TYPE)

| Type | When |
|------|------|
| DECISION | Decision made (by whom, why, what changes) |
| FACT | New confirmed fact (source required) |
| INSIGHT | Pattern, connection, conclusion from data |
| TOOL | Finding from tool usage (PostHog, Exa, web) |
| TASK | Completed task with result |
| HYPOTHESIS | Created/updated/killed a hypothesis |

## Rules

1. **Facts must be verifiable.** "Signups = 0 for 7 days" (ok). "Seems low" (no).
2. **Concepts are for search.** Write keywords you'd use to find this entry later via `memory_search`. Include: names, products, metrics, topics.
3. **Files — only if changed.** List only files that were created or modified.
4. **One entry = one topic.** Don't mix a decision + tool finding in one entry.
5. **Narrative < 50 words.** Context goes in facts, not prose.

## Promotion to MEMORY.md

A fact deserves promotion to MEMORY.md if:
- It changes understanding of wedge, ICP, constraint
- It's confirmed 2+ times from different sources
- It affects current strategy or hypothesis

On promotion — add to the appropriate MEMORY.md section and remove outdated info.

## Example

```markdown
### 14:30 — [TOOL] Analytics: 41% onboarding drop-off

Analytics query revealed a high drop-off rate during onboarding.

**Facts:**
- 41% of users who start onboarding don't complete the key activation step (30d)
- Main cause: timeout on large data imports
- Affects the signup -> activated funnel stage

**Concepts:** onboarding, activation-blocker, funnel-drop, analytics, TTFV
**Files:** —
```
