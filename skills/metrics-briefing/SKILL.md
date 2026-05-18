---
name: metrics-briefing
description: CEO-level metrics interpretation through 9-category framework (market learning, product value, usage, pipeline, retention, B2C->B2B, execution, economics, PMF). For raw PostHog data queries, use posthog-analytics instead.
user-invocable: true
---

# Metrics Briefing

Metrics analysis through CEO Bible Section G — 9 categories. PostHog covers some; the rest come from conversations, CRM, and the founder's observations.

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
| Metric | Definition | PostHog? |
|--------|-----------|----------|
| Qualified conversations/week | 20+ min conversations with target roles; explored problem, trigger, workaround, buyer, urgency | No — track manually, target 8-12/week |
| Repeated pain rate | Same problem + trigger + workaround recur / total qualified conversations | No — from conversation notes |
| Objection concentration | Losses/stalls by top 3 reasons / all losses | No — from CRM/notes |

**If conversations < 8/week -> flag hard.** This is the main leading indicator.

### 2. Product Value (PostHog: partial)
| Metric | Definition | PostHog |
|--------|-----------|---------|
| **Median TTFV** | Time from signup to first meaningful success | `user_journey_milestone` WHERE milestone='First Value Moment', property `timeSincePrevious` |
| **Activation rate** | Target accounts hitting critical event sequence within X days | `funnel_next_stage_available` WHERE currentStage='first_value_delivered' / total signups |
| **Outcome attainment** | Activated accounts achieving promised business result | `funnel_next_stage_available`: first_value_delivered -> return_usage conversion rate |

### 3. Usage / Engagement (PostHog: yes)
| Metric | Definition | PostHog |
|--------|-----------|---------|
| **Retained active target accounts** (week 4/8) | Accounts still performing core workflow | `user_journey_milestone` WHERE milestone='Weekly Active' |
| **Workflow depth** | Core workflow at target frequency, multiple use cases | `core_query_performed` frequency, `deep_workflow_started`, searchMode breakdown |
| **Second-bite rate** | Users repeating core action within X days | `funnel_next_stage_available`: first_value_delivered -> return_usage |

### 4. Sales / Pipeline (MANUAL — CRM/conversations)
| Metric | Definition | PostHog? |
|--------|-----------|----------|
| ICP pipeline created | New opportunities from target wedge per week | No — CRM |
| Meeting -> opportunity | New opps / qualified first meetings | No — CRM |
| Opportunity -> win rate | Closed-won / closed in target wedge | No — CRM |
| Median sales cycle | Days from first meeting to signature | No — CRM |

### 5. Retention / Expansion (PostHog: partial)
| Metric | Definition | PostHog |
|--------|-----------|---------|
| **Healthy account rate** | Paid accounts with green usage + outcome + active champion | `funnel_next_stage_available`: regular_usage+ stage, organizationId grouping |
| **Expansion pull rate** | Healthy accounts requesting more seats/team rollout | `funnel_next_stage_available` WHERE nextStage='team_invitation_sent' |
| **Gross logo retention** | Paying logos retained once cohorts mature | Not fully — partially through return/regular/power stages |

### 6. B2C -> B2B Conversion (PostHog: yes — key category)
| Metric | Definition | PostHog |
|--------|-----------|---------|
| **Target-signup rate** | Signups from target roles/domains / total signups | `user_journey_milestone` milestone='Account Created', filter by email_verified + has_primary_integration_connected |
| **Activated -> PQL rate** | Activated users hitting enterprise triggers | power_user stage + deep_workflow_started + organizationId |
| **PQL -> sales conversation** | PQLs that book real sales call | Partial — track manually |
| **Same-company emergence** | Active companies with >1 user or team invite | `funnel_next_stage_available` nextStage='team_invitation_sent', organizationId grouping |

### 7. Team Execution (MANUAL)
| Metric | Definition | PostHog? |
|--------|-----------|----------|
| Experiment cycle time | Days from hypothesis to readout | No — from hypothesis tracker |
| Hypothesis-linked roadmap % | Work tied to hypothesis / total work | No — from backlog |
| Belief-change rate | Experiments ending in keep/kill/reframe / total | No — from weekly reviews |

### 8. Unit Economics (MANUAL)
| Metric | Definition | PostHog? |
|--------|-----------|----------|
| Net burn / runway | Monthly cash burn; cash / burn | No — finance |
| Core workflow contribution margin | (Revenue - variable delivery costs) / revenue | No — finance |
| Revenue concentration | Top 3 customers / total ARR | No — finance |

### 9. PMF Detection (MIX)
| Metric | Definition | PostHog |
|--------|-----------|---------|
| **Wedge repeatability score** | Last 10 wins matching same ICP/problem/buyer/onboarding / 10 | No — manual assessment |
| **Durable revenue ratio** | Revenue from accounts past trial + healthy >90 days / total | Partial — through regular_usage/power_user stages |
| **Organic pull index** | Target-cohort referrals, unsolicited inbound, expansion requests | Partial — `public_output_viewed`, `output_sharing_enabled` as signals |

## PostHog Implementation Layer

### Core Funnel (funnel_next_stage_available events)
```
signup_started -> account_created -> email_confirmed
  -> workspace_created -> first_value_moment
  -> first_primary_resource_added -> primary_resource_processed
  -> first_key_action_executed -> first_value_delivered
  -> return_usage -> regular_usage -> power_user
  -> team_invitation_sent
```

### 4 Analytics Layers
1. **Anonymous visitor**: $initial_utm_source, $initial_referring_domain, $initial_current_url
2. **User identity**: $identify, email_verified, has_primary_integration_connected
3. **Product value**: workspace_create_started, primary_resource_action, core_query_performed, core_action
4. **Account/company**: organizationId (on all events) — B2B grouping

### Attribution Model
- **First-touch** (person.$initial_*): "What created initial interest?" -> content, SEO, founder content
- **Last-touch**: "What triggered conversion?" -> pricing page, CTA performance
- **Right question**: "Which source produces the most retained companies?" — apply to activation, PQL, paid, retained

### PostHog Query Recipes

**CEO Morning Briefing:**
```bash
# Signups yesterday
posthog__query-generate-hogql-from-question question="How many user_journey_milestone events with milestone Account Created happened yesterday?"

# Funnel transitions yesterday
posthog__query-generate-hogql-from-question question="Show all funnel_next_stage_available events from yesterday, count by currentStage to nextStage"

# Active companies this week
posthog__query-generate-hogql-from-question question="How many distinct organizationId values had any events in the last 7 days?"
```

**Weekly Dashboard:**
```bash
# Funnel health (all stages)
posthog__query-generate-hogql-from-question question="Show funnel_next_stage_available events in the last 7 days, count unique users for each currentStage to nextStage pair"

# TTFV
posthog__query-generate-hogql-from-question question="What is the average timeSincePrevious for user_journey_milestone where milestone is First Value Moment, last 30 days?"

# Attribution: source -> activation
posthog__query-generate-hogql-from-question question="For users who reached first_value_delivered in funnel_next_stage_available last 30 days, what are the top initial UTM sources?"

# Account-level: companies with multiple users
posthog__query-generate-hogql-from-question question="Which organizationId values have more than 1 unique user performing events in the last 30 days?"
```

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

## Telegram Format (max 15 lines)

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
