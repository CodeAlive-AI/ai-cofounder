---
name: install-openclaw-to-yc
description: >-
  Autonomously set up an OpenClaw bot on a fresh Yandex Cloud VM in Kazakhstan
  (kz1-a, Karaganda). Asks the user for exactly two things — a Telegram bot
  token and one of three LLM access options (Anthropic API key, OpenRouter API
  key, or OpenAI Codex OAuth via ChatGPT Plus/Pro subscription) — then handles
  VM creation, hardening, OpenClaw install, CEO AI OS workspace seeding,
  Telegram pairing, chat_id auto-detection, and bot-reply verification on its
  own. The only other actions the user performs are pressing /start in Telegram
  once and (if Codex) confirming a device code on auth.openai.com. Use when the
  user says install OpenClaw to Yandex Cloud, deploy OpenClaw to YC Kazakhstan,
  set up my CEO bot in YC KZ, I am at OpenClaw workshop and need my own bot,
  create a Yandex Cloud VM for OpenClaw, or any close paraphrase. Targets a
  ~15-minute end-to-end run for non-DevOps users (founders, CEOs, marketing
  leads). Supports two modes of accessing Yandex Cloud — Plan A (the user's
  own YC Kazakhstan account via OAuth) and Plan B (a workshop-key bundle
  provided by the workshop organizer, for participants without their own
  YC account). The mode is auto-detected from the inputs. For local-machine
  OpenClaw install, use openclaw/install.sh in this repo instead. Companion
  skill openclaw-guide is required; prepare-yc-workshop is the matching
  organizer-side skill that produces the bundles consumed in Plan B;
  openclaw-user-onboarding is auto-invoked after Step 5 to collect the
  five basic facts about the user (identity, focus, style, tools,
  anti-patterns) and write them into USER.md so the bot is useful from
  message one.
license: MIT
metadata:
  version: 0.9.0
---

# Install OpenClaw to Yandex Cloud (Kazakhstan)

A wizard that takes a non-DevOps user from zero to a working OpenClaw bot on a fresh Yandex Cloud Kazakhstan VM in ~15 minutes. **The user does exactly two-or-three things**: paste a Telegram bot token, paste an LLM API key (or say "Codex" for OAuth via ChatGPT subscription), press `/start` in Telegram once, and — only for Codex — confirm a device code on auth.openai.com. Everything else is silent.

## Operating principles (the "don't bother the user" rules)

These rules override the rest of the document. Read them first.

1. **Two questions. Total.** The only inputs you ask the user for are the **Telegram bot token** and the **LLM access** (one of three options — see Step 1). Everything else — VM name, zone, image, SSH key, security-group ingress, **chat_id** — is decided silently from safe defaults or auto-detected.
2. **Never ask "are you sure"** for actions inside this wizard's own scope (creating its own VM, its own security group, its own bot pairing). Only confirm if you're about to destroy something the user might want to keep (an existing VM with the same name).
3. **Never show shell commands, flags, paths, or stack traces** to the user unless they explicitly ask "what did you run?". Progress is plain language: "Создаю VM…", "Ставлю OpenClaw…", "Проверяю что бот отвечает…".
4. **Validate inputs upfront** with a one-call test (Telegram `/getMe`, LLM key probe). Don't burn 15 minutes on a VM bootstrap with a bad key.
5. **Auto-fix prerequisites silently** when it's safe — install `yc` CLI, generate an SSH key, switch endpoint to Kazakhstan. Only stop and ask the user when something *can't* be done without their input (`yc init` OAuth login, no billing account).
6. **One language — and the bot speaks it too.** If the user wrote to the agent in Russian, all wizard prompts are in Russian, **and** the OpenClaw bot itself is configured to reply in Russian. Detect the user's language from their first few messages, pass it through to cloud-init as `{{USER_LANGUAGE}}` (ISO 639-1: `ru`/`en`/`kk`/...), and the bootstrap script appends a localization block to the bot's `USER.md`. Default if you can't tell: `ru` (workshop audience).
7. **No emojis** in user-facing text unless the user used them first.

## Do NOT ask the user for these (hard override)

These are the things the wizard has been observed asking by mistake. Don't:

| Don't ask | Why | What to do instead |
|---|---|---|
| **Telegram chat_id** | Auto-detected in Step 4 from `getUpdates` after the user presses `/start`. Asking for it makes the user open `@userinfobot`, copy a number, paste — pure friction. | Poll `https://api.telegram.org/bot<TOKEN>/getUpdates` every 2s in Step 4. Pluck `result[0].message.chat.id`. |
| **VM name** | Default is `openclaw-bot`. If taken, append `-<random4>`. | Set silently. Tell user the name only in the final summary. |
| **SSH IP restriction** | Default is "current laptop IP, lock SSH to it". Detected via `curl https://api.ipify.org`. Fallback `0.0.0.0/0` + fail2ban if detection fails. | Set silently. |
| **Zone / region / subnet / image / VM shape** | All hard-coded for YC Kazakhstan (kz1-a, ubuntu-2404-lts, standard-v3, 2 vCPU / 4 GB / 30 GB). | Don't surface to user. |
| **Linux username on the VM** | Always `openclaw`. | Use it without asking. |
| **Anthropic / OpenRouter / OpenAI billing balance** | Caught upfront in Step 1 by a probe call. If insufficient, fail fast with a one-line message — don't ask "are you sure you topped up?". | Probe call before VM create. |

If you catch yourself drafting a question outside the two allowed inputs, re-read this section. The wizard's whole point is autonomy.

## When to invoke

Trigger on: "install OpenClaw on Yandex Cloud", "set up my bot in YC Kazakhstan", "OpenClaw workshop workshop", "deploy OpenClaw remotely", "поставь себе openclaw", "разверни мне бота в Yandex Cloud", "у меня workshop-ключ", "вот bundle от организатора", and close paraphrases.

