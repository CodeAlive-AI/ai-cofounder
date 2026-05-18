---
name: idea-generator
description: Generate business, marketing, and post ideas tied to your product's wedge and stage. Use when asked for partnership ideas, marketing tactics, content angles, or fresh experiments to run.
user-invocable: true
---

# Idea Generator

Idea generation module for a CEO operating system. Job: produce **specific, actionable ideas** in three categories — partnerships, marketing tactics, social posts — all tied to the user's current wedge and stage.

**Important:** before generating, read `MEMORY.md` for the current wedge, stage (pre-PMF / scaling / mature), differentiators, ICP, competitors, and recent priorities. Ideas should help the next learning step or proof point — not premature scaling.

## Reading Context

Pull from MEMORY.md (or ask the user once if missing):

- **Product** — one-sentence description, key differentiators
- **Wedge** — the specific entry point you're attacking
- **Stage** — pre-PMF / early-PMF / scaling
- **Customers (ICP)** — role, company size, industry
- **Competitors** — who shows up in deals
- **Use cases** — top 3-5 jobs the product is hired for
- **Distribution** — current channels that work

If any of these are missing, ask the user once before generating, then save the answer back to MEMORY.md.

## Three Idea Categories

### A: Business Partnership Ideas

Specific partnerships with named companies or company types. Think:

- **Integration partnerships** — tools the customer already uses; embed your product into their workflow
- **AI/agent partnerships** — agent platforms or assistants where your product can be the data/context provider
- **Channel partners** — consultancies, system integrators, resellers who reach your enterprise ICP
- **Co-marketing** — joint research, webinars, reports with adjacent vendors
- **Open source** — contribute to standards/ecosystems where your buyers hang out
- **Vertical** — partners specific to one industry where your wedge lands hardest
- **Academia** — university programs, research partnerships in your domain

### B: Marketing Ideas

Specific tactics with mechanics:

- **Product-led growth** — free tier hooks, viral loops, referral programs
- **Community** — Discord/Slack community, champions program, OSS contributors
- **Content marketing** — SEO articles, comparisons, benchmarks, case studies
- **Events** — relevant conferences, meetups, webinars (name them)
- **Campaigns** — themed campaigns ("[Pain] Month", "[Workflow] Challenge")
- **Influencers** — specific DevRel, YouTube, X/LinkedIn voices in the niche
- **PR** — press releases, research reports, awards in the category

### C: Social Media Post Ideas

With platform and format specified:

- **LinkedIn** — thoughts for your buyer persona, industry observations, mini case studies
- **X (Twitter)** — hot takes, polls, threads in your niche
- **Dev.to / Hashnode / Medium** — technical deep dives, tutorials, "How [YOUR_PRODUCT] does X"
- **HackerNews** — Show HN format, technical breakdowns
- **YouTube** — demos, comparisons, "day in the life" content
- **Reddit** — top subreddits where your ICP hangs out (name them) — valuable posts, not ads

## Validation Filters

Run every idea through these silently. If an idea fails, fix it or drop it.

### Why Now test
"Why is this idea possible/relevant NOW when it wasn't 6 months ago?" Every idea must connect to a recent shift — new technology, behavior change, market event, infrastructure change, regulatory shift.

### Tarpit detection
Flag ideas that fall into crowded spaces where many have tried and failed. Generic tarpits to avoid:
- "Generic AI [category] tool" — many competitors, commodity
- "Another [popular IDE/platform] extension" — oversaturated channel
- "General [job] productivity" — too vague, no wedge

Off-the-beaten-path examples (good):
- Underserved verticals where your wedge is uniquely strong
- New categories that just opened (e.g. recent platform/standard adoption)
- Adjacent jobs your product enables that competitors don't address

### Differentiation check
"Does this idea leverage what your product **uniquely** has?" Tie back to differentiators from MEMORY.md. If any competitor could do this equally well — the idea is weak.

## Idea Format

```
[Category A/B/C] Short title

What: what specifically to do (2-3 sentences)

Why now: what changed that makes this timely (1 sentence)

Why it works: tie to your differentiator (1-2 sentences)

First step: one concrete action to start

Risk: tarpit / crowded / safe (1 word)

[link if found relevant]
```

## Examples (template form)

### Example A (partnership):
```
[A] [Adjacent Tool] Integration

What: propose [Adjacent Tool] (open-source [category], NK+ users) an integration where your product becomes their [data/context/workflow] provider. They actively seek better [missing capability].

Why now: [recent platform shift] is creating demand for this — [Adjacent Tool] just shipped support, perfect timing to plug in.

Why it works: your product's [differentiator] delivers [N]x better [metric] than their built-in [alternative]. Win-win: they get a killer feature, you get distribution.

First step: post in their community (#integrations channel) with a proposal + link to your integration spec.

Risk: safe
```

### Example B (marketing):
```
[B] "[Pain] Horror Stories → How We Fixed It" series

What: 5 real (anonymized) cases where your product solved [pain]. Each case = blog + LinkedIn post + X thread.

Why now: [pain] is the #1 unsolved problem in [adjacent narrative]. Nobody is doing case studies for it specifically.

Why it works: horror stories go viral in your community. Educational + entertaining, not advertising.

First step: ask current users for permission to anonymously describe their use case.

Risk: safe
```

### Example C (post):
```
[C] "I asked an AI to [do task] N times. Here's what it found."

What: LinkedIn post with stats from your product — most common patterns, repeating mistakes, breakdown by category.

Why now: [topic] is hot but nobody publishes real aggregate data. First-mover advantage on data-driven content.

Why it works: your buyers love concrete numbers. Educational + product demo without direct advertising.

First step: run your product on a representative dataset and collect stats.

Risk: safe
```

## Challenge Mode (optional)

If the founder says "challenge me" or "challenge mode" — before generating ideas, ask 2-3 of these questions and use the answers to sharpen the output:

- "What changed in the market this week/month that we should react to?"
- "Which of our current ideas are we most excited about — and why might we be wrong?"
- "What does our unique info diet tell us that other founders don't see?"
- "If your product disappeared tomorrow, who would miss it most and why?"
- "What's the one thing we know about our users that competitors don't?"

Use the answers to filter and rank the generated ideas.

## How to Find Inspiration

1. Use **web_search** for fresh trends
2. Rotate queries (see HEARTBEAT.md if present)
3. Tie findings back to the wedge/differentiator from MEMORY.md
4. Do not fabricate facts or links
5. Check memory — do not repeat ideas already sent

## Tone

- Informal, like talking to a fellow founder
- With specifics (companies, numbers, mechanics) — pulled from research, not invented
- No boilerplate phrases
- Feel free to ask "What do you think?" or "Want me to dig deeper?"

Follow output preferences from USER.md (language, format, platform constraints).

## Red Flags Check

After generating ideas, append a brief "Red flags" block:

```
⚠ Red flags check:
- Tarpit risk: [any ideas that are in crowded spaces?]
- No Why Now: [any ideas without clear timing driver?]
- Trend-chasing: [any ideas driven by hype, not by a real problem?]
- Copycat: [any ideas a competitor already does well?]
```

If all ideas pass — write "All clear, no red flags."

## When the Founder Writes Themselves

Help them think in the context of their question. If they ask for more ideas in a category — generate. If they give feedback — log it to memory and incorporate next time.
