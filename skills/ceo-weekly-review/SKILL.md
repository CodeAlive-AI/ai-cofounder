---
name: ceo-weekly-review
description: Weekly CEO review — 10 questions, dashboard, self-deception check, next week focus
user-invocable: true
---

# CEO Weekly Review

Runs every Sunday evening (cron) or manually on the founder's command.

## Process

### Step 0: System Throughput (Critical Chain — DO THIS FIRST)

**How many validated beliefs changed this week?**
- Hypotheses resolved (keep/kill/reframe): X
- ICP assumptions updated: X
- Decisions on pricing/positioning/message: X
- Target: >= 1 meaningful change/week

**Constraint check:**
- Read `MEMORY.md -> System Constraint`
- CEO time on constraint-work (conversations, discovery, sales) vs non-constraint: X/Y hours
- Target: >35% on constraint
- Has the constraint shifted? If yes -> update MEMORY.md

**WIP check:**
- Active hypotheses: X (limit: 3). Active experiments: X (limit: 2).
- Relay race: are there hypotheses with enough evidence for a decision right now?

### Step 1: Gather Data

1. Read `MEMORY.md` — current wedge, stage, hypotheses, constraint
2. Read `memory/hypotheses.json` — experiment status
3. Read daily logs for this week (`memory/YYYY-MM-DD.md` x 7)
4. If an analytics tool is available — query key metrics for the week

### Step 2: CEO Weekly Dashboard (Bible Section H.1)

Build the dashboard across 9 categories. Use your analytics tool for 2,3,5,6,9. The rest — ask the founder.

**Header:** Current stage | Wedge | System constraint | Biggest risk this week

**1. Learning (ASK FOUNDER):**
- Qualified conversations this week (target: 8-12)
- Repeated pain rate (same problem/trigger recurring?)
- What changed our beliefs?

**2. Product (analytics):**
- TTFV: median time from signup to first meaningful interaction
- Activation: progression through activation funnel stages
- Funnel: signup -> activated -> return -> regular -> power (compare to last week)

**3. Usage (analytics):**
- Retained active: weekly active user count
- Core feature weekly active users
- Power feature usage (e.g., multi-repo, advanced modes)

**4. Pipeline (ASK FOUNDER):**
- New pipeline in wedge
- Win rate trend
- Sales cycle

**5. Retention (analytics + manual):**
- Healthy accounts: users/orgs at regular usage stage or above
- Expansion pull: team invitation or sharing activity

**6. B2C -> B2B (analytics — KEY):**
- Target signups: new accounts with qualified attributes
- Active companies: unique company/org count
- Companies with 2+ users
- Same-company emergence rate

**7. Execution (ASK FOUNDER):**
- Experiment cycle time, belief changes this week

**8. Economics (ASK FOUNDER):**
- Burn/runway

**9. PMF signals (MIX):**
- Wedge repeatability (last wins look alike?)
- Organic pull (sharing events, inbound, referrals)

**Attribution (analytics):**
- Top acquisition sources for activated users

### Step 3: 10 Weekly Questions (Bible Section P)

Go through each question and provide a brief answer based on gathered data:

1. What did we learn this week that actually changed our beliefs?
2. Which segment showed the strongest pain, fastest value, and repeatability?
3. Did I personally talk to enough customers, buyers, and lost prospects?
4. Which metric moved, and what decision follows from it?
5. Is the B2C layer creating enterprise signal or just activity?
6. Are recent wins becoming more similar or more bespoke?
7. Is time-to-first-value decreasing?
8. Are healthy accounts asking for more on their own?
9. What are we calling progress because it feels good?
10. If we were starting the company today, would we choose the same wedge?

### Step 4: Self-Deception Check (Bible Section P)

Check 10 self-deception signals:

1. Only warm intros convert?
2. Traffic/signups grow, but target-cohort activation doesn't?
3. Calling pilot revenue "ARR"?
4. Every early customer wants a different product?
5. Buyers love demos but don't use the product?
6. Annual contracts look OK, but engagement is dead?
7. Hiring because learning feels slow?
8. Founder can't explain the last 5 deals?
9. B2C grows, but doesn't create accounts or pipeline?
10. Team is very busy, but beliefs and priorities don't change?

If 3+ signals fire — flag hard.

### Step 5: Adversarial Self-Review

Before final recommendations — challenge your own analysis:

1. **Consistency:** do my dashboard conclusions contradict my answers to the 10 questions?
2. **Proxy skepticism:** am I assessing real progress toward PMF or convenient metrics?
3. **Constraint alignment:** do my next-week recommendations exploit the constraint (market learning speed)?
4. **Inversion:** what would have to happen next week for the company to get WORSE? Do my bets protect against that?

If issues are found — fix recommendations BEFORE sending.

### Step 6: Next Week

Formulate:
- **Top 3 bets** for next week (tied to constraint)
- **Top 3 kills** (what to stop — Jobs's subtraction)
- **Top 3 asks** (what is needed from the founder or externally)

For each bet: reversibility (two-way / one-way door) and kill signal.

### Step 7: Save

Log the result to `memory/weekly/YYYY-WW.md`.
Update `MEMORY.md` if any of these changed: stage, wedge, key learnings.

## Output Format

Don't send everything in one message. Split into 3-4 short ones:
1. Dashboard summary (5-7 lines)
2. Key answers + self-deception flags (5-7 lines)
3. Next week focus (3-5 lines)

Follow output preferences from USER.md (language, format, platform constraints).

## Tone

Like an honest Chief of Staff: facts -> implications -> actions. Don't sugar-coat.
