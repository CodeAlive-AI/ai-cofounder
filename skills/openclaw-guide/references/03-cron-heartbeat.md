# Cron & heartbeat — scheduled work for the agent

Two complementary mechanisms for time-based actions: **cron** for precise schedules, **heartbeat** for periodic checks.

| Aspect | Cron | Heartbeat |
|--------|------|-----------|
| **When** | Precise time (`0 10 * * *`) | Every N minutes (default 30; tunable) |
| **Session** | `main`, `isolated`, or named `session:cron-<name>` | Main session |
| **Use case** | Reports, reminders, scheduled research | Monitoring, batch checks, mailbox polling |
| **Suppression** | No — every fire produces an agent turn | `HEARTBEAT_OK` if nothing important — silent run |

## Cron CLI (verified against 2026.4.24, unchanged in 2026.5.x)

Subcommands: `add` (alias `create`), `disable`, `edit`, `enable`, `list`, `rm` (alias `remove`), `run`, `runs`, `show`, `status`. **There is no `cron delete` and no `cron reset`** — use `rm` and recreate.

### Key options for `cron add`

| Flag | Purpose |
|------|---------|
| `--name <name>` | Human-readable identifier. **Replaces** the non-existent `--id` flag. IDs are auto-generated UUIDs. |
| `--cron <expr>` | 5-field or 6-field cron expression |
| `--tz <iana>` | Timezone (e.g. `Europe/Berlin`); required for offset-less datetimes |
| `--at <when>` | One-shot: ISO timestamp or `+duration` |
| `--every <duration>` | Recurring: `10m`, `1h` |
| `--message "<text>"` | Agent prompt payload — **must be a flag, NEVER a positional argument** (pitfall #14) |
| `--system-event "<text>"` | System-event payload routed to main session |
| `--session main\|isolated` | Session target |
| `--session-key agent:<a>:<s>` | Specific session key — used for `session:cron-<name>` (workaround for pitfall #1) |
| `--model <provider/model>` | Model override |
| `--thinking off\|minimal\|low\|medium\|high\|xhigh` | Thinking level |
| `--timeout-seconds <n>` | **Agent job timeout. ALWAYS set explicitly** — default is 600s (pitfall #18). Use 300 for simple, 600 for complex skills. |
| `--announce` | Fallback-deliver final agent text to a chat (replaces deprecated `--deliver`) |
| `--no-deliver` / `--best-effort-deliver` | Disable / soften delivery |
| `--channel telegram` + `--to <chatId>` | Delivery destination |
| `--light-context` | Lightweight bootstrap mode for agent jobs |
| `--exact` | Disable cron staggering (set `--stagger 0`) |
| `--stagger <duration>` | Cron stagger window |
| `--wake now\|next-heartbeat` | Wake mode |
| `--disabled` | Create job disabled |
| `--json` | JSON output |

### Production example

```bash
sudo -u openclaw openclaw cron add \
  --name morning-briefing \
  --cron "30 9 * * *" \
  --tz Europe/Berlin \
  --session-key agent:main:cron-morning-briefing \
  --timeout-seconds 600 \
  --announce \
  --channel telegram \
  --to <YOUR_CHAT_ID> \
  --message "Run morning brief skill."
```

## Critical cron gotchas

1. **Isolated sessions can't deliver to Telegram** (pitfall #1) — outbound adapters don't propagate. Use `--session main` or named `session:cron-<name>` via `--session-key`.
2. **Always set `--timeout-seconds`** (pitfall #18) — silent default is 600s; set 300 for simple skills, longer for heavy ones.
3. **`--message` is a flag, not positional.** `--id` does not exist.
4. **`cron rm <id>`** to remove (no `delete`); list IDs with `openclaw cron list`.
5. **Heredoc through `gcloud ssh`** is fragile (pitfall #15). Prefer single quotes + full binary path; for multi-line payloads, write a script file then exec.
6. **Pipe / grep inside `--command`** mangles quoting (pitfall #16). Use `--command='sudo -u openclaw /full/path/openclaw cron list --json'`.

## Heartbeat

The heartbeat schedule fires on a recurring interval. The agent reads `HEARTBEAT.md`, runs every check in one turn, and either acts on findings or responds `HEARTBEAT_OK` to suppress chatter.

**Config (under `agents.defaults.heartbeat`, since 2026.4.x):**

```json5
heartbeat: {
  every: "60m",
  activeHours: { start: "10:00", end: "22:00", timezone: "Europe/Berlin" },
  target: "telegram",
  directPolicy: "allow"
}
```

The older `intervalMinutes` field has been replaced — using it now is a silent no-op. Migrate via `openclaw doctor --fix`.

**Typical heartbeat duties** (define them in `HEARTBEAT.md`):

- Check pending Telegram messages and pair requests
- Scan a watched mailbox or RSS feed
- Compare today's metrics vs yesterday's
- Re-rank the inbox or to-do queue

Keep heartbeat checks fast — sub-30-second runs. Long-running work belongs in cron with `--timeout-seconds` set explicitly.
