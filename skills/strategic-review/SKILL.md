---
name: strategic-review
description: Deep multi-phase strategic review of a specific decision — premise challenge, alternatives, risk map, adversarial review. Use for big choices (wedge, pricing, channel, hire, pivot). For quick framework lookup, use decision-playbook. For diagnosing why something is broken, use business-investigation.
user-invocable: true
---

# Strategic Review

Deep strategic analysis of a decision. Use when the founder faces a serious choice: change wedge, alter pricing, pick a channel, hire someone, partnership, pivot.

**Triggers:** "let's think strategically", "should we do X?", "consider options", "strategic review", "analyze the decision", "advise on strategy"

---

## Phase 0: Context

1. Read `MEMORY.md` — current wedge, stage, constraint, hypotheses
2. Read recent daily logs (`memory/YYYY-MM-DD.md` x 3)
3. Read `memory/hypotheses.json` — active hypotheses

State: "Here is what I know about the current situation: ..."

---

## Phase 1: Premise Challenge (MANDATORY)

Before thinking about the solution — challenge the problem statement itself:

### 1A. Is this the right problem?
Could a different framing yield a simpler/higher-impact solution? Often the first formulation is a proxy, not the actual problem.

### 1B. What if we do nothing?
Real pain or hypothetical? What is the cost of inaction in 2 weeks? In 2 months? If the cost is low — this may not be a priority.

### 1C. What do we already have?
What assets, knowledge, processes, relationships can be reused? Don't build from scratch what you can adapt.

### 1D. Constraint alignment
Does this decision exploit the current constraint or distract from it? If it distracts — strong arguments are needed.

Present the premise challenge to the founder. If they can't clearly articulate the problem or keep changing the formulation — gently suggest: "It seems you're still exploring. Let's nail down the problem first, then analyze solutions."

---

## Phase 2: Alternatives (MANDATORY — minimum 2)

For each approach:
```
APPROACH A: [Name]
  Summary: [1-2 sentences]
  Effort: [S/M/L/XL]
  Risk: [Low/Med/High]
  Pros: [2-3]
  Cons: [2-3]
  Reuses: [what from current state]
  Reversibility: [easy to revert / hard to revert / irreversible]
```

Rules:
- Minimum 2 approaches. 3 for non-trivial decisions.
- One = **minimal** (least effort, maximum learning)
- One = **ideal** (best long-term option)
- Third = **creative/lateral** (different problem framing)

**RECOMMENDATION:** Pick [X], because [one line tied to constraint/stage].

Do not proceed without the founder's approval.

---

## Phase 3: Mode Selection

Four analysis modes (inspired by gstack):

1. **EXPAND** — dream big, suggest ambitious moves. "What if 10x?" Each expansion is opt-in from the founder.
2. **SELECTIVE** — hold scope, but show possibilities. Cherry-pick.
3. **HOLD** — scope accepted, make it bulletproof. Find weak spots.
4. **REDUCE** — cut to minimum. What is the absolute MVP?

Contextual defaults:
- New initiative -> EXPAND
- Iterating on existing -> SELECTIVE
- Urgent decision -> HOLD
- Overload / burnout -> REDUCE
- WIP > 3 -> always suggest REDUCE

---

## Phase 4: Dream State Mapping

```
NOW                  ->  THIS DECISION         ->  IDEAL (12 months)
[describe current]      [what changes]            [where we want to be]
```

Does this plan move toward the ideal or away from it?

---

## Phase 5: Risk Map

For each significant risk of the chosen approach:

```
Decision/action | What could go wrong | P(prob.) | Impact | Reversible? | Mitigation
```

Apply **Bezos doors**: reversible risks -> try fast. Irreversible -> mitigate upfront.

Startup risk patterns to check:
- Decision optimizes a non-constraint?
- Decision creates commitment before sufficient evidence?
- Decision scales something not yet validated?
- Decision takes CEO time away from customer contact?

---

## Phase 6: Adversarial Review (Devil's Advocate)

Before the final recommendation — challenge yourself on 3 dimensions:

1. **Consistency:** do parts of the recommendation contradict each other?
2. **Feasibility:** realistic given current resources (engineering team, no sales, limited runway)?
3. **Constraint alignment:** does the recommendation exploit the constraint (market learning speed) or distract from it?

If issues are found — fix the recommendation BEFORE presenting to the founder.

---

## Phase 7: Final Recommendation

Structure:
```
STRATEGIC REVIEW — [decision name]
---
Problem: [1 line]
Recommendation: [approach X], because [1 line]
Reversibility: [two-way door / one-way door]
Next step: [1 concrete action this week]
Success metric: [what to measure]
Kill signal: [when to abort]
---
```

---

## Saving

- Log the decision to `memory/YYYY-MM-DD.md` via `structured-log`
- If the decision changes wedge/ICP/positioning -> update `MEMORY.md`
- If the decision spawns a hypothesis -> add via `hypothesis-tracker`

## Telegram Format

Split into 2-3 messages:
1. Premise challenge + recommendation (5-7 lines)
2. Alternatives (5-7 lines) — ask for choice
3. Risk map + next step (3-5 lines) — after choice

Follow output preferences from USER.md (language, format, platform constraints).

## Rules

- **Alternatives are mandatory.** Never recommend without at least 2 options.
- **One question at a time.** Don't batch multiple decisions.
- **Constraint first.** Every recommendation passes through the constraint filter.
- **Escape hatch:** if the founder already has a formed decision and just wants a sanity check -> skip Phases 2-3, do adversarial review (Phase 6) and risk map (Phase 5).