Do NOT use this skill for:
- Local-machine OpenClaw install → use `openclaw/install.sh` in this repo (the user runs it on their laptop)
- **Hetzner Cloud** → use `install-openclaw-to-hetzner` (sibling skill, same shape, different CLI)
- AWS / GCP / Azure / other Yandex Cloud regions → this skill is hard-coded for Yandex Cloud Kazakhstan (kz1-a); no sibling skills exist yet for those clouds
- Adding a second agent or a second bot to an existing OpenClaw VM → out of scope
- Preparing the workshop *as an organizer* (creating N folders + keys for participants) → use `prepare-yc-workshop` (the matching organizer-side skill) — this skill is for the *participant*

## Two access modes (Plan A and Plan B)

This skill works in two modes — picked silently at Step 0 from what the user has on hand. The user is shown the choice **only once** in Step 1; after that, both branches converge and the rest of the wizard is identical.

| Mode | When | What the user supplies | Skill does |
|---|---|---|---|
| **Plan A — own YC account** (default) | The user has (or is willing to create) a Yandex Cloud Kazakhstan account. | OAuth token from `oauth.yandex.kz` (asked once in Step 0d). | `yc init`-equivalent on a wizard-owned profile + own cloud-id/folder-id. |
| **Plan B — workshop bundle** | The user is at a workshop, the organizer DM'd them a `bundle-NN.json` file, and they don't want / don't have time to set up their own YC. | Path to the `bundle-NN.json` file the organizer sent them. | Parses the bundle, configures `yc` with the embedded service-account key + cloud-id + folder-id. No OAuth, no personal YC account needed. |

Plan B is recognised by detecting a workshop bundle file in any of these ways (auto-detected in Step 0.5 below):

1. The user pasted a file path that resolves to a JSON whose `$schema` starts with `openclaw-workshop-bundle@`.
2. The user said one of: "у меня workshop-ключ", "вот bundle от организатора", "I have a workshop key", "organizer gave me a key file", "у меня нет своего Yandex Cloud, есть только ключ от воркшопа".
3. A file matching `bundle-*.json` is present in the user's current working directory or `~/Downloads` (offered with a one-line confirmation).

If none match, the wizard defaults to Plan A.

After Step 0.5 the two branches converge — Steps 1, 2, 3, 4, 5 are identical regardless of mode. Plan A and Plan B both end with a working YC profile pointing at one folder; everything downstream just uses that.

## Inputs (the only two questions you ask)

