# install-openclaw-to-hetzner

Wizard skill that takes a non-DevOps user from zero to a working OpenClaw bot on a fresh Hetzner Cloud VM (Falkenstein, Germany — `fsn1` by default) in ~15 minutes. Asks for a Telegram bot token and one of three LLM access options (Anthropic key, OpenRouter key, or OpenAI Codex OAuth via ChatGPT Plus/Pro), then creates the VM, hardens it, installs OpenClaw with the CEO AI OS workspace, wires Telegram, auto-detects `chat_id`, configures the bot to reply in the user's language, and verifies the bot answers.

**Default shape:** `cax11` (ARM Ampere, 2 vCPU / 4 GB / 40 GB SSD) at `fsn1`, with IPv4+IPv6. ~€4.30/month total. Falls back to `cx22` (x86, same shape, same price) if `cax11` is sold out.

**Single mode only:** the user supplies their own Hetzner API token (project-scoped, `hv2-…`). There is no workshop-bundle equivalent on Hetzner — Hetzner has no native multi-tenant analogue of YC's folders. For workshops, use [`install-openclaw-to-yc`](../install-openclaw-to-yc/) with its companion `prepare-yc-workshop` skill, or build a separate `prepare-hetzner-workshop` skill that creates N projects via Cloud Console.

**Always install together with `openclaw-guide`** — that skill is required at runtime and owns all post-install consulting (channels, use cases, debugging, CodeAlive integration). Strongly recommended: also install **`openclaw-user-onboarding`** — auto-invoked at Step 5.5 to collect five basic facts about the user (identity, focus, communication style, tools, anti-patterns) and write them into USER.md, so the bot knows who's talking to it from the first message.

## Install

### Recommended — Skills CLI

```bash
# Install this skill + its required + recommended companions
npx skills add CodeAlive-AI/ceo-ai-os@install-openclaw-to-hetzner -g
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-guide              -g   # required
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-user-onboarding    -g   # recommended (auto-invoked at Step 5.5)
```

Then **restart your code agent** (Claude Code / Claude Cowork / Codex / Cursor / …) so it picks up the new skill.

### Manual — drop the folder into your agent's skills directory

If `npx` is not available, or you already have the folder locally, copy it into the right place for your agent. The directory name MUST stay `install-openclaw-to-hetzner`.

