---
name: install-openclaw-to-hetzner
description: >-
  Autonomously set up an OpenClaw bot on a fresh Hetzner Cloud VM (Falkenstein,
  Germany — fsn1 — by default; switchable to Helsinki/Nuremberg/Ashburn/Hillsboro/
  Singapore). Asks the user for exactly two things — a Telegram bot token and one
  of three LLM access options (Anthropic API key, OpenRouter API key, or OpenAI
  Codex OAuth via ChatGPT Plus/Pro subscription) — then handles Hetzner SSH-key
  upload, firewall creation, VM provisioning, hardening, OpenClaw install, CEO
  AI OS workspace seeding, Telegram pairing, chat_id auto-detection, and
  bot-reply verification on its own. The only other actions the user performs
  are pressing /start in Telegram once and (if Codex) confirming a device code
  on auth.openai.com. Use when the user says install OpenClaw to Hetzner, deploy
  OpenClaw to Hetzner Cloud, set up my CEO bot on Hetzner, create a Hetzner VM
  for OpenClaw, поставь openclaw на hetzner, разверни бота в Hetzner, or any
  close paraphrase. Targets a ~15-minute end-to-end run for non-DevOps users
  (founders, CEOs, marketing leads). Default server type is cax11 (ARM Ampere,
  2 vCPU / 4 GB / 40 GB SSD, ~€4.30/month with IPv4); switchable to cx22 (x86
  same shape, same price) if the user has architecture concerns. For local-
  machine OpenClaw install, use openclaw/install.sh in this repo instead. For
  Yandex Cloud Kazakhstan installs, use install-openclaw-to-yc. Companion skill
  openclaw-guide is required; openclaw-user-onboarding is auto-invoked after
  Step 5 to collect the five basic facts about the user (identity, focus,
  style, tools, anti-patterns) and write them into USER.md so the bot is
  useful from message one.
license: MIT
metadata:
  version: 0.1.3
---

# Install OpenClaw to Hetzner Cloud

A wizard that takes a non-DevOps user from zero to a working OpenClaw bot on a fresh Hetzner Cloud VM in ~15 minutes. **The user does exactly two-or-three things**: paste a Telegram bot token, paste an LLM API key (or say "Codex" for OAuth via ChatGPT subscription), press `/start` in Telegram once, and — only for Codex — confirm a device code on auth.openai.com. Everything else is silent.

## Operating principles (the "don't bother the user" rules)

These rules override the rest of the document. Read them first.

1. **Two questions. Total.** The only inputs you ask the user for are the **Telegram bot token** and the **LLM access** (one of three options — see Step 1). Everything else — server name, location, image, SSH key, firewall ingress, **chat_id** — is decided silently from safe defaults or auto-detected.
2. **The Hetzner API token is a third question only if not already set.** If `HCLOUD_TOKEN` is in env or an `hcloud context` exists, use it silently. Only ask if both are absent. See Step 0c.
3. **Never ask "are you sure"** for actions inside this wizard's own scope (creating its own server, its own firewall, its own bot pairing). Only confirm if you're about to destroy something the user might want to keep (an existing server with the same name).
4. **Never show shell commands, flags, paths, or stack traces** to the user unless they explicitly ask "what did you run?". Progress is plain language: "Создаю сервер…", "Ставлю OpenClaw…", "Проверяю что бот отвечает…".
5. **Validate inputs upfront** with a one-call test (Telegram `/getMe`, LLM key probe, Hetzner token probe). Don't burn 15 minutes on a VM bootstrap with a bad key.
6. **Auto-fix prerequisites silently** when it's safe — install `hcloud` CLI, generate an SSH key, upload it to Hetzner. Only stop and ask the user when something *can't* be done without their input (Hetzner API token entry, no project, account not verified).
7. **One language — and the bot speaks it too.** If the user wrote to the agent in Russian, all wizard prompts are in Russian, **and** the OpenClaw bot itself is configured to reply in Russian. Detect the user's language from their first few messages, pass it through to cloud-init as `{{USER_LANGUAGE}}` (ISO 639-1: `ru`/`en`/`de`/...), and the bootstrap script appends a localization block to the bot's `USER.md`. Default if you can't tell: `ru` (workshop audience).
8. **No emojis** in user-facing text unless the user used them first.

## Do NOT ask the user for these (hard override)

These are the things the wizard has been observed asking by mistake. Don't:

| Don't ask | Why | What to do instead |
|---|---|---|
| **Telegram chat_id** | Auto-detected in Step 4 from `getUpdates` after the user presses `/start`. Asking for it makes the user open `@userinfobot`, copy a number, paste — pure friction. | Poll `https://api.telegram.org/bot<TOKEN>/getUpdates` every 2s in Step 4. Pluck `result[0].message.chat.id`. |
| **Server name** | Default is `openclaw-bot`. If taken, append `-<random4>`. | Set silently. Tell user the name only in the final summary. |
| **SSH IP restriction** | There is none. SSH is open to `0.0.0.0/0` + `::/0` — no per-IP lock — because user/agent IPs are dynamic and an automation AI agent making frequent SSH calls must not be IP-banned. Security control is key-only auth + fail2ban (bans only repeated FAILED auths). | Open SSH to all silently; don't detect or ask for an IP. |
| **Location / image / server type** | Defaults: `fsn1` (Falkenstein), `ubuntu-24.04`, `cax11` (ARM 2 vCPU / 4 GB / 40 GB). | Don't surface to user unless they ask "in what region?". |
| **Linux username on the VM** | Always `openclaw`. | Use it without asking. |
| **Anthropic / OpenRouter / OpenAI billing balance** | Caught upfront in Step 1 by a probe call. If insufficient, fail fast with a one-line message — don't ask "are you sure you topped up?". | Probe call before VM create. |
| **IPv4 / IPv6 choice** | Always create with default IPv4+IPv6. The €0.50/mo IPv4 surcharge is part of the documented cost ceiling; saving €0.50/mo by going IPv6-only breaks SSH from most mobile networks. | Don't ask. |

If you catch yourself drafting a question outside the allowed inputs, re-read this section. The wizard's whole point is autonomy.

## When to invoke

Trigger on: "install OpenClaw on Hetzner", "set up my bot on Hetzner", "deploy OpenClaw to Hetzner Cloud", "поставь openclaw на hetzner", "разверни мне бота в Hetzner Cloud", "Hetzner VM for OpenClaw", and close paraphrases.