| # | Input | How user gets it (paste this verbatim in your prompt) |
|---|---|---|
| 1 | **Telegram bot token** | Open [@BotFather](https://t.me/BotFather) in Telegram → send `/newbot` → pick any display name → pick a username ending in `bot` → copy the token (looks like `7892341234:AAFhJk2mNopq…`). |
| 2 | **LLM access** — one of three options | See the table below. The user picks ONE option, the wizard auto-detects which one from the format of what they paste. |

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
| VM name | `openclaw-bot` (or `openclaw-bot-<random4>` if taken) | If `yc compute instance get --name openclaw-bot` returns a result, append a random 4-char suffix and try again. |
| Zone | `kz1-a` | Only zone in YC Kazakhstan. |
| Subnet | `default-kz1-a` | Auto-provisioned in any new KZ folder. |
| OS image | `ubuntu-2404-lts` (latest) | From `standard-images` folder. |
| VM shape | `standard-v3`, 2 vCPU, 4 GB RAM, 30 GB SSD | Matches the reference deployment. |
| Public IP | yes, ephemeral IPv4 NAT | Simplest path for SSH from anywhere. |
| Linux user | `openclaw` (sudo, no password) | Created by cloud-init. |
| SSH key | `~/.ssh/id_ed25519.pub` (or auto-generate if missing) | `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""` if absent. |
| SSH ingress | `<current public IP>/32` | `curl -s https://api.ipify.org`. If you can't reach ipify, fall back to `0.0.0.0/0` + fail2ban defense. |
| Outbound | open to anywhere | OpenClaw needs Anthropic, Telegram, OpenAI, OpenRouter, etc. — locking down by domain is fragile. |
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

**Critical Yandex Cloud Kazakhstan rules** — read before touching `yc`:

- KZ has its own endpoint `api.yandexcloud.kz:443`. The Russian endpoint `api.cloud.yandex.net:443` and the KZ endpoint serve **different** clouds, folders, and OAuth realms. Mixing them is the #1 cause of "wizard says no billing / no cloud" when both exist.
- Setting `yc config set endpoint api.yandexcloud.kz:443` **does NOT** auto-update `cloud-id` or `folder-id`. If you only flip the endpoint and don't re-set cloud-id/folder-id, every subsequent `yc compute / vpc / resource-manager` command will fail with NotFound, because those IDs belong to the RU realm.
- The KZ endpoint exposes a **smaller command set**: `iam`, `quota-manager`, `resource-manager`, `compute`, `vpc`, `dns`, `managed-kubernetes`. **`yc billing` does NOT exist on the KZ endpoint.** Calling `yc billing account list` always errors out — don't use it for any check.
- Use **named profiles** (`yc config profile create/activate`) instead of editing the active config. The user almost certainly already has profiles for their other clouds — don't clobber them.

**Step 0.5 — Detect mode (Plan A vs Plan B).** Runs **first**, before anything else in Step 0.

Plan B short-circuits steps c, d, e (profile, OAuth, cloud-id/folder-id resolution) because the bundle already has all of that baked in. Plan A keeps them.

Detection order:

1. **Explicit file path** in what the user said. Resolve the path; if it's a readable JSON whose `$schema` field starts with `openclaw-workshop-bundle@`, set `MODE=plan-b` and `BUNDLE_PATH=<path>`.
2. **Phrase match.** If the user wrote any of these (or close paraphrase) in the activation message:
   - "У меня workshop-ключ" / "вот bundle от организатора" / "ключ от воркшопа"
   - "I have a workshop key" / "organizer gave me a key file"
   - "Bundle from the organizer is here:" → followed by path
   - Then ask **one** clarifier: "Где лежит файл `bundle-NN.json` от организатора? (можешь перетащить файл в чат, или просто путь)" — accept the path, validate the `$schema`, set `MODE=plan-b`.
3. **Auto-discovery.** Glob `bundle-*.json` in `$PWD`, `~/Downloads`, `~/Desktop`. If exactly one match whose `$schema` starts with `openclaw-workshop-bundle@`, ask once: "Нашёл workshop-ключ `bundle-NN.json` в `<path>`. Это от организатора? (да / нет)". On "да" → `MODE=plan-b`. On "нет" → continue to next step.
4. **Default.** No bundle detected → `MODE=plan-a`. Don't ask "do you have a workshop key?" upfront — that's friction for the >50% of users who have their own YC and would treat the question as noise.

Schema sanity check on the bundle file:

```bash
SCHEMA=$(jq -r '."$schema" // empty' "$BUNDLE_PATH" 2>/dev/null)
[[ "$SCHEMA" =~ ^openclaw-workshop-bundle@ ]] \
  || { say "Это не похоже на workshop-bundle от организатора. Проверь, что прислали правильный файл."; stop; }

# Required fields
for f in cloud_id folder_id zone endpoint key; do
  jq -er ".${f}" "$BUNDLE_PATH" >/dev/null \
    || { say "В bundle не хватает поля ${f}. Попроси у организатора новый файл."; stop; }
done
```

On any validation failure for Plan B, tell the user in one sentence what's wrong, advise asking the organizer, and stop — don't silently fall back to Plan A. Falling back would burn 10 minutes asking for OAuth they don't have.

**If `MODE=plan-b`**: configure `yc` from the bundle and skip directly to Step 0a, then `f`, then `g` (skipping `c`, `d`, `e`):

```bash
# Wizard-owned profile so we don't disturb the user's other yc setups
yc config profile create openclaw-workshop 2>/dev/null || true
yc config profile activate openclaw-workshop

# Carve the SA key into the shape `yc config set service-account-key` expects
KEY_FILE="$(mktemp -t openclaw-sa-key.XXXXXX.json)"
jq '.key' "$BUNDLE_PATH" > "$KEY_FILE"
chmod 600 "$KEY_FILE"

yc config set service-account-key "$KEY_FILE"
yc config set endpoint            "$(jq -r '.endpoint'  "$BUNDLE_PATH")"
yc config set cloud-id            "$(jq -r '.cloud_id'  "$BUNDLE_PATH")"
yc config set folder-id           "$(jq -r '.folder_id' "$BUNDLE_PATH")"
yc config set compute-default-zone "$(jq -r '.zone'      "$BUNDLE_PATH")"

# Verify it actually works — one read call against the configured folder
yc compute zone list --format json | jq -e '.[] | select(.id=="kz1-a")' >/dev/null \
  || { say "Ключ от организатора не работает (или истёк). Напиши организатору: попроси новый bundle."; stop; }
```

Plan-B-specific failure modes:
- **Schema older than `@1`** → bundle predates this version of the skill. Ask user to refresh from organizer; don't try to be smart.
- **Schema newer than what this skill recognises** → also ask for guidance from organizer (they updated `prepare-yc-workshop` past us). Bundle may still work — try the steps above and surface YC errors plainly.
- **`yc compute zone list` returns empty** → key was revoked or folder deleted. Tell the user: "Кажется, организатор уже свернул облако воркшопа. Свяжись с ним."
- **`yc compute zone list` returns `ru-central1-*`** instead of `kz1-a` → bundle's `endpoint` field was wrong. Surface plainly; this is an organizer-side bug.

**On `MODE=plan-b`, skip Step 0c, 0d, 0e entirely** and proceed to 0a → 0b → 0f → 0g. The bundle already contains a valid token-equivalent + cloud-id + folder-id, so re-asking for OAuth would be cruel and pointless.

**On `MODE=plan-a`, proceed normally** through Step 0a-g as written.

---

**a. Companion skill `openclaw-guide` must be loaded.** Probe the agent's skill loader. If it's not present, run `npx skills add CodeAlive-AI/ceo-ai-os@openclaw-guide -g` silently. If `npx` is unavailable, tell the user (one sentence) to install both skills manually, then stop.

**b. `yc` CLI installed.** `yc --version`. If missing: silently `curl -fsSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash -s -- -i $HOME/yandex-cloud -n` and add `~/yandex-cloud/bin` to PATH for this session.

**(c, d, e are Plan A only — skip on `MODE=plan-b`, which configured the profile from the bundle in Step 0.5.)**

**c. Activate a dedicated Kazakhstan profile.** Use a wizard-owned profile so we don't disturb the user's existing setup:

```bash
PROFILE_NAME=openclaw-kz
CURRENT_PROFILE=$(yc config profile list 2>/dev/null | awk '/ACTIVE/{print $1}')

# If the user is already on a profile pointing at KZ, just use it.
if [[ "$CURRENT_PROFILE" != "$PROFILE_NAME" ]]; then
  if [[ "$(yc config get endpoint 2>/dev/null)" != "api.yandexcloud.kz:443" ]]; then
    # Create/activate our own profile rather than mutating the user's active one
    yc config profile list 2>/dev/null | grep -qE "^${PROFILE_NAME}\b" \
      || yc config profile create "$PROFILE_NAME"
    yc config profile activate "$PROFILE_NAME"
  fi
fi
```

After this block, the active profile is either the user's pre-existing KZ-pointing profile (preserve their settings — they know what they're doing) or our fresh `openclaw-kz` profile (we'll fill it in steps d-f).

**d. OAuth token + endpoint on the active profile.** Check `yc config get token` and `yc config get endpoint`:

- Both already set, endpoint is KZ → ✅ skip ahead.
- Endpoint set to KZ but no token → ask the user once (see below).
- Token set but wrong endpoint → silently `yc config set endpoint api.yandexcloud.kz:443`.
- Nothing set (fresh profile) → ask the user once for an OAuth token.

The OAuth ask is **the only mandatory user prompt in Step 0**. Say exactly:

> Для работы с Yandex Cloud Kazakhstan нужен OAuth-токен (один раз). Открой в браузере:
>
> https://oauth.yandex.kz/authorize?response_type=token&client_id=1a6990aa636648e9b2ef855fa7bec2fb
>
> Войди под своим Yandex ID, разреши доступ. После редиректа браузер покажет URL вида `https://oauth.yandex.kz/verification_code#access_token=y0_XXXXXX…&token_type=bearer&expires_in=...`. Скопируй значение `access_token=…` (длинная строка между `=` и `&`) и пришли мне.

After receiving the token: `yc config set token <token>`, then set the endpoint **and** the zone in the same breath:

```bash
yc config set endpoint api.yandexcloud.kz:443
yc config set compute-default-zone kz1-a
```

`compute-default-zone` is decoupled from endpoint — `yc config set endpoint` doesn't touch it. Without it set, any `yc compute *` command that omits `--zone` falls back to whatever was there before (often `ru-central1-a` from a previous RU init) and fails with "zone not found".

**e. cloud-id and folder-id.** After step d, the profile has a valid token. Now resolve the IDs:

```bash
CLOUD_ID=$(yc config get cloud-id 2>/dev/null || true)
if [[ -z "$CLOUD_ID" ]]; then
  CLOUD_ID=$(yc resource-manager cloud list --format json | jq -r '.[0].id // empty')
  [[ -n "$CLOUD_ID" ]] && yc config set cloud-id "$CLOUD_ID"
fi

FOLDER_ID=$(yc config get folder-id 2>/dev/null || true)
if [[ -z "$FOLDER_ID" ]]; then
  FOLDER_ID=$(yc resource-manager folder list --cloud-id "$CLOUD_ID" --format json | jq -r '.[0].id // empty')
  [[ -n "$FOLDER_ID" ]] && yc config set folder-id "$FOLDER_ID"
fi
```

Failure modes:
- `cloud list` returns empty → the OAuth token is for a Yandex ID that has no clouds in KZ. Tell the user: "Похоже, у тебя нет облака в Yandex Cloud Kazakhstan. Создай облако в https://kz.console.yandex.cloud, потом запусти меня снова." Stop.
- `cloud list` returns multiple → use the first, but tell the user one line: "Использую облако `<NAME>`. Если это не то — скажи, переключусь."
- Same logic for folder.

**Do not call `yc billing account list`.** It doesn't exist on the KZ endpoint. If the user has a cloud and a folder, billing is either active or will fail concretely at VM creation time with a clear error. Catching that one error in Step 2 is fine.

**f. SSH key.** `ls ~/.ssh/id_ed25519.pub`. If missing: silently `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "openclaw-yc-$(date +%Y%m%d)"`.

**g. Existing instance with the same name in this cloud.** `yc compute instance get --name openclaw-bot 2>/dev/null`. If a result comes back, ask once: "У тебя уже есть VM 'openclaw-bot' — поставить новую под именем `openclaw-bot-XXXX`?" Default yes; pick a random 4-char suffix.

Do not print anything to the user about (a)-(g) if everything passed silently. Move to Step 1.

### Step 1 — Ask the two questions

In **one** message, in the user's language:

> Сейчас поставлю тебе OpenClaw-бота в Yandex Cloud. От тебя нужны две вещи (~5 минут).
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
    # Minimal completion call confirms key + at least some credit
    curl -fsS https://api.anthropic.com/v1/messages \
      -H "x-api-key: ${LLM_API_KEY}" \
      -H "anthropic-version: 2023-06-01" \
      -H "content-type: application/json" \
      -d '{"model":"claude-haiku-4-5","max_tokens":1,"messages":[{"role":"user","content":"ok"}]}' \
      | jq -er '.content' >/dev/null \
      || (say "Anthropic ключ не работает или нет кредита. Проверь на console.anthropic.com." && stop)
    ;;
  openrouter)
    # OpenRouter exposes /api/v1/auth/key as a free credit check
    curl -fsS https://openrouter.ai/api/v1/auth/key \
      -H "Authorization: Bearer ${LLM_API_KEY}" \
      | jq -er '.data.usage != null' >/dev/null \
      || (say "OpenRouter ключ не прошёл проверку. Перепроверь на openrouter.ai/keys." && stop)
    # Optional: warn if balance below $1
    BAL=$(curl -fsS https://openrouter.ai/api/v1/auth/key -H "Authorization: Bearer ${LLM_API_KEY}" \
      | jq -r '.data.limit_remaining // 0')
    [[ "$BAL" == "0" ]] && say "На OpenRouter $0 кредита. Бот не сможет отвечать. Пополни на openrouter.ai/credits."
    ;;
  openai-codex)
    # Can't validate before OAuth — defer to Step 4.5 after VM is up.
    # Just confirm the user understands they'll need to do one extra step.
    say "Хорошо, после установки бота на VM покажу 8-символьный код для https://auth.openai.com/codex/device. Это разовое действие."
    ;;
