# CodeAlive Context Engine — code search inside your bot

The CodeAlive Context Engine is an MCP server that gives the bot **semantic + literal search over any Git repository indexed under your CodeAlive account**. Once connected, the bot answers questions like "where is `AuthService.login` called from?" or "show me how onboarding is implemented in our backend" without you opening the IDE.

**What you get:** five tools (plus two deprecated aliases) exposed as `codealive__<tool>` inside OpenClaw.

**Cost:** included in any CodeAlive plan that exposes an MCP API key. No separate per-call billing for the public hosted endpoint; the self-hosted Docker image is free.

## 1. Get a key

1. Sign up or log in at https://app.codealive.ai/
2. Open **MCP & API** in the sidebar
3. Click **+ Create API Key**
4. Copy the key immediately — it is shown once

Manage existing keys at https://app.codealive.ai/settings/api-keys.

## 2. Index at least one repository

The MCP API serves search over **repositories indexed under your CodeAlive account**. Before the bot can do anything useful, connect at least one Git provider (GitHub / GitLab / Bitbucket) at https://app.codealive.ai/ and pick the repos to index. First-time indexing takes minutes to hours depending on repo size.

`get_data_sources` (called below) lists what's available — if it returns empty after install, this is why.

## 3. Add the MCP server to OpenClaw

The canonical hosted endpoint is **`https://mcp.codealive.ai/api`** (no trailing slash — `/api/` is a 307 redirect to `/api`). Register it as a streamable-http MCP server, with the key in the `Authorization` header:

```bash
# Put the API key in gateway.env so ${CODEALIVE_API_KEY} interpolation works
echo "CODEALIVE_API_KEY=ca_live_..." | sudo tee -a /home/openclaw/.openclaw/gateway.env >/dev/null
sudo chmod 600 /home/openclaw/.openclaw/gateway.env
sudo chown openclaw:openclaw /home/openclaw/.openclaw/gateway.env

# Register the MCP server
sudo -u openclaw bash -lc '
export PATH="$HOME/.npm-global/bin:$PATH"
openclaw mcp set codealive '\''{
  "url": "https://mcp.codealive.ai/api",
  "transport": "streamable-http",
  "headers": { "Authorization": "Bearer ${CODEALIVE_API_KEY}" }
}'\''
'
```

Restart the gateway following the pitfall #20 sequence:

```bash
sudo systemctl stop openclaw-monitor.timer
sudo systemctl restart openclaw.service && sleep 60
curl -s http://127.0.0.1:18789/health    # expect 200
sudo systemctl start openclaw-monitor.timer
```

Then install the workflow skill so the agent knows when and how to use the tools, and send `/new` in Telegram to reload bootstrap:

```bash
# in the agent's workspace (e.g. ceo-os/ in the CEO AI OS layout)
npx skills add CodeAlive-AI/codealive-skills@codealive-context-engine
./sync-to-server.sh
```

**Self-hosted variant.** Swap the URL for your own host:

```bash
# Docker self-host (image port 8000, auth via Authorization header same as cloud)
openclaw mcp set codealive '{
  "url": "https://codealive.yourcompany.com/api",
  "transport": "streamable-http",
  "headers": { "Authorization": "Bearer ${CODEALIVE_API_KEY}" }
}'
```

Docker image: `ghcr.io/codealive-ai/codealive-mcp:main` — listens on port 8000 by default.

## 4. Tools available

OpenClaw exposes each tool as `codealive__<tool>`. The agent calls them automatically based on the workflow skill — you don't need to think about which one to invoke unless you're authoring a custom skill.

| Tool | What it does | When the agent picks it |
|------|--------------|-------------------------|
| `get_data_sources` | Lists indexed repositories and workspaces | First call when starting a new code question — discover what's available |
| `semantic_search` | Natural-language search by meaning | Default discovery: "how is X implemented?", "where do we handle Y?" |
| `grep_search` | Exact string or regex match | Known identifier, error string, config key |
| `fetch_artifacts` | Loads full source for hits from search | After search, when full code (not snippet) is needed and the repo isn't local |
| `get_artifact_relationships` | Call graph, inheritance, references for one artifact | Drill-down: all callers, subclasses, usages of a method/class |
| `chat` | Server-side LLM Q&A over a codebase (slow, costly) | **Only** when the user explicitly says "use chat" / "use codebase_consultant". Treat as opt-in. |
| `codebase_search` (deprecated alias) | Same as `semantic_search` | Back-compat — avoid in new prompts |
| `codebase_consultant` (deprecated alias) | Same as `chat` | Back-compat |

## 5. Example queries (try in Telegram)

After install, talk to the bot in your normal voice. The agent picks the right tool automatically.

- *"Покажи список индексированных репо в CodeAlive."* — triggers `get_data_sources`.
- *"Найди, как реализована аутентификация в codealive-app."* — triggers `semantic_search`.
- *"Где в openclaw используется идентификатор `HEARTBEAT_OK`?"* — triggers `grep_search`.
- *"Покажи всех вызывающих метод `AuthService.login()` в codealive-app."* — triggers `semantic_search` then `get_artifact_relationships`.
- *"Расскажи мне в двух абзацах, как устроена система памяти openclaw — используй chat."* — explicitly triggers `chat`.

## 6. Troubleshooting

- **`401 Unauthorized` / "API key not configured"**
  - Header format must be exactly `Authorization: Bearer <key>` — no extra quotes, no `Token` prefix.
  - Run `openclaw mcp show codealive` to confirm the header value made it into the config.
  - Check the key is still valid at https://app.codealive.ai/settings/api-keys (rotate if compromised).

- **`get_data_sources` returns empty**
  - No repositories indexed for this key's organisation yet.
  - Open https://app.codealive.ai/, connect a Git provider, and wait for the first index to finish (status visible in the data-sources UI).

- **Slow or timing out**
  - `chat` is the slow one by design — switch to `semantic_search` + `fetch_artifacts` for most needs.
  - If even `semantic_search` is slow, probe the endpoint directly to isolate gateway-side latency from server-side latency:
    ```bash
    curl -fsS -X POST -H 'Content-Type: application/json' \
      -H 'Accept: application/json, text/event-stream' \
      -H "Authorization: Bearer $CODEALIVE_API_KEY" \
      -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"probe","version":"0.1"}}}' \
      https://mcp.codealive.ai/api | jq .
    ```
    A `result.serverInfo` block means the server is healthy and auth is correct — the latency is somewhere else.

- **Tools missing after `mcp set`**
  - Gateway restart was skipped or the monitor timer raced it.
  - Re-run the stop-timer / restart / start-timer sequence above and send `/new` in Telegram so the agent re-loads the tool list on its next turn.

- **307 redirect loop / connection refused**
  - You're hitting `https://mcp.codealive.ai/api/` (with trailing slash). The server replies with a 307 to `/api` (no slash) — some HTTP clients don't follow `307` for `POST`. Use `https://mcp.codealive.ai/api` directly in the OpenClaw config.

## Related references in this skill

- `references/04-mcp.md` — native MCP support in OpenClaw, transports, tool naming rules
- `references/05-config-and-cli.md` — gateway restart sequence (pitfall #20), `openclaw.json` schema
- `references/06-troubleshooting.md` — broader OpenClaw debugging patterns
