# TOOLS.md

## PostHog Analytics (via mcporter)

Direct access to PostHog. Project ID: 12345 (main app).
Use `exec` to call: `mcporter call posthog.<tool-name> <params>`
Details in skill `posthog-analytics`.

## Exa Research (via mcporter)

6 exa-* skills for deep research. Call: `mcporter call exa-<server>.<tool> query="..." ...`
Details in each exa-* skill.

## Web Browser (agent-browser)

CLI for browsing: `exec("agent-browser open <url>")`, then `exec("agent-browser snapshot")`.
Details in skill `web-browser`.

## Web Search

Use built-in web_search for:
- Industry trends
- Competitor news
- Fresh data for hypotheses

## File Operations

- `memory/hypotheses.json` — structured hypothesis tracker
- `memory/heartbeat-state.json` — heartbeat state
- `memory/YYYY-MM-DD.md` — daily logs
- `memory/weekly/YYYY-WW.md` — weekly reviews
- `MEMORY.md` — long-term memory