esac
```

`BOT_USERNAME` (e.g. `your_ceo_bot`) is captured here for the one-click chat link in Step 5.

### Step 2 — Silent VM creation

**a. Ensure the default network + subnet exist in the current folder.** Brand-new folders sometimes lack them (or the user removed them). Don't assume — discover, then create if missing.

```bash
NETWORK_ID=$(yc vpc network get --name default --format json 2>/dev/null | jq -r .id 2>/dev/null)
if [[ -z "$NETWORK_ID" ]]; then
  NETWORK_ID=$(yc vpc network create --name default --format json | jq -r .id)
fi

SUBNET_ID=$(yc vpc subnet get --name default-kz1-a --format json 2>/dev/null | jq -r .id 2>/dev/null)
if [[ -z "$SUBNET_ID" ]]; then
  # Pick a /24 from 10.130.x.x that doesn't collide with the user's other subnets
  SUBNET_ID=$(yc vpc subnet create \
    --name default-kz1-a \
    --network-id "$NETWORK_ID" \
    --zone kz1-a \
    --range 10.130.0.0/24 \
    --format json | jq -r .id)
fi
```

Don't mention any of this to the user unless it errors — these are quiet idempotent ops.

**b. Detect the caller's public IP** (for the SSH ingress rule):

```bash
MY_IP=$(curl -fsS --max-time 5 https://api.ipify.org 2>/dev/null \
  || curl -fsS --max-time 5 https://icanhazip.com 2>/dev/null \
  || echo "")  # empty → fall back to 0.0.0.0/0 (fail2ban catches the rest)
