---
name: web-browser
description: Browse the web using agent-browser CLI with Lightpanda engine. Read pages, extract content, interact with elements.
user-invocable: true
---

# Web Browser (agent-browser + Lightpanda)

Use `agent-browser` CLI via `exec` for all web browsing tasks.
Default engine: Lightpanda (fast, low-RAM). Falls back to Chrome if needed.

## Quick Reference

### Open a page
```bash
agent-browser open https://example.com
```

### Get page content (text snapshot)
```bash
# Full content with text (for reading pages)
agent-browser snapshot

# Interactive elements only (for finding buttons/links/inputs to click)
agent-browser snapshot -i

# Structure only, no text (for understanding page layout)
agent-browser snapshot -c

# Scoped to a CSS selector
agent-browser snapshot -s "#main-content"
```

### Interact with elements

Snapshots return refs like `@e1`, `@e2`. Use them to interact:

```bash
agent-browser click @e3          # Click a link/button
agent-browser fill @e5 "text"    # Fill an input field
agent-browser type @e5 "text"    # Type without clearing
agent-browser select @e7 "value" # Select dropdown option
agent-browser press @e5 Enter    # Press key
agent-browser hover @e2          # Hover
agent-browser scroll @e1         # Scroll to element
```

### Navigation
```bash
agent-browser back               # Go back
agent-browser forward            # Go forward
agent-browser open <new-url>     # Navigate to new URL
```

## Typical Workflow

1. `exec("agent-browser open https://example.com")` - open page
2. `exec("agent-browser snapshot")` - read page content
3. If need to interact: `exec("agent-browser snapshot -i")` - get interactive elements with refs
4. `exec("agent-browser click @e3")` - click element
5. `exec("agent-browser snapshot")` - check result

## Engine Selection

```bash
# Lightpanda (default, fast, low RAM, no screenshots)
agent-browser --engine lightpanda open https://example.com

# Chrome (fallback for complex sites or screenshots)
agent-browser --engine chrome open https://example.com
agent-browser screenshot              # Only with Chrome engine
agent-browser screenshot --annotate   # Annotated screenshot
```

Use Chrome engine only when Lightpanda fails on a complex site or you need a screenshot.

## Notes

- Lightpanda: no screenshots, no visual rendering, but 10x faster and 10x less RAM
- Refs (`@e1`) persist across exec calls — daemon stays alive between commands
- `snapshot` — full text for reading; `snapshot -i` — refs for clicking; `snapshot -c` — layout only
- Google and some sites block headless browsers from cloud IPs (empty page) — use web_search instead
- If a site crashes with Lightpanda, retry with `--engine chrome`
