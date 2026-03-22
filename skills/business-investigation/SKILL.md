---
name: business-investigation
description: Root cause analysis for business problems — why no signups, why churn, why stalled pipeline. Use when diagnosing WHY something is broken. For choosing between strategic options, use strategic-review instead.
user-invocable: true
---

# Business Investigation

Systematic root cause analysis for business problems. Engineering debugging adapted for CEO tasks.

**Triggers:** "why no signups", "why churn", "figure out why X", "what's wrong with Y", "investigate", "dig into"

---

## Iron Law

**DO NOT PROPOSE SOLUTIONS WITHOUT INVESTIGATING THE ROOT CAUSE.**

- Not "let's redesign the landing page" -> first "WHY signups = 0?"
- Not "let's hire sales" -> first "WHY is the current approach not working?"
- Symptomatic treatment creates whack-a-mole debugging. Find the root cause.

---

## Phase 1: Symptom Collection

1. **Define the problem specifically:** not "growth is slow", but "0 signups in 7 days with X visitors" or "3 out of 5 customers didn't complete onboarding"
2. **Gather data:**
   - Analytics tool: query quantitative data (see posthog-analytics skill or your analytics setup)
   - MEMORY.md: what do we already know about this problem?
   - Daily logs: were there similar problems before? What was tried?
   - Hypotheses.json: are there related hypotheses?
3. **Timeline:** when did the problem start? What changed? Regression = cause is in the change.

---

## Phase 2: Pattern Matching

Check typical startup patterns:

### Funnel Problems

| Where the problem is | Common cause | Where to look |
|---|---|---|
| Traffic -> signup | Positioning / channel / trust | Language, source quality, proof, CTA |
| Signup -> activation | Product / onboarding / TTFV | Steps to first value, friction points |
| Activation -> paid | Outcome proof / buyer / pricing | Value clear? Right buyer? |
| Paid -> retained | Problem frequency / workflow embed | Recurring job? In daily workflow? |
| Retained -> expansion | Narrow value / weak multi-user | Team hooks, second use case |

### Structural Problems

| Pattern | Symptom | Root cause |
|---|---|---|
| Wrong ICP | Every customer wants something different | Wedge too broad |
| Wrong channel | High effort, low response | Message-channel mismatch |
| Wrong timing | "Interesting, but not now" | No urgent trigger |
| Wrong buyer | User loves it, buyer won't pay | Value doesn't connect to budget |
| Feature != product | Demo wow, usage dead | Solves interesting != painful problem |
| Trust gap | Enterprise stalls at procurement | No case studies, no compliance, no social proof |

---

## Phase 3: Hypotheses (3-Strike Rule)

Formulate 1-3 root cause hypotheses. For each:

```
HYPOTHESIS: [specific statement]
  Evidence FOR: [what supports it]
  Evidence AGAINST: [what refutes it]
  How to test: [concrete action in 1-2 days]
  If true we'll see: [observable outcome]
  If false we'll see: [observable outcome]
```

**3-Strike Rule:** if 3 hypotheses turn out to be wrong -> STOP. The problem is likely architectural (wrong market, wrong product, wrong channel). Escalate:

```
3 hypotheses tested, none confirmed.
The problem may be deeper — not tactics, but strategy.

A) Continue investigation with a new hypothesis: [describe]
B) Launch strategic-review to reassess wedge/ICP
C) Talk to customers directly (CEO = best investigator)
```

---

## Phase 4: Root Cause -> Recommendation

When root cause is identified:

1. **Name the cause specifically.** Not "bad marketing", but "positioning says 'AI platform' instead of a specific outcome we deliver for engineering leads"
2. **Minimal intervention.** The smallest change that eliminates the cause.
3. **Tie to constraint.** Does the solution exploit the constraint (market learning speed) or not?
4. **Kill signal.** At what result do we abort the solution?

---

## Phase 5: Report

```
INVESTIGATION REPORT
---
Symptom:        [what we observe]
Root cause:     [why this is happening]
Evidence:       [data confirming]
Recommendation: [what to do]
Metric:         [what to measure]
Kill signal:    [when to abort]
Status:         DONE / DONE_WITH_CONCERNS / BLOCKED
---
```

Log to `memory/YYYY-MM-DD.md` via `structured-log`.

---

## Telegram Format

```
Investigation: [problem]

Root cause: [1-2 lines]
Evidence: [key proof]

Recommendation: [action]
Metric: [what to measure]

Status: [DONE/BLOCKED/NEEDS_CONTEXT]
```

Follow output preferences from USER.md (language, format, platform constraints).

## Rules

- **Data -> hypothesis -> test -> conclusion.** Not the other way around.
- **Don't say "should fix it".** Show evidence.
- **If you can't test** — say NEEDS_CONTEXT and request specific data.
- **Don't expand scope.** Investigate one problem, don't switch.