```

**c. Render the cloud-init file.** Substitute these placeholders (no `TELEGRAM_CHAT_ID` — it's auto-detected in Step 4):

- `{{TELEGRAM_BOT_TOKEN}}` — from Step 1.
- `{{SSH_PUBLIC_KEY}}` — content of `~/.ssh/id_ed25519.pub`.
- `{{LLM_ENV_LINE}}` — depends on the chosen LLM provider:

  | Provider | Substituted line |
  |---|---|
  | anthropic | `ANTHROPIC_API_KEY=<key>` |
  | openrouter | `OPENROUTER_API_KEY=<key>` |
  | openai-codex | *(empty string — no env var at this stage; OAuth fills the profile after Step 4.5)* |

Write to `/tmp/openclaw-cloud-init.yaml` with mode 600.

**d. Create the security group:**

```bash
SSH_CIDR="${MY_IP:+${MY_IP}/32}"
SSH_CIDR="${SSH_CIDR:-0.0.0.0/0}"

SG_ID=$(yc vpc security-group create \
  --name "${VM_NAME}-sg" \
  --network-id "$NETWORK_ID" \
  --rule "direction=ingress,port=22,protocol=tcp,v4-cidrs=[${SSH_CIDR}]" \
  --rule "direction=egress,from-port=0,to-port=65535,protocol=any,v4-cidrs=[0.0.0.0/0]" \
  --format json | jq -r .id)
```

Note: use `--network-id` not `--network-name`. The named lookup fails silently in some yc CLI versions when the folder has multiple networks.

**e. Create the instance.** Try `standard-v3` first (Intel Ice Lake), fall back to `standard-v2` (Cascade Lake) if v3 isn't available in this folder:

```bash
PLATFORM=standard-v3
yc compute instance create \
  --name "${VM_NAME}" \
  --zone kz1-a \
  --platform "$PLATFORM" \
  --cores 2 --memory 4 \
  --network-interface "subnet-id=${SUBNET_ID},nat-ip-version=ipv4,security-group-ids=${SG_ID}" \
  --create-boot-disk "type=network-ssd,size=30,image-folder-id=standard-images,image-family=ubuntu-2404-lts" \
  --ssh-key ~/.ssh/id_ed25519.pub \
  --metadata-from-file user-data=/tmp/openclaw-cloud-init.yaml \
  --hostname "${VM_NAME}" \
  --format json > /tmp/openclaw-vm.json 2>/tmp/openclaw-vm.err

# If v3 not available in this folder, retry with v2.
if grep -qiE "platform.*not.*found|unsupported platform" /tmp/openclaw-vm.err; then
  yc compute instance create --platform standard-v2 ...   # same flags
fi
```

Capture `external_ipv4_address` from `/tmp/openclaw-vm.json` (`.network_interfaces[0].primary_v4_address.one_to_one_nat.address`). Then one sentence to the user:

> VM создана. Ставлю OpenClaw — займёт около 10 минут. Можешь пока заварить чай.

If the instance create errors with `billing account is not active` or `billing_disabled` — that's the one billing case we couldn't detect in Step 0 (because there's no `yc billing` on KZ). Tell the user: "Похоже, в Yandex Cloud Kazakhstan не активирован биллинг. Открой https://kz.console.yandex.cloud/billing — там подсказка. Когда активируешь, запусти меня снова — VM подхвачу автоматически." Stop.

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

Cap at 15 minutes. If still not ready, surface to the user with a single sentence ("Что-то пошло не так на VM, проверяю логи") and jump to `references/04-troubleshooting.md`.

### Step 3.5 — OAuth device-code flow (ONLY if `LLM_PROVIDER=openai-codex`)

Skip this entire step for `anthropic` and `openrouter` — they have the key already in `gateway.env` and the bot is ready to talk.

For `openai-codex`, the cloud-init left the gateway running but without a model configured (no Anthropic/OpenRouter key was in env). Run the device-code OAuth flow now via SSH with a forced TTY:

```bash
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
  # Pro subscription
  ssh openclaw@$IP "openclaw config set agents.defaults.model.primary 'openai-codex/gpt-5.5' \
    && openclaw config set agents.defaults.model.fallbacks '[\"openai-codex/gpt-4o\"]'"
else
  # Plus subscription — gpt-4o is the best available
  ssh openclaw@$IP "openclaw config set agents.defaults.model.primary 'openai-codex/gpt-4o' \
    && openclaw config set agents.defaults.model.fallbacks '[]'"
fi

