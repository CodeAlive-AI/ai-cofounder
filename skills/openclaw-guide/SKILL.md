---
name: openclaw-guide
description: |
  Reference and consulting skill for OpenClaw — a messaging gateway that connects
  AI agents to multiple communication platforms (Telegram, Discord, Slack, WhatsApp,
  iMessage, and more). Use when working with OpenClaw configuration, channels,
  Gateway setup, skills, cron jobs, MCP servers, memory, OAuth, or troubleshooting.
  Also use when the user asks how to implement a use case on their OpenClaw bot
  (daily morning brief, research workflows, competitive radar, decision playbook),
  how to add a new channel, or how to connect the CodeAlive context engine.
  Triggers on requests like "configure openclaw", "add Discord to my bot",
  "set up morning brief", "gateway not starting", "connect CodeAlive search",
  "OAuth re-auth", or any close paraphrase. Companion of install-openclaw-to-yc —
  install both together.
license: MIT
metadata:
  version: 0.2.0
---

# OpenClaw Guide

OpenClaw is a messaging gateway that connects AI agents to 24+ communication platforms. This skill is the reference for everything **after** the bot is installed — channels, use cases, memory, cron, MCP, OAuth, troubleshooting.

**Current production version assumed:** 2026.5.x (latest 2026.4.x is also fully covered).
**Official docs:** https://docs.openclaw.ai/ · **Source:** https://github.com/openclaw/openclaw

## Setup (install OpenClaw first)

This skill is consultation-only. If the user doesn't have an OpenClaw bot yet, install both skills together and run the companion wizard:

```bash
npx skills add CodeAlive-AI/ceo-ai-os@install-openclaw-to-yc -g
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-guide -g
```

Then tell the agent: *"install OpenClaw on Yandex Cloud Kazakhstan"*. The `install-openclaw-to-yc` skill takes over and uses this one for any post-install consultation.

For other hosts (local Mac, GCP, AWS, bare metal) the OpenClaw upstream documentation at https://docs.openclaw.ai/start/getting-started is the canonical guide — no CEO AI OS wizard exists for them yet.

## How to read this skill

The full content is split across nine reference files. Read **only the one that matches the user's current question** — bringing all of them into context wastes the budget.

| If the user asks about… | Read |
|---|---|
| Agent runtime, bootstrap files, sessions, message flow, chat commands, skills | `references/01-architecture.md` |
| MEMORY.md, daily notes, dreaming, memory backends, embedding providers, sync safety | `references/02-memory.md` |
| Cron jobs (add / list / rm), heartbeat, scheduled tasks, timezones, delivery flags | `references/03-cron-heartbeat.md` |
| MCP servers (Exa, PostHog, Grafana, …), `openclaw mcp set`, transports, tool naming | `references/04-mcp.md` |
| `openclaw.json` schema, key CLI commands, paths, auth modes, exec approvals, systemd units | `references/05-config-and-cli.md` |
| OAuth re-auth (`models auth login` bugs, orphan profiles), server-side debugging, channel caveats | `references/06-troubleshooting.md` |
| **Use cases** — morning brief, research workflows, competitive radar, decision playbook, email handler, meeting prep | `references/use-cases.md` |
| **Channels** — Telegram details, adding Discord / Slack / WhatsApp / iMessage | `references/channels.md` |
| **CodeAlive search inside the bot** — `semantic_search`, `grep_search`, `chat` over indexed repos | `references/codealive-context-engine.md` |

## Critical pitfalls (always cross-check before infrastructure changes)

These are the recurring footguns. Read this table before any planned restart, OAuth re-auth, cron edit, or schema change.

