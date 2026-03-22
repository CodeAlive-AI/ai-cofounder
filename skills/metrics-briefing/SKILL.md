---
name: metrics-briefing
description: CEO-level metrics interpretation through 9-category framework (market learning, product value, usage, pipeline, retention, B2C->B2B, execution, economics, PMF). For raw analytics data queries, use your analytics skill (e.g., posthog-analytics) instead.
user-invocable: true
---

# Metrics Briefing

Metrics analysis through CEO Bible Section G — 9 categories. An analytics tool covers some; the rest come from conversations, CRM, and the founder's observations.

## Principles (Bible G)

1. **All metrics by target wedge.** Segment first, aggregate second.
2. **Behavior > opinions.** Usage, money, time spent > compliments.
3. **Pre-PMF metrics answer 5 questions:**
   - Are we talking to the right people?
   - Do they share the same painful problem?
   - Do they get value quickly?
   - Do they come back?
   - Can we win them again without heroics?
4. **MRR, CAC, LTV are guardrails, not the steering wheel.** Until there is repeatability.

## 9 CEO Metrics Categories

### 1. Market Learning (MANUAL — ask the founder)
| Metric | Definition | Source |
|--------|-----------|--------|
| Qualified conversations/week | 20+ min conversations with target roles; explored problem, trigger, workaround, buyer, urgency | Manual — track directly, target 8-12/week |
| Repeated pain rate | Same problem + trigger + workaround recur / total qualified conversations | Manual — from conversation notes |
| Objection concentration | Losses/stalls by top 3 reasons / all losses | Manual — from CRM/notes |

**If conversations < 8/week -> flag hard.** This is the main leading indicator.

### 2. Product Value (Analytics tool: partial)
| Metric | Definition | Source |
|--------|-----------|--------|
| **Median TTFV** | Time from signup to first meaningful success | Analytics — time between signup and first meaningful interaction event |
| **Activation rate** | Target accounts hitting critical event sequence within X days | Analytics — accounts reaching "meaningful result" milestone / total signups |
| **Outcome attainment** | Activated accounts achieving promised business result | Analytics — meaningful result → return usage conversion rate |

### 3. Usage / Engagement (Analytics tool: yes)
| Metric | Definition | Source |
|--------|-----------|--------|
| **Retained active target accounts** (week 4/8) | Accounts still performing core workflow | Analytics — accounts reaching "weekly active user" milestone |
| **Workflow depth** | Core workflow at target frequency, multiple use cases | Analytics — core action frequency, feature breadth per account |
| **Second-bite rate** | Users repeating core action within X days | Analytics — meaningful result → return usage conversion rate |

### 4. Sales / Pipeline (MANUAL — CRM/conversations)
| Metric | Definition | Source |
|--------|-----------|--------|
| ICP pipeline created | New opportunities from target wedge per week | Manual — CRM |
| Meeting -> opportunity | New opps / qualified first meetings | Manual — CRM |
| Opportunity -> win rate | Closed-won / closed in target wedge | Manual — CRM |
| Median sales cycle | Days from first meeting to signature | Manual — CRM |

### 5. Retention / Expansion (Analytics tool: partial)
| Metric | Definition | Source |
|--------|-----------|--------|
| **Healthy account rate** | Paid accounts with green usage + outcome + active champion | Analytics — accounts at regular/power usage stage, grouped by company |
| **Expansion pull rate** | Healthy accounts requesting more seats/team rollout | Analytics — accounts transitioning into team/multi-user stages |
| **Gross logo retention** | Paying logos retained once cohorts mature | Partial analytics — inferred from sustained usage stages; verify manually |

### 6. B2C -> B2B Conversion (Analytics tool: yes — key category)
| Metric | Definition | Source |
|--------|-----------|--------|
| **Target-signup rate** | Signups from target roles/domains / total signups | Analytics — filter signups by verified identity + connected integrations |
| **Activated -> PQL rate** | Activated users hitting enterprise triggers | Analytics — power users reaching multi-team or advanced usage signals, grouped by company |
| **PQL -> sales conversation** | PQLs that book real sales call | Partial analytics + manual CRM tracking |
| **Same-company emergence** | Active companies with >1 user or team invite | Analytics — companies with multiple active users or team invitation events |

### 7. Team Execution (MANUAL)
| Metric | Definition | Source |
|--------|-----------|--------|
| Experiment cycle time | Days from hypothesis to readout | Manual — from hypothesis tracker |
| Hypothesis-linked roadmap % | Work tied to hypothesis / total work | Manual — from backlog |
| Belief-change rate | Experiments ending in keep/kill/reframe / total | Manual — from weekly reviews |

### 8. Unit Economics (MANUAL)
| Metric | Definition | Source |
|--------|-----------|--------|
| Net burn / runway | Monthly cash burn; cash / burn | Manual — finance |
| Core workflow contribution margin | (Revenue - variable delivery costs) / revenue | Manual — finance |
| Revenue concentration | Top 3 customers / total ARR | Manual — finance |

### 9. PMF Detection (MIX)
| Metric | Definition | Source |
|--------|-----------|--------|
| **Wedge repeatability score** | Last 10 wins matching same ICP/problem/buyer/onboarding / 10 | Manual — assessment from CRM and deal notes |
| **Durable revenue ratio** | Revenue from accounts past trial + healthy >90 days / total | Partial analytics — inferred from sustained regular/power usage stages |
| **Organic pull index** | Target-cohort referrals, unsolicited inbound, expansion requests | Partial analytics — sharing/referral events as signals; verify manually |

## Analytics Implementation

See your analytics skill (e.g., posthog-analytics) for implementation details and query recipes — funnel event names, attribution model, company grouping, and morning briefing queries.

## Vanity Metrics (DO NOT report as progress)

- Total traffic, total signups, total "active users" mixed
- Feature count shipped
- Total pipeline across all segments
- PR hits, likes, followers
- Total MRR without durability/health filters
- B2C DAU that never clusters into accounts
- "AI usage" with no evidence of business outcome

## Metrics That Matter LATER (after PMF)

CAC payback, LTV/CAC, quota attainment, forecast accuracy, mature NRR, Rule of 40, hiring efficiency.

## Output Format (max 15 lines)

```
Metrics for [period]:

Learning: X conversations (target 8-12), pain rate Y%
Product: TTFV Xh, activation Z%
Usage: retained W4 X%, second-bite Y%
B2C->B2B: X signups -> Y activated -> Z PQL, same-co X
Pipeline: X opps, win rate Y%
PMF: repeatability [low/growing], organic pull [none/emerging]
Burn: $X/mo, runway Y months

Conclusion: [what this means for the current stage]
Action: [concrete action]
```

Follow output preferences from USER.md (language, format, platform constraints).