ssh openclaw@$IP "systemctl --user restart openclaw-gateway"
```

If after 15 minutes the SSH session timed out and `auth-profiles.json` still has no `openai-codex` profile: tell the user "не получилось войти в ChatGPT, давай попробуем ещё раз" and re-run the SSH `openclaw models auth login` command. Don't kill the VM — only the OAuth step needs to be retried.

### Step 4 — One-click chat link + auto-pair (the actual flow, not the easy one)

When `/var/lib/openclaw-bootstrap-done` exists, the gateway is up in `pairing` mode. **This is where wizards historically fail silently**: they think `openclaw pairing approve` succeeded, hand off to the user, and the user discovers the bot still asks for a confirmation code. Read this whole section.

#### What actually happens when the user presses /start

1. Telegram delivers `/start` to the bot.
2. OpenClaw enforces `dmPolicy=pairing` — it does **not** drop the message, it calls `issuePairingChallenge()`, records a pending request in the gateway, **and the bot replies to the user with the pairing code + instructions** (something like "To complete pairing, ask your admin to run `openclaw pairing approve telegram ABCD-1234`"). The user sees this message; they shouldn't reply to it.
3. The pending request lives in `openclaw pairing list telegram --format json` until either approved or expired.

#### Pre-emptive heads-up to the user

Send this **before** asking them to press /start, so they don't get confused when the bot's first reply is a code message:

> Бот готов. Открой его в Telegram: **https://t.me/{{BOT_USERNAME}}** и нажми `/start`.
>
> Бот пришлёт тебе короткое сообщение с кодом — **ничего с ним делать не надо, я подтвержу доступ автоматически за пару секунд**. После этого можешь начать переписываться с ботом как обычно.

#### Poll for chat_id (Telegram getUpdates)

```bash
# Empty getUpdates returns until the user actually presses /start
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
# Give the gateway up to 10s to record the pending request after /start arrives
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
  systemctl --user restart openclaw-gateway
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
# Language-matched probe text
case "$USER_LANGUAGE" in
  ru) PROBE="Скажи 'привет', чтобы я убедился, что ты отвечаешь." ;;
  kk) PROBE="Сәлем деп жаз — жауап беретіндігіңе көз жеткізейін." ;;
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
  timeout 90 journalctl --user -u openclaw-gateway -f --no-pager 2>/dev/null \
    | grep -m1 -E 'telegram.*sent|outgoing.*telegram|sendMessage.*ok'
"
```

If this times out: gateway accepted the inbound but didn't reply. Most likely cause = LLM provider not configured (Codex OAuth didn't finish, or env key empty). Jump to `references/04-troubleshooting.md` §4c-e.

**Check 2 — A bot reply appears in `getUpdates`** within 90s. Poll for any new update authored by the bot:

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

Note: a bot's own outgoing messages don't appear in `getUpdates` directly — but the bot's reply, after you send a follow-up probe, **does** appear as a forwarded/preceding context in subsequent updates. If this check is unreliable in your test environment, fall back on Check 1 (journal) + Check 3 (user confirmation).

**Check 3 — User confirms.** Ask the user once, in their language:

> Бот должен был тебе ответить в Telegram. Ответил?

Wait for "да"/"yes"/"работает". If "нет"/"не отвечает" — jump to `references/04-troubleshooting.md` §4. Never claim success unless all three pass.

#### 5c. If language is wrong

If checks 1+2 pass but the bot replied in English while the user expected Russian (or vice versa), the locale override wasn't applied. Re-apply over SSH and reset the session:

```bash
LOCALE_PACK="/usr/local/share/openclaw-locale-${USER_LANGUAGE}.md"
ssh openclaw@$IP "
  test -f $LOCALE_PACK && cat $LOCALE_PACK >> ~/.openclaw/workspace/USER.md
  # Trigger session reset so the bot re-reads USER.md
  openclaw sessions reset --channel telegram --to ${CHAT_ID} 2>/dev/null || true
"
```

Then re-run the probe (5a + 5b). If the bot is still answering in the wrong language, surface to the user — don't loop.

### Step 5.5 — Onboarding (hand off to `openclaw-user-onboarding` skill)

The bot is alive but anonymous — it doesn't know who's talking to it. Before the final summary, hand off to `openclaw-user-onboarding`, which collects five basic fields about the user (identity, focus, communication style, tools, anti-patterns), writes `USER.md` on the VM, and resets the Telegram session so the bot picks up the profile from the very next message.

Hand-off payload (everything the onboarding skill needs):

| Variable | Source in this wizard |
|---|---|
| `IP` | Step 2e `external_ipv4_address` |
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

If the user wants to skip onboarding entirely (says "пропусти", "skip", "потом"): write a minimal placeholder USER.md and proceed. **Don't block** — onboarding is a nice-to-have at this step, not a gate. The user can always run `openclaw-user-onboarding` standalone later.

If `openclaw-user-onboarding` skill is not loaded (the agent doesn't have it installed): fall back to writing a minimal placeholder USER.md inline and mention in the final summary: "Чтобы дозаполнить профиль, поставь скилл openclaw-user-onboarding и скажи мне «онбординг»."

#### Final hand-off message

Only after all three checks pass, drop the summary:

Then drop the final summary. Adapt the `LLM` line to the provider the user chose:

```
OpenClaw запущен в Yandex Cloud Kazakhstan.

  VM           : openclaw-bot  (kz1-a, 2 vCPU / 4 GB / 30 GB SSD)
  IP           : 84.x.x.x
  Бот          : @your_bot_name
  LLM          : <one of three lines below>
  Workspace    : CEO AI OS (48 CEO-скиллов)
  Стоимость    : ~3–5 ₸/час, ~100 ₸/день (VM) + LLM по тарифу провайдера
