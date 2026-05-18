# Configuration & CLI reference

## openclaw.json — production schema (trimmed)

Location: `~/.openclaw/openclaw.json` (JSON5).

Backups:
- `openclaw.json.bak` — CLI auto-saved before each overwrite
- `openclaw.json.last-good` — gateway-saved after successful load

```json5
{
  gateway: {
    port: 18789,
    bind: "loopback",        // loopback | external | tailnet
    mode: "local",
    auth: { mode: "token", token: "..." },  // none | token | password | trust
    tailscale: { mode: "off", resetOnExit: false }
  },
  channels: {
    telegram: {
      enabled: true,
      botToken: "...",
      dmPolicy: "pairing",   // pairing | allowlist | open | disabled
      groups: { "*": { requireMention: true } },
      streaming: { mode: "off" },         // anti-spam (see CHANGELOG 2026-04-12)
      execApprovals: { enabled: true, approvers: [<userId>], target: "dm" }
    }
  },
  tools: {
    exec: { security: "full", ask: "off" }  // headless server: pitfall #19
  },
  mcp: {
    sessionIdleTtlMs: 600000,
    servers: { /* see references/04-mcp.md */ }
  },
  agents: {
    defaults: {
      workspace: "/home/openclaw/.openclaw/workspace",
      bootstrapMaxChars: 15000,           // ⚠ nested under agents.defaults, NOT gateway
      compaction: { mode: "safeguard" },
      model: {
        primary: "openai-codex/gpt-5.5",
        fallbacks: ["google-oai/gemini-3.1-pro-preview"]
      },
      models: {                           // ⚠ pitfall #21 — JSON key is `models`, NOT `configuredModels`
        "openai-codex/gpt-5.5": { alias: "gpt-5.5" },
        "digitalocean/anthropic-claude-opus-4.7": { alias: "do-opus" },
        "google-oai/gemini-3.1-pro-preview": { alias: "gemini-pro" }
      },
      heartbeat: {
        every: "60m",
        activeHours: { start: "10:00", end: "22:00", timezone: "Europe/Berlin" },
        target: "telegram",
        directPolicy: "allow"
      },
      maxConcurrent: 4,
      subagents: { maxConcurrent: 8 }
    }
  }
}
```

## Critical schema notes

- `agents.defaults.bootstrapMaxChars` (NOT `gateway.bootstrapMaxChars`) — bootstrap budget. Default 15000.
- `agents.defaults.models` — dict keyed by `<provider>/<model-id>`. Pitfall #21: writing `models.configuredModels` instead crashes the gateway with `Config invalid: models: Unrecognized key: "configuredModels"`.
- `agents.defaults.heartbeat` shape (since 2026.4.x): `every` (duration string), `activeHours`, `target`, `directPolicy`. Older `intervalMinutes` is silently ignored — migrate via `openclaw doctor --fix`.
- `tools.exec.security` and `tools.exec.ask` live **at top level** (not under `agents.defaults`).

## Key CLI commands

