---
name: openclaw-user-onboarding
description: >-
  After an OpenClaw bot is freshly installed (via install-openclaw-to-yc or
  any other path), collect a small set of basic facts about the user — name,
  role/company, what matters this week, communication preferences, tools they
  live in, and anti-patterns — and write them into the bot's USER.md on the
  remote VM via SSH. This is the difference between a bot that answers
  generically and one that knows from the very first message who it's talking
  to. Use when the user says onboard me, knowing me, set up my profile,
  finish setup, последний шаг, расскажу о себе, познакомимся, who I am, or
  whenever install-openclaw-to-yc has just successfully completed Step 5 and
  is handing off. Runs in 2-5 minutes of conversation, idempotent, safe to
  re-run later to update the profile. For the VM install itself, use
  install-openclaw-to-yc. For ongoing bot consulting, use openclaw-guide.
license: MIT
metadata:
  version: 0.1.0
---

# OpenClaw User Onboarding

A short conversational step that turns a freshly-installed bot from "anonymous answering machine" into "an agent that knows who you are from message one". Asks the user a small, intentional set of questions and writes the result to `USER.md` on the bot's VM, then resets the active Telegram session so the next message lands in a session that has already read the new profile.

## When this runs

Two paths:

1. **Auto-triggered**, immediately after `install-openclaw-to-yc` Step 5 (verification) passes. The install wizard hands off to this skill before the final summary so the user never has to think "what now?" — onboarding is part of the install flow.
2. **Standalone**, when the user later wants to update the profile: "обнови мой профиль для бота", "I changed jobs, update my bot", "let's redo onboarding".

Both paths use the same flow below. The standalone path additionally reads the **existing** USER.md from the VM first and uses it as the baseline (diff-style update, not overwrite).

## What you need before running

| # | Input | Default / how the wizard gets it |
|---|---|---|
| 1 | VM public IPv4 (`$IP`) | Passed by `install-openclaw-to-yc` Step 5 — or auto-detect from `yc compute instance get` if standalone |
| 2 | SSH user (`openclaw`) | Hard-coded; matches install-openclaw-to-yc / cloud-init |
| 3 | Telegram `chat_id` (`$CHAT_ID`) | Passed by install wizard; needed to reset session after writing USER.md |
| 4 | Telegram bot token (`$BOT_TOKEN`) | Passed by install wizard; only used if the user prefers to do onboarding *in Telegram* instead of in the code-agent (currently unused — code-agent only path) |
| 5 | User language (`$USER_LANGUAGE`, ISO 639-1) | Passed by install wizard. Default `ru`. Questions are asked in this language. |
| 6 | Agent type (`main` or `routinet`) | Default `main` — that's what install-openclaw-to-yc deploys. Determines the workspace path on the VM. |

The skill assumes SSH to `openclaw@$IP` already works (install-openclaw-to-yc made sure of that). If standalone and SSH is broken, surface plainly and stop — don't try to debug SSH from here.

## Operating principles

1. **One message, five fields, free-form answers.** Don't ask question by question. Send one block listing the five things you want to know, in the user's language. Accept any structure — paragraphs, bullets, "skip", "пропусти".
2. **Defaults for everything skipped.** If the user answers only 2 of 5, fill the rest with safe defaults (see `references/02-user-md-template.md`). Don't loop until the user answers all five.
3. **Don't grill.** Keep it under 3 minutes of wall-clock conversation. The user just spent 15 minutes on install — this should feel like the last small thing, not a survey.
4. **Confirm once before writing.** After drafting USER.md from answers, show the user a 5-line preview and ask "пишу?". Default yes if no answer in 10 seconds.
5. **Write atomically.** SSH the rendered USER.md to a temp file on the VM, `chown openclaw:openclaw`, `mv` over the existing file. Don't `cat >>` — full replacement is intentional, this file is human-curated and we're the human (via the user) right now.
6. **Reset the active Telegram session** after writing so the bot picks up the new USER.md on the very next message. Without this, the user has to send `/new` themselves.
7. **No emojis** unless the user used them first.

## The five fields

