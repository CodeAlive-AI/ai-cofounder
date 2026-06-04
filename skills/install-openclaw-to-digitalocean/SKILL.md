---
name: install-openclaw-to-digitalocean
description: >-
  Autonomously set up an OpenClaw bot on a fresh DigitalOcean Droplet
  (Ubuntu 24.04, default region Frankfurt fra1). Asks the user for exactly
  two things — a Telegram bot token and one of three LLM access options
  (Anthropic API key, OpenRouter API key, or OpenAI Codex OAuth via ChatGPT
  Plus/Pro subscription) — then handles a DigitalOcean API token check,
  SSH-key upload, Droplet creation, Cloud Firewall, OS hardening, OpenClaw
  install, CEO AI OS workspace seeding, Telegram pairing, chat_id
  auto-detection, and bot-reply verification on its own. The only other
  actions the user performs are pasting a DigitalOcean API token once,
  pressing /start in Telegram once, and (if Codex) confirming a device code
  on auth.openai.com. Use when the user says install OpenClaw to
  DigitalOcean, deploy OpenClaw to a DO Droplet, set up my CEO bot on
  DigitalOcean, spin up an OpenClaw droplet, create a DigitalOcean VM for
  OpenClaw, or any close paraphrase. Targets a ~15-minute end-to-end run for
  non-DevOps users (founders, CEOs, marketing leads). For Yandex Cloud
  Kazakhstan use install-openclaw-to-yc instead; for a local-machine install
  use openclaw/install.sh. Companion skill openclaw-guide is required;
  openclaw-user-onboarding is auto-invoked after Step 5 to collect the five
  basic facts about the user (identity, focus, style, tools, anti-patterns)
  and write them into USER.md so the bot is useful from message one.
license: MIT
metadata:
  version: 0.1.3
---

# Install OpenClaw to DigitalOcean

A wizard that takes a non-DevOps user from zero to a working OpenClaw bot on a fresh DigitalOcean Droplet in ~15 minutes. **The user does exactly three-or-four things**: paste a DigitalOcean API token, paste a Telegram bot token, paste an LLM API key (or say "Codex" for OAuth via ChatGPT subscription), press `/start` in Telegram once, and — only for Codex — confirm a device code on auth.openai.com. Everything else is silent.

> This is the DigitalOcean sibling of `install-openclaw-to-yc`. The flow, the cloud-init, the hardening, the Telegram pairing and the verification are identical. What differs is the provider plumbing: `doctl` instead of `yc`, an API token instead of a Yandex OAuth dance, a Cloud Firewall instead of a security group, and **no cheap "stop the VM" pause** (DO bills powered-off Droplets — see Step 6 / `references/04`).

## Operating principles (the "don't bother the user" rules)

These rules override the rest of the document. Read them first.

1. **Three inputs. Total.** The only things you ask the user for are the **DigitalOcean API token** (Step 0), the **Telegram bot token**, and the **LLM access** (one of three options — see Step 1). Everything else — Droplet name, region, image, size, SSH key, firewall ingress, **chat_id** — is decided silently from safe defaults or auto-detected.
2. **Never ask "are you sure"** for actions inside this wizard's own scope (creating its own Droplet, its own firewall, its own bot pairing). Only confirm if you're about to destroy something the user might want to keep (an existing Droplet with the same name).
3. **Never show shell commands, flags, paths, or stack traces** to the user unless they explicitly ask "what did you run?". Progress is plain language: "Создаю Droplet…", "Ставлю OpenClaw…", "Проверяю что бот отвечает…".
4. **Validate inputs upfront** with a one-call test (`doctl account get`, Telegram `/getMe`, LLM key probe). Don't burn 15 minutes on a Droplet bootstrap with a bad key.
5. **Auto-fix prerequisites silently** when it's safe — install `doctl`, generate an SSH key, upload it to the account. Only stop and ask the user when something *can't* be done without their input (the API token itself, no payment method on the account).
6. **One language — and the bot speaks it too.** If the user wrote to the agent in Russian, all wizard prompts are in Russian, **and** the OpenClaw bot itself is configured to reply in Russian. Detect the user's language from their first few messages, pass it through to cloud-init as `{{USER_LANGUAGE}}` (ISO 639-1: `ru`/`en`/`kk`/...), and the bootstrap script appends a localization block to the bot's `USER.md`. Default if you can't tell: `ru` (workshop audience).
7. **No emojis** in user-facing text unless the user used them first.

## Do NOT ask the user for these (hard override)

| Don't ask | Why | What to do instead |
|---|---|---|
| **Telegram chat_id** | Auto-detected in Step 4 from `getUpdates` after the user presses `/start`. Asking makes the user open `@userinfobot`, copy a number, paste — pure friction. | Poll `https://api.telegram.org/bot<TOKEN>/getUpdates` every 2s in Step 4. Pluck `result[0].message.chat.id`. |
| **Droplet name** | Default is `openclaw-bot`. If taken, append `-<random4>`. | Set silently. Tell user the name only in the final summary. |
| **SSH IP restriction** | There is none. SSH is open to `0.0.0.0/0` + `::/0` (no per-IP lock) because users and the automation AI agent connect from dynamic IPs and the agent makes frequent SSH calls that must never be IP-banned. The security control is **key-only auth + fail2ban** (fail2ban bans only on FAILED auths). | Open SSH to all silently. |
| **Region / image / Droplet size** | Defaults: `fra1` (Frankfurt — lowest latency for EU/CIS/KZ), `ubuntu-24-04-x64`, `s-2vcpu-4gb`. | Don't surface to user unless they ask. |
| **Linux username on the Droplet** | Always `openclaw`. | Use it without asking. |
| **Which SSH key to upload** | `~/.ssh/id_ed25519.pub`, auto-generated if missing, uploaded to the DO account idempotently by fingerprint. | Handle in Step 0f. |
| **Anthropic / OpenRouter / OpenAI billing balance** | Caught upfront in Step 1 by a probe call. If insufficient, fail fast with a one-line message. | Probe call before Droplet create. |