| Command | Description |
|---------|-------------|
| `openclaw --version` | Print installed version + git sha |
| `openclaw status` | Overview of gateway and providers |
| `openclaw doctor` | Validate config and fix issues (`--fix` to auto-repair) |
| `openclaw health` | Fetch `/health` JSON from running gateway |
| `openclaw gateway status` / `restart` / `install` | Service lifecycle |
| `openclaw gateway --verbose` / `--force` | Debug logs / force restart |
| `openclaw dashboard` | Open Control UI in browser |
| `openclaw channels status` / `login` | Channel state / WhatsApp QR |
| `openclaw devices ...` | Device pairing + token management |
| `openclaw config get <path>` / `set <path> <value>` / `unset <path>` | Configuration helpers |
| `openclaw config validate` / `file` | Validate JSON5 / show config path |
| `openclaw configure` | Interactive setup wizard |
| `openclaw models status` (or `--status-json` / `--status-plain`) | Model + OAuth profile state |
| `openclaw models set <provider/model>` | Set default model (writes `agents.defaults.model.primary`) |
| `openclaw models aliases` / `fallbacks` / `image-fallbacks` / `scan` | Manage model aliases, fallback list, image-model fallbacks, OpenRouter scan |
| `openclaw models auth login --provider <name>` | OAuth login (⚠ pitfall #21 — backup config first; pitfall #23 — prune orphan profiles) |
| `openclaw mcp list` / `show` / `set` / `unset` | Native MCP server registry (see `references/04-mcp.md`) |
| `openclaw mcp serve` | Run OpenClaw as an MCP server (bridge for Claude Code / Codex clients) |
| `openclaw approvals get` / `allowlist add\|remove` / `set` | Manage exec approvals |
| `openclaw exec-policy ...` | Show / sync requested exec policy with host approvals |
| `openclaw logs --follow` | Live gateway logs via RPC |
| `openclaw cron list` / `add` / `rm` / `edit` / `run` / `runs` / `disable` / `enable` / `show` / `status` | Cron CLI (full reference in `references/03-cron-heartbeat.md`) |
| `openclaw memory search "query"` / `index --force` / `status` | Memory search, reindex, health |
| `openclaw memory promote` / `rem-backfill` / `rem-harness` / `promote-explain` | Dreaming & promotion controls |
| `openclaw message send/read/...` | Send / inspect channel messages |
| `openclaw directory ...` | Lookup contact + group IDs (self/peers/groups) |
| `openclaw hooks ...` | Manage internal agent hooks |
| `openclaw plugins install/list/inspect/marketplace ...` | Plugin / bundle install (Codex / Claude / Cursor formats) |
| `openclaw backup ...` | Local state backup + verify |
| `openclaw docs "<query>"` | Search live OpenClaw docs |
| `openclaw security audit` / `audit --deep` | Security audit |

## Installation paths

```bash
# Recommended
curl -fsSL https://openclaw.ai/install.sh | bash

# NPM (one-shot)
npx -y openclaw

# npm/pnpm global
npm install -g openclaw@latest
```

**Update sequence (avoid the built-in `openclaw update` — pitfall #3, loops on small VMs):**

```bash
sudo -u openclaw bash -c 'export PATH="$HOME/.npm-global/bin:$PATH" && npm install -g openclaw@latest'
sudo systemctl stop openclaw-monitor.timer            # pitfall #20
sudo systemctl restart openclaw.service && sleep 180  # ≥180 s after major version bumps
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:18789/health  # expect 200
sudo systemctl start openclaw-monitor.timer
```

## Default ports

- **Gateway:** `127.0.0.1:18789`
- **Canvas Host:** `127.0.0.1:18793`

## Key paths

| Path | Description |
|------|-------------|
| `~/.openclaw/openclaw.json` | Main config file (JSON5) |
| `~/.openclaw/workspace/` | Default agent workspace |
| `~/.openclaw/workspace/skills/` | Per-agent skills |
| `~/.openclaw/skills/` | Shared skills (all agents) |
| `~/.openclaw/agents/<agentId>/` | Agent-specific data |
| `~/.openclaw/agents/<agentId>/sessions/` | Session transcripts |
| `~/.openclaw/credentials/` | OAuth and credentials |
| `~/.openclaw/identity/` | Device identity and keys |
| `~/.openclaw/cron/jobs.json` | Cron job definitions |
| `/tmp/openclaw/` | Logs |

## Auth modes

| Mode | Description |
|------|-------------|
| `none` | No auth (safe **only if gateway is on loopback**) |
| `token` | Pre-shared token (challenge-response) |
| `password` | Interactive password |
| `trust` | Tailscale identity |

## DM policies

| Policy | Description |
|--------|-------------|
| `pairing` | Require explicit approval for new DMs (default for new installs) |
| `allowlist` | Only `allowFrom` senders |
| `open` | Accept all (gateway warns) |
| `disabled` | No DMs |

## Exec approvals (shell-command permissions)

Exec approvals control which shell commands the agent can run via the `exec` tool. **Separate** from tool policy, which controls tool availability.

**Security modes** (`tools.exec.security` in `openclaw.json`):

| Mode | Behaviour |
|------|-----------|
| `full` | All commands run without approval. Skips `exec-approvals.json`. |
| `allowlist` | Only allowlisted binaries run freely. Others → ask or deny. |
| `deny` | All exec denied. |

**Ask modes** (`tools.exec.ask`): `on-miss` (prompt for approval) or `off` (no prompt, fallback to deny).

**Key files:**

- `~/.openclaw/exec-approvals.json` — allowlist entries + per-agent overrides
- `tools.exec.*` in `openclaw.json` — security mode, ask mode, safeBins

**CRITICAL: allowlist matches RESOLVED binary paths only.** Symlinks don't match. Always use `realpath /usr/local/bin/<tool>` to find the actual path before adding to the allowlist.

**Managing the allowlist:**

```bash
openclaw approvals allowlist add --agent "*" "/resolved/path/to/binary"
openclaw approvals allowlist remove "/resolved/path"
openclaw approvals get
openclaw config set tools.exec.security allowlist
openclaw config set tools.exec.ask on-miss
```

**Telegram approval forwarding** (for non-allowlisted commands):

```json5
{
  channels: {
    telegram: {
      execApprovals: {
        enabled: true,
        approvers: [123456789],  // Telegram user IDs
        target: "dm"             // "dm" | "channel" | "both"
      }
    }
  }
}
```

The user approves in chat: `/approve <id> allow-once` | `allow-always` | `deny`.

**Session-level override:** `/exec security=full ask=off host=gateway` — resets on `/new`.

Plugin tools (composio, browser plugin) are governed by tool policy (`tools.allow` / `tools.deny`), which has no approval mode — only allow or deny.

## Security recommendations

1. **Gateway on loopback only** — never expose port 18789 to the internet
2. **Use pairing mode** — require approval for new DMs
3. **Require mentions in groups** — `requireMention: true`
4. **Run security audits** — `openclaw security audit --deep`
5. **Proper permissions** — 700 for directories, 600 for config files
6. **Consider Tailscale Serve** — for secure remote access when needed

## Systemd health units (reference deployment pattern)

Two timers run side-by-side on a hosted VM. **Read pitfall #20 before touching either.**

| Unit | Cadence | Job |
|------|---------|-----|
| `openclaw.service` | Always | Gateway daemon. `WorkingDirectory=/home/openclaw` (matters for pitfall #22 — bundled `composio` plugin re-execs itself). |
| `openclaw-monitor.timer` + `.service` | `OnBootSec=120`, `OnUnitActiveSec=120` | `/usr/local/bin/openclaw-monitor.sh` curls `127.0.0.1:18789/health` and `systemctl restart openclaw.service` if HTTP ≠ 200. Interval **bumped from 60 s → 120 s on 2026-04-20** so a slow startup doesn't get killed. **Stop this timer before any planned restart.** |
| `openclaw-watchdog.timer` + `.service` | `OnBootSec=5min`, `OnUnitActiveSec=30min`, `Persistent=true` | `/usr/local/bin/openclaw-watchdog.sh` greps `journalctl -u openclaw` for outbound errors (Telegram silently dies after ~12h, pitfall #2) and restarts the gateway when matched. |

**Planned-restart sequence (memorise this):**

```bash
sudo systemctl stop openclaw-monitor.timer
sudo systemctl restart openclaw.service
sleep 180   # composio plugin install can take 1m30s after major version bump
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:18789/health   # expect 200
sudo systemctl start openclaw-monitor.timer
```

If `/health` is still failing after 180 s on a fresh upgrade, tail `journalctl -u openclaw -f` and watch for `[gateway] ready` instead of blind-sleeping longer.