Internal model — what we want to end up with in USER.md. The questions to the user are softer (see "Wizard flow"); these are the slots the wizard fills.

| # | Field | Purpose | Default if skipped |
|---|---|---|---|
| 1 | **Identity** — what to call the user, their role, their company/project, their stage | Lets the bot address the user by name and frame answers in their domain | "пользователь", role/company "—" |
| 2 | **Focus** — what matters in the next 1-2 weeks | Lets the bot prioritise: if everything points at "closing 3 enterprise pilots", the bot won't suggest a logo redesign | "не указано — спрошу позже" |
| 3 | **Style** — language(s), emoji yes/no, formality (ты/вы), tolerance for hedging vs. directness | Lets the bot match the user's preferred register from message one | Language = `$USER_LANGUAGE`, no emoji, ты, direct |
| 4 | **Tools** — calendar, email, messengers, code-agent, etc. | Lets the bot ask "want me to schedule it?" instead of "what's your calendar?" later | Empty list |
| 5 | **Anti-patterns** — things the user explicitly does NOT want from the bot | The single most underused field; saves the user a year of friction | Empty list |

If the user says "пропусти" on a field, mark it as `(пропущено)` in USER.md — not as empty — so a re-run knows the user intentionally skipped and doesn't re-ask.

## Wizard flow

### Step 0 — Silent preflight

**a. Verify SSH works.** `ssh -o ConnectTimeout=5 -o BatchMode=yes openclaw@$IP true`. If it fails: tell the user one sentence and stop. Don't try to fix SSH — that's `install-openclaw-to-yc/references/04-troubleshooting.md` §5's job.

**b. Pick workspace path.** For agent type `main` it's `/home/openclaw/.openclaw/workspace/USER.md`. For `routinet`: `/home/openclaw/.openclaw/workspace-routinet/USER.md`. Standalone runs default to `main` unless the user specifies.

**c. Read existing USER.md (if any).**

```bash
EXISTING_USER_MD=$(ssh openclaw@$IP "cat /home/openclaw/.openclaw/workspace/USER.md 2>/dev/null" || echo "")
```

If non-empty AND the wizard is in standalone mode (NOT auto-triggered by install), parse it and pre-fill the slots — the wizard will show what's already there and ask which fields to update. If empty OR auto-triggered → fresh template.

### Step 1 — Ask the five questions in one message

In the user's language. Russian shown here; English/Kazakh variants in `references/01-questions.md`.

> Последний шаг — расскажи коротко о себе, чтобы я был полезным с первого сообщения в Telegram. Заполни в любом формате (можно по пунктам, можно одним абзацем, можно пропустить пункт — напиши «пропусти»).
>
> **1. Как тебя называть** и чем ты занимаешься?
>    Имя, роль, компания/проект, стадия (если применимо).
>
> **2. Что важно на ближайшие 1-2 недели?**
>    1-3 главных задачи или цели.
>
> **3. Стиль общения.**
>    Язык по умолчанию (русский/английский/смешанно), эмодзи (да/нет), на «ты» или на «вы», как реагировать когда я ошибаюсь — прямо или мягко.
>
> **4. Чем пользуешься?**
>    Почта (gmail, yandex, ...), календарь, мессенджеры, код-агент — что в твоей повседневке.
>
> **5. Чего НЕ нужно от меня?**
>    Что раздражает, что не делай (например: «не пиши после 23:00», «без маркетингового жаргона», «не предлагай решения, пока я не попросил»).
>
> Если что-то неудобно отвечать сейчас — пиши «пропусти» по этому пункту, поправим потом.