```

LLM line variants:

| Provider | Line |
|---|---|
| anthropic | `LLM          : Anthropic Claude Sonnet 4.6 (API key, ~$3/M tokens)` |
| openrouter | `LLM          : OpenRouter → Moonshot Kimi K2.6 (API key, +5% markup)` |
| openai-codex | `LLM          : OpenAI Codex / gpt-5.5 (ChatGPT Pro подписка)` or `gpt-4o (Plus подписка)` depending on what got resolved in Step 3.5 |

Что дальше:
  • Просто пиши боту в Telegram — он уже знает кто ты, сразу пробуй: «что у меня сегодня важно?»
  • Чтобы попробовать стратегические скиллы: «Сделай weekly review» или «Помоги принять решение об X»
  • Обновить профиль (роль сменилась, новые приоритеты): скажи мне «обнови мой профиль для бота» — openclaw-user-onboarding перезапустится в standalone-режиме
  • Когда захочешь паузу (бот выключится, диск останется): yc compute instance stop --name openclaw-bot
  • Совсем удалить: yc compute instance delete --name openclaw-bot && yc vpc security-group delete --name openclaw-bot-sg

Если что-то сломается — просто скажи мне «бот молчит» или «openclaw сломался», я разберусь.
```

If the verification ping doesn't get a reply within 60 seconds, run `references/04-troubleshooting.md` §4 silently — don't claim success.

## Auto-recovery (what the wizard does without asking)

These are the things the wizard fixes on its own if it sees them during the run. The user is told only the end result, not the diagnostic steps.

| Detected condition | Silent fix |
|---|---|
| `yc` CLI missing | Install to `$HOME/yandex-cloud/bin`, add to PATH for this session. |
| Active `yc` profile points at RU but user has a KZ cloud | Create/activate a dedicated `openclaw-kz` profile, set token + endpoint + cloud-id + folder-id. Don't touch the user's existing profiles. |
| User opens with "у меня workshop-ключ" but no bundle path | Ask once: "Где лежит файл? Можешь перетащить в чат". Then validate `$schema`. Don't auto-fall-back to Plan A — the user already told us they have a key, asking for OAuth would be wrong. |
| Plan B bundle has `$schema` newer than `openclaw-workshop-bundle@1` | Warn once: "Bundle от организатора новее, чем я умею. Попробую как есть." Try the standard Plan B steps. Surface any `yc` error plainly. |
| Plan B `yc compute zone list` returns empty (key revoked / folder gone) | Tell the user: "Кажется, организатор свернул облако. Напиши ему." Don't retry. |
| Endpoint set to KZ but cloud-id/folder-id are empty or RU-flavoured | Re-resolve via `yc resource-manager cloud list` / `folder list` on the active profile, then `yc config set`. |
| Multiple clouds returned by `cloud list` | Use the first; tell the user one line "использую облако `<NAME>`". |
| `yc vpc network get --name default` returns nothing | Create the default network silently, then create `default-kz1-a` subnet with range `10.130.0.0/24`. |
| Subnet `default-kz1-a` missing | Create it under the (existing or fresh) default network. |
| `--platform standard-v3` rejected as "not supported in folder" | Retry once with `--platform standard-v2`. |
| `--network-name default` silently picks the wrong network | Always use `--network-id`/`--subnet-id` (resolved earlier), never the `-name` variant. |
| `~/.ssh/id_ed25519.pub` missing | Generate a new one with no passphrase. |
| Caller IP can't be detected | Fall back to `0.0.0.0/0` ingress with fail2ban defense (one-line note to user). |
| `npm install -g openclaw` failed once | Retry once after 30 seconds. If still fails, escalate. |
| Gateway `/health` returns non-200 for first 90 seconds | Keep polling — composio plugin can take that long. Only escalate after 4 minutes. |
| Pairing approval returns "code not found" | Wait 3 seconds, re-list pairing requests. Telegram sometimes lags. |
| `openclaw pairing list` returns entries but jq filter on `.chatId` returns empty | The schema field is `.senderId` / `.requestId`, not `.chatId` / `.code`. The wizard's Step 4 uses a defensive filter that tries both — don't simplify it. |
| Bot replies in wrong language after locale pack applied | `cat` the locale pack again over SSH + `openclaw sessions reset --channel telegram --to <CHAT_ID>` to force USER.md re-read. See Step 5c. |
| Bot doesn't reply to verification ping within 30s | Restart adapter once before declaring failure. |

## Yandex Cloud Kazakhstan — common trip points (read before debugging)

If anything fails during the wizard run, check these first — most YC KZ issues come from one of these five mistakes:

1. **Endpoint vs cloud-id mismatch.** Setting `endpoint=api.yandexcloud.kz:443` does NOT auto-update `cloud-id` or `folder-id`. If you only flip the endpoint, every subsequent `yc compute / vpc / resource-manager` call sees an empty result because it's looking up RU IDs against the KZ realm. **Always update all three together** — endpoint, cloud-id, folder-id — or use a separate profile.
2. **`yc billing` doesn't exist on KZ endpoint.** Calling `yc billing account list` errors with `Unknown command 'billing account list'`. Don't use it for any pre-flight check. Detect billing problems from the actual `yc compute instance create` error message, not by trying to list accounts.
3. **`yc resource-manager cloud list` returning empty.** When the OAuth token doesn't match the realm (RU token on KZ endpoint, or vice versa), the call succeeds with an empty array — not an auth error. If empty, the answer is "wrong token", not "no cloud".
4. **`--network-name default` lookup is fragile.** When the folder has multiple networks (common after the user experiments), the named lookup can pick the wrong one or fail silently. Always resolve to a network-id first (`yc vpc network get --name default`) and pass `--network-id` to subsequent commands.
5. **Subnet not auto-provisioned.** Default subnet `default-kz1-a` is created with the default network in most cases, but not all. New empty folders sometimes lack it. Always check before referencing it in instance create.

## Failure modes (when the silent fixes aren't enough)

