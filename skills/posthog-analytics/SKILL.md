---
name: posthog-analytics
description: Raw PostHog data queries via MCP — event catalog, query recipes, dashboards, funnels, experiments. Use for specific data questions. For CEO-level metric interpretation and frameworks, use metrics-briefing instead.
user-invocable: true
---

# PostHog Analytics (via mcporter)

Direct access to PostHog data. Requires PostHog account + mcporter setup (see docs/adding-tools.md).

## Projects

Configure your PostHog projects here:

| Name | ID | Use |
|------|----|-----|
| app | [YOUR_PROJECT_ID] | Main product analytics (DEFAULT) |

## Tool

Use `exec` to call: `mcporter call posthog.<tool-name> <params>`

## Event Catalog

Configure your event catalog here. Common SaaS events to track:

### Journey & Funnel Events
| Event | Description | Key Properties |
|-------|------------|----------------|
| `signup_started` | User begins signup | source, utm_* |
| `signup_completed` | User completes signup | method |
| `activation_completed` | User reaches key activation milestone | timeSincePrevious |
| `feature_used` | Core feature usage | featureName, count |

### Common Funnel Stages
```
signup -> email_confirmed -> onboarding_started
-> first_value_moment -> return_visit
-> regular_usage -> power_user
-> team_invite
```

Customize this to match your product's activation funnel.

### Person Properties (B2B-relevant)
| Property | Type | Use |
|----------|------|-----|
| `$initial_utm_source` | String | First-touch attribution |
| `$initial_utm_medium` | String | First-touch attribution |
| `$initial_utm_campaign` | String | First-touch attribution |
| `$initial_referring_domain` | String | First-touch attribution |
| `organizationId` | String | B2B account grouping |

## Key Tools

### Discovery
```bash
mcporter call posthog.event-definitions-list
mcporter call posthog.event-definitions-list q="signup"
mcporter call posthog.properties-list type=event eventName="your_event"
mcporter call posthog.properties-list type=person
mcporter call posthog.entity-search query="activation"
```

### Natural Language Queries (recommended)
```bash
mcporter call posthog.query-generate-hogql-from-question question="..."
```

Best for:
- Complex breakdowns by multiple properties
- Account-level aggregations
- Attribution analysis ($initial_* properties)
- Time-between-events calculations

### Saved Insights
```bash
mcporter call posthog.insights-get-all
mcporter call posthog.insight-get insightId="123"
mcporter call posthog.insight-query insightId="123"
```

### Dashboards
```bash
mcporter call posthog.dashboards-get-all
mcporter call posthog.dashboard-get dashboardId=YOUR_DASHBOARD_ID
```

### Experiments & Feature Flags
```bash
mcporter call posthog.experiment-get-all
mcporter call posthog.experiment-results-get experimentId=123 refresh=false
mcporter call posthog.feature-flag-get-all
mcporter call posthog.feature-flag-get-definition flagKey="my-flag"
```

### Errors
```bash
mcporter call posthog.list-errors orderBy=occurrences dateFrom="2026-03-08T00:00:00Z"
mcporter call posthog.error-details issueId="uuid-here"
```

### Surveys
```bash
mcporter call posthog.surveys-get-all
mcporter call posthog.survey-stats survey_id="uuid"
```

## Switching Projects

If you have multiple projects:
```bash
mcporter call posthog.switch-project projectId=YOUR_OTHER_PROJECT_ID
# Switch back after:
mcporter call posthog.switch-project projectId=YOUR_DEFAULT_PROJECT_ID
```

## Query Recipes

### CEO Morning Briefing
```bash
# DAU yesterday
mcporter call posthog.query-generate-hogql-from-question question="How many unique users had events yesterday?"

# New signups yesterday
mcporter call posthog.query-generate-hogql-from-question question="How many signup events happened yesterday?"

# Funnel progression yesterday
mcporter call posthog.query-generate-hogql-from-question question="Show funnel stage transitions from yesterday, count by stage"
```

### Weekly CEO Dashboard
```bash
# Funnel health
mcporter call posthog.query-generate-hogql-from-question question="Show funnel events in the last 7 days, count unique users for each stage transition"

# Active companies
mcporter call posthog.query-generate-hogql-from-question question="How many distinct organizationId values had any events in the last 7 days?"

# TTFV (time to first value)
mcporter call posthog.query-generate-hogql-from-question question="What is the average time from signup to first activation event, last 30 days?"

# Source attribution
mcporter call posthog.query-generate-hogql-from-question question="For activated users last 30 days, what are the top initial UTM sources?"
```

## Output Format

Present results concisely:
- Key number + trend (vs previous period)
- Flag anomalies
- Link to metric class (Primary CEO / Secondary / B2B bridge)
- Always segment by target cohort when possible

Follow output preferences from USER.md.
