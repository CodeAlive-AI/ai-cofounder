# Adding External Tools

The CEO OS works without external tools, but adding analytics and research capabilities makes it significantly more powerful.

## Architecture

OpenClaw doesn't support MCP natively. External tools are accessed via [mcporter](https://github.com/steipete/mcporter) — a CLI bridge that lets the agent call MCP servers through the `exec` tool.

```
Agent -> exec("mcporter call server.tool param=value") -> MCP Server -> Response
```

## Setup mcporter

```bash
# Install
npm install -g mcporter

# Create symlink (required — exec tool doesn't read .bashrc)
sudo ln -sf $(which mcporter) /usr/local/bin/mcporter

# Verify
mcporter --version
```

## Adding PostHog

### 1. Get your PostHog API key

Go to PostHog > Project Settings > Personal API Keys > Create key.

### 2. Add to mcporter config

Edit `~/.mcporter/mcporter.json`:

```json
{
  "mcpServers": {
    "posthog": {
      "url": "https://mcp.posthog.com/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_POSTHOG_PERSONAL_API_KEY"
      }
    }
  }
}
```

### 3. Test

```bash
mcporter list posthog
mcporter call posthog.event-definitions-list
```

### 4. Configure the skill

Edit `workspace/skills/posthog-analytics/SKILL.md`:
- Set your project IDs
- Add your event catalog
- Update query recipes for your events

### 5. Update TOOLS.md

Add PostHog section to `workspace/TOOLS.md`.

## Adding Exa Search

### 1. Get Exa API key

Sign up at [exa.ai](https://exa.ai) and get an API key.

### 2. Add to mcporter config

```json
{
  "mcpServers": {
    "exa-search": {
      "url": "https://mcp.exa.ai/mcp?tools=web_search_advanced_exa",
      "headers": {
        "x-api-key": "YOUR_EXA_API_KEY"
      }
    },
    "exa-deep": {
      "url": "https://mcp.exa.ai/mcp?tools=deep_search_exa",
      "headers": {
        "x-api-key": "YOUR_EXA_API_KEY"
      }
    },
    "exa-code": {
      "url": "https://mcp.exa.ai/mcp?tools=get_code_context_exa",
      "headers": {
        "x-api-key": "YOUR_EXA_API_KEY"
      }
    }
  }
}
```

### 3. Test

```bash
mcporter list exa-search
mcporter call exa-search.web_search_advanced_exa query="AI startups" category=company numResults=5
```

## Adding agent-browser

```bash
# Install
npm install -g agent-browser

# Create symlink
sudo ln -sf $(which agent-browser) /usr/local/bin/agent-browser

# Optional: Install Lightpanda for faster, lighter browsing
# See https://github.com/nichochar/agent-browser for details
```

## Important Notes

- **PATH:** `exec` tool doesn't read `.bashrc`. Always create symlinks in `/usr/local/bin/` for globally installed CLIs.
- **Permissions:** If running OpenClaw as a dedicated user, make sure that user can access the symlinks.
- **Budget:** Adding tools doesn't affect the bootstrap context budget. Tool skills load on-demand.
- **After adding tools:** Update `TOOLS.md`, then send `/new` in chat to reload.
