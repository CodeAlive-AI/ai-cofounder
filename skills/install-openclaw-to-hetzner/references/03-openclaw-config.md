# OpenClaw configuration deep-dive

This file unpacks the three pieces of OpenClaw config the wizard sets up — Telegram channel, LLM provider, and workspace. Read it when something in Step 5 of `cloud-init.yaml` doesn't take or the user wants to swap an option.

## 1. Telegram bot — what BotFather gives you

In Telegram, talk to [@BotFather](https://t.me/BotFather):

1. `/newbot` → BotFather asks for a **display name** (anything) and a **username** that must end in `bot` (e.g. `your_ceo_bot`).
2. Copy the token. It looks like `7892341234:AAFhJk2mNopq-Rs...`. Treat it as a password — anyone with this token can read and send messages as your bot.
3. To get your numeric `chat_id`, the wizard auto-detects it after the first `/start` — don't ask the user to look it up via `@userinfobot`.

If the user is creating the bot for the first time:
- Set a description: `/setdescription`
- Set a profile picture: `/setuserpic` (optional)
- Disable bot from groups it isn't invited to: `/setjoingroups` → disable, unless the user wants group-chat capability

For groups: the wizard's default `dmPolicy: pairing` means the bot will only respond after the user explicitly pairs the chat. Group support needs `groupPolicy: allowlist` and a one-time invite — out of scope for this skill.

### Pairing the chat

After the cloud-init finishes, OpenClaw's Telegram adapter starts in **pairing mode**: any message you send to the bot generates a pairing code in the gateway logs. Without the code, the bot won't reply.

The wizard's Step 4 sends `/start`, polls `getUpdates` to extract `chat_id`, then calls `openclaw pairing approve telegram <requestId>` over SSH. The user sees the bot's first reply (with the pairing code) but doesn't have to do anything with it.

If pairing fails:

```bash
ssh openclaw@$IP 'openclaw pairing list telegram'
# copy the code or requestId shown for the user's chat_id, then:
ssh openclaw@$IP 'openclaw pairing approve telegram <code-or-requestId>'
```

## 2. LLM provider — three auth methods

The wizard supports **three LLM auth methods**, picked by the user in Step 1 from the format of what they paste. None of them is hard-coded — the cloud-init reads `ANTHROPIC_API_KEY` / `OPENROUTER_API_KEY` from `gateway.env` and configures `agents.defaults.model.primary` accordingly. OAuth Codex runs as a post-bootstrap step.

| Method | User input | env / profile | Default primary model | Default fallbacks |
|---|---|---|---|---|
| **A. Anthropic API key** | `sk-ant-…` | `ANTHROPIC_API_KEY` env | `anthropic/claude-sonnet-4-6` | `["anthropic/claude-haiku-4-5"]` |
| **B. OpenRouter API key** | `sk-or-…` | `OPENROUTER_API_KEY` env | `openrouter/moonshotai/kimi-k2.6` | `["openrouter/openai/gpt-5.5", "openrouter/anthropic/claude-haiku-4-5"]` |
| **C. OpenAI Codex OAuth** | word `Codex` | OAuth profile in `~/.openclaw/agents/main/agent/auth-profiles.json`, written by `openclaw models auth login --provider openai-codex --device-code` | `openai-codex/gpt-5.5` (Pro) or `openai-codex/gpt-4o` (Plus) | `["openai-codex/gpt-4o"]` |

### A. Anthropic API key (recommended for first-timers)

Anthropic stopped allowing third-party OAuth for Claude Pro/Max in January 2026 — API key is the only way to reach Claude directly from a hosted bot. Pros: no per-month subscription, pay-as-you-go (~$3 per million input tokens for Sonnet 4.6). Cons: needs at least $5 credit on https://console.anthropic.com/settings/billing or the bot fails to answer.

Validation call before VM bootstrap:

```bash
curl -fsS https://api.anthropic.com/v1/messages \
  -H "x-api-key: $KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-haiku-4-5","max_tokens":1,"messages":[{"role":"user","content":"ok"}]}' \
  | jq -er '.content'
```

If `.content` is present, key works and there's at least a few cents of credit.

### B. OpenRouter API key (unified access to many vendors)

OpenRouter is a built-in OpenClaw provider in 2026.4+ — no custom `models.providers.openrouter.{baseUrl, apiKey}` block needed if you only use `OPENROUTER_API_KEY`. Set the env var and pick any model. Pros: single key for Anthropic + OpenAI + 200 others. Cons: ~5% markup over native; doesn't fall under Anthropic's data-handling agreement.

Validation call:

```bash
curl -fsS https://openrouter.ai/api/v1/auth/key -H "Authorization: Bearer $KEY" \
  | jq -er '.data.usage != null'
```

Model naming: `openrouter/<upstream-vendor>/<model-id>`. Examples:

- `openrouter/moonshotai/kimi-k2.6` (wizard default — strong long-context model, cost-effective)
- `openrouter/anthropic/claude-sonnet-4-6`
- `openrouter/openai/gpt-5.5`
- `openrouter/auto` (cheapest model meeting quality bar — only use for cron jobs)

### C. OpenAI Codex via ChatGPT subscription (free if you already pay)

ChatGPT Plus ($20/mo) or Pro ($200/mo) grants access to GPT-4o / o3 / GPT-5.5 through OpenClaw's `openai-codex` provider, with no per-token bill. Auth is **device-code OAuth** — the wizard runs `openclaw models auth login --provider openai-codex --device-code` over SSH after VM bootstrap, the user opens https://auth.openai.com/codex/device on their phone or laptop and pastes the 8-character code.

Subscription unlocks (May 2026):

| Subscription | Models you can pick |
|---|---|
| ChatGPT Plus ($20/mo) | `openai-codex/gpt-4o`, `openai-codex/gpt-4.5`, `openai-codex/o3` |
| ChatGPT Pro ($200/mo) | All Plus models + `openai-codex/gpt-5.5`, `openai-codex/gpt-5.5-pro`, higher rate limits |

The wizard probes `openclaw models list --provider openai-codex` after auth and sets primary to `gpt-5.5` if present (Pro), else `gpt-4o` (Plus).

**Known issue #74212 (2026-05):** in some SSH sessions OpenClaw masks the device-pairing code as `[shown on the local device only]`. Workaround: ensure `ssh -tt` is used (forces a TTY); if the mask persists, run `openclaw models auth login` in a fresh interactive SSH session.

**Orphan-profile pitfall (issue #69414, still open in 2026.5.x):** re-auth (`openclaw models auth login` a second time) writes a new profile keyed by email instead of replacing the existing `openai-codex:default`. After every re-auth, run `openclaw models status` and prune any duplicate that shares a `chatgpt_account_id` with a fresher entry. The full JWT-decode snippet lives in `openclaw-guide`.

## 3. Why `gateway.auth.mode: none`

OpenClaw's gateway can require a token for `openclaw <cmd>` calls to reach the daemon. On this VM:

- The gateway binds to `127.0.0.1:18789` (loopback only — never exposed on a public interface).
- The only Unix user who can reach loopback inside the network namespace is the `openclaw` user (and root).
- The VM has no other accounts.

So the threat the token mode defends against — "someone else on the same machine running `openclaw status`" — doesn't exist here. Setting `gateway.auth.mode: none` removes the 3-second challenge-response handshake that flakily times out on small VMs.

If the user later adds a second human user on this VM, **flip it back**:

```bash
ssh openclaw@$IP 'openclaw config set gateway.auth.mode token'
```

## 4. Workspace seeded by `ceo-ai-os/openclaw/install.sh`

The wizard runs `bash ceo-ai-os/openclaw/install.sh` as the openclaw user. That script:

- Copies `ceo-ai-os/openclaw/workspace/{SOUL,USER,AGENTS,MEMORY,IDENTITY,HEARTBEAT,TOOLS}.md` into `~/.openclaw/workspace/`.
- Copies all 48 portable skills from `ceo-ai-os/skills/` into `~/.openclaw/workspace/skills/`.
- Seeds `~/.openclaw/workspace/memory/{hypotheses,heartbeat-state}.json` with empty defaults.

The user gets a working CEO OS personality immediately. To personalize:

```bash
ssh openclaw@$IP
nano ~/.openclaw/workspace/IDENTITY.md   # bot name + vibe
nano ~/.openclaw/workspace/USER.md       # who you are
nano ~/.openclaw/workspace/MEMORY.md     # company context, wedge, ICP, constraint
```

Then in Telegram send `/new` to start a fresh session that reloads the bootstrap files.

For deep customization see [openclaw/CUSTOMIZATION.md](../../../openclaw/CUSTOMIZATION.md) in this repo.

## 5. `bootstrapMaxChars: 15000` — why lower than default

The wizard lowers `agents.defaults.bootstrapMaxChars` from the OpenClaw default `20000` to `15000`. Reason: the CEO AI OS AGENTS.md currently weighs 4.5 KB, SOUL.md 3.6 KB, MEMORY.md grows over weeks. Setting a tighter ceiling forces hygiene early — when a file approaches the limit OpenClaw warns instead of silently truncating it.

Lowering further (to e.g. 12000) would risk truncating an honest AGENTS.md mid-rules. Raising back to 20000 is fine if the user knows what they're doing.

## 6. ARM vs x86 considerations (CAX11 default)

The wizard defaults to **CAX11** (ARM Ampere) for cost reasons (~30% lower power → same EUR price as x86, but more headroom over time). For OpenClaw (Node.js) and the ceo-ai-os skill bundle (almost all pure JS/Markdown), ARM is transparent.

Known cases where x86 matters:

- Native modules compiled for x86 only (rare in modern npm — most packages publish both).
- Pre-built binaries downloaded by ceo-ai-os skills (e.g. `playwright-guide` would need ARM-compatible browser builds — check before assuming).
- Third-party APIs that expect x86-specific behaviour (essentially never).

If the user reports a skill failing with `Error: Cannot find module ...node-gyp...` or `unsupported architecture`, the fallback is:

```bash
# Recreate the VM with cx22 (x86 same shape, same price)
hcloud server delete openclaw-bot
# ... then re-run the wizard with SERVER_TYPE=cx22 forced
```

The wizard's auto-recovery falls back to `cx22` automatically if `cax11` is `resource_unavailable` at create time, so most users never need to think about this. Architecture-specific failures only surface during install of an x86-only skill weeks later.
