---
name: exa-lead-gen
description: Generate enriched lead lists using Exa deep search. Finds companies matching an ICP, enriches with signals/news/scores, and outputs CSV. Use when generating leads, building prospect lists, finding companies to sell to, doing outbound research, or ICP-based company discovery.
user-invocable: true
---

# Lead Generation (Exa Deep Search)

## Tool

Use `exec` to call: `mcporter call exa-deep.deep_search_exa <params>`

## Architecture

**Main agent orchestrates; subagents run the searches.** This keeps context lean.

```
Main Agent (orchestrator)
├── Step 1: ICP research (1 deep call)
├── Step 2: Generate micro-verticals (LLM reasoning)
├── Step 3: Design outputSchema
├── Step 4: Batch subagents (5 micro-verticals each, parallel)
│     Each subagent: runs 5 deep calls → writes JSON → reports count
├── Step 5: Python CSV compiler (reads JSON, dedupes, sorts)
└── Step 6: Summary
```

## Required Params on Every deep_search_exa Call

```
structuredOutput=true
numResults=50
highlightMaxCharacters=1
type=deep
```

**numResults and systemPrompt must align** — set numResults=50 and ask for "exactly 50 companies" in systemPrompt.

## outputSchema Constraints

- Max **10 properties total** across all nesting levels
- Array items: flat objects with primitive fields only (string, integer, boolean, array of strings)
- Every string field **must have a word limit** in its description
- Root must be `"type": "object"`

## Call Syntax

```bash
# Step 1: ICP Research
mcporter call exa-deep.deep_search_exa \
  objective="About {company_name}, {company_name} customers" \
  systemPrompt="Research the company and return ICP, sub-verticals, and useful enrichments" \
  structuredOutput=true \
  numResults=10 \
  highlightMaxCharacters=1 \
  type=deep

# Step 4: Lead gen call (inside subagent)
mcporter call exa-deep.deep_search_exa \
  objective="B2B sales intelligence platforms using web scraping and contact data enrichment" \
  systemPrompt="List exactly 50 companies. Score each 1-10 on ICP fit. Return structured enriched data." \
  structuredOutput=true \
  numResults=50 \
  highlightMaxCharacters=1 \
  type=deep
```

## Micro-Vertical Budget

Target `ceil(requested_leads / 35)` micro-verticals (overshoot for dedupe losses).

## Step 1: ICP Research Schema

```json
{
  "type": "object",
  "properties": {
    "company_description": {"type": "string", "description": "What they do in 2 sentences"},
    "product_description": {"type": "string", "description": "What they sell and to whom, 2 sentences"},
    "existing_customers": {"type": "array", "items": {"type": "string"}},
    "icp_description": {"type": "string", "description": "ICP in 12 words or less"},
    "sub_verticals": {"type": "array", "items": {"type": "string"}},
    "demographic_signals": {"type": "array", "items": {"type": "string"}},
    "useful_enrichments": {"type": "array", "items": {"type": "string"}}
  }
}
```

## Standard Lead Schema (customize per use case)

```json
{
  "type": "object",
  "properties": {
    "companies": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "company_name": {"type": "string", "description": "in 5 words or less"},
          "website": {"type": "string", "description": "homepage URL"},
          "product_description": {"type": "string", "description": "in 12 words or less"},
          "icp_fit_score": {"type": "integer"},
          "icp_fit_reasoning": {"type": "string", "description": "one-liner in 20 words or less"},
          "industry_vertical": {"type": "string", "description": "in 3 words or less"},
          "funding_stage": {"type": "string", "description": "Bootstrap/Seed/Series A/B/C+/Public/Unknown"},
          "headquarters_location": {"type": "string", "description": "City, Country in 4 words or less"},
          "recent_signals": {"type": "array", "items": {"type": "string", "description": "under 12 words each"}}
        }
      }
    }
  }
}
```

## Output Format

After CSV is generated, report:
- Total leads, duplicates removed
- ICP score distribution (8-10 / 5-7 / 1-4)
- Number of Exa calls made
- Output filename

## Performance

- Each `deep_search_exa` call: 4-12s
- Yield: ~35-48 companies per call (avg ~42)
- For 500+ leads: confirm with user before starting
- Launch batch subagents in waves of ~6 to respect QPS limits