If you catch yourself drafting a question outside the three allowed inputs, re-read this section. The wizard's whole point is autonomy.

## When to invoke

Trigger on: "install OpenClaw on DigitalOcean", "deploy OpenClaw to a DO droplet", "set up my CEO bot on DigitalOcean", "spin up an OpenClaw droplet", "поставь openclaw на digitalocean", "разверни бота на DigitalOcean", "у меня есть DO токен, подними бота", and close paraphrases.

Do NOT use this skill for:
- **Yandex Cloud Kazakhstan** → use `install-openclaw-to-yc` (hard-coded for the kz1-a realm).
- **Local-machine OpenClaw install** → use `openclaw/install.sh` in the ceo-ai-os repo (the user runs it on their laptop).
- **AWS / GCP / Azure** → out of scope.
- Adding a second agent or a second bot to an existing OpenClaw Droplet → out of scope.

## The "dangerous install" disclaimer — say this once, early

OpenClaw is an agent runtime with **full shell access** on the box it runs on, it stores provider credentials in **plaintext** under `~/.openclaw/`, and the gateway executes whatever the LLM decides to run. That is the deal everywhere OpenClaw is installed — it is not specific to DigitalOcean. This wizard mitigates the blast radius (dedicated non-root user, key-only SSH auth + fail2ban brute-force defense, ufw, systemd sandboxing, loopback-only gateway) but it does **not** make the install "safe" in an absolute sense.

Surface this **once**, in plain language, the first time you create real infrastructure (right before Step 2), then move on — don't nag:

> Небольшое предупреждение: OpenClaw — это агент с полным доступом к своей VM, ключи он хранит на диске в открытом виде. Я разверну его на отдельной изолированной машине, доступ по SSH только по ключу (паролей нет) + fail2ban против перебора, и захардижу систему — но держи на этой VM только то, что не страшно потерять. Не клади на неё доступы к проду или личные секреты. Продолжаю.

Full security rationale and the threat model live in `references/02-network-and-security.md`.

## Inputs (the only three questions you ask)

