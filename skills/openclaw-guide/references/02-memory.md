# Memory — files, backends, dreaming, sync safety

OpenClaw memory is a **hybrid system**: plain Markdown files are the primary interface; SQLite (FTS5 + vector) is the internal search index. The agent reads and writes Markdown; OpenClaw indexes automatically. **The model only "remembers" what gets saved to disk — there is no hidden state.**

## Three memory files (per agent workspace)

| File | Owner | Bootstrap? | Purpose |
|------|-------|------------|---------|
| `MEMORY.md` | **Human** (curated) | Yes (every DM session) | Long-term durable facts, preferences, decisions. Budget-constrained. |
| `memory/YYYY-MM-DD.md` | **Agent** (auto-flush) | No (today + yesterday auto-loaded) | Daily running notes and observations |
| `DREAMS.md` (optional) | **Agent + dreaming sweep** | No (review surface) | Dream Diary entries + grounded historical backfill summaries |

Operational extras:

- `memory/*.json` — state files, **full rewrites** (not safe for text-based merge/diff)
- `memory/.dreams/short-term-recall.json` — machine-facing ranking surface for dreaming
- `sessions/*.jsonl` — gateway-owned raw transcripts (don't edit)

## Memory tools the agent calls

- `memory_search` — hybrid search (BM25 + vector); auto-detects embedding provider from API keys (OpenAI / Gemini / Voyage / Mistral)
- `memory_get` — read a specific file or line range

Both are provided by the active memory plugin (default: `memory-core`).

## Memory backends (configurable)

| Backend | Role | Notes |
|---------|------|-------|
| **Builtin** (default) | SQLite, in-process | Keyword + vector + hybrid search out of the box |
| **QMD** | Local sidecar | Reranking, query expansion, can index dirs outside workspace |
| **Honcho** | Plugin | AI-native cross-session memory with user modeling and multi-agent awareness |
| **memory-wiki** (optional layer) | Plugin alongside active memory | Compiles durable knowledge into a provenance-rich wiki vault (claims, evidence, contradiction tracking, dashboards). Adds tools `wiki_search`, `wiki_get`, `wiki_apply`, `wiki_lint`. |

## Dreaming (opt-in background consolidation)

Dreaming scores short-term recalls and promotes only qualified items into `MEMORY.md`. **Default: disabled.** Enable when the bot has run long enough that daily notes outweigh manual curation.

- **Scheduled** — when enabled, `memory-core` auto-manages one recurring cron job for the full sweep
- **Thresholded** — promotion requires score, recall frequency, and query-diversity gates
- **Reviewable** — phase summaries and Dream Diary entries are written to `DREAMS.md`
- **Live dreaming** ranks the short-term store under `memory/.dreams/`
- **Grounded backfill** — `openclaw memory rem-backfill --path ./memory --stage-short-term` replays older daily notes and stages durable candidates into the same short-term store. **Does NOT directly write to `MEMORY.md`.** Rollback with `--rollback` / `--rollback-short-term`.
- **Preview without writes** — `openclaw memory rem-harness`
- **Manual promotion** — `openclaw memory promote` ranks short-term recalls and (optionally) appends top entries to `MEMORY.md`

## Auto-flush (always on)

Before [compaction](https://docs.openclaw.ai/concepts/compaction), OpenClaw runs a silent turn that prompts the agent to save important context into memory files. Prevents context loss when the conversation summary kicks in.

## Key behaviours and gotchas

- **MEMORY.md is human-curated by design.** Don't have the agent write to it directly — that's what daily notes and dreaming promotion are for.
- **JSON state files are full rewrites.** Not safe for text-based merge or diff. Two writers = lost data.
- **No file locking** on workspace files. Sync scripts can corrupt files if the agent is writing simultaneously.
- **Embedding provider auto-detected** from available API keys — no manual wiring needed if any OpenAI / Gemini / Voyage / Mistral key is configured.

## Sync safety rules

When pushing the workspace from a local checkout to the VM:

1. **Push only human-owned bootstrap + skills:** SOUL.md, AGENTS.md, IDENTITY.md, TOOLS.md, USER.md, MEMORY.md, HEARTBEAT.md, skills/
2. **Never push `memory/` or `DREAMS.md`** — agent-owned territory. Use `--exclude='./memory' --exclude='DREAMS.md'` in tar/rsync. The CEO AI OS `./sync-to-server.sh` already does this.
3. **After push:** send `/new` in the chat to force a bootstrap reload.

## Memory CLI

```bash
openclaw memory status                                          # index status, provider, dreaming state
openclaw memory search "query"                                  # CLI search
openclaw memory index --force                                   # rebuild index from .md files
openclaw memory promote                                         # promote short-term recalls → MEMORY.md
openclaw memory rem-backfill --path ./memory --stage-short-term # replay historical notes
openclaw memory rem-harness                                     # preview promotions without writing
```

Index path: `~/.openclaw/memory/<agentId>.sqlite` (FTS5 + vector cache, auto-rebuilt on demand).
