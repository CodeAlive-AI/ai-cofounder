# Architecture — agent, sessions, skills

OpenClaw runs a single embedded agent runtime per gateway. Skills, channels, sub-agents, and bootstrap files all hang off it.

## Agent runtime

The agent's working directory is the **workspace** — `~/.openclaw/workspace/` by default. Everything the agent reads, writes, or executes happens here.

### Bootstrap files (injected on session start)

| File | Purpose |
|------|---------|
| `SOUL.md` | Persona, boundaries, communication tone |
| `USER.md` | User profile information |
| `MEMORY.md` | Human-curated context & state. **Main sessions only.** The agent should NOT write to this file directly. |
| `AGENTS.md` | Operating instructions. **Injected in all sessions, including sub-agents.** |
| `TOOLS.md` | Tool usage guidance. Injected in all sessions. |
| `IDENTITY.md` | Agent name, vibe, emoji |
| `HEARTBEAT.md` | Periodic task checklist |
| `BOOTSTRAP.md` | First-run initialization (deleted after) |

Blank files are skipped. Large files are truncated with a **70% head + 20% tail** strategy — the middle is dropped. Keep individual bootstrap files small enough to stay under `agents.defaults.bootstrapMaxChars` (default 15000) so nothing important falls into the dropped middle (pitfall #7).

### Prompt modes

| Mode | Bootstrap files loaded |
|---|---|
| `full` (default) | All of the above |
| `minimal` (sub-agents) | AGENTS.md + TOOLS.md only |

### Session storage

`~/.openclaw/agents/<agentId>/sessions/<SessionId>.jsonl` — raw JSONL transcripts owned by the gateway. Don't edit by hand.

## Messages & sessions

**Message flow:**
1. Channel adapter receives inbound message
2. Routing decides which agent/session it belongs to
3. Queue (if a run is already active)
4. Agent execution with streaming
5. Outbound formatting respects per-channel limits

**Key behaviours:**

- **Deduplication** cache prevents duplicate processing of retries
- **Debounce** batches rapid messages (2000 ms default)
- Media/attachments flush immediately (no debounce)
- **Queue modes:** `interrupt`, `steer`, `followup`, `collect`
- **Session pruning:** cache-ttl mode removes old tool results to reduce context size
- **Compaction:** summarises older turns to stay under the model context window

**Sessions belong to the gateway, not to clients.** DMs use the main session key; groups get separate keys. Restarting a client doesn't drop the session.

## In-chat commands

Sent as a normal message to the bot. The agent recognises them as control commands and acts immediately.

| Command | Effect |
|---|---|
| `/new` | Start a new session (re-reads all bootstrap files — use after editing SOUL.md / USER.md / MEMORY.md) |
| `/reset` | Reset the current session (drops conversation, keeps bootstrap) |
| `/help` | Show command help |
| `/status` | Gateway status, current model, token usage |
| `/reasoning on\|off\|stream` | Control reasoning visibility |
| `/verbose on\|off` | Toggle verbose output |
| `/think N` | Set thinking level for this session |
| `/context` | Show current context stats |
| `/compact` | Force summarisation of older turns |
| `/model <name>` | Switch model for this session (per-session, doesn't persist) |
| `/models` | List available models |

After editing bootstrap files on disk, **always send `/new`** — without it the agent keeps using the previously loaded copy.

## Skills

Skills are folders with `SKILL.md` (YAML frontmatter + instructions). Loaded **on demand** when the description matches the user's request, not as part of the bootstrap budget.

**Priority:** `<workspace>/skills` → `~/.openclaw/skills` → bundled skills.

**Frontmatter schema:**

```yaml
---
name: skill-name
description: What this skill does (triggers invocation when this matches the user's intent)
user-invocable: true        # default true
model: gpt-4o               # optional override
thinking: true|moderate|deep  # optional
temperature: 0.7            # optional
---
```

## Sub-agents (background workers)

Sub-agents are isolated background sessions spawned via the `sessions_spawn` tool for parallel or long-running tasks.

**Key facts:**

- Run in **minimal prompt mode** — AGENTS.md + TOOLS.md only (no SOUL.md, MEMORY.md, USER.md)
- Results announced back to the parent session via the gateway
- Default `maxSpawnDepth = 1` (no nesting)
- Can override the model per sub-agent (cost optimisation: send cheap tasks to a cheaper model)
- Pass any critical context in the `task` text — a sub-agent has no MEMORY.md

**Practical use cases:**

- Parallel data gathering — N sub-agents querying different sources simultaneously
- Multi-step workflows — e.g. morning briefing with 3 parallel sub-agents (metrics / news / issues) → aggregate
- Heavy analysis without polluting main-session context
- Delegating cheap tasks to cheaper models

**Limitations:** no persona (SOUL.md), no strategic context (MEMORY.md), best-effort delivery, VM RAM constrains concurrency.

**Config:**

- `agents.defaults.tools.subagents.runTimeoutSeconds`
- `agents.defaults.tools.subagents.maxSpawnDepth`
