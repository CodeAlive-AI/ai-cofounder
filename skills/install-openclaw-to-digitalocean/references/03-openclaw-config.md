# OpenClaw configuration deep-dive

This file unpacks the OpenClaw config the wizard sets up — Telegram channel, the three LLM providers, and the workspace. It is provider-agnostic (the bot config is identical to the Yandex Cloud sibling skill); only the host it runs on differs. Read it when something in phase 5 of `cloud-init.yaml` doesn't take or the user wants to swap an option.

## 1. Telegram bot — what BotFather gives you

In Telegram, talk to [@BotFather](https://t.me/BotFather):

1. `/newbot` → BotFather asks for a **display name** (anything) and a **username** ending in `bot` (e.g. `your_ceo_bot`).
2. Copy the token (`7892341234:AAFhJk2mNopq-Rs...`). Treat it as a password — anyone with it can read and send as your bot.
3. The wizard auto-detects your numeric `chat_id` after you press `/start` — you do **not** need `@userinfobot`.

Optional first-time polish: `/setdescription`, `/setuserpic`, `/setjoingroups` → disable (unless you want group chats).

### Pairing the chat

After bootstrap, the Telegram adapter starts in **pairing mode**: the first message you send generates a pairing request in the gateway. Without approval, the bot won't reply.

The wizard (Step 4) detects your `chat_id` from `getUpdates`, then approves the pending request:

```bash
ssh openclaw@$IP 'openclaw pairing list telegram --format json' | jq .
# entries look like {requestId:"...", senderId:123456789, channel:"telegram"}
ssh openclaw@$IP 'openclaw pairing approve telegram <requestId>'
```

Schema note (verified against `src/gateway/protocol/schema/devices.ts`): the fields are **`senderId`** and **`requestId`**, NOT `chatId` / `code`. A filter on `.chatId` always returns empty — Step 4's filter tries both defensively.

After approval the wizard locks the channel down:

```bash
ssh openclaw@$IP "
  openclaw config set channels.telegram.dmPolicy allowlist
  openclaw config set channels.telegram.allowFrom '[<chat_id>]'
  sudo systemctl restart openclaw-gateway
"
```

## 2. The three LLM auth methods

None is hard-coded — cloud-init reads `ANTHROPIC_API_KEY` / `OPENROUTER_API_KEY` from `gateway.env` and sets `agents.defaults.model.*` accordingly; OAuth Codex runs as a post-bootstrap step.

| Method | User input | env / profile | Default primary | Default fallbacks |
|---|---|---|---|---|
| **A. Anthropic API key** | `sk-ant-…` | `ANTHROPIC_API_KEY` env | `anthropic/claude-sonnet-4-6` | `["anthropic/claude-haiku-4-5"]` |
| **B. OpenRouter API key** | `sk-or-…` | `OPENROUTER_API_KEY` env | `openrouter/moonshotai/kimi-k2.6` | `["openrouter/openai/gpt-5.5","openrouter/anthropic/claude-haiku-4-5"]` |
| **C. OpenAI Codex OAuth** | word `Codex` | profile `openai-codex:<email>` in `~/.openclaw/agents/main/agent/auth-profiles.json` | `openai/gpt-5.5` (Pro) or `openai/gpt-5.4` (Plus) | `["openai/gpt-5.4"]` |

### A. Anthropic API key (recommended for first-timers)

Anthropic stopped allowing third-party OAuth for Claude Pro/Max in January 2026 — API key is the only way to reach Claude from a hosted bot. Pay-as-you-go (~$3 per million input tokens for Sonnet 4.6); needs ≥$5 credit. Validation call:

```bash
curl -fsS https://api.anthropic.com/v1/messages \
  -H "x-api-key: $KEY" -H "anthropic-version: 2023-06-01" -H "content-type: application/json" \
  -d '{"model":"claude-haiku-4-5","max_tokens":1,"messages":[{"role":"user","content":"ok"}]}' | jq -er '.content'
```

### B. OpenRouter API key (unified access)

Built-in OpenClaw provider in 2026.4+ — set `OPENROUTER_API_KEY`, pick any `openrouter/<vendor>/<model>`. ~5% markup; doesn't fall under Anthropic's data-handling terms. Validation:

```bash
curl -fsS https://openrouter.ai/api/v1/auth/key -H "Authorization: Bearer $KEY" | jq -er '.data.usage != null'
```

Wizard default `openrouter/moonshotai/kimi-k2.6` (strong long-context, cost-effective). Others: `openrouter/anthropic/claude-sonnet-4-6`, `openrouter/openai/gpt-5.5`, `openrouter/auto` (cron only).

### C. OpenAI Codex via ChatGPT subscription (free if you already pay)

ChatGPT Plus ($20) / Pro ($200) grants access via the `openai-codex` provider, no per-token bill. Device-code OAuth — the wizard runs `openclaw models auth login --provider openai-codex --device-code` over SSH after bootstrap, the user pastes an 8-char code at https://auth.openai.com/codex/device.

| Subscription | Models (in the `openai/` namespace, backed by the `openai-codex` OAuth profile) |
|---|---|
| Plus ($20/mo) | `openai/gpt-5.4`, `openai/gpt-5.4-mini` |
| Pro ($200/mo) | all Plus + `openai/gpt-5.5`, `openai/gpt-5.5-pro`, higher limits |

The wizard probes `openclaw models list --json` for `openai/gpt-5.5` and sets it primary if present (Pro), else `openai/gpt-5.4` (Plus). Note: Codex models register under `openai/*` (the `openai-codex` profile only backs auth), so `--provider openai-codex` lists nothing, and the JSON flag is `--json` not `--format json` — both verified on a live 2026.5.27 bot.

**Known issue #74212 (2026-05):** SSH sessions sometimes mask the code as `[shown on the local device only]`. Use `ssh -tt`; if still masked, run the auth in a fresh interactive SSH session.

**Orphan-profile pitfall (issue #69414):** re-auth writes a new profile keyed by email instead of replacing `openai-codex:default`; the old one drifts to expired-JWT. After every re-auth, run `openclaw models status` and prune duplicates sharing a `chatgpt_account_id`. Full JWT-decode snippet in `openclaw-guide` §13.

## 3. Why `gateway.auth.mode: none`

The gateway binds to `127.0.0.1:18789` (loopback only), the only Unix users are `openclaw` + root, and the box is single-tenant — so the token handshake the auth mode defends against has no attacker to defend against, and it flakily times out on small Droplets. If the user ever adds a second human user, flip it back: `openclaw config set gateway.auth.mode token`.

## 4. Workspace seeded by `ceo-ai-os/openclaw/install.sh`

The bootstrap runs `bash ceo-ai-os/openclaw/install.sh` as the openclaw user. It copies `{SOUL,USER,AGENTS,MEMORY,IDENTITY,HEARTBEAT,TOOLS}.md` into `~/.openclaw/workspace/`, copies all 48 portable skills into `~/.openclaw/workspace/skills/`, and seeds empty `memory/*.json`. To personalize:

```bash
ssh openclaw@$IP
nano ~/.openclaw/workspace/IDENTITY.md   # bot name + vibe
nano ~/.openclaw/workspace/USER.md       # who you are
nano ~/.openclaw/workspace/MEMORY.md     # company context, wedge, ICP, constraint
```

Then send `/new` in Telegram to reload the bootstrap files.

## 5. `bootstrapMaxChars: 15000`

Lowered from OpenClaw's default 20000 to force context hygiene early — when a bootstrap file approaches the ceiling, OpenClaw warns instead of silently truncating. Don't go below ~12000 (risks cutting AGENTS.md mid-rule).
