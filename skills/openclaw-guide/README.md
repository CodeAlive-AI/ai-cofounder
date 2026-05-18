# openclaw-guide

Reference and consulting skill for **OpenClaw** — a messaging gateway that connects AI agents to Telegram, WhatsApp, Discord, Slack, iMessage, Matrix, and 20+ other platforms. Use this skill when configuring OpenClaw, debugging the gateway, wiring channels or models, adding skills, designing **use cases** (morning brief, research workflows, competitive radar, decision playbook), or working through any of the well-known pitfalls (memory limits, monitor-timer order, OAuth orphan profiles, native MCP setup, …).

This skill is the **required companion** for [`install-openclaw-to-yc`](../install-openclaw-to-yc/). The install wizard refuses to start without `openclaw-guide` loaded — the agent uses it to diagnose problems from documented behaviour instead of guessing, and to consult the user on use cases / channels / integrations after the bot is up.

## Install (always install both skills together)

```bash
npx skills add CodeAlive-AI/ceo-ai-os@install-openclaw-to-yc -g
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-guide -g
```

Restart your code agent (Claude Code / Claude Cowork / Codex / Cursor / …) to pick them up.

### Manual — drop the folder into your agent's skills directory

If `npx` is not available, copy both folders into the right place. Directory names MUST stay `openclaw-guide` and `install-openclaw-to-yc`.

| Agent | Path (global, all projects) | Path (project-scoped) |
|---|---|---|
| Claude Code | `~/.claude/skills/openclaw-guide/` | `.claude/skills/openclaw-guide/` |
| Claude Cowork | `~/.claude/skills/openclaw-guide/` | `.claude/skills/openclaw-guide/` |
| Codex | `~/.codex/skills/openclaw-guide/` | `.agents/skills/openclaw-guide/` |
| Cursor | `~/.cursor/skills/openclaw-guide/` | `.cursor/skills/openclaw-guide/` |
| Gemini CLI | `~/.gemini/skills/openclaw-guide/` | `.agents/skills/openclaw-guide/` |
| OpenCode | `~/.config/opencode/skills/openclaw-guide/` | `.opencode/skills/openclaw-guide/` |
| OpenClaw | `~/.openclaw/skills/openclaw-guide/` | `skills/openclaw-guide/` |
| Other | see [skills.sh registry](https://skills.sh) | — |

Example (Claude Code, from this repo's checkout):

```bash
mkdir -p ~/.claude/skills/
cp -r skills/openclaw-guide       ~/.claude/skills/
cp -r skills/install-openclaw-to-yc ~/.claude/skills/   # companion
```

Restart the agent — discovery is automatic.

## When the agent loads this skill

The skill auto-triggers on any of:

- "configure openclaw", "openclaw not starting", "openclaw config"
- "setup Telegram bot for openclaw", "add Discord / Slack / WhatsApp / iMessage to my bot"
- "add openclaw skill", "openclaw memory", "REM / Dreams"
- "openclaw cron", "heartbeat", "openclaw doctor"
- "openclaw OAuth", "models auth login", "openai-codex re-auth"
- "openclaw MCP", "native MCP server", "mcp.servers", "add CodeAlive search to my bot"
- "set up morning brief", "competitive radar", "research workflow", "decision playbook"
- "gateway memory limits", "openclaw-monitor.timer", any of the named pitfalls

And on close paraphrases.

## What it covers

The SKILL.md is a tight index; the substance lives in nine reference files loaded only when the matching question comes up:

| File | Topic |
|---|---|
| `references/01-architecture.md` | Agent runtime, bootstrap files, sessions, message flow, chat commands, skills, sub-agents |
| `references/02-memory.md` | MEMORY.md, daily notes, dreaming, memory backends, embedding providers, sync safety |
| `references/03-cron-heartbeat.md` | Cron CLI (verified flags), heartbeat config, scheduled-job examples, gotchas |
| `references/04-mcp.md` | Native MCP server registry, transports, tool naming rules, add-a-server walkthrough |
| `references/05-config-and-cli.md` | `openclaw.json` schema, key CLI commands, paths, auth modes, exec approvals, systemd units |
| `references/06-troubleshooting.md` | OAuth re-auth bugs (config clobber + orphan profiles), server-side debugging, channel caveats |
| `references/use-cases.md` | **Use cases** — morning brief, research, competitive radar, decision playbook, email handler, meeting prep |
| `references/channels.md` | **Channels** — Telegram details, adding Discord / Slack / WhatsApp / iMessage |
| `references/codealive-context-engine.md` | **CodeAlive search inside the bot** — `semantic_search`, `grep_search`, `chat` over indexed repos |

The SKILL.md itself also includes:

- **Critical pitfalls cross-reference** — 11 high-impact pitfalls with one-line fix recipes (monitor.timer kill loop, orphan auth profiles, isolated cron + Telegram, allowlist resolved paths, native MCP setup, …)
- **Upstream documentation index** — direct URLs into docs.openclaw.ai for anything this skill doesn't cover

## Folder layout

```
openclaw-guide/
├── SKILL.md                                  # Entry-point index + critical pitfalls + upstream URLs (~150 lines)
├── SOURCE.md                                 # Origin tracking
├── README.md                                 # This file
└── references/
    ├── 01-architecture.md                    # Agent, sessions, skills, sub-agents
    ├── 02-memory.md                          # Memory files, backends, dreaming, sync safety
    ├── 03-cron-heartbeat.md                  # Cron CLI + heartbeat
    ├── 04-mcp.md                             # Native MCP server registry
    ├── 05-config-and-cli.md                  # openclaw.json schema + key CLI + systemd
    ├── 06-troubleshooting.md                 # OAuth bugs, debugging, channel caveats
    ├── use-cases.md                          # Morning brief, research, competitive, decision, email, meeting prep
    ├── channels.md                           # Telegram, Discord, Slack, WhatsApp, iMessage
    └── codealive-context-engine.md           # CodeAlive MCP integration
```

## License

MIT — see [LICENSE](../../LICENSE) at the repo root.
