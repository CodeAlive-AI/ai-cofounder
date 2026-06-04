# install-openclaw-to-yc

Wizard skill that takes a non-DevOps user from zero to a working OpenClaw bot on a fresh Yandex Cloud Kazakhstan VM (zone `kz1-a`, Karaganda) in ~15 minutes. Asks for a Telegram bot token and one of three LLM access options (Anthropic key, OpenRouter key, or OpenAI Codex OAuth via ChatGPT Plus/Pro), then creates the VM, hardens it, installs OpenClaw with the CEO AI OS workspace, wires Telegram, auto-detects `chat_id`, configures the bot to reply in the user's language, and verifies the bot answers.

Works in two modes — auto-detected from the inputs:

- **Plan A** — the user has (or is willing to create) their own YC Kazakhstan account. OAuth via `oauth.yandex.kz`, one prompt.
- **Plan B** — the user is at a workshop and has a `bundle-NN.json` file from the organizer. No OAuth, no personal YC account needed. The bundle ships a per-participant service-account key + folder-id + cloud-id; the wizard uses it as a drop-in replacement for personal OAuth. See `references/05-workshop-key-mode.md`.

**Always install together with `openclaw-guide`** — that skill is required at runtime and owns all post-install consulting (channels, use cases, debugging, CodeAlive integration). Strongly recommended: also install **`openclaw-user-onboarding`** — auto-invoked at Step 5.5 to collect five basic facts about the user (identity, focus, communication style, tools, anti-patterns) and write them into USER.md, so the bot knows who's talking to it from the first message. Organizers running a workshop also need `prepare-yc-workshop` (the companion organizer-side skill that produces the bundles consumed in Plan B).

## Install

### Recommended — Skills CLI

```bash
# Install this skill + its required + recommended companions
npx skills add CodeAlive-AI/ceo-ai-os@install-openclaw-to-yc   -g
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-guide           -g   # required
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-user-onboarding -g   # recommended (auto-invoked at Step 5.5)
```

Then **restart your code agent** (Claude Code / Claude Cowork / Codex / Cursor / …) so it picks up the new skill.

### Manual — drop the folder into your agent's skills directory

If `npx` is not available, or you already have the folder locally, copy it into the right place for your agent. The directory name MUST stay `install-openclaw-to-yc`.

