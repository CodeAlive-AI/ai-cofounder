# Native MCP servers

OpenClaw is a **first-class MCP client** since 2026.4.x — `mcp.servers` in `openclaw.json` registers external MCP servers, and the agent calls their tools directly as `<serverName>__<toolName>`. **No CLI bridge** is required (`mcporter` was removed; all skills use native invocation now).

For CodeAlive Context Engine setup specifically, see `references/codealive-context-engine.md`.

## Three transports

| Transport | When to use | Required fields |
|-----------|-------------|-----------------|
| `stdio` | Local child process (Python/Node CLIs, `uvx ...`) | `command`, `args`, optional `env`, `cwd` / `workingDirectory` |
| `sse` (default if `transport` omitted) | Remote MCP server over Server-Sent Events | `url`, optional `headers`, `connectionTimeoutMs` |
| `streamable-http` | Remote MCP that requires HTTP streaming (e.g. `mcp.exa.ai`, `mcp.posthog.com`, `mcp.codealive.ai`) | `url` + `"transport": "streamable-http"`, optional `headers`, `connectionTimeoutMs` |

`headers` values support `${ENV_VAR}` interpolation. Only `http:` / `https:` URL schemes are accepted. URL credentials and header secrets are redacted from logs.

## Tool naming rules (enforced by OpenClaw)

- Form: `<serverName>__<toolName>` (double underscore separator)
- Server prefix: ≤30 chars; full tool name: ≤64 chars
- Non-`A-Za-z0-9_-` chars are replaced with `-`
- Colliding sanitised names get numeric suffixes
- Order is deterministic (sorted by safe name) — keeps prompt-cache tool blocks stable

## Config example

```json5
{
  "mcp": {
    "sessionIdleTtlMs": 600000,  // stdio servers reaped after 10 min idle (set 0 to disable)
    "servers": {
      "exa-search": {
        "url": "https://mcp.exa.ai/mcp?tools=web_search_advanced_exa&exaApiKey=${EXA_API_KEY}",
        "transport": "streamable-http"
      },
      "posthog": {
        "url": "https://mcp.posthog.com/mcp",
        "transport": "streamable-http",
        "headers": { "Authorization": "Bearer ${POSTHOG_TOKEN}" }
      },
      "codealive": {
        "url": "https://mcp.codealive.ai/api",
        "transport": "streamable-http",
        "headers": { "Authorization": "Bearer ${CODEALIVE_API_KEY}" }
      },
      "grafana": {
        "command": "uvx",
        "args": ["mcp-grafana"],
        "env": {
          "GRAFANA_URL": "https://example.grafana.net",
          "GRAFANA_SERVICE_ACCOUNT_TOKEN": "${GRAFANA_SA_TOKEN}"
        }
      }
    }
  }
}
```

## Stdio env safety filter (security boundary)

OpenClaw **rejects** interpreter-startup env keys before launching a stdio process — `NODE_OPTIONS`, `PYTHONSTARTUP`, `PYTHONPATH`, `PERL5OPT`, `RUBYOPT`, `SHELLOPTS`, `PS4`, and similar. Ordinary credential / proxy / `*_API_KEY` env vars pass through. If your stdio MCP genuinely needs one of the blocked keys, set it on the gateway host process (e.g. in `gateway.env`) instead.

## CLI

```bash
openclaw mcp list                            # list configured servers (sorted)
openclaw mcp show <name> [--json]            # show one server (or full mcp config without name)
openclaw mcp set <name> '<json-object>'      # add or replace one server
openclaw mcp unset <name>                    # remove (fails if not present)
```

**`set` does NOT validate reachability** — it only edits config. Test with a tool call after gateway restart. The `mcp set/unset` commands are pure config writers; runtime adapters decide which transports they actually support at call time.

## Adding a new server (full flow)

1. `sudo -u openclaw openclaw mcp set <name> '<json>'` — writes to `mcp.servers.<name>` in `openclaw.json`
2. **Stop monitor timer first** (pitfall #20): `sudo systemctl stop openclaw-monitor.timer`
3. `sudo systemctl restart openclaw.service` and wait 60 s (more if version just upgraded)
4. Verify: `curl -s http://127.0.0.1:18789/health` → expect `200`
5. `sudo systemctl start openclaw-monitor.timer`
6. Tools are **lazy-loaded** — connection happens on first call
7. (Optional) Create `workspace/skills/<name>/SKILL.md` so the agent knows when to call the tool, add routing entry to `AGENTS.md`, sync to server, send `/new` in Telegram

## `openclaw mcp serve` is a different feature

It makes OpenClaw act as an MCP *server* — exposes channel conversations to MCP **clients** like Claude Code or Codex. Not relevant for outbound MCP integration. Documented at https://docs.openclaw.ai/cli (search `mcp serve`).

## Common patterns

**Adding a key only known at runtime (e.g. user pastes a key into chat):**

```bash
# Write the key to gateway.env so `${MY_KEY}` interpolation works
echo "MY_KEY=sk-..." | sudo tee -a /home/openclaw/.openclaw/gateway.env >/dev/null
sudo chmod 600 /home/openclaw/.openclaw/gateway.env
sudo chown openclaw:openclaw /home/openclaw/.openclaw/gateway.env

# Then register the MCP server with header interpolation
sudo -u openclaw openclaw mcp set my-server '{
  "url": "https://api.example.com/mcp",
  "transport": "streamable-http",
  "headers": {"Authorization": "Bearer ${MY_KEY}"}
}'

# Restart via pitfall #20 sequence
```

**Verifying a server actually responds (before relying on it from chat):**

```bash
# stdio — connectivity is just process exit code
ssh openclaw@$IP "openclaw mcp show <name> --json"

# streamable-http — quick initialize call confirms auth + URL
curl -fsS -X POST -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H "Authorization: Bearer $KEY" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"probe","version":"0.1"}}}' \
  https://<host>/<path> | jq .
```

A `result.serverInfo` block in the response means auth + URL + transport are all correct.