Do NOT use this skill for:
- Local-machine OpenClaw install → use `openclaw/install.sh` in this repo (the user runs it on their laptop)
- Yandex Cloud Kazakhstan → use `install-openclaw-to-yc` (separate sibling skill)
- AWS / GCP / Azure / DigitalOcean → out of scope for this skill (build a parallel `install-openclaw-to-<cloud>` if you need one)
- Adding a second agent or a second bot to an existing Hetzner VM → out of scope

## Single access mode (Plan A only)

Unlike the Yandex Cloud variant, this skill has only **one mode** — the user supplies a Hetzner API token (or has one already configured), and the wizard provisions in their personal Hetzner project. There is no workshop-bundle equivalent: Hetzner has no native multi-tenant analogue of YC's folders that fits the bundle pattern. If you ever need a workshop flow for Hetzner, build it as a separate `prepare-hetzner-workshop` skill that creates N projects via Cloud Console + project-scoped tokens (each participant gets their own token JSON file).

## Inputs (the two-plus-one questions you ask)

| # | Input | When asked | How user gets it (paste this verbatim in your prompt) |
|---|---|---|---|
| 1 | **Telegram bot token** | Always | Open [@BotFather](https://t.me/BotFather) in Telegram → send `/newbot` → pick any display name → pick a username ending in `bot` → copy the token (looks like `7892341234:AAFhJk2mNopq…`). |
| 2 | **LLM access** — one of three options | Always | See the table below. The user picks ONE option, the wizard auto-detects which one from the format of what they paste. |
| 3 | **Hetzner API token** | Only if no `HCLOUD_TOKEN` env var **and** no existing `hcloud context` | Open [console.hetzner.cloud](https://console.hetzner.cloud) → pick (or create) a project → **Security → API tokens → Generate API token** → name it `openclaw-install`, permission **Read & Write** → copy the `hv2-…` token (shown only once, before the dialog closes). |

### LLM access options (the user picks one)

| Option | What user pastes | Detection signal | Cost / requirements |
|---|---|---|---|
| **A. Anthropic API key** | Key starting with `sk-ant-…` from [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) | Prefix `sk-ant-` | ≥$5 credit on [console.anthropic.com/settings/billing](https://console.anthropic.com/settings/billing). Best raw quality. Pay-as-you-go (~$3 per million input tokens for Sonnet 4.6). |
| **B. OpenRouter API key** | Key starting with `sk-or-…` from [openrouter.ai/keys](https://openrouter.ai/keys) | Prefix `sk-or-` | ≥$5 credit on OpenRouter. Unified access to Anthropic + OpenAI + 200 other models through one key, ~5% markup over native. Good if user wants to A/B different models later. |
| **C. OpenAI Codex via ChatGPT** | The literal word `Codex` (or `codex`, `chatgpt`, `oauth`) — **not** a key | Token doesn't start with `sk-` | Active **ChatGPT Plus ($20/mo)** or **Pro ($200/mo)** subscription. After VM bootstrap, the wizard prompts the user once on auth.openai.com with a device code — no API key needed, no metered billing. Plus gives `gpt-4.5`/`gpt-4o`/`o3`; Pro gives `gpt-5.5`. |

Order of recommendation in the prompt: **A → C → B** for first-timers. A is the simplest happy path with the best Anthropic model. C is best for users who already pay for ChatGPT and want zero added bill. B is the power-user choice.

Everything below is decided **without asking the user**:

| Decided silently | Value | How |
|---|---|---|
| Server name | `openclaw-bot` (or `openclaw-bot-<random4>` if taken) | If `hcloud server describe openclaw-bot` returns a result, append a random 4-char suffix and try again. |
| Location | `fsn1` (Falkenstein, Germany) | EU-central network zone, cheapest pricing tier, low latency from RU/EU/KZ. |
| OS image | `ubuntu-24.04` | Latest Ubuntu LTS at time of writing. Same string works for ARM and x86. |
| Server type | `cax11` (ARM Ampere, 2 vCPU / 4 GB / 40 GB SSD) | Same price as x86 `cx22`, ~30% less power draw. Falls back to `cx22` if `cax11` is sold out. |
| Public IP | yes, IPv4 + IPv6 (+€0.50/mo for IPv4) | Simplest path for SSH from anywhere. |
| Linux user | `openclaw` (sudo, no password) | Created by cloud-init. |
| SSH key | `~/.ssh/id_ed25519.pub` (or auto-generate if missing) | `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""` if absent. Uploaded to the active Hetzner project as `openclaw-install-<hostname>-<date>`. |
| Firewall ingress | port 22 open to `0.0.0.0/0` + `::/0` (no per-IP lock, no rate-limit), ICMP from anywhere | SSH is intentionally open to all because users/automation have dynamic IPs and a frequent-connecting AI agent must not be IP-banned. Security control is key-only auth + fail2ban (bans only repeated FAILED auths). |
| Outbound | open to anywhere | Hetzner firewall default-allows outbound; we add no egress rules. OpenClaw needs Anthropic, Telegram, OpenAI, OpenRouter, npm, GitHub, etc. — locking down by domain is fragile. |
| Telegram chat_id | **auto-detected** after first `/start` | Poll `https://api.telegram.org/bot<TOKEN>/getUpdates`. Never asked. |
| Primary model | Depends on chosen LLM option, see table below | |
| Fallback models | Depends on chosen LLM option, see table below | |

### Default models per LLM option

| Option | `agents.defaults.model.primary` | `agents.defaults.model.fallbacks` |
|---|---|---|
| A. Anthropic | `anthropic/claude-sonnet-4-6` | `["anthropic/claude-haiku-4-5"]` |
| B. OpenRouter | `openrouter/moonshotai/kimi-k2.6` | `["openrouter/openai/gpt-5.5", "openrouter/anthropic/claude-haiku-4-5"]` |
| C. OpenAI Codex | `openai-codex/gpt-5.5` (Pro) or `openai-codex/gpt-4o` (Plus only) | `["openai-codex/gpt-4o"]` |

For C, the wizard probes the user's subscription tier after OAuth completes — if `gpt-5.5` isn't in `openclaw models list`, fall back to `gpt-4o` as primary.

## Wizard flow

### Step 0 — Silent preflight (no user-facing output unless something breaks)

Run in order. Each block has a silent auto-fix path; only fall through to a user prompt when no silent path exists.

**a. Companion skill `openclaw-guide` must be loaded.** Probe the agent's skill loader. If it's not present, run `npx skills add CodeAlive-AI/ceo-ai-os@openclaw-guide -g` silently. If `npx` is unavailable, tell the user (one sentence) to install both skills manually, then stop.

**b. `hcloud` CLI installed.** `hcloud version`. If missing:

- macOS: `brew install hcloud` (Homebrew is the canonical install path; if Homebrew is missing too, fall back to the binary route below)
- Linux / no Homebrew: `curl -sSLO https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/').tar.gz && sudo tar -C /usr/local/bin --no-same-owner -xzf hcloud-linux-*.tar.gz hcloud && rm hcloud-linux-*.tar.gz`

Verify with `hcloud version` (any 1.50+ is fine). **Avoid `apt install hcloud`** — Debian/Ubuntu repos ship significantly outdated versions.

**c. Hetzner authentication.** Check, in order:

```bash
# 1. Env var wins if present (CI / agent-supplied token)
if [[ -n "${HCLOUD_TOKEN:-}" ]]; then
  hcloud server list >/dev/null 2>&1 && AUTH_OK=1
fi

# 2. Existing wizard-owned context
if [[ -z "${AUTH_OK:-}" ]]; then
  if hcloud context list 2>/dev/null | grep -q '^openclaw-install\b'; then
    hcloud context use openclaw-install
    hcloud server list >/dev/null 2>&1 && AUTH_OK=1
  fi
fi

# 3. Active context (the user's pre-existing one) — use it if it works
if [[ -z "${AUTH_OK:-}" ]]; then
  hcloud server list >/dev/null 2>&1 && AUTH_OK=1
fi

# 4. Ask the user for a token (one-time)
```

The token ask is **the only mandatory user prompt in Step 0**. Say exactly:

> Для работы с Hetzner Cloud нужен API-токен (один раз).
>
> Открой https://console.hetzner.cloud → выбери или создай проект → **Security → API tokens → Generate API token** → имя `openclaw-install`, права **Read & Write** → скопируй токен (начинается на `hv2-...`, виден только один раз).
>
> Пришли мне токен — я сохраню его в локальный контекст `hcloud` под именем `openclaw-install`, твои другие проекты не затрону.

After receiving the token, store it in a wizard-owned context (so we don't disturb the user's existing setup):

```bash
echo "$HCLOUD_TOKEN_INPUT" | hcloud context create openclaw-install
hcloud context use openclaw-install
hcloud server list >/dev/null \
  || { say "Hetzner токен не прошёл проверку. Перепроверь, что скопировал целиком (hv2-...) и что проект существует."; stop; }
```

Tokens are **project-scoped** in Hetzner. Whichever project the user generated the token in is the one we'll create the VM in — that's the right behaviour; we don't try to switch projects.

**d. SSH key.** `ls ~/.ssh/id_ed25519.pub`. If missing: silently `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "openclaw-hetzner-$(date +%Y%m%d)"`.

**e. Existing server with the same name in this project.** `hcloud server describe openclaw-bot 2>/dev/null`. If a result comes back, ask once: "У тебя уже есть сервер 'openclaw-bot' в этом проекте Hetzner — поставить новый под именем `openclaw-bot-XXXX`?" Default yes; pick a random 4-char suffix.

Do not print anything to the user about (a)-(e) if everything passed silently. Move to Step 1.

### Step 1 — Ask the two questions

In **one** message, in the user's language:

> Сейчас поставлю тебе OpenClaw-бота в Hetzner Cloud (Falkenstein, Германия). От тебя нужны две вещи (~5 минут).
>
> **1) Telegram bot token.** Открой @BotFather в Telegram → отправь `/newbot` → придумай имя (любое) → придумай username, заканчивающийся на `bot` → BotFather пришлёт токен. Пришли его мне.
>
> **2) Доступ к LLM — выбери ОДИН из трёх вариантов:**
>
>   **A) Anthropic API ключ** (рекомендую первым, лучшее качество)
>   Открой https://console.anthropic.com/settings/keys → Create Key. Ключ начинается на `sk-ant-`. На https://console.anthropic.com/settings/billing должно быть ≥$5.
>
>   **B) OpenRouter API ключ** (один ключ к Anthropic + OpenAI + 200 моделям)
>   Открой https://openrouter.ai/keys → Create Key. Начинается на `sk-or-`. Нужен баланс ≥$5 на openrouter.ai/credits.
>
>   **C) OpenAI Codex через ChatGPT подписку** (бесплатно если уже платишь Plus или Pro)
>   Не нужен ключ. Просто напиши слово **«Codex»**. После установки бота я попрошу ввести 8-символьный код на auth.openai.com — один раз.
>
> Пришли мне токен Telegram и один из трёх (ключ или слово «Codex»). Хоть в одном сообщении, хоть по отдельности. Я никуда не сохраняю и не показываю значения обратно.

