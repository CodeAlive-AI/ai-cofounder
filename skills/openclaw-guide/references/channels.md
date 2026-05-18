# Channels — Telegram, Discord, Slack, WhatsApp, iMessage

OpenClaw 2026.5.x ships first-class support for 10+ channels. This file covers the five most common ones for a single-user CEO bot, in order of practicality on a Linux VM (Yandex Cloud, GCP, AWS, etc.).

**Default recommendation: Telegram.** One bot token from `@BotFather`, no public URL, long-polling works on any headless Linux box, the CEO AI OS `install-openclaw-to-yc` wizard already configures it. Use the other channels only when you have a specific reason — a team workspace on Slack, a community on Discord, a phone-first audience on WhatsApp, an Apple-only household on iMessage.

All four non-Telegram channels are 1st-class in 2026.5.x source — there are no `experimental` / `beta` tags. The warnings below are *operational* (which channel works where), not stability.

## 1. Telegram (default)

If you used the CEO AI OS install wizard, Telegram is already done. This section is for **adding a second Telegram bot**, **switching DM policy**, or **debugging a Telegram channel** on an existing install.

**Prerequisites.** A bot from `@BotFather`. To add a new bot in Telegram: send `/newbot`, pick a display name, pick a username ending in `bot`, copy the token (looks like `7892341234:AAFhJk2mNopq...`). Treat the token as a password.

**Setup.**

```bash
openclaw channels add --channel telegram --token "<TELEGRAM_BOT_TOKEN>"
# Or per-account (multi-bot setup):
openclaw channels add --channel telegram --token "..." --account work
openclaw config set channels.telegram.dmPolicy pairing      # pairing | allowlist | open | disabled
```

**Verify.** `openclaw channels status --probe` shows the bot account as `connected`. Send `/start` from your phone — the bot responds with a pairing code if `dmPolicy=pairing`, or chats directly if `allowlist`.

**Gotchas.**