| # | Title | When it bites |
|---|-------|---------------|
| 1 | Isolated cron sessions can't deliver to Telegram | Use `--session main` or `session:cron-<name>`, not `isolated` |
| 2 | Telegram adapter silently dies after ~12h | Watchdog timer restarts gateway on outbound errors |
| 6 | Gateway auth handshake timeout on small VMs | `gateway.auth.mode: none` is safe on loopback |
| 7 | Bootstrap file truncation drops the middle | Keep individual files compact; truncation = 70% head + 20% tail |
| 14 | `cron add` syntax — `--message` (not positional), `--name` (no `--id`), `cron rm` (no `delete`) | All cron CLI work |
| 18 | Cron jobs without explicit `--timeout-seconds` use 600s default | Always set explicitly |
| 19 | Exec approval blocked when no Telegram approver | `tools.exec.security: full` + `ask: off` on headless server |
| 20 | `openclaw-monitor.timer` kills gateway during slow startup | Stop timer → restart → wait `/health=200` → start timer |
| 21 | `models auth login` clobbers other providers + schema gotcha | Backup config first; correct path is `agents.defaults.models`, NOT `models.configuredModels` |
| 22 | `composio` CLI fails with EACCES posix_spawn from `gcloud ssh` | Run `cd /tmp` first or invoke as root |
| 23 | OAuth re-auth leaves orphan profiles | Decode `access` JWT, compare `chatgpt_account_id`, prune duplicates |

Full numbered list with workarounds lives in the CEO AI OS workspace repo at `OPENCLAW_PITFALLS.md`. When a new pitfall surfaces, add it there — single source of truth.

## Upstream documentation index (quick links)

These are direct URLs into docs.openclaw.ai for occasions when this skill's references don't cover a feature. Prefer this skill's references first — they're tuned for the workshop / personal CEO bot context.

### Getting started

| Topic | URL |
|---|---|
| Getting Started | https://docs.openclaw.ai/start/getting-started |
| Onboarding Wizard | https://docs.openclaw.ai/start/wizard |
| Documentation Hub | https://docs.openclaw.ai/start/hubs |
| DM/Node Pairing | https://docs.openclaw.ai/start/pairing |

### Gateway & configuration

| Topic | URL |
|---|---|
| Gateway Runbook | https://docs.openclaw.ai/gateway |
| Configuration | https://docs.openclaw.ai/gateway/configuration |
| Authentication | https://docs.openclaw.ai/gateway/authentication |
| Sandboxing | https://docs.openclaw.ai/gateway/sandboxing |
| Security | https://docs.openclaw.ai/gateway/security |
| Troubleshooting | https://docs.openclaw.ai/gateway/troubleshooting |

### Channels

| Topic | URL |
|---|---|
| Telegram | https://docs.openclaw.ai/channels/telegram |
| WhatsApp | https://docs.openclaw.ai/channels/whatsapp |
| Discord | https://docs.openclaw.ai/channels/discord |
| Slack | https://docs.openclaw.ai/channels/slack |
| iMessage | https://docs.openclaw.ai/channels/imessage |
| Matrix | https://docs.openclaw.ai/channels/matrix |
| Mattermost | https://docs.openclaw.ai/channels/mattermost |
| Groups | https://docs.openclaw.ai/channels/groups |

### Core concepts

| Topic | URL |
|---|---|
| Agent | https://docs.openclaw.ai/concepts/agent |
| Agent Workspace | https://docs.openclaw.ai/concepts/agent-workspace |
| Memory | https://docs.openclaw.ai/concepts/memory |
| Sessions | https://docs.openclaw.ai/concepts/session |
| Compaction | https://docs.openclaw.ai/concepts/compaction |
| Models | https://docs.openclaw.ai/concepts/models |

### Tools, automation, install

| Topic | URL |
|---|---|
| Skills | https://docs.openclaw.ai/tools/skills |
| Plugin System | https://docs.openclaw.ai/tools/plugin |
| Cron Jobs | https://docs.openclaw.ai/automation/cron-jobs |
| Hooks | https://docs.openclaw.ai/automation/hooks |
| Webhooks | https://docs.openclaw.ai/automation/webhook |
| Docker install | https://docs.openclaw.ai/install/docker |
| CLI Reference | https://docs.openclaw.ai/cli |

## Companion skill (required at install time)

`install-openclaw-to-yc` (sibling) — the wizard that creates the VM, installs OpenClaw, and seeds the workspace. Install it alongside this skill:

```bash
npx skills add CodeAlive-AI/ceo-ai-os@install-openclaw-to-yc -g
```

The two skills cross-reference: `install-openclaw-to-yc` runs the bootstrap and hands off to this guide for everything after. This guide assumes the bot is already up and walks the user through configuration, channels, use cases, and operations.