| # | Input | How user gets it (paste this verbatim in your prompt) |
|---|---|---|
| 0 | **DigitalOcean API token** | Open [cloud.digitalocean.com/account/api/tokens](https://cloud.digitalocean.com/account/api/tokens) → **Generate New Token** → name it `openclaw`, scope **Full Access** (or custom: read+write on Droplet, SSH Key, Firewall), expiry 90 days is fine → copy the `dop_v1_…` string. Asked once in Step 0. |
| 1 | **Telegram bot token** | Open [@BotFather](https://t.me/BotFather) → `/newbot` → pick any display name → pick a username ending in `bot` → copy the token (looks like `7892341234:AAFhJk2mNopq…`). |
| 2 | **LLM access** — one of three options | See the table below. The user picks ONE option; the wizard auto-detects which from the format of what they paste. |

### LLM access options (the user picks one)

| Option | What user pastes | Detection signal | Cost / requirements |
|---|---|---|---|
| **A. Anthropic API key** | Key starting with `sk-ant-…` from [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) | Prefix `sk-ant-` | ≥$5 credit on [console.anthropic.com/settings/billing](https://console.anthropic.com/settings/billing). Best raw quality. Pay-as-you-go (~$3 per million input tokens for Sonnet 4.6). |
| **B. OpenRouter API key** | Key starting with `sk-or-…` from [openrouter.ai/keys](https://openrouter.ai/keys) | Prefix `sk-or-` | ≥$5 credit on OpenRouter. Unified access to Anthropic + OpenAI + 200 other models through one key, ~5% markup over native. |
| **C. OpenAI Codex via ChatGPT** | The literal word `Codex` (or `codex`, `chatgpt`, `oauth`) — **not** a key | Token doesn't start with `sk-` | Active **ChatGPT Plus ($20/mo)** or **Pro ($200/mo)** subscription. After bootstrap, the wizard prompts the user once on auth.openai.com with a device code — no API key, no metered billing. Plus gives `gpt-4o`/`o3`; Pro gives `gpt-5.5`. |

Order of recommendation in the prompt: **A → C → B** for first-timers.

Everything below is decided **without asking the user**:

| Decided silently | Value | How |
|---|---|---|
| Droplet name | `openclaw-bot` (or `openclaw-bot-<random4>` if taken) | If `doctl compute droplet list --format Name --no-header` contains `openclaw-bot`, append a random 4-char suffix. |
| Region | `fra1` (Frankfurt) | Lowest latency to EU / CIS / Kazakhstan. Fallbacks `ams3`, then `blr1`. DigitalOcean has no Central-Asia DC. |
| OS image | `ubuntu-24-04-x64` | Stock DO Ubuntu 24.04 LTS. |
| Droplet size | `s-2vcpu-4gb` (2 vCPU / 4 GB / 80 GB SSD, ~$24/mo) | Matches the reference 4 GB deployment. Budget option `s-1vcpu-2gb` (~$12/mo) works too — the cloud-init adds 2 GB swap for it. |
| Public IPv4 | yes (default on Basic Droplets) | Simplest path for SSH from anywhere. |
| Linux user | `openclaw` (sudo, no password) | Created by cloud-init. |
| SSH key | `~/.ssh/id_ed25519.pub` (auto-generate if missing), uploaded to the DO account | `ssh-keygen -t ed25519 …` if absent; `doctl compute ssh-key import` (idempotent by fingerprint). |
| Firewall SSH ingress | `0.0.0.0/0` + `::/0` (open, no per-IP lock) | Users / automation agent have dynamic IPs and the agent SSHes frequently — IP-locking would break it. Controls are key-only auth + fail2ban. |
| Outbound | open to anywhere | OpenClaw needs Anthropic, Telegram, OpenAI, OpenRouter, GitHub, npm — locking down by domain is fragile. |
| Telegram chat_id | **auto-detected** after first `/start` | Poll `getUpdates`. Never asked. |
| Primary / fallback models | Depends on chosen LLM option (table below) | |

### Default models per LLM option

| Option | `agents.defaults.model.primary` | `agents.defaults.model.fallbacks` |
|---|---|---|
| A. Anthropic | `anthropic/claude-sonnet-4-6` | `["anthropic/claude-haiku-4-5"]` |
| B. OpenRouter | `openrouter/moonshotai/kimi-k2.6` | `["openrouter/openai/gpt-5.5", "openrouter/anthropic/claude-haiku-4-5"]` |
| C. OpenAI Codex | `openai-codex/gpt-5.5` (Pro) or `openai-codex/gpt-4o` (Plus only) | `["openai-codex/gpt-4o"]` |

For C, the wizard probes the user's subscription tier after OAuth completes — if `gpt-5.5` isn't in `openclaw models list`, fall back to `gpt-4o` as primary.

## Wizard flow

### Step 0 — Silent preflight + the one mandatory prompt (the API token)

Run in order. Each block has a silent auto-fix path; only fall through to a user prompt when no silent path exists.

**DigitalOcean basics — much simpler than Yandex Cloud:**

- DigitalOcean is a **single global API** — `https://api.digitalocean.com`. There is no per-region endpoint, no cloud-id / folder-id, no realm split. The entire "four properties must move together" complexity from the YC skill does not exist here. One API token scopes the whole account.
- `doctl` stores credentials in **contexts** (`~/.config/doctl/config.yaml`). Use a dedicated context `openclaw` so you never clobber the user's existing `default` context.
- A Droplet that is **powered off still bills** on DigitalOcean. There is no cheap "stopped" state like YC. To stop paying you must destroy the Droplet (optionally snapshot first). Tell the user this only at Step 6 / teardown — not upfront.

**a. Companion skill `openclaw-guide` must be loaded.** Probe the agent's skill loader. If absent, run `npx skills add CodeAlive-AI/ceo-ai-os@openclaw-guide -g` silently. If `npx` is unavailable, tell the user (one sentence) to install both skills manually, then stop.

**b. `doctl` CLI installed.** `doctl version`. If missing, install silently for the platform:

```bash
# macOS (Homebrew is the common case on a founder's laptop)
brew install doctl 2>/dev/null \
  || {
    # Fallback: download the release tarball for the arch
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')      # darwin | linux
    ARCH=$(uname -m); case "$ARCH" in x86_64) ARCH=amd64;; arm64|aarch64) ARCH=arm64;; esac
    VER=$(curl -fsSL https://api.github.com/repos/digitalocean/doctl/releases/latest | jq -r .tag_name | sed 's/^v//')
    curl -fsSL "https://github.com/digitalocean/doctl/releases/download/v${VER}/doctl-${VER}-${OS}-${ARCH}.tar.gz" \
      | tar -xz -C "$HOME/.local/bin" 2>/dev/null || tar -xz -C /tmp && sudo mv /tmp/doctl /usr/local/bin/
  }
doctl version
```

**c. Authenticate a dedicated `openclaw` context.** This is **the only mandatory user prompt in Step 0**.

First, check whether a working context already exists (the user may have used `doctl` before):

```bash
if doctl account get --context openclaw --format Email,Status --no-header >/dev/null 2>&1; then
  DOCTL_CTX="--context openclaw"      # already good
elif doctl account get --format Email,Status --no-header >/dev/null 2>&1; then
  DOCTL_CTX=""                        # default context works — reuse it, don't clobber
else
  NEED_TOKEN=1                        # fresh — must ask
fi
```

If `NEED_TOKEN=1`, ask the user once. Say exactly:

> Чтобы создать сервер на DigitalOcean, мне нужен API-токен (один раз).
>
> Открой https://cloud.digitalocean.com/account/api/tokens → **Generate New Token** → назови `openclaw`, оставь **Full Access**, срок 90 дней → скопируй строку, начинается на `dop_v1_…` и пришли мне. Я её никуда не сохраняю и не показываю обратно.

After receiving the token, initialize the dedicated context non-interactively and validate it in one call:

```bash
doctl auth init --context openclaw --access-token "$DO_TOKEN" >/dev/null 2>&1 \
  || { say "Токен не подошёл — проверь, что скопировал целиком (начинается на dop_v1_)."; stop; }
DOCTL_CTX="--context openclaw"

# One read call confirms the token works AND the account can create Droplets.
ACCT=$(doctl account get $DOCTL_CTX --output json)
STATUS=$(echo "$ACCT" | jq -r '.status')        # expect "active"
LIMIT=$(echo  "$ACCT" | jq -r '.droplet_limit')  # 0 → no payment method on file
[[ "$STATUS" != "active" ]] && { say "Аккаунт DigitalOcean не активен (status=$STATUS). Проверь почту/биллинг на cloud.digitalocean.com."; stop; }
[[ "${LIMIT:-0}" == "0" ]] && { say "К аккаунту DigitalOcean не привязан способ оплаты — лимит Droplet'ов = 0. Добавь карту на cloud.digitalocean.com/account/billing и запусти меня снова."; stop; }
```

From here on, **every `doctl` call carries `$DOCTL_CTX`** so we never touch the user's default context.

**d. SSH key — local.** `ls ~/.ssh/id_ed25519.pub`. If missing: silently `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "openclaw-do-$(date +%Y%m%d)"`.

**e. SSH key — uploaded to the DO account (idempotent by fingerprint).** Unlike Yandex Cloud (where you pass the pubkey file straight to `instance create`), DigitalOcean requires the key to be **registered in the account first**, then referenced by fingerprint at Droplet-create time.

```bash
# DO identifies keys by MD5 fingerprint (colon-hex). Compute the local key's.
FP=$(ssh-keygen -E md5 -lf ~/.ssh/id_ed25519.pub | awk '{print $2}' | sed 's/^MD5://')

# Already uploaded?
if doctl compute ssh-key list $DOCTL_CTX --format FingerPrint --no-header | grep -qx "$FP"; then
  SSH_FP="$FP"
else
  SSH_FP=$(doctl compute ssh-key import "openclaw-$(date +%Y%m%d)" \
            --public-key-file ~/.ssh/id_ed25519.pub \
            $DOCTL_CTX --format FingerPrint --no-header)
fi
# $SSH_FP is what we pass to `droplet create --ssh-keys`.
```

If `ssh-key import` errors with "SSH key is already in use on your account" (a 422 when the same key was uploaded under a different name), fall back to the fingerprint from the list — it's already there.

**f. Existing Droplet with the same name.** `doctl compute droplet list $DOCTL_CTX --format Name --no-header | grep -qx openclaw-bot`. If found, ask once: "У тебя уже есть Droplet 'openclaw-bot' — поставить новый под именем `openclaw-bot-XXXX`?" Default yes; pick a random 4-char suffix.

Do not print anything to the user about (a)-(f) if everything passed silently. Move to Step 1.

### Step 1 — Ask the two remaining questions (Telegram + LLM)

In **one** message, in the user's language:

> Отлично, доступ к DigitalOcean есть. Теперь две вещи для самого бота (~5 минут).
>
> **1) Telegram bot token.** Открой @BotFather в Telegram → отправь `/newbot` → придумай имя → придумай username, заканчивающийся на `bot` → BotFather пришлёт токен. Пришли его мне.
>
> **2) Доступ к LLM — выбери ОДИН из трёх вариантов:**
>
>   **A) Anthropic API ключ** (рекомендую первым, лучшее качество)
>   https://console.anthropic.com/settings/keys → Create Key. Начинается на `sk-ant-`. На billing должно быть ≥$5.
>
>   **B) OpenRouter API ключ** (один ключ к 200+ моделям)
>   https://openrouter.ai/keys → Create Key. Начинается на `sk-or-`. Баланс ≥$5.
>
>   **C) OpenAI Codex через ChatGPT подписку** (бесплатно если уже платишь Plus/Pro)
>   Не нужен ключ. Просто напиши слово **«Codex»**. После установки я попрошу ввести 8-символьный код на auth.openai.com — один раз.
>
> Пришли токен Telegram и один из трёх. Хоть в одном сообщении, хоть по отдельности. Я никуда не сохраняю значения.