- Telegram bot commands ≤100 (pitfall #9). If you hit `BOT_COMMANDS_TOO_MUCH`, set `channels.telegram.commands.native: false` or trim skills.
- Streaming = message spam (CHANGELOG 2026-04-12). If users complain about message bursts, set `channels.telegram.streaming.mode: "off"`.
- Adapter silently dies after ~12 h (pitfall #2). The watchdog timer in the reference VM deployment restarts the gateway on outbound errors — keep it on.

## 2. Discord (closest analogue to Telegram for Linux VMs)

**Prerequisites.** A Discord application + bot from https://discord.com/developers/applications. Enable the **Message Content Intent** (required); `Server Members` and `Presence` intents are optional. Invite the bot to your server via the OAuth2 URL generator with `bot` + `applications.commands` scopes and at minimum `View Channels` / `Send Messages` / `Read Message History`.

**Setup.**

```bash
openclaw channels add --channel discord --token "<DISCORD_BOT_TOKEN>"

# Env-driven equivalent for managed / Docker installs:
export DISCORD_BOT_TOKEN=...
# Docker:
docker compose run --rm openclaw-cli channels add --channel discord --token "<token>"
```

**Verify.**

```bash
openclaw channels status --probe                                       # bot connected
openclaw channels capabilities --channel discord --target channel:<id>  # per-channel permissions
```

The capability probe flags missing `ViewChannel` / `SendMessages` / `ReadMessageHistory` (and for voice features `Connect` / `Speak`).

**Gotchas.**

- Headless-Linux friendly — outbound WSS only, no inbound port needed.
- `DISCORD_BOT_TOKEN` env fallback applies **only to the default account**. For multi-account setups, configure via `openclaw config set`.
- Voice features need `ffmpeg` / `ffprobe` installed on the gateway host.
- The agent sandbox blocks `DISCORD_BOT_TOKEN` from leaking into spawned tools.

## 3. Slack (workspace bot via Socket Mode)

**Prerequisites.** A Slack workspace where you can create apps. Two tokens:

- **Bot User OAuth Token** (`xoxb-…`) — for chat.write and event subscriptions
- **App-Level Token** with `connections:write` scope (`xapp-…`) — for **Socket Mode** (the right transport for a VM without a public URL)

For HTTP/Events mode you would also need a public HTTPS URL and the Signing Secret — skip this unless you actually have those.

**Setup.**

Create the app at https://api.slack.com/apps (from manifest is fastest), install it in the workspace, copy the tokens, then:

```bash
export SLACK_BOT_TOKEN=xoxb-...
export SLACK_APP_TOKEN=xapp-...   # Socket Mode

# Then either the interactive wizard
openclaw channels add --channel slack
# or direct config
openclaw config set channels.slack.botToken "$SLACK_BOT_TOKEN"
openclaw config set channels.slack.appToken "$SLACK_APP_TOKEN"
```

Per-channel flags `--bot-token` / `--app-token` exist on `channels add` — verify in `openclaw channels add --help` before scripting (the flag set is the canonical source).

**Verify.**

```bash
openclaw channels status --probe                  # token status (bot + app)
openclaw channels capabilities --channel slack    # granted OAuth scopes
```

**Gotchas.**

- **Socket Mode is the only sane choice on a VM without a public URL.** HTTP Events Mode requires HTTPS ingress, which the CEO AI OS install wizard deliberately doesn't provide.
- `SLACK_BOT_TOKEN` / `SLACK_APP_TOKEN` env fallback applies only to the default account. For multi-account, configure via `openclaw config set`.
- Slack rate-limits new bots aggressively for the first 24 h — expect occasional `429`s while the app is fresh.

## 4. WhatsApp (Baileys, requires a real phone)

OpenClaw uses the **WhatsApp Web protocol via Baileys** — there is no Meta Cloud API path in the bundled channel. This means no business verification, but it also means your bot is tied to a real WhatsApp number on a real phone and counts as one of that number's four linked devices.

**Prerequisites.**

- A phone with WhatsApp installed and signed in
- Ability to scan a QR or accept a pairing code on that phone
- Node.js runtime (Bun is documented as incompatible for WhatsApp specifically)

**Setup.**

```bash
openclaw channels add --channel whatsapp
openclaw channels login --channel whatsapp
# Or for multi-account:
openclaw channels add --channel whatsapp --account work --auth-dir /path/to/wa-auth
openclaw channels login --channel whatsapp --account work
```

`channels login` prints a QR (rendered as ASCII in the terminal — works over SSH) or a pairing code. Approve the device on the phone.

**Verify.** `openclaw channels status --probe` shows the account as connected. Send a message from another WhatsApp user — the bot should reply.

**Gotchas.**

- No Meta Business credentials required, but each account is tied to a real WhatsApp number, and a logged-in WhatsApp Web session counts against the four-device limit on that account.
- Works on headless Linux (ASCII QR over SSH).
- Sessions can de-sync if the phone goes offline for days. Re-run `openclaw channels login --channel whatsapp` to recover.
- Baileys is an **unofficial** Web protocol implementation — Meta can break it on their side; treat it as best-effort.

## 5. iMessage (macOS-only — has a Linux workaround)

iMessage **cannot run on a Linux VM**. The OpenClaw channel needs a macOS host signed into iMessage to talk to Apple's daemon. There is a documented workaround for Linux gateways: point `channels.imessage.cliPath` at an SSH wrapper that runs `imsg` on a Mac you control. For a Linux-only workshop audience this is usually out of scope.

**Prerequisites (Mac path).**

- A macOS host signed into iMessage
- `imsg` CLI installed — `brew install steipete/tap/imsg`
- Full Disk Access for the gateway process (so it can read `chat.db`)
- Automation permissions for Messages.app
- For advanced features (tapbacks, edits, effects): SIP disabled + helper dylib injected into Messages.app

**Setup.**

iMessage uses pairing, not tokens. Configure `channels.imessage.cliPath` and policy fields via `openclaw config set` or the wizard, then:

```bash
imsg launch                              # only if using private-API actions
openclaw channels status --probe
openclaw pairing list imessage
openclaw pairing approve imessage <CODE>
```

Verify exact flag names in `openclaw channels add --help`.

**Linux VM workaround.**

Point `channels.imessage.cliPath` at an SSH wrapper:

```bash
cat > /usr/local/bin/imsg-remote <<'EOF'
#!/usr/bin/env bash
exec ssh -T mac-host /usr/local/bin/imsg "$@"
EOF
chmod 0755 /usr/local/bin/imsg-remote
openclaw config set channels.imessage.cliPath /usr/local/bin/imsg-remote
```

Gateway speaks JSON-RPC over stdio, so SSH transport works. You still need the Mac to be signed into iMessage and have the gateway process granted the relevant permissions.

**Gotchas.**

- Permissions are granted **per process context** — if the gateway runs as a LaunchAgent, trigger the consent prompts from that same context once.
- **BlueBubbles support was removed** from upstream — migrate old configs.
- Use this channel only if your audience is genuinely Apple-first. For mixed audiences, Telegram or Discord is friction-free.

## Verification cheat-sheet (all channels)

```bash
openclaw channels list --all                       # configured + installable
openclaw channels status --probe                   # live transport state
openclaw channels capabilities --channel <name>    # provider scopes/intents
openclaw channels logs --channel <name> --lines 100
openclaw channels add --help                       # canonical per-channel flags
```

**Per-channel `channels add` support summary (verified in source):**

- Telegram, Discord, Nostr, QQ Bot, Synology Chat, Nextcloud Talk, Matrix, WhatsApp — yes, `channels add --channel <name> [...flags]`.
- Slack — token-driven via env (`SLACK_BOT_TOKEN` / `SLACK_APP_TOKEN`) or `openclaw config set`. Per-channel `--bot-token` / `--app-token` flags exist.
- iMessage — pairing-based, not token-based; configured via `channels.imessage.*` keys and `openclaw pairing approve imessage`.

When in doubt about flag names, `openclaw channels add --help` is the canonical authority — it always reflects the installed CLI version.
