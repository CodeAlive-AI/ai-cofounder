# Adding External Tools

The CEO OS works without external tools, but adding analytics and research capabilities makes it significantly more powerful.

## Architecture

Most modern agents (OpenClaw 2026.4+, Claude Code, Claude Cowork, Cursor, Codex, OpenCode, etc.) support **MCP natively** — the agent calls MCP tools directly as function calls, no CLI bridge needed.

```
Agent -> mcp_call(server.tool, {param: value}) -> MCP Server -> Response
```

Older agents without native MCP support can still use these skills via [mcporter](https://github.com/steipete/mcporter), a CLI bridge — but most users won't need that.

## Configure MCP servers

The exact place to add MCP servers depends on your agent. For OpenClaw:

```bash
# Add a server (stdio or remote-http)
openclaw mcp set <name> '{"url": "https://...", "transport": "streamable-http", "headers": {...}}'

# List configured servers
openclaw mcp list

# Restart gateway to pick up changes
sudo systemctl restart openclaw.service
```

For Claude Code: edit `~/.claude/settings.json` or use `claude mcp add`. For Cursor / OpenCode / Codex: see their docs.

After adding a server, send `/new` in chat to refresh the session.

## Adding PostHog

### 1. Get your PostHog API key

Go to PostHog > Project Settings > Personal API Keys > Create key.

### 2. Add to your MCP config (OpenClaw example)

```bash
openclaw mcp set posthog '{
  "url": "https://mcp.posthog.com/mcp",
  "transport": "streamable-http",
  "headers": {
    "Authorization": "Bearer YOUR_POSTHOG_PERSONAL_API_KEY"
  }
}'
```

### 3. Test

In chat, ask the agent to call `posthog__event-definitions-list`. You should see your project's events.

### 4. Configure the skill

Edit `workspace/skills/posthog-analytics/SKILL.md`:
- Set your project IDs
- Add your event catalog
- Update query recipes for your events

### 5. Update TOOLS.md

Add a PostHog section to `workspace/TOOLS.md`.

## Adding Exa Search

### 1. Get Exa API key

Sign up at [exa.ai](https://exa.ai) and get an API key.

### 2. Add three MCP entries (one per Exa tool subset)

```bash
openclaw mcp set exa-search '{
  "url": "https://mcp.exa.ai/mcp?tools=web_search_advanced_exa",
  "transport": "streamable-http",
  "headers": {"x-api-key": "YOUR_EXA_API_KEY"}
}'

openclaw mcp set exa-deep '{
  "url": "https://mcp.exa.ai/mcp?tools=deep_search_exa",
  "transport": "streamable-http",
  "headers": {"x-api-key": "YOUR_EXA_API_KEY"}
}'

openclaw mcp set exa-code '{
  "url": "https://mcp.exa.ai/mcp?tools=get_code_context_exa",
  "transport": "streamable-http",
  "headers": {"x-api-key": "YOUR_EXA_API_KEY"}
}'
```

### 3. Test

In chat, ask the agent to run `exa-search__web_search_advanced_exa query="AI startups" category=company numResults=5`.

## Adding Grafana Cloud (optional)

```bash
openclaw mcp set grafana '{
  "command": "uvx",
  "args": ["mcp-grafana"],
  "env": {
    "GRAFANA_URL": "https://yourstack.grafana.net",
    "GRAFANA_API_KEY": "YOUR_GRAFANA_SERVICE_ACCOUNT_TOKEN"
  }
}'
```

## Adding agent-browser

```bash
# Install
npm install -g agent-browser

# Create symlink so the agent's exec tool can find it
sudo ln -sf $(which agent-browser) /usr/local/bin/agent-browser

# Optional: Install Lightpanda for faster, lighter browsing
# See https://github.com/nichochar/agent-browser for details
```

## Important Notes

- **MCP transport types:** `stdio` (`command`+`args`+`env`), HTTP (`url`+`headers`), or `streamable-http` (`url`+`headers` with `"transport": "streamable-http"`).
- **Tool naming convention:** `<serverName>__<toolName>` (double underscore separator).
- **PATH for stdio servers:** stdio MCP servers don't read `.bashrc`. Either use the binary's full path in `command`, or set `PATH` in the server's `env`.
- **Budget:** Adding tools doesn't affect the bootstrap context budget. Tool skills load on-demand.
- **After adding tools:** Update `workspace/TOOLS.md`, then send `/new` in chat to reload the session.