**Detect the LLM provider from what the user pasted:**

```bash
case "$LLM_INPUT" in
  sk-ant-*)
    LLM_PROVIDER=anthropic ;;
  sk-or-*)
    LLM_PROVIDER=openrouter ;;
  Codex|codex|CODEX|ChatGPT|chatgpt|OpenAI*|"openai codex"|OAuth|oauth)
    LLM_PROVIDER=openai-codex
    LLM_API_KEY=""   # OAuth flow — no key at this stage
    ;;
  *)
    say "Не распознал — это Anthropic-ключ (начинается на sk-ant-), OpenRouter-ключ (sk-or-) или слово 'Codex'?" && reprompt
    ;;
esac
```

**Validate the credential** based on which option was chosen. Don't burn 15 minutes on a VM bootstrap with a bad key.

```bash
# Telegram token — always validate, confirms format + that the bot actually exists
BOT_USERNAME=$(curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe" \
  | jq -er '.result.username') \
  || (say "Telegram токен не прошёл проверку. Скопируй его ещё раз из @BotFather." && stop)

case "$LLM_PROVIDER" in
  anthropic)
    curl -fsS https://api.anthropic.com/v1/messages \
      -H "x-api-key: ${LLM_API_KEY}" \
      -H "anthropic-version: 2023-06-01" \
      -H "content-type: application/json" \
      -d '{"model":"claude-haiku-4-5","max_tokens":1,"messages":[{"role":"user","content":"ok"}]}' \
      | jq -er '.content' >/dev/null \
      || (say "Anthropic ключ не работает или нет кредита. Проверь на console.anthropic.com." && stop)
    ;;
  openrouter)
    curl -fsS https://openrouter.ai/api/v1/auth/key \
      -H "Authorization: Bearer ${LLM_API_KEY}" \
      | jq -er '.data.usage != null' >/dev/null \
      || (say "OpenRouter ключ не прошёл проверку. Перепроверь на openrouter.ai/keys." && stop)
    BAL=$(curl -fsS https://openrouter.ai/api/v1/auth/key -H "Authorization: Bearer ${LLM_API_KEY}" \
      | jq -r '.data.limit_remaining // 0')
    [[ "$BAL" == "0" ]] && say "На OpenRouter $0 кредита. Бот не сможет отвечать. Пополни на openrouter.ai/credits."
    ;;
  openai-codex)
    say "Хорошо, после установки бота на VM покажу 8-символьный код для https://auth.openai.com/codex/device. Это разовое действие."
    ;;
esac
```

