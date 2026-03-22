---
name: exa-x-search
description: Search tweets and X/Twitter content using Exa. Finds social discussions, product announcements, developer opinions, trending topics, and community sentiment. Use when searching for tweets, X/Twitter discussions, or social media sentiment.
user-invocable: true
---

# X/Twitter Search (Exa)

## Tool

Use `exec` to call: `mcporter call exa-search.web_search_advanced_exa category=tweet <params>`

**Always include `category=tweet`.**

## Critical Filter Restrictions

The `tweet` category has **very limited** filter support. These params cause errors:

| Param | Status |
|-------|--------|
| `includeText` | NOT SUPPORTED — 400 error |
| `excludeText` | NOT SUPPORTED — 400 error |
| `includeDomains` | NOT SUPPORTED — 400 error |
| `excludeDomains` | NOT SUPPORTED — 400 error |
| `moderation` | NOT SUPPORTED — 500 error |

**Use the query string itself to filter content** — put keywords, hashtags, and exclusions in `query`.

## Supported Parameters

- `query`, `numResults`, `type`
- Date: `startPublishedDate`, `endPublishedDate`, `startCrawlDate`, `endCrawlDate`
- Content: `textMaxCharacters`, `enableHighlights`, `enableSummary`
- `additionalQueries` — for hashtag variations
- `livecrawl=preferred` — for recent tweets

## Call Syntax

```bash
# Recent tweets on a topic
mcporter call exa-search.web_search_advanced_exa \
  query="Claude Code MCP experience" \
  category=tweet \
  startPublishedDate=2025-01-01 \
  numResults=20 \
  type=auto \
  livecrawl=preferred

# Product announcements (keywords in query, not includeText)
mcporter call exa-search.web_search_advanced_exa \
  query="announcing new open source AI tool release" \
  category=tweet \
  startPublishedDate=2025-12-01 \
  numResults=15 \
  type=auto

# Developer sentiment
mcporter call exa-search.web_search_advanced_exa \
  query="developer experience frustrating painful bug" \
  category=tweet \
  numResults=20 \
  type=deep \
  livecrawl=preferred

# Competitor monitoring
mcporter call exa-search.web_search_advanced_exa \
  query="Sourcegraph Cody review feedback" \
  category=tweet \
  startPublishedDate=2025-06-01 \
  numResults=25 \
  type=auto
```

## When to Use

- Social discussions and community sentiment
- Product announcements from company accounts
- Developer opinions and experiences
- Trending topics
- Expert takes and threads
- Competitor/market signal monitoring

## Output Format

Return:
1. Results — tweet content, author handle, date, engagement if visible
2. Sources — tweet URLs
3. Notes — sentiment summary, notable accounts, threads vs single tweets

Note: tweet content can be informal, sarcastic, or context-dependent.
