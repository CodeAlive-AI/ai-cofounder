---
name: competitor-research
description: "Research competitors: products, pricing, team, funding, strategy, and positioning. Use when asked to analyze a competitor, compare products, or understand competitive landscape. For general company info without comparison angle, see company-intel."
user-invocable: true
---

## [YOUR_PRODUCT] Context

Before helping, check `MEMORY.md` for: current competitors list, wedge, positioning.
Output in Russian (product names and company names in original).
For chat platforms: actionable summary with "so what" for [YOUR_PRODUCT].

# Competitor Research

Gather competitive intelligence: products, pricing, team, funding, strategy.

## Workflow

### Step 1: Company Overview (Brand.dev)

```bash
orth run brand-dev /v1/brand/retrieve -q domain=COMPETITOR_DOMAIN
```

### Step 2: Find Similar Companies (Exa)

Discover competitors you might not know about:

```bash
orth run exa /findSimilar -d '{"url": "https://COMPETITOR_DOMAIN", "numResults": 10}'
```

### Step 3: Products & Pricing (ScrapeGraph)

```bash
orth run scrapegraph /v1/smartscraper -d '{"website_url": "https://COMPETITOR_DOMAIN/pricing", "user_prompt": "Extract all pricing tiers, features per tier, enterprise options, and free tier limits"}'
```

### Step 4: Leadership & Key Hires (Fiber)

```bash
orth run fiber /v1/people-search -d '{"searchParams": {"company_names": ["COMPETITOR"], "job_titles": ["CEO", "CTO", "VP Product", "VP Engineering", "VP Sales"]}}'
```

### Step 5: Recent Activity (Exa)

```bash
orth run exa /search -d '{"query": "COMPETITOR_NAME announcement launch funding 2026", "numResults": 15, "contents": {"text": true}}'
```

## Output Format

```
**[Competitor]** vs [YOUR_PRODUCT]

Overview: [what they do, positioning]
Stage: [funding, team size]
Products: [list with pricing]
Strengths: [what they do well]
Weaknesses: [gaps, complaints]
Recent moves: [launches, hires, funding]

Implications for [YOUR_PRODUCT]:
- [actionable takeaway 1]
- [actionable takeaway 2]
```

Always end with "Implications for [YOUR_PRODUCT]" — raw data without analysis is not useful.

## Tips

- Check their job postings (Step 4) — hiring reveals strategy
- Scrape their changelog/blog for recent product moves
- Use Exa findSimilar to discover competitors you didn't know about
- Compare pricing tiers directly with [YOUR_PRODUCT] pricing

## Related Skills

- **signal-scanner** — detects competitor mentions as buying signals
- **company-intel** — general company report (not competition-focused)
- **competitive-analysis** — strategic framework for competitive positioning
- **positioning-messaging** — refine positioning based on competitive findings
- **social-listening** — monitor what people say about competitors
- **exa-company-research** — web research on companies via Exa