`BOT_USERNAME` (e.g. `your_ceo_bot`) is captured here for the one-click chat link in Step 5.

### Step 2 — Silent VM creation

**a. Upload (or find) the SSH key in the Hetzner project.**

Hetzner SSH keys are project-scoped. If the user already uploaded their key to this project before, reuse it; otherwise upload now.

```bash
FINGERPRINT=$(ssh-keygen -lf ~/.ssh/id_ed25519.pub -E sha256 | awk '{print $2}' | sed 's/^SHA256://')
# hcloud doesn't expose --fingerprint filter, so list-and-grep
KEY_NAME=$(hcloud ssh-key list -o noheader -o columns=name,fingerprint \
  | awk -v fp="$FINGERPRINT" '$2 ~ fp {print $1; exit}')

if [[ -z "$KEY_NAME" ]]; then
  KEY_NAME="openclaw-install-$(hostname -s 2>/dev/null || echo laptop)-$(date +%Y%m%d)"
  hcloud ssh-key create --name "$KEY_NAME" --public-key-from-file ~/.ssh/id_ed25519.pub >/dev/null
fi
```

Note: Hetzner stores the SHA256 fingerprint in MD5 colon-format internally; the regex grep above tolerates both representations. If a future `hcloud` CLI version adds `--fingerprint`, switch to it.

