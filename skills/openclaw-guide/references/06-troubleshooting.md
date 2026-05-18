# Troubleshooting — OAuth, debugging, channel caveats

Recurring problems and their workarounds. Cross-reference numbered pitfalls in `OPENCLAW_PITFALLS.md` (single source of truth in the CEO AI OS workspace).

## OAuth re-auth — two upstream bugs

`openclaw models auth login --provider <name>` is the standard re-auth path. Two known upstream issues, both reproduce on 2026.4.x and 2026.5.x.

### Bug 1 — `auth login` clobbers `agents.defaults.models` (pitfall #21)

After OAuth login the CLI prints `Config overwrite: ~/.openclaw/openclaw.json (... changedPaths=14)`. It serialises a *partial* provider tree and overwrites the whole `agents.defaults.models` dict — entries for all **other** providers disappear. `agents.defaults.model.primary` and `.fallbacks` are NOT updated, so they may end up pointing to model IDs that no longer exist → silent fallback or runtime errors.

Upstream: [openclaw/openclaw#69414](https://github.com/openclaw/openclaw/issues/69414) (closed but still reproduces) and [#55797](https://github.com/openclaw/openclaw/issues/55797).

**Schema gotcha (will crash gateway):** the CLI output calls this list "Configured models" but the JSON key is **`agents.defaults.models`**, NOT `models.configuredModels`. Writing the wrong path causes a crash loop with `Config invalid: models: Unrecognized key: "configuredModels"`.

**Always backup before login:**

```bash
sudo cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak-pre-auth-$(date +%Y%m%d-%H%M)
```

**Recovery if hit:**

1. Diff against `~/.openclaw/openclaw.json.bak` (CLI auto-creates this right before overwrite)
2. Re-add missing entries to `agents.defaults.models` — dict keyed by `<provider>/<model-id>`, value `{}` or `{"alias": "..."}`
3. Restore `models.providers.<provider>.models` array if it was trimmed
4. Make sure `agents.defaults.model.primary` and `.fallbacks` point to IDs that exist in `agents.defaults.models`
5. Validate: `python3 -c 'import json; json.load(open("/home/openclaw/.openclaw/openclaw.json"))'` then `openclaw doctor` (no "Unrecognized key" errors)
6. Restart gateway via the monitor-timer pause flow (see `references/05-config-and-cli.md` → systemd health units)

Fallback: `~/.openclaw/openclaw.json.last-good` is written by gateway after a successful config load — safe to copy back.

### Bug 2 — `auth login` leaves an orphan profile every rotation (pitfall #23)

Re-auth does **not** replace the existing entry in `auth-profiles.json`. It writes a new profile keyed by the OAuth email (`openai-codex:<email>`) and leaves the prior one (typically `openai-codex:default`) untouched. The old key keeps its now-stale JWT and rots, surfacing later as an `expired expires in 0m` entry that looks like a real failure.

**Symptom:** `openclaw models status` shows two profiles for the same provider — one `expired`, one `ok`. If the JWTs share an account_id, the broken one is a leftover orphan, **not** the active profile dying. Re-authing again will only create a third orphan.

**Prune at re-auth time, not next expiry:**

1. Snapshot keys before login: `jq '.profiles | keys' ~/.openclaw/agents/<agentId>/agent/auth-profiles.json`
2. Run re-auth (interactive TTY, paste callback URL)
3. Decode each profile's `access` JWT and compare the provider account claim — `chatgpt_account_id` for OpenAI. **Same account_id across two profiles → older one is an orphan, safe to delete.** Different account_ids → legitimate multi-account, leave alone.
4. Edit `auth-profiles.json`:
   ```bash
   python3 -c 'import json,sys,pathlib
   p = pathlib.Path(sys.argv[1])
   d = json.loads(p.read_text())
   d["profiles"].pop(sys.argv[2])
   p.write_text(json.dumps(d, indent=2))' <file> <orphan-key>
   ```
   Back up the file first.
5. Restart gateway via the monitor-timer pause flow.

Full playbook with JWT decode snippet: `OPENCLAW_BEST_PRACTICES.md` § 13 in the CEO AI OS workspace.

## Server-side debugging quirks (hosted-VM specific)

These are workspace-specific quirks worth knowing before you start poking at the VM.

- **`composio` CLI from `gcloud ssh` hits EACCES** (pitfall #22). The Bun-bundled binary re-execs itself for analytics; `posix_spawn` requires the cwd to be readable by the target uid. `gcloud ssh` lands you in `/home/sa_<id>/`, which `openclaw` can't read. Workaround: `cd /tmp && /home/openclaw/.composio/composio <subcommand>`. Gateway-side `exec` is unaffected because `openclaw.service` runs with `WorkingDirectory=/home/openclaw`.
- **File ownership after `gcloud ssh`** (pitfall #5). The gcloud SSH user is NOT `openclaw`. Files created via SSH are owned by the SSH user. Always write through `/tmp/` then `sudo cp` + `sudo chown openclaw:openclaw`.
- **PATH in `exec` tool** (pitfall #4). The agent's `exec` tool does NOT source `.bashrc`. Globally installed npm CLIs (`agent-browser`, `orth`, ...) need a symlink: `sudo ln -sf ~/.npm-global/bin/<tool> /usr/local/bin/<tool>`.
- **Heredoc through `gcloud ssh --command`** is fragile — nested quoting collides (pitfall #15). For multi-line content, write a script to `/tmp/` first and execute it remotely.
- **Pipe / grep inside `--command`** mangles the local-vs-remote shell parse (pitfall #16). Prefer single quotes + full binary path; for `cron list | grep`, use `--command='sudo -u openclaw /home/openclaw/.npm-global/bin/openclaw cron list --json'` and parse with `jq` locally.

## Channel-specific caveats

For per-channel setup (Telegram, Discord, Slack, WhatsApp, iMessage) see `references/channels.md`. The items below are gotchas that bite *after* a channel is configured.

- **Telegram bot commands ≤100** (pitfall #9). With many skills you'll hit `BOT_COMMANDS_TOO_MUCH`. Workaround: `channels.telegram.commands.native: false` to disable native command registration, or trim skills.
- **Streaming = bot spam** (CHANGELOG 2026-04-12). If users complain about message bursts, set `channels.telegram.streaming.mode: "off"` (the `partial` mode runs a separate pipeline from `blockStreaming`, both must be off). Run `openclaw doctor --fix` to migrate legacy streaming config to the new nested format.
- **Google Gemini native provider returns 400** (pitfall #17). Use the OpenAI-compatible endpoint via `models.providers.google-oai` with `api: "openai-completions"` and `compat.supportsStore: false, compat.supportsStrictMode: false`.
- **Telegram adapter silently dies after ~12h** (pitfall #2). The watchdog timer documented in `references/05-config-and-cli.md` § systemd health units restarts the gateway on outbound errors. If you removed the watchdog, schedule your own `journalctl` scan + restart.
- **`gateway.auth.mode: token` flakes on small VMs** (pitfall #6). The challenge-response handshake times out under memory pressure. On a 1-user loopback-only VM, `gateway.auth.mode: none` is safe.

## When `openclaw doctor` doesn't help

Some failure modes need direct evidence from the gateway logs, not the doctor heuristic. In order of usefulness:

1. **Gateway health endpoint** — `curl -s http://127.0.0.1:18789/health | jq`. Any HTTP status other than `200` means the gateway can't take requests.
2. **Live gateway logs** — `sudo journalctl -u openclaw.service -f`. Look for `[gateway] ready`, ERROR lines, OAuth `401`, model `4xx`.
3. **Per-channel logs** — `openclaw channels logs --channel telegram --lines 200`.
4. **Models status** — `openclaw models status` shows OAuth profile state, model availability, last call latency.
5. **Config validation** — `openclaw config validate`. Catches JSON5 syntax errors and schema mismatches before they crash the gateway.

If the gateway is in a crash loop on start, the most common cause is an `openclaw.json` schema error from a previous edit. Restore `~/.openclaw/openclaw.json.last-good` and re-apply the change one key at a time.
