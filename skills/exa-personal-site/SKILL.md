---
name: exa-personal-site
description: Search personal websites and blogs using Exa. Finds individual perspectives, portfolios, tutorials, and personal blogs. Use when searching for personal sites, blog posts, practitioner deep-dives, or portfolio websites.
user-invocable: true
---

# Personal Site Search (Exa)

## Tool

Call the native MCP tool `exa-search__web_search_advanced_exa` directly with `category: "personal site"`.

**Always include `category: "personal site"`.**

## Full Filter Support

Unlike `company` or `tweet` categories, `personal site` supports ALL parameters:

- Domain: `includeDomains`, `excludeDomains`
- Date: `startPublishedDate`, `endPublishedDate`, `startCrawlDate`, `endCrawlDate`
- Text: `includeText`, `excludeText` (single-item only — multi-item causes 400 error)
- Content: `enableSummary`, `enableHighlights`, `subpages`, `subpageTarget`

## Call Examples

Tool: `exa-search__web_search_advanced_exa`

```
# Technical blog posts
{ query: "building production LLM applications lessons learned", category: "personal site",
  numResults: 15, type: "deep", enableSummary: true }

# Recent posts only
{ query: "Rust async runtime comparison", category: "personal site",
  startPublishedDate: "2025-01-01", numResults: 10, type: "auto" }

# Exclude aggregators, find independent blogs
{ query: "startup founder lessons", category: "personal site",
  excludeDomains: ["medium.com","substack.com"], numResults: 15, type: "auto" }

# Portfolio sites with subpages
{ query: "AI engineer portfolio projects", category: "personal site",
  numResults: 10, subpages: 2, subpageTarget: "projects" }
```

## When to Use

- Individual expert opinions and experiences
- Personal blog posts on technical topics
- Portfolio websites
- Independent analysis (not corporate content)
- Deep-dives and tutorials from practitioners

## Output Format

Return:
1. Results — title, author/site name, date, key insights
2. Sources — URLs
3. Notes — author expertise, potential biases, depth of coverage