| Symptom | Where to look |
|---|---|
| `yc compute zone list` returns `ru-central1-*` or empty after the wizard's profile setup | `references/04-troubleshooting.md` §1a — endpoint still RU |
| `yc resource-manager cloud list` returns `[]` even though the cloud is visible in https://kz.console.yandex.cloud | `references/04-troubleshooting.md` §1b — cloud-id/folder-id still RU, or §1c — OAuth token from wrong realm |
| `yc compute instance create` errors with `billing account is not active` | `references/04-troubleshooting.md` §1d — billing genuinely missing |
| `yc compute instance create` errors with `quota_exceeded` | `references/01-prerequisites.md` §5 |
| `yc compute instance create` errors with `platform … not supported` | Already handled by auto-recovery (retry with `standard-v2`). If it still fails, `references/04-troubleshooting.md` §2 |
| Cloud-init log shows `npm install -g openclaw` failed twice | `references/04-troubleshooting.md` §2 |
| `openclaw gateway status` shows `RPC probe: failed` after 4 min | `references/04-troubleshooting.md` §3 |
| User pressed `/start` but `getUpdates` returns no chat | `references/04-troubleshooting.md` §4a-b |
| Bot pairs but doesn't reply | `references/04-troubleshooting.md` §4c-e (key, credit, model) |
| SSH `Permission denied (publickey)` | `references/04-troubleshooting.md` §5 |

For everything else: dump `/var/log/openclaw-bootstrap.log` and `journalctl --user -u openclaw-gateway -n 200` from the VM, surface to the user as "вот что я вижу, давай разбираться", do not guess.

## References

- `references/01-prerequisites.md` — yc CLI install, KZ endpoint init, SSH key, billing checks (most are silent now; only OAuth login and missing billing surface to the user)
- `references/02-network-and-security.md` — security-group rules, public-IP rationale, hardening choices
- `references/03-openclaw-config.md` — Telegram pairing flow, Anthropic auth, workspace seeding
- `references/04-troubleshooting.md` — 7 failure modes with copy-paste fixes
- `references/05-workshop-key-mode.md` — Plan B (workshop bundle) end-to-end: schema check, profile carve-out, what NOT to do, organizer hand-off
- `scripts/cloud-init.yaml` — the full VM bootstrap (Node, OpenClaw, hardening, ceo-ai-os workspace, systemd user service)

## Companion skills

| Skill | Required? | Role |
|---|---|---|
| `openclaw-guide` | **required** | Loaded by Step 0a; owns all post-install consultation (channels, use cases, debugging). |
| `openclaw-user-onboarding` | recommended | Auto-invoked at Step 5.5 to collect five user facts and write USER.md. If missing, Step 5.5 falls back to a placeholder USER.md and surfaces "поставь openclaw-user-onboarding и скажи 'онбординг'" in the final summary. |
| `prepare-yc-workshop` | organizer-only | Matching organizer-side skill that produces the bundle files consumed by this skill's Plan B. Participants don't need it. |
| `install-openclaw-to-hetzner` | alternative | Sibling skill for Hetzner Cloud (Falkenstein, Germany). Pick by target cloud — they don't co-exist on one VM. Hetzner is single-mode (Plan A only) — no workshop-bundle equivalent. |

### About `openclaw-guide` (required)

`openclaw-guide` (sibling) — **must be installed alongside this one**. The wizard refuses to start without it loaded. Two reasons:

1. **During install** — if cloud-init logs surface something this skill doesn't know about, the agent reads `openclaw-guide/references/06-troubleshooting.md` instead of guessing.
2. **After install** — when the user asks "how do I add Slack?", "how do I make the bot wake me up at 8am?", "what skills should I install?", the agent reads `openclaw-guide/references/use-cases.md` and `openclaw-guide/references/channels.md` to advise. This wizard is silent after Step 5; the guide owns ongoing consultation.

Joint install:

```bash
npx skills add CodeAlive-AI/ceo-ai-os@install-openclaw-to-yc -g
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-guide -g
```

If `npx` is unavailable: clone `https://github.com/CodeAlive-AI/ceo-ai-os` and drop `skills/install-openclaw-to-yc` **and** `skills/openclaw-guide` into the agent's skills directory (see this skill's README for per-agent paths).

## Ecosystem — what to install next

The VM ships with all 49 ceo-ai-os skills pre-seeded into the workspace (the bot calls them automatically when the user's request matches). For the agent's own skill loader (the one driving this wizard), here are the highest-ROI add-ons. **Mention them only after Step 5 passes** — bringing them up earlier dilutes the install flow.

| Trigger ("user later asks for X") | Skill to suggest | One-line pitch |
|---|---|---|
| "I want a daily morning brief" | `daily-recap` | Cron-driven morning + evening summary of metrics, calendar, and yesterday's wins. |
| "Help me prep for a strategic decision" | `decision-playbook` | Structured deliberation with explicit options, kill criteria, and a 7-day review. |
| "Research this company before my meeting" | `exa-company-research` | Exa-powered company profile (positioning, traction, team) in <30 s. |
| "Find people who fit ICP X" | `exa-lead-gen` | Multi-source lead discovery with enrichment. |
| "Watch what competitors are doing" | `competitive-analysis` | Daily radar over competitor sites, blog, GitHub, hiring. |
| "I want to use CodeAlive search inside the bot" | (see `openclaw-guide/references/codealive-context-engine.md`) | Adds `codealive__semantic_search` / `grep_search` / `chat` MCP tools to the bot — bot can answer questions about any indexed repo. |

Full catalogue lives at `https://github.com/CodeAlive-AI/ceo-ai-os/tree/main/skills`. Install any of them globally with:

```bash
npx skills add CodeAlive-AI/ceo-ai-os@<skill-name> -g
```

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
- Cost optimisation past the trial grant — `references/04-troubleshooting.md` §7
