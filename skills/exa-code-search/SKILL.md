---
name: exa-code-search
description: Code search using Exa. Finds real code snippets, API docs, and examples from GitHub, StackOverflow, and technical docs. Use when searching for code examples, API syntax, library documentation, or debugging help.
user-invocable: true
---

# Code Search (Exa)

## Tool

Use `exec` to call: `mcporter call exa-code.get_code_context_exa <params>`

## Critical Rules

- **Never run in main context.** Spawn subagents or run sequentially.
- **Always include the programming language** in the query to reduce noise.
  - Good: "Go generics", "Python asyncio", "React 19 hooks"
  - Bad: "generics", "async", "hooks"
- Include framework + version when relevant: "Next.js 14", "Playwright Python".
- Include exact identifiers (function names, error messages) when you have them.

## Token Tuning

| Need | tokensNum |
|------|-----------|
| Quick snippet | 1000-3000 |
| Most tasks | 5000 (default) |
| Complex integration | 10000-20000 |

## Call Syntax

```bash
# Find code example
mcporter call exa-code.get_code_context_exa \
  query="Python asyncio aiohttp client example" \
  tokensNum=5000

# API usage
mcporter call exa-code.get_code_context_exa \
  query="OpenAI Responses API streaming Python" \
  tokensNum=8000

# Debugging
mcporter call exa-code.get_code_context_exa \
  query="Next.js 14 App Router useSearchParams error boundary" \
  tokensNum=5000

# Complex integration
mcporter call exa-code.get_code_context_exa \
  query="Playwright Python page.wait_for_selector timeout handling" \
  tokensNum=15000
```

## Output Format

Return:
1. Best minimal working snippet(s) — copy/paste ready
2. Notes — version constraints, gotchas
3. Sources — URLs if present

Deduplicate similar results; keep only the best representative snippet per approach.