| Agent | Path (global, all projects) | Path (project-scoped) |
|---|---|---|
| Claude Code | `~/.claude/skills/install-openclaw-to-yc/` | `.claude/skills/install-openclaw-to-yc/` |
| Claude Cowork | `~/.claude/skills/install-openclaw-to-yc/` | `.claude/skills/install-openclaw-to-yc/` |
| Codex | `~/.codex/skills/install-openclaw-to-yc/` | `.agents/skills/install-openclaw-to-yc/` |
| Cursor | `~/.cursor/skills/install-openclaw-to-yc/` | `.cursor/skills/install-openclaw-to-yc/` |
| Gemini CLI | `~/.gemini/skills/install-openclaw-to-yc/` | `.agents/skills/install-openclaw-to-yc/` |
| OpenCode | `~/.config/opencode/skills/install-openclaw-to-yc/` | `.opencode/skills/install-openclaw-to-yc/` |
| OpenClaw | `~/.openclaw/skills/install-openclaw-to-yc/` | `skills/install-openclaw-to-yc/` |
| Other | see [skills.sh registry](https://skills.sh) | — |

Example (Claude Code, from this repo's checkout):

```bash
mkdir -p ~/.claude/skills/
cp -r skills/install-openclaw-to-yc ~/.claude/skills/
cp -r skills/openclaw-guide       ~/.claude/skills/   # required companion
```

Restart the agent. The skill is discovered automatically — no other registration step.

## Required companion skill

`openclaw-guide` (sibling folder) **must** be installed at the same time. Two roles:

1. **During install** — the wizard refuses to start without it loaded; the agent uses it to debug OpenClaw on the VM if anything breaks, instead of guessing from a stack trace.
2. **After install** — when the user later asks "how do I add Slack?", "set up a daily morning brief", or "connect CodeAlive search", the agent reads `openclaw-guide/references/*.md` rather than inventing answers. This wizard is silent after Step 5.

## Use

After install, type any of these to your agent:

- "install OpenClaw to Yandex Cloud Kazakhstan"
- "set up my CEO bot in YC KZ"
- "I'm at OpenClaw workshop and need my own OpenClaw bot"
- "у меня workshop-ключ от организатора, вот файл `./bundle-07.json`"  *(Plan B)*

The skill takes over from there. It asks for **two** things in one message — Telegram bot token + LLM access — then runs everything itself. If you mention a workshop bundle, it switches to Plan B automatically and skips the OAuth step.

## What you need before running it

1. **`yc` CLI** — the skill installs it silently if missing.
2. **One of two:**
   - **Plan A:** **Yandex Cloud account with the Kazakhstan endpoint** (`api.yandexcloud.kz:443`). The skill activates a dedicated `openclaw-kz` profile and asks for the OAuth token once if you've never used the KZ realm.
   - **Plan B:** **A `bundle-NN.json` from the workshop organizer.** No personal YC account needed. The bundle contains a service-account key + folder-id + cloud-id. Tell the agent where the file is; the wizard does the rest. Note: your VM will live in the **organizer's** cloud and disappear when they clean up after the workshop — for a permanent bot, switch to Plan A after the workshop.
3. **Active billing account** in Yandex Cloud Kazakhstan (24 000 ₸ trial grant for 60 days covers ~8 months of run). Plan B participants don't need their own — they ride on the organizer's billing.
4. **Telegram bot token** from [@BotFather](https://t.me/BotFather). The wizard auto-detects `chat_id` after you press `/start` — you do **not** need to look it up via `@userinfobot`.
5. **LLM access — pick one:**
   - **A.** [Anthropic API key](https://console.anthropic.com/settings/keys) starting with `sk-ant-` + ≥$5 credit (recommended for first-time users; best raw quality)
   - **B.** [OpenRouter API key](https://openrouter.ai/keys) starting with `sk-or-` + ≥$5 credit (unified access to 200+ models)
   - **C.** Just write the word **"Codex"** if you have ChatGPT Plus ($20/mo) or Pro ($200/mo) — the wizard runs the OAuth device flow for you after VM bootstrap
6. **Local SSH key** at `~/.ssh/id_ed25519.pub` — auto-generated if missing.

The skill checks all of these in Step 0 and walks you through any missing piece before proceeding.

## What you get post-install

The VM ships with the full `ceo-ai-os` workspace (49 CEO skills pre-seeded), Telegram paired, and the bot replying in your language (Russian by default for the workshop audience). Then your agent can help you, using the companion `openclaw-guide` skill:

- Add a daily morning brief: ask "set up a morning brief on my OpenClaw bot"
- Add competitive-radar cron: ask "set up competitor monitoring"
- Connect CodeAlive search: ask "add CodeAlive context engine to my bot" → `openclaw-guide/references/codealive-context-engine.md`
- Add another channel (Discord, Slack, WhatsApp, iMessage): ask "add Discord to my bot" → `openclaw-guide/references/channels.md`

## Folder layout

```
install-openclaw-to-yc/
├── SKILL.md                              # Wizard instructions (the brain)
├── SOURCE.md                             # Origin tracking
├── README.md                             # This file
├── scripts/
│   ├── cloud-init.yaml                   # VM bootstrap (Node 22, OpenClaw, hardening, ceo-ai-os workspace, systemd)
│   └── locale/                           # ru/kk locale packs (base64'd into cloud-init)
└── references/
    ├── 01-prerequisites.md               # yc CLI for KZ endpoint, named profiles, SSH, OAuth (Plan A)
    ├── 02-network-and-security.md        # SG rules, public-IP vs NAT, hardening rationale, lockout recovery
    ├── 03-openclaw-config.md             # Telegram pairing, all three LLM providers, workspace seeding
    ├── 04-troubleshooting.md             # 7 failure modes with copy-paste fixes
    └── 05-workshop-key-mode.md           # Plan B — bundle schema, profile carve-out, organizer hand-off
```

Channels other than Telegram, use cases (morning brief / research / competitive / decision), and CodeAlive integration are documented in the companion `openclaw-guide` skill — not here. This skill is install-only.

## Cost ceiling

A `standard-v3` 2 vCPU / 4 GB VM with public IP in `kz1-a` costs **80–120 ₸/day** at current YC KZ rates. The trial grant covers ~8 months of 24/7 run. Stop the VM (`yc compute instance stop`) to pause to ~25 ₸/day (disk only).

## Scope

This skill is for **fresh Yandex Cloud Kazakhstan VMs only**. For AWS / GCP / Azure / other YC regions, this skill will refuse to run.

For local-machine OpenClaw installs, use [`openclaw/install.sh`](../../openclaw/install.sh) in this repo instead.

## License

MIT — see [LICENSE](../../LICENSE) at the repo root.
