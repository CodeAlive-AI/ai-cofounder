# MVNA Fallback Library

Minimum Viable Next Actions for cold-start (empty pipeline, no active hypotheses).

Select ONE action per day. Don't repeat yesterday's type — rotate.
**Default: async-first.** Never suggest cold calls unless CEO explicitly asks.

## Friction Rating

Each action has a friction level. Default to LOW friction. Escalate only on request or after 5+ successful completions.

- 🟢 LOW: Bot does everything, CEO clicks "send"
- 🟡 MEDIUM: CEO reviews/edits a draft
- 🔴 HIGH: CEO initiates live conversation

## Research (5-10 min, bot does the work) 🟢

### Find ICP Company
- Run `exa-company-research` for ICP matches (criteria from MEMORY.md)
- Present 3 results with 1-line summaries
- CEO picks 1 → bot adds to pipeline
- **Chain:** exa-company-research → pipeline-manager

### Find Contact
- From pipeline prospect or ICP description
- Run `person-lookup` + `find-email-by-name`
- Present: name, role, email, LinkedIn
- **Chain:** person-lookup → find-email-by-name → pipeline-manager

## Async Outreach (7-12 min, bot drafts, CEO approves) 🟢-🟡

### Cold Email 🟡
- Pick target from pipeline (or today's research)
- Draft via `cold-email` using value prop from MEMORY.md
- Polish via `humanizer`
- Show complete draft: "Reply go — отправлю через Gmail"
- **Chain:** cold-email → humanizer → outreach-sender

### Warm Follow-up 🟢
- Find most recent contact from pipeline or daily logs
- Draft short follow-up referencing last interaction
- **Chain:** cold-email (follow-up) → humanizer → outreach-sender

### LinkedIn Comment 🟢
- Find relevant post from ICP person
- Draft useful technical comment (not sales pitch)
- Present for CEO to post manually
- **Chain:** exa-personal-site → cold-email (comment template)

### LinkedIn DM 🟡
- Draft short personalized message to ICP contact
- Reference their recent post/activity
- Present for CEO to send
- **Chain:** exa-personal-site → cold-email (DM template) → humanizer

## Strategy (5-10 min, structured thinking) 🟡

### Create Hypothesis
- Guide through hypothesis-tracker: "For [ICP] who [trigger], if we [change], then [metric] X → Y"
- Ask CEO ONE question to fill template
- **Chain:** hypothesis-tracker

### Discovery Question
- Generate 1 specific question for next customer conversation
- Based on current hypothesis or wedge assumption
- **Chain:** conducting-user-interviews

## Live Conversation (only if CEO requests) 🔴

### Book Call
- Find warm contact from pipeline
- Draft async message proposing specific time
- **Chain:** cold-email → google-calendar

### Ask for Intro
- Identify mutual connection
- Draft intro request message
- **Chain:** person-lookup → cold-email → humanizer

## Selection Logic

```
IF pipeline has overdue follow-up → Warm Follow-up 🟢
ELIF pipeline has enriched prospect without outreach → Cold Email 🟡
ELIF hypotheses.json has active hypothesis needing data → Discovery Question 🟡
ELIF last MVNA was Research → pick Async Outreach
ELIF last MVNA was Outreach → pick Research or Strategy
ELSE → Find ICP Company 🟢 (safest cold-start)
```

After 3+ consecutive misses → drop to 🟢-only options.
Always check `focus-history.jsonl` last 3 entries to avoid repeating same type.
