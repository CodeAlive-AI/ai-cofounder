---
name: hypothesis-tracker
description: Add, update, review, and kill hypotheses using CEO Bible framework
user-invocable: true
---

# Hypothesis Tracker

Hypothesis management per CEO Bible Section J.

## WIP Limits (Critical Chain)

- **Max active hypotheses: 3**
- **Max concurrent experiments: 2**
- Stagger rule: do not start a new experiment until the bottleneck step of the current one is complete

If the founder asks to add a 4th active hypothesis -> ask: "Which of the current ones are you pausing or killing?"

Reason: each parallel project doubles the lead time of all others (Goldratt Critical Chain). Less WIP = faster throughput.

## Relay Race (Critical Chain)

Don't wait for the deadline. If evidence is sufficient for a decision (keep/kill/reframe) BEFORE the timebox — decide now.

On every hypothesis update, check: "Is there enough data for a decision already?" If yes -> flag: "H00X has sufficient evidence. Relay race — decide now."

## Commands

The founder may say:
- "new hypothesis: ..." -> add (check WIP limit!)
- "update hypothesis X: ..." -> update status/result
- "kill hypothesis X: ..." -> close with reason
- "show hypotheses" -> list active ones
- "rank hypotheses" -> re-sort by ELV

## Hypothesis Format (Bible J)

**For [ICP] who [trigger/problem], if we change [message / offer / product step / pricing / channel], then [metric] will move from X to Y by [date], because [evidence].**

## Structure in `memory/hypotheses.json`

```json
{
  "hypotheses": [
    {
      "id": "H001",
      "created": "2026-03-15",
      "status": "active",
      "statement": "For [ICP] who [trigger/problem], if we [change], then [metric] will move from X to Y within 30 days, because [evidence].",
      "icp": "[Your ICP description]",
      "change": "[What you're changing]",
      "metric": "[Key metric]",
      "baseline": null,
      "target": null,
      "deadline": "2026-04-15",
      "earliest_decision_possible": null,
      "evidence_tier": 4,
      "elv_score": null,
      "on_constraint": true,
      "result": null,
      "decision": null,
      "killed_reason": null
    }
  ]
}
```

## Signal Tiers (for evidence quality scoring)

1. **Tier 1:** costly-to-fake behavioral (paid pilots, expansion, integration, renewals)
2. **Tier 2:** product/onboarding evidence (session replays, drop-offs, support tickets)
3. **Tier 3:** commercial evidence (win/loss, objections, stalled deals)
4. **Tier 4:** market narrative (competitor moves, content performance, search behavior)
5. **Tier 5:** low-power (praise, vanity traffic, investor excitement)

## ELV Score (Expected Learning Value)

ELV = (pain severity x frequency x wedge fit x evidence quality x strategic leverage) / time-to-learning

In practice:
- Prefer hypotheses touching painful, frequent problem in core wedge
- Prefer tests that can change a major decision quickly
- Deprioritize elegant ideas that take months to disprove

## Experiment Design (when creating hypothesis)

Every experiment must contain:
- target cohort
- hypothesis statement
- exact metric
- baseline
- success threshold
- timebox
- owner
- what would falsify it
- what decision follows each outcome

## Good vs Bad Experiment Types

**Good pre-PMF:**
- message tests, onboarding/TTFV tests, core workflow simplification, pricing framing, pilot design, PQL handoff, founder outbound, proof asset tests

**Bad pre-PMF:**
- broad brand campaigns, "viral" growth hacks, complex pricing overhauls without usage proof, feature programs with no decision question

## Readout Rules

Experiment produces real learning only if it changes one of:
- who you target
- what you promise
- what users must do first
- what sales motion you use
- what you price/package
- what you stop building

A test that moves a CTR but doesn't change a real decision = activity, not learning.

## When Updating a Hypothesis

Log:
- Result (data)
- Decision (keep / kill / reframe)
- What changed in the company as a result
- Update `MEMORY.md` if the hypothesis affected wedge/stage

Follow output preferences from USER.md.
