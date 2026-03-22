---
name: discovery-debrief
description: Structured debrief AFTER a customer conversation — extract learnings, update hypotheses, track demand signals. Use when the founder says "talked to a customer". For preparing and planning interviews beforehand, use conducting-user-interviews.
user-invocable: true
---

# Discovery Debrief

Structured extraction after a customer/prospect conversation. Every conversation is data. This skill turns conversations into actionable learnings.

**Triggers:** "talked to a customer", "customer call", "debrief", "discovery call", "had a call with...", "met with..."

---

## Step 0: Context

1. Read `MEMORY.md` — current wedge, ICP, constraint
2. Read `memory/hypotheses.json` — active hypotheses
3. Ask: "Who did you talk to? Tell me in free form."

---

## Step 1: Structured Extraction

After the founder's free-form story — extract structured data. Ask clarifying questions ONE AT A TIME (don't batch).

### 1.1 Who
- Name, role, company, team/company size
- How the contact was established (inbound/outbound/referral)
- Buyer or user? (often different people)

### 1.2 Demand Reality (is demand real?)
> "Would this person be upset if our product disappeared tomorrow?"

Look for behavioral evidence, not words:
- Paying or willing to pay? How much?
- Using the product? How often?
- Building workflow around the product?
- Would scramble if the product vanished?

**Red flags:** "interesting", "need to think about it", "show it to my colleagues" — this is politeness, not demand.

### 1.3 Status Quo (what are they doing now?)
> "How do they solve this problem today — even poorly?"

Look for the specific workflow:
- What tools/processes do they use?
- How much time/money do they spend?
- Who does it manually?
- What breaks in the current process?

**Red flag:** "they don't do anything" -> the problem may not be painful enough.

### 1.4 Narrowest Wedge (minimum product for money)
> "What is the smallest version of the product they would pay for right now?"

Not "the full platform", but one workflow, one integration, one use case.

### 1.5 Surprise (what was unexpected?)
> "What in this conversation didn't match your expectations?"

Surprise = the most valuable signal. If there are no surprises — either wasn't listening or confirming bias.

**Gold:** customer uses the product in an unintended way -> that might be the real product.

---

## Step 2: Signal Assessment

Assess signal strength using Evidence Tiers (CEO Bible):

| Tier | Evidence type | Strength |
|------|-------------|------|
| 1 | Pays, expands, integrated, renewed | Strongest |
| 2 | Session replays, drop-offs, support tickets | Strong |
| 3 | Win/loss, objections, stalled deals | Medium |
| 4 | Market narrative, competitor moves, content | Weak |
| 5 | Praise, vanity traffic, investor excitement | Near zero |

Classify: "This conversation yielded tier [X] evidence: [specifically what]"

---

## Step 3: Hypothesis Check

For each active hypothesis from `memory/hypotheses.json`:
- Does this conversation confirm, refute, or remain neutral?
- If confirms/refutes — what specific evidence?

**Relay Race check:** is there a hypothesis with enough evidence for a decision RIGHT NOW? If yes -> flag: "H00X has sufficient data. Decide now, don't wait for the deadline."

---

## Step 4: Pattern Detection

Compare with previous conversations (from daily logs):
- Same pain recurring? (repeated pain -> strong signal)
- Same trigger? Same workaround?
- Same buyer profile? Or different people with different problems?

**Convergence signal:** 3+ conversations with same pain, same trigger, same workaround -> wedge is clarifying.
**Divergence signal:** every customer wants something different -> wedge is blurry, need to narrow.

---

## Step 5: Save

1. Log to `memory/YYYY-MM-DD.md` via `structured-log`:
```
## Discovery: [Company] — [Name, Role]
- **Source:** inbound/outbound/referral
- **Demand:** [tier X] — [evidence]
- **Status quo:** [what they do now]
- **Wedge fit:** [high/medium/low] — [why]
- **Surprise:** [what was unexpected]
- **Hypothesis impact:** [H00X: confirms/weakens/neutral]
- **Next step:** [concrete action]
```

2. Update `memory/hypotheses.json` if there is hypothesis impact
3. Update `MEMORY.md` if any of these change: ICP, wedge, positioning, PMF stage

---

## Step 6: Constraint Nudge

Close the debrief with a reminder:
- "Qualified conversations this week: X out of target 8-12"
- If < 4 -> "Priority: more conversations, less code"
- If the conversation was not with target ICP -> note: "This conversation is outside the current wedge. OK for exploration, but don't count as qualified."

---

## Telegram Format

```
Discovery: [Company] — [Role]

Demand: Tier [X] — [1 line evidence]
Status quo: [what they do now]
Surprise: [what was unexpected]
Hypothesis: H00X [confirms/weakens]

Conversations: X/8-12 this week
Next: [concrete action]
```

Follow output preferences from USER.md (language, format, platform constraints).

## Rules

- One question at a time. Don't batch.
- Quote exact customer words when possible — customer's words > founder's interpretation.
- Don't assess until all 5 points (1.1-1.5) are collected.
- If the founder retells superficially -> push: "What exactly did they say? In what words?"