**b. Render the cloud-init file.** Substitute these placeholders (no `TELEGRAM_CHAT_ID` — it's auto-detected in Step 4):

- `{{TELEGRAM_BOT_TOKEN}}` — from Step 1.
- `{{SSH_PUBLIC_KEY}}` — content of `~/.ssh/id_ed25519.pub`.
- `{{USER_LANGUAGE}}` — detected language code (`ru`/`en`/`de`/...).
- `{{LLM_ENV_LINE}}` — depends on the chosen LLM provider:

  | Provider | Substituted line |
  |---|---|
  | anthropic | `ANTHROPIC_API_KEY=<key>` |
  | openrouter | `OPENROUTER_API_KEY=<key>` |
  | openai-codex | *(empty string — no env var at this stage; OAuth fills the profile after Step 4.5)* |

Write to `/tmp/openclaw-cloud-init.yaml` with mode 600. Verify the resulting file is ≤ 32 KiB (Hetzner cloud-init limit); if larger after substitution, abort with a clear message — the wizard should not silently truncate.

**c. Create the Hetzner firewall.**

Hetzner firewalls default-DENY inbound when applied with no inbound rules and default-ALLOW all outbound. We add exactly two inbound rules — SSH and ICMP (for diagnostics). No outbound rules.

SSH is intentionally open to all (`0.0.0.0/0` + `::/0`): users and the automation AI agent connect from dynamic IPs, and an agent making frequent SSH calls must never be IP-banned or rate-limited. The security controls are key-only auth + fail2ban (which bans only on repeated FAILED auths, never an authenticated key user).

```bash
FW_NAME="${SERVER_NAME}-fw"

# Idempotent: delete a leftover firewall with the same name from a prior failed run
hcloud firewall describe "$FW_NAME" >/dev/null 2>&1 && hcloud firewall delete "$FW_NAME" >/dev/null 2>&1

hcloud firewall create --name "$FW_NAME" >/dev/null

# SSH open to all — no per-IP lock (dynamic IPs), no rate-limit (frequent agent connects).
hcloud firewall add-rule "$FW_NAME" \
  --direction in --protocol tcp --port 22 \
  --source-ips 0.0.0.0/0 --source-ips ::/0 \
  --description "SSH (open — key-only auth + fail2ban are the controls)" >/dev/null

# ICMP — convenient for the user to ping the server during diagnostics.
hcloud firewall add-rule "$FW_NAME" \
  --direction in --protocol icmp \
  --source-ips 0.0.0.0/0 --source-ips ::/0 \
  --description "ICMP in" >/dev/null
```

**d. Create the server.** Try `cax11` first; fall back to `cx22` if Hetzner returns `resource_unavailable` (ARM type sold out in `fsn1`).

```bash
SERVER_TYPE=cax11
hcloud server create \
  --name "$SERVER_NAME" \
  --type "$SERVER_TYPE" \
  --image ubuntu-24.04 \
  --location fsn1 \
  --ssh-key "$KEY_NAME" \
  --firewall "$FW_NAME" \
  --user-data-from-file /tmp/openclaw-cloud-init.yaml \
  -o json > /tmp/openclaw-vm.json 2>/tmp/openclaw-vm.err

# If cax11 sold out in fsn1, retry once with cx22 (x86, same shape, same price)
if grep -qiE "resource_unavailable|server_type_unavailable|sold.?out" /tmp/openclaw-vm.err; then
  hcloud server create --name "$SERVER_NAME" --type cx22 \
    --image ubuntu-24.04 --location fsn1 \
    --ssh-key "$KEY_NAME" --firewall "$FW_NAME" \
    --user-data-from-file /tmp/openclaw-cloud-init.yaml \
    -o json > /tmp/openclaw-vm.json 2>/tmp/openclaw-vm.err \
    && SERVER_TYPE=cx22
fi
```

Capture the public IPv4 from the JSON output:

```bash
IP=$(jq -r '.server.public_net.ipv4.ip' /tmp/openclaw-vm.json)
```

Then one sentence to the user:

> Сервер создан. Ставлю OpenClaw — займёт около 10 минут. Можешь пока заварить чай.

If the instance create errors with `unauthorized` / `403`: the token doesn't have write permission on this project (was created as read-only). Tell the user: "Hetzner-токен только на чтение. Создай новый с правами Read & Write в том же проекте и пришли мне."

If the error is `action_failed` / `verification_required`: the Hetzner account has not finished fraud-review verification (common for fresh accounts). Tell the user: "Hetzner ещё не подтвердил твой аккаунт — обычно занимает несколько часов. Напиши на cda-review@hetzner.com если стоит дольше суток. Я запущусь, когда проверка пройдёт — просто скажи мне 'продолжай'."

### Step 3 — Wait silently for cloud-init

Poll every 30 seconds:

```bash
ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 openclaw@$IP \
  'test -f /var/lib/openclaw-bootstrap-done && echo READY || echo PENDING'
```

Don't spam the user with raw log lines. Every ~3 minutes, emit one warm progress sentence based on the current phase you see in `tail -1 /var/log/openclaw-bootstrap.log`:

| If the log mentions | Tell the user |
|---|---|
| firewall / hardening | "Настраиваю файрвол и SSH" |
| nodesource / Node | "Ставлю Node.js" |
| `npm install` openclaw | "Качаю OpenClaw" |
| ceo-ai-os / install.sh | "Загружаю CEO-скиллы" |
| openclaw onboard / config | "Подключаю Telegram и LLM" |
| systemd / health | "Запускаю бот" |

Cap at 15 minutes. If still not ready, surface to the user with a single sentence ("Что-то пошло не так на сервере, проверяю логи") and jump to `references/04-troubleshooting.md`.

**Initial SSH window:** first connect can fail for ~30 seconds while cloud-init's `ssh_authorized_keys` write is still being merged with Hetzner's injected key. Don't escalate before ~60 seconds of polling silence.

### Step 3.5 — OAuth device-code flow (ONLY if `LLM_PROVIDER=openai-codex`)

Skip this entire step for `anthropic` and `openrouter` — they have the key already in `gateway.env` and the bot is ready to talk.

The provider id is **`openai-codex`** and the command **`openclaw models auth login --provider openai-codex --device-code`** is real and current (verified against OpenClaw `docs/providers/openai.md` — the device-code path exists specifically for headless/callback-hostile VMs; OpenClaw performs the OAuth itself and stores the profile as `openai-codex:default`). Do **not** rename the provider to `codex` (that is the agent-runtime id, a different concept) or shell out to a native `codex login` binary (not needed).

For `openai-codex`, first make sure the Codex provider is loadable, then run the device-code OAuth flow now via SSH with a forced TTY:

```bash
# The openai-codex auth provider ships in the bundled `openai` extension, but on
# some builds the login errors with "No provider plugins found" until the Codex
# plugin is present. Ensure it once (idempotent, harmless if already there):
ssh openclaw@$IP "openclaw plugins install clawhub:@openclaw/codex 2>/dev/null || true"

ssh -tt -o ServerAliveInterval=30 openclaw@$IP \
  "openclaw models auth login --provider openai-codex --device-code" \
  | tee /tmp/openclaw-oauth.log
```

The CLI prints two things on stdout, usually within 2 seconds:

- A URL like `https://auth.openai.com/codex/device` (or `https://auth.openai.com/device`)
- An 8-character code like `ABCD-1234`

Extract both with a regex on `/tmp/openclaw-oauth.log` (the formats may shift slightly across OpenClaw releases — match generously). Show the user **one** clean message:

> Последний шаг — подключи бота к ChatGPT.
>
> Открой в браузере: **https://auth.openai.com/codex/device**
>
> Введи код: **ABCD-1234**
>
> Войди под аккаунтом ChatGPT (Plus или Pro) и разреши доступ. Жду до 15 минут.

The SSH session will block until the user completes the device flow (or the 15-minute server-side timeout expires). When it exits 0, OpenClaw has written `auth-profiles.json` with the OAuth token and the gateway will pick it up on next config reload.

**Known pitfall (issue #74212, 2026-05):** in some SSH sessions OpenClaw masks the device-pairing code as `[shown on the local device only]`. If that's what you see in `/tmp/openclaw-oauth.log`:

- Retry with `ssh -tt` if you didn't already — the masking is triggered by a TTY check that some non-interactive SSH invocations fail.
- If retry doesn't help: run the auth command directly inside a fresh SSH session (`ssh openclaw@$IP` → `openclaw models auth login --provider openai-codex --device-code`), pull the code from there, then resume the wizard.

After the OAuth profile is written:

```bash
# Probe what models the user's subscription unlocks
HAS_GPT55=$(ssh openclaw@$IP "openclaw models list --provider openai-codex --format json" \
  | jq -r '.[] | select(.id=="gpt-5.5") | .id // empty')

if [[ "$HAS_GPT55" == "gpt-5.5" ]]; then
  ssh openclaw@$IP "openclaw config set agents.defaults.model.primary 'openai-codex/gpt-5.5' \
    && openclaw config set agents.defaults.model.fallbacks '[\"openai-codex/gpt-4o\"]'"
else
  ssh openclaw@$IP "openclaw config set agents.defaults.model.primary 'openai-codex/gpt-4o' \
    && openclaw config set agents.defaults.model.fallbacks '[]'"
fi

ssh openclaw@$IP "sudo systemctl restart openclaw-gateway"
```

If after 15 minutes the SSH session timed out and `auth-profiles.json` still has no `openai-codex` profile: tell the user "не получилось войти в ChatGPT, давай попробуем ещё раз" and re-run the SSH `openclaw models auth login` command. Don't kill the VM — only the OAuth step needs to be retried.

### Step 4 — One-click chat link + auto-pair (the actual flow, not the easy one)

When `/var/lib/openclaw-bootstrap-done` exists, the gateway is up in `pairing` mode. **This is where wizards historically fail silently**: they think `openclaw pairing approve` succeeded, hand off to the user, and the user discovers the bot still asks for a confirmation code. Read this whole section.

#### What actually happens when the user presses /start

1. Telegram delivers `/start` to the bot.
2. OpenClaw enforces `dmPolicy=pairing` — it does **not** drop the message, it calls `issuePairingChallenge()`, records a pending request in the gateway, **and the bot replies to the user with the pairing code + instructions**. The user sees this message; they shouldn't reply to it.
3. The pending request lives in `openclaw pairing list telegram --format json` until either approved or expired.

#### Pre-emptive heads-up to the user

Send this **before** asking them to press /start, so they don't get confused when the bot's first reply is a code message:

> Бот готов. Открой его в Telegram: **https://t.me/{{BOT_USERNAME}}** и нажми `/start`.
>
> Бот пришлёт тебе короткое сообщение с кодом — **ничего с ним делать не надо, я подтвержу доступ автоматически за пару секунд**. После этого можешь начать переписываться с ботом как обычно.

#### Poll for chat_id (Telegram getUpdates)

```bash
for i in $(seq 1 150); do  # 150 × 2s = 5 minutes
  CHAT_ID=$(curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?timeout=2" \
    | jq -r '.result[0].message.chat.id // empty')
  [[ -n "$CHAT_ID" ]] && break
  sleep 2
done
[[ -z "$CHAT_ID" ]] && fail "Пользователь не нажал /start за 5 минут"
```

#### Approve the pairing (the part the old wizard broke)

The pending pairing request lives in `openclaw pairing list telegram --format json`. Its schema (verified against `src/gateway/protocol/schema/devices.ts`) uses **`senderId`** for the Telegram user ID and **`requestId`** for the primary key — **not** `chatId` and **not** `code`. A wizard that filters on `.chatId == $CHAT_ID` always gets empty results and the subsequent `xargs approve` is a no-op.

Defensive filter (handles both schemas in case a future OpenClaw release renames again):

```bash
APPROVE_TOKEN=""
for i in $(seq 1 5); do
  APPROVE_TOKEN=$(ssh openclaw@$IP "openclaw pairing list telegram --format json 2>/dev/null" \
    | jq -r --arg cid "$CHAT_ID" '
        .[]
        | select(
            (.senderId|tostring) == $cid
            or (.chatId|tostring) == $cid
            or (.sender // empty | tostring) == $cid
          )
        | (.requestId // .code // empty)
      ' \
    | head -n1)
  [[ -n "$APPROVE_TOKEN" ]] && break
  sleep 2
done

[[ -z "$APPROVE_TOKEN" ]] && fail "Запрос на pairing не появился в openclaw pairing list — посмотри journalctl на VM"

ssh openclaw@$IP "openclaw pairing approve telegram '$APPROVE_TOKEN'" \
  || fail "openclaw pairing approve failed (token=$APPROVE_TOKEN)"
```

#### Lock down + persist chat_id

```bash
ssh openclaw@$IP "
  openclaw config set channels.telegram.dmPolicy allowlist
  openclaw config set channels.telegram.allowFrom '[${CHAT_ID}]'
  echo 'TELEGRAM_CHAT_ID=${CHAT_ID}' >> /home/openclaw/.openclaw/gateway.env
  sudo systemctl restart openclaw-gateway
"
```

Wait ~60s for the gateway to come back. Don't proceed to Step 5 until `/health` returns 200:

```bash
for i in $(seq 1 30); do
  ssh openclaw@$IP 'curl -fsS -m 3 http://127.0.0.1:18789/health' >/dev/null 2>&1 && break
  sleep 2
done
```

If the user doesn't press `/start` within 5 minutes, poke them gently with a one-line reminder. After 15 minutes of no signal, stop and tell them how to resume.

### Step 5 — Verify the bot answers (do NOT skip), then hand off

The wizard's #1 historical failure mode was claiming "done" while the bot was still silent. The verification below is **mandatory** — three independent signals, all must pass, before you tell the user it works.

#### 5a. Trigger a reply

Send a probe message from the user's laptop, in the language set in Step 0 (`USER_LANGUAGE`):

```bash
case "$USER_LANGUAGE" in
  ru) PROBE="Скажи 'привет', чтобы я убедился, что ты отвечаешь." ;;
  de) PROBE="Sag 'hallo', damit ich sehe, dass du antwortest." ;;
  *)  PROBE="Say 'hi' so I can confirm you're alive." ;;
esac

curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${CHAT_ID}" \
  -d "text=${PROBE}"
```

#### 5b. Three checks, all required

**Check 1 — Gateway logged an outgoing message.** Watch the journal for an outbound telegram event within 90 seconds:

```bash
ssh openclaw@$IP "
  timeout 90 sudo journalctl -u openclaw-gateway -f --no-pager 2>/dev/null \
    | grep -m1 -E 'telegram.*sent|outgoing.*telegram|sendMessage.*ok'
"
```

If this times out: gateway accepted the inbound but didn't reply. Most likely cause = LLM provider not configured (Codex OAuth didn't finish, or env key empty). Jump to `references/04-troubleshooting.md` §4c-e.

**Check 2 — A bot reply appears in `getUpdates`** within 90s.

```bash
LAST_OFFSET=$(curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=-1" \
  | jq -r '.result[-1].update_id // 0')

for i in $(seq 1 45); do
  REPLY=$(curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=$((LAST_OFFSET+1))&timeout=2" \
    | jq -r '.result[]? | select(.message.from.is_bot==true) | .message.text' \
    | head -n1)
  [[ -n "$REPLY" ]] && break
  sleep 2
done

[[ -z "$REPLY" ]] && fail "Не вижу ответа бота в getUpdates через 90с"
```

**Check 3 — User confirms.** Ask the user once, in their language:

> Бот должен был тебе ответить в Telegram. Ответил?

Wait for "да"/"yes"/"работает". If "нет"/"не отвечает" — jump to `references/04-troubleshooting.md` §4. Never claim success unless all three pass.

#### 5c. If language is wrong

If checks 1+2 pass but the bot replied in English while the user expected Russian (or vice versa), the locale override wasn't applied. Re-apply over SSH and reset the session:

```bash
LOCALE_PACK="/usr/local/share/openclaw-locale-${USER_LANGUAGE}.md"
ssh openclaw@$IP "
  test -f $LOCALE_PACK && cat $LOCALE_PACK >> ~/.openclaw/workspace/USER.md
  openclaw sessions reset --channel telegram --to ${CHAT_ID} 2>/dev/null || true
"
```

Then re-run the probe (5a + 5b). If the bot is still answering in the wrong language, surface to the user — don't loop.

### Step 5.5 — Onboarding (hand off to `openclaw-user-onboarding` skill)

The bot is alive but anonymous — it doesn't know who's talking to it. Before the final summary, hand off to `openclaw-user-onboarding`, which collects five basic fields about the user (identity, focus, communication style, tools, anti-patterns), writes `USER.md` on the VM, and resets the Telegram session so the bot picks up the profile from the very next message.

Hand-off payload (everything the onboarding skill needs):

| Variable | Source in this wizard |
|---|---|
| `IP` | Step 2d (parsed from `hcloud server create` JSON output) |
| `CHAT_ID` | Step 4 (auto-detected from `getUpdates`) |
| `BOT_TOKEN` | Step 1 (Telegram token the user pasted) |
| `USER_LANGUAGE` | Step 0 (detected from user's first messages) |
| `AGENT_TYPE` | `main` (this wizard always installs the main agent) |

Trigger the skill with a single one-liner to the user, in their language:

> Бот живой. Последний шаг — расскажи о себе коротко, чтобы я с первого сообщения был полезным.

Then immediately invoke `openclaw-user-onboarding`. The onboarding skill takes over the conversation:

1. Asks the five questions in one message
2. Parses the user's free-form reply
3. Renders `USER.md` from the template
4. Shows a 15-line preview, asks for confirmation
5. Atomic SCP upload to `~/.openclaw/workspace/USER.md` (mode 600, owned by `openclaw:openclaw`)
6. Resets the active Telegram session (or restarts gateway as fallback)
7. Returns control to this wizard

If the user wants to skip onboarding entirely (says "пропусти", "skip", "потом"): write a minimal placeholder USER.md and proceed. **Don't block** — onboarding is a nice-to-have at this step, not a gate.

If `openclaw-user-onboarding` skill is not loaded: fall back to writing a minimal placeholder USER.md inline and mention in the final summary: "Чтобы дозаполнить профиль, поставь скилл openclaw-user-onboarding и скажи мне «онбординг»."

#### Final hand-off message

Only after all three checks pass, drop the summary. Adapt the `LLM` line to the provider the user chose:

```
OpenClaw запущен на Hetzner Cloud.

  Сервер       : openclaw-bot  (fsn1, cax11, 2 vCPU ARM / 4 GB / 40 GB SSD)
  IP           : 5.x.x.x
  Бот          : @your_bot_name
  LLM          : <one of three lines below>
  Workspace    : CEO AI OS (48 CEO-скиллов)
  Стоимость    : ~€4.30/мес (CAX11 + IPv4), включено 20 ТБ исходящего трафика
```

LLM line variants:

| Provider | Line |
|---|---|
| anthropic | `LLM          : Anthropic Claude Sonnet 4.6 (API key, ~$3/M tokens)` |
| openrouter | `LLM          : OpenRouter → Moonshot Kimi K2.6 (API key, +5% markup)` |
| openai-codex | `LLM          : OpenAI Codex / gpt-5.5 (ChatGPT Pro подписка)` or `gpt-4o (Plus подписка)` depending on what got resolved in Step 3.5 |

```
Что дальше:
  • Просто пиши боту в Telegram — он уже знает кто ты, сразу пробуй: «что у меня сегодня важно?»
  • Чтобы попробовать стратегические скиллы: «Сделай weekly review» или «Помоги принять решение об X»
  • Обновить профиль (роль сменилась, новые приоритеты): скажи мне «обнови мой профиль для бота» — openclaw-user-onboarding перезапустится в standalone-режиме
  • Когда захочешь паузу (сервер выключится, диск останется, IPv4 продолжит биллиться €0.50/мес): hcloud server poweroff openclaw-bot
  • Совсем удалить: hcloud server delete openclaw-bot && hcloud firewall delete openclaw-bot-fw

Если что-то сломается — просто скажи мне «бот молчит» или «openclaw сломался», я разберусь.
```

If the verification ping doesn't get a reply within 60 seconds, run `references/04-troubleshooting.md` §4 silently — don't claim success.

## Auto-recovery (what the wizard does without asking)

These are the things the wizard fixes on its own if it sees them during the run. The user is told only the end result, not the diagnostic steps.

| Detected condition | Silent fix |
|---|---|
| `hcloud` CLI missing | Install via Homebrew on macOS or release binary on Linux. |
| No `HCLOUD_TOKEN` env var, no existing context | Ask the user once for a token (see Step 0c). |
| `hcloud context openclaw-install` already exists but doesn't work | Probe with `hcloud server list`. If 401, ask for a fresh token; if 403, ask the user to regenerate with Read & Write. |
| `~/.ssh/id_ed25519.pub` missing | Generate a new one with no passphrase. |
| SSH key with the same fingerprint already uploaded to the project | Reuse it (don't re-upload — Hetzner rejects duplicate names; we look up by fingerprint). |
| (Caller IP detection — N/A) | SSH is always open to `0.0.0.0/0` + `::/0` by design; there's no caller IP to detect, so nothing can fail here. Key-only auth + fail2ban are the controls. |
| Firewall `openclaw-bot-fw` already exists from prior failed run | Delete and recreate (firewall has no stateful resources to lose). |
| `cax11` returns `server_type_unavailable` / `resource_unavailable` | Retry once with `cx22` (x86, same shape, same price). |
| `npm install -g openclaw` failed once | Retry once after 30 seconds. If still fails, escalate. |
| Gateway `/health` returns non-200 for first 90 seconds | Keep polling — composio plugin can take that long. Only escalate after 4 minutes. |
| Pairing approval returns "code not found" | Wait 3 seconds, re-list pairing requests. Telegram sometimes lags. |
| `openclaw pairing list` returns entries but jq filter on `.chatId` returns empty | The schema field is `.senderId` / `.requestId`, not `.chatId` / `.code`. The wizard's Step 4 uses a defensive filter that tries both — don't simplify it. |
| Bot replies in wrong language after locale pack applied | `cat` the locale pack again over SSH + `openclaw sessions reset --channel telegram --to <CHAT_ID>` to force USER.md re-read. See Step 5c. |
| Bot doesn't reply to verification ping within 30s | Restart adapter once before declaring failure. |

## Hetzner Cloud — common trip points (read before debugging)

If anything fails during the wizard run, check these first — most Hetzner-side issues come from one of these five mistakes:

1. **Token created with wrong permission.** Hetzner API tokens come in **Read** or **Read & Write** flavours. A read-only token will pass `hcloud server list` (used in Step 0c probe) but fail at `hcloud server create` with `unauthorized`. If you hit this, ask the user to regenerate with Read & Write — there is no way to upgrade an existing token's scope.
2. **Token created in the wrong project.** Tokens are project-scoped. If the user has multiple Hetzner projects and pasted a token from the wrong one, the VM will be created in the wrong project — and the user won't see it in their default view. There is no cross-project visibility in `hcloud`. If the VM seems to vanish, ask the user to check **all** their projects in console.hetzner.cloud.
3. **Account not verified.** New Hetzner accounts go through fraud review before the first server. The error is `action_failed` with `error.code = "verification_required"`. There is no way to bypass it from the CLI; the user must email `cda-review@hetzner.com` and wait (hours to days). The wizard should detect this error explicitly and tell the user clearly — do NOT retry in a loop.
4. **Server type sold out in chosen location.** `cax11` in `fsn1` occasionally goes into `resource_unavailable` during demand peaks. Auto-recovery falls back to `cx22` (same shape, same price). If `cx22` is also unavailable, try `nbg1` or `hel1` — but that requires user input (different EU location, otherwise transparent). Don't auto-switch location without confirmation.
5. **`#cloud-config` header missing.** The first line of user-data must be exactly `#cloud-config` — if the wizard's template substitution accidentally prepends whitespace or a different header, cloud-init silently does nothing and the server boots vanilla. Check `/var/log/cloud-init-output.log` on the VM if the bootstrap marker never appears.

## Failure modes (when the silent fixes aren't enough)

| Symptom | Where to look |
|---|---|
| `hcloud server list` returns `unauthorized` after token entry | `references/04-troubleshooting.md` §1a — wrong token, wrong project, or read-only scope |
| `hcloud server create` errors with `verification_required` | `references/04-troubleshooting.md` §1b — Hetzner account not yet verified |
| `hcloud server create` errors with `resource_unavailable` after both cax11 and cx22 tried | `references/04-troubleshooting.md` §1c — both fall back to another location (nbg1/hel1) |
| Cloud-init log shows `npm install -g openclaw` failed twice | `references/04-troubleshooting.md` §2 |
| `openclaw gateway status` shows `RPC probe: failed` after 4 min | `references/04-troubleshooting.md` §3 |
| User pressed `/start` but `getUpdates` returns no chat | `references/04-troubleshooting.md` §4a-b |
| Bot pairs but doesn't reply | `references/04-troubleshooting.md` §4c-e (key, credit, model) |
| SSH `Permission denied (publickey)` | `references/04-troubleshooting.md` §5 |
| Forgot IP, lost SSH, want to start over | `references/04-troubleshooting.md` §6 |

For everything else: dump `/var/log/openclaw-bootstrap.log` and `sudo journalctl -u openclaw-gateway -n 200` from the VM, surface to the user as "вот что я вижу, давай разбираться", do not guess.

## References

- `references/01-prerequisites.md` — `hcloud` CLI install, API token creation, SSH key, account verification
- `references/02-network-and-security.md` — Hetzner firewall model, public-IP rationale, hardening choices
- `references/03-openclaw-config.md` — Telegram pairing flow, all three LLM providers, workspace seeding
- `references/04-troubleshooting.md` — 7 failure modes with copy-paste fixes
- `scripts/cloud-init.yaml` — the full VM bootstrap (Node, OpenClaw, hardening, ceo-ai-os workspace, systemd system service)

## Companion skills

| Skill | Required? | Role |
|---|---|---|
| `openclaw-guide` | **required** | Loaded by Step 0a; owns all post-install consultation (channels, use cases, debugging). |
| `openclaw-user-onboarding` | recommended | Auto-invoked at Step 5.5 to collect five user facts and write USER.md. If missing, Step 5.5 falls back to a placeholder USER.md and surfaces "поставь openclaw-user-onboarding и скажи 'онбординг'" in the final summary. |
| `install-openclaw-to-yc` | alternative | The Yandex Cloud Kazakhstan variant of this skill. Pick by target cloud — they don't co-exist on one VM. |

### About `openclaw-guide` (required)

`openclaw-guide` (sibling) — **must be installed alongside this one**. The wizard refuses to start without it loaded. Two reasons:

1. **During install** — if cloud-init logs surface something this skill doesn't know about, the agent reads `openclaw-guide/references/06-troubleshooting.md` instead of guessing.
2. **After install** — when the user asks "how do I add Slack?", "how do I make the bot wake me up at 8am?", "what skills should I install?", the agent reads `openclaw-guide/references/use-cases.md` and `openclaw-guide/references/channels.md` to advise. This wizard is silent after Step 5; the guide owns ongoing consultation.

Joint install:

```bash
npx skills add CodeAlive-AI/ceo-ai-os@install-openclaw-to-hetzner -g
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-guide              -g
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-user-onboarding    -g   # recommended
```

If `npx` is unavailable: clone `https://github.com/CodeAlive-AI/ceo-ai-os` and drop the three skill folders into the agent's skills directory (see this skill's README for per-agent paths).

## Ecosystem — what to install next

The VM ships with all 48 ceo-ai-os skills pre-seeded into the workspace (the bot calls them automatically when the user's request matches). For the agent's own skill loader, here are the highest-ROI add-ons. **Mention them only after Step 5 passes** — bringing them up earlier dilutes the install flow.

| Trigger ("user later asks for X") | Skill to suggest | One-line pitch |
|---|---|---|
| "I want a daily morning brief" | `daily-recap` | Cron-driven morning + evening summary of metrics, calendar, and yesterday's wins. |
| "Help me prep for a strategic decision" | `decision-playbook` | Structured deliberation with explicit options, kill criteria, and a 7-day review. |
| "Research this company before my meeting" | `exa-company-research` | Exa-powered company profile (positioning, traction, team) in <30 s. |
| "Find people who fit ICP X" | `exa-lead-gen` | Multi-source lead discovery with enrichment. |
| "Watch what competitors are doing" | `competitive-analysis` | Daily radar over competitor sites, blog, GitHub, hiring. |
| "I want to use CodeAlive search inside the bot" | (see `openclaw-guide/references/codealive-context-engine.md`) | Adds `codealive__semantic_search` / `grep_search` / `chat` MCP tools to the bot — bot can answer questions about any indexed repo. |

Full catalogue lives at `https://github.com/CodeAlive-AI/ceo-ai-os/tree/main/skills`.

## Consulting after install — delegate, don't duplicate

When the user asks anything **not** about VM install (channel setup, use cases, debugging an existing bot, adding MCP servers, multi-agent), do not answer from memory — read the matching `openclaw-guide/references/<file>.md` first. The guide is the source of truth for ongoing OpenClaw operations. This skill's job ends after Step 5.

| User asks about | Read first |
|---|---|
| Adding WhatsApp / Slack / Discord / iMessage | `openclaw-guide/references/channels.md` |
| Setting up a daily brief, research workflow, decision playbook | `openclaw-guide/references/use-cases.md` |
| Adding CodeAlive search to the bot | `openclaw-guide/references/codealive-context-engine.md` |
| Bot stopped responding, OAuth re-auth, memory full | `openclaw-guide/references/06-troubleshooting.md` |
| Cron / heartbeat / scheduled jobs | `openclaw-guide/references/03-cron-heartbeat.md` |

## What this skill does NOT cover

- Multi-agent setups (two agents on one VM) — out of scope
- WhatsApp / Discord / Slack channels — Telegram only here; for other channels see `openclaw-guide/references/channels.md`
- Use-case design (morning brief, research workflows, decision playbooks) — see `openclaw-guide/references/use-cases.md`
- Backup and migration — separate skill
- Production-grade hardening (SELinux, kernel sysctl, SSH cert auth) — overkill for a workshop / personal CEO bot
- Workshop / multi-tenant provisioning — Hetzner has no native folder equivalent, so this skill is Plan A only. Build a separate `prepare-hetzner-workshop` if you need it.
- Yandex Cloud / AWS / GCP / Azure / DigitalOcean — use the matching `install-openclaw-to-<cloud>` skill (only `install-openclaw-to-yc` exists today)