| Agent | Path (global, all projects) | Path (project-scoped) |
|---|---|---|
| Claude Code | `~/.claude/skills/install-openclaw-to-hetzner/` | `.claude/skills/install-openclaw-to-hetzner/` |
| Claude Cowork | `~/.claude/skills/install-openclaw-to-hetzner/` | `.claude/skills/install-openclaw-to-hetzner/` |
| Codex | `~/.codex/skills/install-openclaw-to-hetzner/` | `.agents/skills/install-openclaw-to-hetzner/` |
| Cursor | `~/.cursor/skills/install-openclaw-to-hetzner/` | `.cursor/skills/install-openclaw-to-hetzner/` |
| Gemini CLI | `~/.gemini/skills/install-openclaw-to-hetzner/` | `.agents/skills/install-openclaw-to-hetzner/` |
| OpenCode | `~/.config/opencode/skills/install-openclaw-to-hetzner/` | `.opencode/skills/install-openclaw-to-hetzner/` |
| OpenClaw | `~/.openclaw/skills/install-openclaw-to-hetzner/` | `skills/install-openclaw-to-hetzner/` |
| Other | see [skills.sh registry](https://skills.sh) | — |

Example (Claude Code, from this repo's checkout):

```bash
mkdir -p ~/.claude/skills/
cp -r skills/install-openclaw-to-hetzner ~/.claude/skills/
cp -r skills/openclaw-guide              ~/.claude/skills/   # required companion
```

Restart the agent. The skill is discovered automatically — no other registration step.

## Required companion skill

`openclaw-guide` (sibling folder) **must** be installed at the same time. Two roles:

1. **During install** — the wizard refuses to start without it loaded; the agent uses it to debug OpenClaw on the VM if anything breaks, instead of guessing from a stack trace.
2. **After install** — when the user later asks "how do I add Slack?", "set up a daily morning brief", or "connect CodeAlive search", the agent reads `openclaw-guide/references/*.md` rather than inventing answers. This wizard is silent after Step 5.

## Use

After install, type any of these to your agent:

- "install OpenClaw to Hetzner"
- "set up my CEO bot on Hetzner Cloud"
- "deploy OpenClaw to Hetzner"
- "поставь openclaw на hetzner"
- "разверни мне бота в hetzner cloud"

The skill takes over from there. It asks for **two-or-three** things in one or two messages — Telegram bot token + LLM access (always asked), Hetzner API token (only if not already configured) — then runs everything itself.

## What you need before running it

1. **`hcloud` CLI** — the skill installs it silently if missing (`brew install hcloud` on macOS, release binary on Linux). Avoid `apt install hcloud` — distro repos ship stale versions.
2. **A Hetzner Cloud account with verified status** ([console.hetzner.cloud](https://console.hetzner.cloud)). Fresh accounts go through fraud-review verification before the first server can be created — this is manual and can take hours to days. Resolution: complete any verification prompts shown in the console; if stuck for >24h, email `cda-review@hetzner.com`.
3. **Active payment method** (or a redeemed €20 signup credit — Hetzner offers €20 for new accounts, valid 3 months, sometimes auto-applied at signup, sometimes via a promo code). The credit covers ~4-5 months of a CAX11 bot.
4. **A Hetzner Cloud project** (any name). Tokens are project-scoped — whichever project you generate the token in is the one the VM will live in.
5. **Telegram bot token** from [@BotFather](https://t.me/BotFather). The wizard auto-detects `chat_id` after you press `/start` — you do **not** need to look it up via `@userinfobot`.
6. **LLM access — pick one:**
   - **A.** [Anthropic API key](https://console.anthropic.com/settings/keys) starting with `sk-ant-` + ≥$5 credit (recommended for first-time users; best raw quality)
   - **B.** [OpenRouter API key](https://openrouter.ai/keys) starting with `sk-or-` + ≥$5 credit (unified access to 200+ models)
   - **C.** Just write the word **"Codex"** if you have ChatGPT Plus ($20/mo) or Pro ($200/mo) — the wizard runs the OAuth device flow for you after VM bootstrap
7. **Local SSH key** at `~/.ssh/id_ed25519.pub` — auto-generated if missing.

The skill checks all of these in Step 0 and walks you through any missing piece before proceeding.

## What you get post-install

The VM ships with the full `ceo-ai-os` workspace (48 CEO skills pre-seeded), Telegram paired, and the bot replying in your language (Russian by default; German available; English is the ceo-ai-os default). Then your agent can help you, using the companion `openclaw-guide` skill:

- Add a daily morning brief: ask "set up a morning brief on my OpenClaw bot"
- Add competitive-radar cron: ask "set up competitor monitoring"
- Connect CodeAlive search: ask "add CodeAlive context engine to my bot" → `openclaw-guide/references/codealive-context-engine.md`
- Add another channel (Discord, Slack, WhatsApp, iMessage): ask "add Discord to my bot" → `openclaw-guide/references/channels.md`

## Folder layout

```
install-openclaw-to-hetzner/
├── SKILL.md                              # Wizard instructions (the brain)
├── SOURCE.md                             # Origin tracking
├── README.md                             # This file
├── scripts/
│   └── cloud-init.yaml                   # VM bootstrap (Node 22, OpenClaw, hardening, ceo-ai-os workspace, systemd)
└── references/
    ├── 01-prerequisites.md               # hcloud CLI, API token creation & scopes, SSH, account verification
    ├── 02-network-and-security.md        # Hetzner firewall model, public-IP rationale, hardening choices, lockout recovery (Rescue Mode)
    ├── 03-openclaw-config.md             # Telegram pairing, all three LLM providers, workspace seeding, ARM vs x86
    └── 04-troubleshooting.md             # 7 failure modes with copy-paste fixes
```

Channels other than Telegram, use cases (morning brief / research / competitive / decision), and CodeAlive integration are documented in the companion `openclaw-guide` skill — not here. This skill is install-only.

## Cost ceiling

A `cax11` 2 vCPU ARM / 4 GB / 40 GB SSD VM with IPv4 in `fsn1` costs **~€4.30/month** at current Hetzner rates (~€0.14/day). The €20 signup credit covers ~4-5 months of run. Stop the VM (`hcloud server poweroff openclaw-bot`) to pause CPU/RAM billing — disk + IPv4 still cost ~€0.54/mo.

Includes 20 TB outbound traffic per month at EU locations (overage €1.00/TB). A Telegram bot uses orders of magnitude less than this.

## Scope

This skill is for **fresh Hetzner Cloud VMs only**. For Yandex Cloud Kazakhstan, AWS, GCP, Azure, or any other provider, this skill will refuse to run.

| Target | Use |
|---|---|
| Hetzner Cloud (any location) | This skill |
| Yandex Cloud Kazakhstan | `install-openclaw-to-yc` (sibling skill) |
| Local machine | [`openclaw/install.sh`](../../openclaw/install.sh) in this repo |
| AWS / GCP / Azure / DigitalOcean | Not supported yet — build a parallel `install-openclaw-to-<cloud>` skill |

## License

MIT — see [LICENSE](../../LICENSE) at the repo root.
