# TOOLS.md

## Analytics (optional)

If you have a PostHog MCP server configured, the agent calls it directly:

```
# Example: PostHog
posthog__<tool-name> <params>
```

Details in the `posthog-analytics` skill.

## Research (optional)

If you have Exa MCP servers configured:

```
# Example: Company research
exa-search__web_search_advanced_exa query="..." category=company numResults=20
```

6 exa-* skills available. Details in each skill.

## Monitoring (optional)

If you have a Grafana MCP server configured:

```
# Example: query logs
grafana__query_loki_logs query="..." datasourceUid="..."
```

Details in the `grafana-monitoring` skill.

## Web Browser (optional)

If you have agent-browser installed:

```
agent-browser open <url>
agent-browser snapshot
```

Details in the `web-browser` skill.

## Web Search

Use built-in web_search for:
- Industry trends
- Competitor news
- Fresh data for hypotheses and ideas

## File Operations

- `memory/hypotheses.json` — structured hypothesis tracker
- `memory/heartbeat-state.json` — heartbeat state
- `memory/YYYY-MM-DD.md` — daily logs
- `memory/weekly/YYYY-WW.md` — weekly reviews
- `MEMORY.md` — long-term memory
