---
name: company-intel
description: "Full company intelligence report: overview, team, funding, products, news. Use when asked to research a company or understand a potential customer/partner/competitor. For pre-meeting briefings with pipeline context, see meeting-prep. For head-to-head competitor comparison, see competitor-research."
user-invocable: true
---

## [YOUR_PRODUCT] Context

Before helping, check `MEMORY.md` for current ICP, competitors, and target accounts.
Output in Russian (company names, titles, and product names in original).
For chat platforms: structured summary, no raw JSON.

# Company Intelligence Report

Generate a full intelligence report on any company using multiple Orthogonal APIs.

## Workflow

Run steps sequentially. Skip a step if not needed or if previous steps gave enough data.

### Step 1: Company Overview (Brand.dev)

```bash
orth run brand-dev /v1/brand/retrieve -q domain=COMPANY_DOMAIN
```

Returns: name, description, logo, colors, social links, industry.

### Step 2: Leadership Team (Fiber)

```bash
orth run fiber /v1/people-search -d '{"searchParams": {"company_names": ["COMPANY_NAME"], "job_titles": ["CEO", "CTO", "CFO", "COO", "VP"]}}'
```

Returns: names, titles, LinkedIn URLs.

### Step 3: Company Data & Size (Fiber)

```bash
orth run fiber /v1/company-search -d '{"searchParams": {"company_names": ["COMPANY_NAME"]}}'
```

Returns: employee count, location, industry, funding.

### Step 4: Products & Pricing (ScrapeGraph)

Only if user needs product/pricing details:

```bash
orth run scrapegraph /v1/smartscraper -d '{"website_url": "https://COMPANY_DOMAIN/pricing", "user_prompt": "Extract all products, pricing tiers, and key features"}'
```

## Output Format

Present as structured report:

```
**[Company Name]** — [one-line description]

Industry: [industry]
Employees: [count]
HQ: [location]
Funding: [total raised, last round]

Leadership:
- [Name] — [Title]
- [Name] — [Title]

Products: [brief summary]
Pricing: [tiers if available]

Key links: [website], [LinkedIn], [Twitter]
```

## Tips

- Start with Step 1 (cheap, fast) — often gives enough for a quick overview
- Add Steps 2-4 only for deep research or meeting prep
- For competitors specifically, use `competitor-research` skill instead
- Always use main domain (stripe.com not dashboard.stripe.com)

## Related Skills

- **meeting-prep** — pre-meeting briefings combining company + person + pipeline context
- **pipeline-manager** — store company research as pipeline prospect data
- **signal-scanner** — automated company discovery via buying signals
- **competitor-research** — head-to-head comparison with products/strategy analysis
- **lead-enrichment** — enrich a specific person at the company
- **person-lookup** — deep lookup on a single person
- **exa-company-research** — web-based company research via Exa