**Wait for a single reply** (the user can take 30s or 3 minutes — don't poll, just wait for the agent to receive their message). Do NOT ask follow-up questions for each field separately even if the user only answered 2 of 5 — that's the "don't grill" rule. Fill skipped fields with defaults from the table above.

### Step 2 — Parse the reply and draft USER.md

The user's reply is free-form. Use the LLM to extract the five fields. Don't regex.

The output template is in `references/02-user-md-template.md`. Render it with the extracted fields, falling back to defaults for anything the user skipped or didn't address.

**Important rule:** if a field is genuinely empty (user skipped, no default makes sense), write `(не указано)` — not `<placeholder>` or empty line. A future re-run of the skill checks for `(не указано)` to know it can re-ask that one field.

Also include a small footer with the timestamp and the agent that wrote this:

```markdown
---
Last updated by openclaw-user-onboarding skill on YYYY-MM-DD via install-openclaw-to-yc / standalone re-run.
```

### Step 3 — Confirm and write

Show the user the rendered USER.md (or just the first ~15 lines + "... + footer" if it's longer). One short question:

> Вот что записываю в профиль бота. Норм? (да / поправь / отмени)

- **да** → write
- **поправь** → ask "что поправить?", apply the diff in-place, show again
- **отмени** → stop, don't write anything. The bot keeps whatever USER.md it had before.

Default to "да" if no answer for 10 seconds.

### Step 4 — Atomic upload + ownership

```bash
LOCAL_TMP=$(mktemp -t openclaw-user-md.XXXXXX.md)
cat > "$LOCAL_TMP" <<'EOF'
... rendered USER.md ...
EOF

REMOTE_TMP="/tmp/openclaw-user-md.$$.md"
scp -o StrictHostKeyChecking=accept-new "$LOCAL_TMP" "openclaw@$IP:$REMOTE_TMP"

ssh openclaw@$IP "
  set -e
  WORKSPACE=/home/openclaw/.openclaw/workspace
  [[ -d \$WORKSPACE ]] || { echo 'workspace missing on VM' >&2; exit 2; }
  mv $REMOTE_TMP \$WORKSPACE/USER.md
  chown openclaw:openclaw \$WORKSPACE/USER.md
  chmod 600 \$WORKSPACE/USER.md
"

rm -f "$LOCAL_TMP"
```

If anything in the SSH block fails: surface plainly, don't retry silently — the user should know if their profile didn't land.

`scripts/upload-user-md.sh` is the canonical implementation of the upload — call it from the wizard or inline the same logic.

### Step 5 — Reset the active Telegram session

So the user's very next message in Telegram lands in a session that has already read the new USER.md.

```bash
ssh openclaw@$IP "openclaw sessions reset --channel telegram --to $CHAT_ID 2>/dev/null" \
  || true   # if reset fails, the user can /new manually — not fatal
```

If `openclaw sessions reset` doesn't exist on this OpenClaw version (older CLI), fall back to:

```bash
ssh openclaw@$IP "systemctl --user restart openclaw-gateway"
sleep 10
```

The restart is heavier but guaranteed.

### Step 6 — Short confirmation

One sentence to the user:

> Записал в профиль. Бот знает кто ты с следующего сообщения — попробуй: «привет, что у меня сегодня важно?».

That's it. Do NOT print the rendered USER.md again — already shown in Step 3.

## Standalone re-run (later, after install)

When invoked outside the install flow:

- Step 0c reads the existing USER.md and pre-fills slots.
- Step 1 shows what's already there per field and asks "что поменялось?" instead of asking everything from scratch.
- Default to keeping existing values for unanswered fields.

Same Step 2-6.

## What this skill does NOT cover

- The bot's persona, tone, language behaviour at runtime → that's `SOUL.md` (separate, agent-owned)
- Memory of conversations → `memory/YYYY-MM-DD.md` (agent-owned, append-only)
- Adding skills / channels / MCP servers → use `openclaw-guide`
- Re-configuring LLM provider or rotating API keys → `openclaw-guide/references/03-openclaw-config.md`

## References

- `references/01-questions.md` — full question variants for `ru` / `en` / `kk`, with rationale for each field
- `references/02-user-md-template.md` — the rendered USER.md template + a worked example
- `scripts/upload-user-md.sh` — atomic upload + ownership + session reset (the SSH block above, encapsulated)

## Companion skills

- `install-openclaw-to-yc` — triggers this skill automatically after Step 5 verification
- `openclaw-guide` — owns ongoing consultation (channels, use cases, debugging) once the bot is set up
