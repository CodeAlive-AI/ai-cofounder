# TOOLS.md

## PostHog Analytics (optional)

If you have a PostHog MCP server configured, call it directly as `posthog__<tool-name>`.

```
# Example
posthog__event-definitions-list q="signup"
```

Project ID for the default workspace: 12345.
Details in skill `posthog-analytics`.

## Exa Research (optional)

6 exa-* skills for deep research, each backed by an MCP server (`exa-search`, `exa-deep`, `exa-code`).

```
# Example
exa-search__web_search_advanced_exa query="..." category=company numResults=10
```

Details in each exa-* skill.

## Web Browser (optional)

CLI for browsing via `agent-browser`: `exec("agent-browser open <url>")`, then `exec("agent-browser snapshot")`.
Details in skill `web-browser`.

## Web Search

Use built-in `web_search` for:
- Industry trends
- Competitor news
- Fresh data for hypotheses

## File Operations

- `memory/hypotheses.json` — structured hypothesis tracker
- `memory/heartbeat-state.json` — heartbeat state
- `memory/YYYY-MM-DD.md` — daily logs
- `memory/weekly/YYYY-WW.md` — weekly reviews
- `MEMORY.md` — long-term memory
