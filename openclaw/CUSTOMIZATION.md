# Customization Guide

The power of AI Cofounder comes from deep customization to your company. A generic setup is 10% as useful as a properly configured one.

## Step 1: IDENTITY.md — Name Your Agent

Give your AI Chief of Staff an identity:

```markdown
- **Name:** Atlas
- **Creature:** AI Chief of Staff for Acme CEO
- **Vibe:** Direct, data-driven, no-BS.
- **Emoji:** [pick one that fits]
- **Role:** CEO Operating System — helps Jane work as CEO, not as engineer.
```

**Tips:**
- Pick a name you'll enjoy seeing in chat every day
- The vibe sets the tone — "honest and direct" vs "supportive and encouraging"
- The emoji appears in the agent's identity display

## Step 2: USER.md — Tell It About Yourself

This is how the agent calibrates its communication:

```markdown
- **Name:** Jane Smith
- **Timezone:** America/New_York
- **Language:** English
```

**Key sections to fill:**
- **Communication style** — how direct/brief do you want responses?
- **CEO transformation context** — what shifts are you working through? (engineer->CEO, consultant->CEO, etc.)
- **Output preferences** — platform (Telegram/WhatsApp), max message length, language

## Step 3: MEMORY.md — Your Company Context (Most Important)

This is what makes every recommendation specific to YOUR situation. Fill in every section:

### Company
Basic info: name, what you do, team, stage.

### Current Wedge
This drives everything. Be specific:
- **ICP**: Not "companies" but "Engineering leads at 200-2000 dev companies with multi-repo legacy codebases"
- **Pain**: Not "they need our product" but "AI coding tools lose context in large codebases, onboarding takes weeks"
- **Promise**: Your one-line value prop for this specific ICP
- **Competitors**: Top 3-5 alternatives they actually consider (including "do nothing")

### PMF Stage
Be honest about where you are:
- **0-1 (Search)**: Still looking for repeatable pain + value
- **1-2 (Prove)**: Found pain, proving value is repeatable
- **2-3 (Scale)**: Repeatable, now scaling

### System Constraint
The single biggest bottleneck in your system. Common pre-PMF constraints:
- "Rate of validated market learning" (not enough customer contact)
- "Time to first value" (product too complex to onboard)
- "Positioning clarity" (people don't understand what we do)
- "Pipeline quality" (talking to wrong people)

The agent uses this to filter every recommendation: "Does this exploit the constraint or distract from it?"

## Step 4: TOOLS.md — External Tools (Optional)

If you use PostHog, Exa, or other tools via mcporter, configure them here. Otherwise, leave TOOLS.md minimal — the CEO OS works without external tools.

## Step 5: HEARTBEAT.md — Proactive Cadence

The default heartbeat sends:
- **Type B** (Insight + constraint nudge): max 2/day, min 4h apart
- **Type C** (CEO coaching): alternates with B
- **Type D** (Daily recap): once in the evening window

**Adjust timing** to your schedule:
- Change the morning quiet period (default: before 13:00)
- Change the evening recap window (default: 21:00-22:00)
- Increase/decrease the max messages per day

## Step 6: AGENTS.md — Skill Routing

Usually no changes needed. But if you:
- Removed some skills → remove them from the skill lists
- Added custom skills → add them to the appropriate category
- Want different routing → update the Routing section

## Step 7: Cron Jobs (Optional)

Set up recurring tasks:

```bash
# Morning briefing every day at 9 AM
openclaw cron create \
  --cron "0 9 * * *" \
  --timezone "America/New_York" \
  --session isolated \
  --deliver --channel telegram --to YOUR_CHAT_ID \
  --prompt "Run the morning CEO briefing. Check metrics, flag anomalies, suggest priorities."

# Weekly review on Sundays at 6 PM
openclaw cron create \
  --cron "0 18 * * 0" \
  --timezone "America/New_York" \
  --session isolated \
  --deliver --channel telegram --to YOUR_CHAT_ID \
  --prompt "Run ceo-weekly-review"
```

## After Changes

1. **Sync to server** (if remote): copy files to `~/.openclaw/workspace/`
2. **Fix permissions**: `chown -R openclaw:openclaw ~/.openclaw/workspace/`
3. **Reload**: send `/new` in chat

## Context Budget

OpenClaw has a bootstrap context limit (~15,000 chars). Keep within:
- SOUL.md < 3KB
- AGENTS.md < 2KB
- MEMORY.md < 3KB
- IDENTITY.md < 500B
- USER.md < 1KB
- TOOLS.md < 1KB
- HEARTBEAT.md < 1.5KB

Skills load on-demand and don't count toward this budget.

## Tips

- **Update MEMORY.md weekly** — after your weekly review, update metrics, hypotheses, and learnings
- **Don't over-fill MEMORY.md** — keep it to confirmed facts and current state. Use daily logs for ephemeral data.
- **Be specific in your constraint** — "growth is slow" is useless. "0 qualified conversations this week, target is 8-12" is actionable.
- **Let the agent push back** — the anti-pattern checks and self-deception flags are features, not bugs