**Detect the LLM provider from what the user pasted:**

```bash
case "$LLM_INPUT" in
  sk-ant-*) LLM_PROVIDER=anthropic ;;
  sk-or-*)  LLM_PROVIDER=openrouter ;;
  Codex|codex|CODEX|ChatGPT|chatgpt|OpenAI*|"openai codex"|OAuth|oauth)
    LLM_PROVIDER=openai-codex; LLM_API_KEY="" ;;
  *) say "Не распознал — это Anthropic-ключ (sk-ant-), OpenRouter-ключ (sk-or-) или слово 'Codex'?" && reprompt ;;
esac
```

**Validate the credentials** (don't burn 15 minutes on a bad key):

```bash
# Telegram token — always validate
BOT_USERNAME=$(curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe" | jq -er '.result.username') \
  || (say "Telegram токен не прошёл проверку. Скопируй его ещё раз из @BotFather." && stop)

case "$LLM_PROVIDER" in
  anthropic)
    curl -fsS https://api.anthropic.com/v1/messages \
      -H "x-api-key: ${LLM_API_KEY}" -H "anthropic-version: 2023-06-01" -H "content-type: application/json" \
      -d '{"model":"claude-haiku-4-5","max_tokens":1,"messages":[{"role":"user","content":"ok"}]}' \
      | jq -er '.content' >/dev/null \
      || (say "Anthropic ключ не работает или нет кредита. Проверь на console.anthropic.com." && stop) ;;
  openrouter)
    curl -fsS https://openrouter.ai/api/v1/auth/key -H "Authorization: Bearer ${LLM_API_KEY}" \
      | jq -er '.data.usage != null' >/dev/null \
      || (say "OpenRouter ключ не прошёл проверку. Перепроверь на openrouter.ai/keys." && stop)
    BAL=$(curl -fsS https://openrouter.ai/api/v1/auth/key -H "Authorization: Bearer ${LLM_API_KEY}" | jq -r '.data.limit_remaining // 0')
    [[ "$BAL" == "0" ]] && say "На OpenRouter $0 кредита. Бот не сможет отвечать. Пополни на openrouter.ai/credits." ;;
  openai-codex)
    say "Хорошо, после установки покажу 8-символьный код для https://auth.openai.com/codex/device. Это разовое действие." ;;
esac
```

`BOT_USERNAME` is captured here for the one-click chat link in Step 5.

### Step 2 — Silent Droplet creation

Show the one-time "dangerous install" disclaimer (above) now, then proceed silently.

**a. Render the cloud-init file.** Substitute these placeholders (no `TELEGRAM_CHAT_ID` — auto-detected in Step 4):

- `{{SSH_PUBLIC_KEY}}` — content of `~/.ssh/id_ed25519.pub`.
- `{{TELEGRAM_BOT_TOKEN}}` — from Step 1.
- `{{USER_LANGUAGE}}` — detected language code.
- `{{LLM_ENV_LINE}}` — depends on the chosen provider:

  | Provider | Substituted line |
  |---|---|
  | anthropic | `ANTHROPIC_API_KEY=<key>` |
  | openrouter | `OPENROUTER_API_KEY=<key>` |
  | openai-codex | *(empty string — OAuth fills the profile after Step 3.5)* |

Write to `/tmp/openclaw-cloud-init.yaml` with mode 600.

**b. Create the Droplet.** `--wait` blocks until it's active, then we read the public IP. Try `fra1`; if the size/region pairing is unavailable, fall back to `ams3`.

```bash
DROPLET_ID=$(doctl compute droplet create "$VM_NAME" \
  --region fra1 \
  --image ubuntu-24-04-x64 \
  --size s-2vcpu-4gb \
  --ssh-keys "$SSH_FP" \
  --user-data-file /tmp/openclaw-cloud-init.yaml \
  --enable-monitoring \
  --tag-name openclaw \
  --wait \
  $DOCTL_CTX --format ID --no-header 2>/tmp/openclaw-droplet.err) \
  || true

# Region/size fallback
if [[ -z "$DROPLET_ID" ]] && grep -qiE "not available|can only be created|region" /tmp/openclaw-droplet.err; then
  DROPLET_ID=$(doctl compute droplet create "$VM_NAME" \
    --region ams3 --image ubuntu-24-04-x64 --size s-2vcpu-4gb \
    --ssh-keys "$SSH_FP" --user-data-file /tmp/openclaw-cloud-init.yaml \
    --enable-monitoring --tag-name openclaw --wait \
    $DOCTL_CTX --format ID --no-header)
fi
[[ -z "$DROPLET_ID" ]] && { say "Не удалось создать Droplet. Вот что вернул DigitalOcean:"; cat /tmp/openclaw-droplet.err; stop; }

IP=$(doctl compute droplet get "$DROPLET_ID" $DOCTL_CTX --format PublicIPv4 --no-header)
```

If the create errors with `you are not authorized` or a payment message — that's the billing case Step 0c should have caught; surface it: "Похоже, к аккаунту DigitalOcean не привязана карта. Открой cloud.digitalocean.com/account/billing, добавь способ оплаты и запусти меня снова." Stop.

**c. Create + attach the Cloud Firewall.** DigitalOcean firewalls are a separate resource attached by Droplet ID. Default-deny inbound except SSH; allow all outbound. SSH is intentionally open to all (`0.0.0.0/0` + `::/0`, no per-IP lock) because users and the automation AI agent connect from dynamic IPs and the agent makes frequent SSH calls that must never be IP-banned or throttled. The security controls are **key-only auth + fail2ban** (fail2ban bans only on FAILED auths, never an authenticated key user).

```bash
doctl compute firewall create \
  --name "${VM_NAME}-fw" \
  --inbound-rules "protocol:tcp,ports:22,address:0.0.0.0/0,address:::/0" \
  --outbound-rules "protocol:tcp,ports:all,address:0.0.0.0/0,address:::/0 protocol:udp,ports:all,address:0.0.0.0/0,address:::/0 protocol:icmp,address:0.0.0.0/0,address:::/0" \
  --droplet-ids "$DROPLET_ID" \
  $DOCTL_CTX --format ID --no-header
```

Note: the gateway port `18789` is **not** opened — it binds to loopback only and we reach it over SSH. The host-level `ufw` inside cloud-init is a second, independent layer behind this Cloud Firewall (defense in depth).

Then one sentence to the user:

> Сервер создан. Ставлю OpenClaw — займёт около 10 минут. Можешь пока заварить чай.

### Step 3 — Wait silently for cloud-init

Poll every 30 seconds (DO's stock image creates no `ubuntu`/`root`-only barrier; our cloud-init makes `openclaw`):

```bash
ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 openclaw@$IP \
  'test -f /var/lib/openclaw-bootstrap-done && echo READY || echo PENDING'
```

Don't spam the user with raw log lines. Every ~3 minutes, emit one warm progress sentence based on the current phase from `tail -1 /var/log/openclaw-bootstrap.log`:

| If the log mentions | Tell the user |
|---|---|
| swap / firewall / hardening | "Настраиваю файрвол и SSH" |
| nodesource / Node | "Ставлю Node.js" |
| `npm install` openclaw | "Качаю OpenClaw" |
| ceo-ai-os / install.sh | "Загружаю CEO-скиллы" |
| openclaw onboard / config | "Подключаю Telegram и LLM" |
| systemd / health | "Запускаю бот" |

Cap at 15 minutes. If still not ready, surface to the user ("Что-то пошло не так на VM, проверяю логи") and jump to `references/04-troubleshooting.md`.

### Step 3.5 — OAuth device-code flow (ONLY if `LLM_PROVIDER=openai-codex`)

Skip this entire step for `anthropic` and `openrouter`.

For `openai-codex`, run the device-code OAuth flow over SSH with a forced TTY:

```bash
ssh -tt -o ServerAliveInterval=30 openclaw@$IP \
  "openclaw models auth login --provider openai-codex --device-code" | tee /tmp/openclaw-oauth.log
```

The CLI prints a URL (`https://auth.openai.com/codex/device`) and an 8-char code (`ABCD-1234`). Extract both (match generously — formats shift across releases). Show the user **one** clean message:

> Последний шаг — подключи бота к ChatGPT.
>
> Открой: **https://auth.openai.com/codex/device**
> Введи код: **ABCD-1234**
>
> Войди под аккаунтом ChatGPT (Plus или Pro) и разреши доступ. Жду до 15 минут.

The SSH session blocks until the user completes the flow. When it exits 0, OpenClaw wrote `auth-profiles.json`.

**Known pitfall (issue #74212, 2026-05):** in some SSH sessions OpenClaw masks the code as `[shown on the local device only]`. Retry with `ssh -tt`; if still masked, run the auth command in a fresh interactive `ssh openclaw@$IP` session, read the code there, resume.

After the profile is written, probe the subscription tier and set the model:

```bash
HAS_GPT55=$(ssh openclaw@$IP "openclaw models list --provider openai-codex --format json" \
  | jq -r '.[] | select(.id=="gpt-5.5") | .id // empty')
if [[ "$HAS_GPT55" == "gpt-5.5" ]]; then
  ssh openclaw@$IP "openclaw config set agents.defaults.model.primary 'openai-codex/gpt-5.5' && openclaw config set agents.defaults.model.fallbacks '[\"openai-codex/gpt-4o\"]'"
else
  ssh openclaw@$IP "openclaw config set agents.defaults.model.primary 'openai-codex/gpt-4o' && openclaw config set agents.defaults.model.fallbacks '[]'"
fi
ssh openclaw@$IP "systemctl --user restart openclaw-gateway"
```

If after 15 minutes there's still no `openai-codex` profile: tell the user "не получилось войти в ChatGPT, давай ещё раз" and re-run the auth command. Don't destroy the Droplet — only the OAuth step needs retrying.

### Step 4 — One-click chat link + auto-pair

When `/var/lib/openclaw-bootstrap-done` exists, the gateway is up in `pairing` mode. **This is where wizards historically fail silently** — read this whole section.

#### What actually happens when the user presses /start

1. Telegram delivers `/start` to the bot.
2. OpenClaw enforces `dmPolicy=pairing` — it calls `issuePairingChallenge()`, records a pending request, **and the bot replies to the user with the pairing code + instructions**. The user sees this; they shouldn't reply to it.
3. The pending request lives in `openclaw pairing list telegram --format json` until approved or expired.

#### Pre-emptive heads-up (send BEFORE asking them to press /start)

> Бот готов. Открой его в Telegram: **https://t.me/{{BOT_USERNAME}}** и нажми `/start`.
>
> Бот пришлёт короткое сообщение с кодом — **ничего с ним делать не надо, я подтвержу доступ автоматически за пару секунд**. После этого пиши боту как обычно.

#### Poll for chat_id

```bash
for i in $(seq 1 150); do   # 150 × 2s = 5 minutes
  CHAT_ID=$(curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?timeout=2" \
    | jq -r '.result[0].message.chat.id // empty')
  [[ -n "$CHAT_ID" ]] && break
  sleep 2
done
[[ -z "$CHAT_ID" ]] && fail "Пользователь не нажал /start за 5 минут"
```

#### Approve the pairing (the part the old wizard broke)

The pending request schema (verified against `src/gateway/protocol/schema/devices.ts`) uses **`senderId`** for the Telegram user ID and **`requestId`** for the primary key — **not** `chatId` / `code`. A filter on `.chatId` always returns empty.

```bash
APPROVE_TOKEN=""
for i in $(seq 1 5); do
  APPROVE_TOKEN=$(ssh openclaw@$IP "openclaw pairing list telegram --format json 2>/dev/null" \
    | jq -r --arg cid "$CHAT_ID" '
        .[] | select((.senderId|tostring)==$cid or (.chatId|tostring)==$cid or (.sender // empty|tostring)==$cid)
            | (.requestId // .code // empty)' | head -n1)
  [[ -n "$APPROVE_TOKEN" ]] && break
  sleep 2
done
[[ -z "$APPROVE_TOKEN" ]] && fail "Запрос на pairing не появился — посмотри journalctl на VM"

ssh openclaw@$IP "openclaw pairing approve telegram '$APPROVE_TOKEN'" \
  || fail "openclaw pairing approve failed (token=$APPROVE_TOKEN)"
```

#### Lock down + persist chat_id

```bash
ssh openclaw@$IP "
  openclaw config set channels.telegram.dmPolicy allowlist
  openclaw config set channels.telegram.allowFrom '[${CHAT_ID}]'
  echo 'TELEGRAM_CHAT_ID=${CHAT_ID}' >> /home/openclaw/.openclaw/gateway.env
  systemctl --user restart openclaw-gateway
"
# Wait for /health 200 before Step 5
for i in $(seq 1 30); do
  ssh openclaw@$IP 'curl -fsS -m 3 http://127.0.0.1:18789/health' >/dev/null 2>&1 && break
  sleep 2
done
```

If the user doesn't press `/start` within 5 minutes, poke them once. After 15 minutes of no signal, stop and tell them how to resume.

### Step 5 — Verify the bot answers (do NOT skip), then hand off

The #1 historical failure mode was claiming "done" while the bot was silent. Verification below is **mandatory** — three signals, all must pass.

#### 5a. Trigger a reply

```bash
case "$USER_LANGUAGE" in
  ru) PROBE="Скажи 'привет', чтобы я убедился, что ты отвечаешь." ;;
  kk) PROBE="Сәлем деп жаз — жауап беретіндігіңе көз жеткізейін." ;;
  *)  PROBE="Say 'hi' so I can confirm you're alive." ;;
esac
curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d "chat_id=${CHAT_ID}" -d "text=${PROBE}"
```

#### 5b. Three checks, all required

**Check 1 — Gateway logged an outgoing message** within 90s:

```bash
ssh openclaw@$IP "timeout 90 journalctl --user -u openclaw-gateway -f --no-pager 2>/dev/null \
  | grep -m1 -E 'telegram.*sent|outgoing.*telegram|sendMessage.*ok'"
```

If it times out: gateway accepted inbound but didn't reply. Most likely the LLM provider isn't configured (Codex OAuth didn't finish, or env key empty). Jump to `references/04-troubleshooting.md` §4c-e.

**Check 2 — A bot reply appears in `getUpdates`** within 90s (see YC-derived note in §04: this check can be unreliable in some test setups; fall back on Check 1 + Check 3).

**Check 3 — User confirms.** Ask once: "Бот должен был тебе ответить в Telegram. Ответил?" Wait for "да". If "нет" → `references/04-troubleshooting.md` §4. Never claim success unless all three pass.

#### 5c. If language is wrong

```bash
LOCALE_PACK="/usr/local/share/openclaw-locale-${USER_LANGUAGE}.md"
ssh openclaw@$IP "
  test -f $LOCALE_PACK && cat $LOCALE_PACK >> ~/.openclaw/workspace/USER.md
  openclaw sessions reset --channel telegram --to ${CHAT_ID} 2>/dev/null || true
"
```

Then re-run the probe. If still wrong language, surface to the user — don't loop.

### Step 5.5 — Onboarding (hand off to `openclaw-user-onboarding`)

The bot is alive but anonymous. Hand off to `openclaw-user-onboarding`, which collects five fields (identity, focus, style, tools, anti-patterns), writes `USER.md` on the Droplet, and resets the Telegram session.

Hand-off payload:

| Variable | Source |
|---|---|
| `IP` | Step 2b |
| `CHAT_ID` | Step 4 |
| `BOT_TOKEN` | Step 1 |
| `USER_LANGUAGE` | Step 0 |
| `AGENT_TYPE` | `main` |

Trigger with one line: "Бот живой. Последний шаг — расскажи о себе коротко, чтобы я с первого сообщения был полезным." Then invoke `openclaw-user-onboarding`.

If the user says "пропусти"/"skip": write a minimal placeholder USER.md and proceed — onboarding is not a gate. If the skill isn't loaded: write a placeholder inline and mention it in the final summary.

#### Final hand-off message

Only after all three checks pass:

```
OpenClaw запущен на DigitalOcean.

  Droplet      : openclaw-bot  (fra1, 2 vCPU / 4 GB / 80 GB SSD)
  IP           : 159.x.x.x
  Бот          : @your_bot_name
  LLM          : <one of three lines below>
  Workspace    : CEO AI OS (48 CEO-скиллов)
  Стоимость    : ~$24/мес (Droplet) + LLM по тарифу провайдера
```

LLM line variants:

| Provider | Line |
|---|---|
| anthropic | `LLM          : Anthropic Claude Sonnet 4.6 (API key, ~$3/M tokens)` |
| openrouter | `LLM          : OpenRouter → Moonshot Kimi K2.6 (API key, +5% markup)` |
| openai-codex | `LLM          : OpenAI Codex / gpt-5.5 (ChatGPT Pro)` or `gpt-4o (Plus)` |

```
Что дальше:
  • Просто пиши боту в Telegram — он уже знает кто ты, попробуй: «что у меня сегодня важно?»
  • Стратегические скиллы: «Сделай weekly review» или «Помоги принять решение об X»
  • Обновить профиль: скажи мне «обнови мой профиль для бота»
  • ВАЖНО про деньги: на DigitalOcean выключенный Droplet ВСЁ РАВНО тарифицируется.
    Чтобы перестать платить — Droplet нужно удалить (по желанию — сделать snapshot).
    Поставить «на паузу» дёшево, как в облаках с почасовой остановкой, тут нельзя.
  • Удалить совсем (перестать платить):
    doctl compute droplet delete openclaw-bot --context openclaw --force
    doctl compute firewall delete <fw-id> --context openclaw --force

Если что-то сломается — просто скажи мне «бот молчит» или «openclaw сломался», я разберусь.
```

If the verification ping doesn't get a reply within 60s, run `references/04-troubleshooting.md` §4 silently — don't claim success.

## Auto-recovery (what the wizard does without asking)

| Detected condition | Silent fix |
|---|---|
| `doctl` CLI missing | Install via Homebrew or the GitHub release tarball; verify with `doctl version`. |
| `doctl` default context exists and works | Reuse it — don't create the `openclaw` context, don't ask for a token. |
| No working context at all | Ask for the API token once, `doctl auth init --context openclaw`. |
| Account `status != active` or `droplet_limit == 0` | Stop with a one-line billing message — don't try to create a Droplet that will 422. |
| `~/.ssh/id_ed25519.pub` missing | Generate a new one with no passphrase. |
| SSH key not yet in the DO account | `doctl compute ssh-key import`; if "already in use", reuse the fingerprint from `ssh-key list`. |
| `droplet create` fails with region/size unavailable | Retry once in `ams3`. |
| (SSH IP detection no longer needed) | Firewall ingress is always `0.0.0.0/0` + `::/0` — SSH is intentionally open to all so the automation agent on a dynamic IP is never IP-banned; key-only auth + fail2ban are the controls. Nothing to detect. |
| `npm install -g openclaw` failed once | Retry once after 30s. If still fails, escalate. |
| Gateway `/health` non-200 for first 90s | Keep polling — plugins can take that long. Escalate only after 4 minutes. |
| Pairing approval returns "code not found" | Wait 3s, re-list. Telegram sometimes lags. |
| `openclaw pairing list` non-empty but `.chatId` filter empty | Schema field is `.senderId` / `.requestId`. Step 4's defensive filter tries both — don't simplify it. |
| Bot replies in wrong language | `cat` the locale pack again + `openclaw sessions reset`. See Step 5c. |

## DigitalOcean — common trip points (read before debugging)

1. **Powered-off Droplets still bill.** The single biggest DO surprise. `doctl compute droplet-action power-off` stops the OS but you keep paying for the Droplet's reserved CPU/RAM/disk. To actually stop paying: snapshot (optional, ~$0.06/GB/mo) then `droplet delete`. Don't tell the user "just stop it to save money" — that's true on YC, false on DO.
2. **SSH keys must be uploaded to the account first.** Passing a raw pubkey path to `droplet create --ssh-keys` does NOT work — it expects a fingerprint or numeric ID of an **already-registered** key. Always `ssh-key import` (idempotent) before create.
3. **`droplet_limit == 0` means no payment method.** A fresh account with no card has a Droplet limit of 0 and every `create` 422s with an authorization error. Check `doctl account get` first.
4. **Firewall is a separate resource.** Inbound default-deny only takes effect once a Cloud Firewall is **attached** to the Droplet. A Droplet with no firewall is wide open on every port the OS listens on — which is why the cloud-init also runs `ufw` as a second layer.
5. **User-data (cloud-init) is retrievable from the metadata service** at `169.254.169.254/metadata/v1/user-data` for the Droplet's lifetime, and it contains the secrets we injected. There's no API to wipe it. We scrub the on-disk copy; treat the Droplet as holding its own bootstrap secrets and don't share the box.

## Failure modes (when the silent fixes aren't enough)

| Symptom | Where to look |
|---|---|
| `doctl auth init` rejects the token | `references/01-prerequisites.md` §2 — token scope / typo |
| `droplet create` 422 "not authorized" / payment | `references/01-prerequisites.md` §3 — no payment method |
| `droplet create` "size not available in region" | Auto-recovery retries `ams3`; else `references/04-troubleshooting.md` §2 |
| Cloud-init log shows `npm install -g openclaw` failed twice | `references/04-troubleshooting.md` §2 |
| `openclaw gateway status` shows `RPC probe: failed` after 4 min | `references/04-troubleshooting.md` §3 |
| User pressed `/start` but `getUpdates` returns no chat | `references/04-troubleshooting.md` §4a-b |
| Bot pairs but doesn't reply | `references/04-troubleshooting.md` §4c-e (key, credit, model) |
| SSH `Permission denied (publickey)` | `references/04-troubleshooting.md` §5 |
| Forgot the IP / lost SSH | `references/04-troubleshooting.md` §6 |
| Worried about cost / wants to stop paying | `references/04-troubleshooting.md` §7 (destroy, not power-off) |

For everything else: dump `/var/log/openclaw-bootstrap.log` and `journalctl --user -u openclaw-gateway -n 200` from the Droplet, surface to the user as "вот что я вижу, давай разбираться", do not guess.

## References

- `references/01-prerequisites.md` — doctl install, API token + contexts, SSH key upload, account/payment checks.
- `references/02-network-and-security.md` — Cloud Firewall rules, public-IP rationale, hardening choices, the "dangerous install" threat model.
- `references/03-openclaw-config.md` — Telegram pairing flow, all three LLM providers, workspace seeding.
- `references/04-troubleshooting.md` — failure modes with copy-paste fixes (incl. the power-off-still-bills trap).
- `references/05-marketplace-and-workshop.md` — DO Marketplace 1-click alternative (and why automation skips it) + workshop shared-token mode.
- `scripts/cloud-init.yaml` — the full Droplet bootstrap (swap, Node, OpenClaw, hardening, ceo-ai-os workspace, systemd user service).

## Companion skills

| Skill | Required? | Role |
|---|---|---|
| `openclaw-guide` | **required** | Loaded by Step 0a; owns all post-install consultation (channels, use cases, debugging). The wizard refuses to start without it. |
| `openclaw-user-onboarding` | recommended | Auto-invoked at Step 5.5 to collect five user facts and write USER.md. If missing, Step 5.5 falls back to a placeholder. |
| `install-openclaw-to-yc` | sibling | Same wizard for Yandex Cloud Kazakhstan. Use that one when the user wants the KZ realm / tenge billing instead of DigitalOcean. |

Joint install:

```bash
npx skills add CodeAlive-AI/ceo-ai-os@install-openclaw-to-digitalocean -g
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-guide                    -g   # required
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-user-onboarding          -g   # recommended
```

## Consulting after install — delegate, don't duplicate

When the user asks anything **not** about install (channel setup, use cases, debugging an existing bot, adding MCP servers, multi-agent), read the matching `openclaw-guide/references/<file>.md` first — don't answer from memory. This skill's job ends after Step 5.

| User asks about | Read first |
|---|---|
| Adding WhatsApp / Slack / Discord / iMessage | `openclaw-guide/references/channels.md` |
| Daily brief, research workflow, decision playbook | `openclaw-guide/references/use-cases.md` |
| Adding CodeAlive search to the bot | `openclaw-guide/references/codealive-context-engine.md` |
| Bot stopped responding, OAuth re-auth, memory full | `openclaw-guide/references/06-troubleshooting.md` |
| Cron / heartbeat / scheduled jobs | `openclaw-guide/references/03-cron-heartbeat.md` |

## What this skill does NOT cover

- Multi-agent setups (two agents on one Droplet) — out of scope.
- WhatsApp / Discord / Slack channels — Telegram only here; see `openclaw-guide/references/channels.md`.
- Use-case design (morning brief, research, decision playbooks) — see `openclaw-guide/references/use-cases.md`.
- Backup, snapshots, and migration beyond the teardown note — separate skill.
- Production-grade hardening (SELinux, kernel sysctl, SSH cert auth) — overkill for a personal CEO bot.
- DigitalOcean App Platform / Kubernetes deploys — this skill provisions a plain Droplet only.
