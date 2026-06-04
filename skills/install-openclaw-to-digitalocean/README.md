# install-openclaw-to-digitalocean

Wizard skill that takes a non-DevOps user from zero to a working OpenClaw bot on a fresh **DigitalOcean Droplet** (default region `fra1`, Frankfurt) in ~15 minutes. Asks for a DigitalOcean API token, a Telegram bot token, and one of three LLM access options (Anthropic key, OpenRouter key, or OpenAI Codex OAuth via ChatGPT Plus/Pro), then creates the Droplet, hardens it, installs OpenClaw with the CEO AI OS workspace, wires Telegram, auto-detects `chat_id`, configures the bot to reply in the user's language, and verifies the bot answers.

This is the **DigitalOcean sibling of [`install-openclaw-to-yc`](../install-openclaw-to-yc/)**. The flow, cloud-init, hardening, Telegram pairing and verification are identical; what differs is the provider plumbing:

| | install-openclaw-to-yc | install-openclaw-to-digitalocean |
|---|---|---|
| CLI | `yc` | `doctl` |
| Auth | Yandex OAuth (`oauth.yandex.kz`) + endpoint/cloud-id/folder-id | One API token in a dedicated `doctl` context |
| SSH key | passed inline at create | **uploaded to the account first** (`ssh-key import`) |
| Firewall | YC security group | DO Cloud Firewall (separate resource) + host ufw |
| Default region | `kz1-a` (Karaganda) | `fra1` (Frankfurt) — no DC in Central Asia |
| Default size | 2 vCPU / 4 GB / 30 GB | `s-2vcpu-4gb` (2 vCPU / 4 GB / 80 GB, ~$24/mo) |
| "Pause to save money" | `yc compute instance stop` (cheap) | **does not exist** — powered-off Droplets still bill; only destroy stops the charge |

**Always install together with `openclaw-guide`** — required at runtime; it owns all post-install consulting (channels, use cases, debugging, CodeAlive integration). Strongly recommended: also install **`openclaw-user-onboarding`** — auto-invoked at Step 5.5 to collect five basic facts about the user and write them into USER.md.

## Install

### Recommended — Skills CLI

```bash
npx skills add CodeAlive-AI/ceo-ai-os@install-openclaw-to-digitalocean -g
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-guide                    -g   # required
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-user-onboarding          -g   # recommended
```

Then **restart your code agent** so it picks up the new skill.

### Manual — drop the folder into your agent's skills directory

The directory name MUST stay `install-openclaw-to-digitalocean`.

| Agent | Path (global) | Path (project) |
|---|---|---|
| Claude Code / Cowork | `~/.claude/skills/install-openclaw-to-digitalocean/` | `.claude/skills/install-openclaw-to-digitalocean/` |
| Codex | `~/.codex/skills/install-openclaw-to-digitalocean/` | `.agents/skills/install-openclaw-to-digitalocean/` |
| Cursor | `~/.cursor/skills/install-openclaw-to-digitalocean/` | `.cursor/skills/install-openclaw-to-digitalocean/` |
| OpenCode | `~/.config/opencode/skills/install-openclaw-to-digitalocean/` | `.opencode/skills/install-openclaw-to-digitalocean/` |
| OpenClaw | `~/.openclaw/skills/install-openclaw-to-digitalocean/` | `skills/install-openclaw-to-digitalocean/` |

## Use

After install, type any of these to your agent:

- "install OpenClaw to DigitalOcean"
- "spin up an OpenClaw droplet"
- "set up my CEO bot on DigitalOcean"

The skill takes over. It asks for **three** things — a DigitalOcean API token (once), a Telegram bot token, and LLM access — then runs everything itself.

## What you need before running it

1. **`doctl` CLI** — installed silently if missing.
2. **A DigitalOcean account with a payment method** — a fresh account with no card has a Droplet limit of 0 and can't create anything. Promotional credit ($200/60d via referral) still needs a verified card.
3. **A DigitalOcean API token** — [cloud.digitalocean.com/account/api/tokens](https://cloud.digitalocean.com/account/api/tokens) → Generate New Token → Full Access (or write on droplet/ssh_key/firewall). Starts `dop_v1_`.
4. **Telegram bot token** from [@BotFather](https://t.me/BotFather). `chat_id` is auto-detected after `/start`.
5. **LLM access — pick one:** Anthropic key (`sk-ant-`, ≥$5), OpenRouter key (`sk-or-`, ≥$5), or just write **"Codex"** if you have ChatGPT Plus/Pro.
6. **Local SSH key** at `~/.ssh/id_ed25519.pub` — auto-generated and uploaded to the account if missing.

## The "dangerous install" note

OpenClaw is an agent with **full shell access** on its Droplet and stores credentials in **plaintext**. The wizard hardens the box (dedicated non-root user, tight SSH, ufw + fail2ban, systemd sandbox, loopback-only gateway) but does not make it absolutely safe. **Put nothing on this Droplet you can't afford to lose or leak** — no prod credentials, no customer data. Full threat model in `references/02-network-and-security.md` §0.

## What you get post-install

The full `ceo-ai-os` workspace (48 CEO skills), Telegram paired, the bot replying in your language (Russian by default). Then your agent can extend it via `openclaw-guide`: daily morning brief, competitive radar, CodeAlive search, extra channels (Discord/Slack/WhatsApp/iMessage).

## Folder layout

```
install-openclaw-to-digitalocean/
├── SKILL.md                              # Wizard instructions (the brain)
├── SOURCE.md                             # Origin tracking (derived from install-openclaw-to-yc)
├── README.md                             # This file
├── scripts/
│   └── cloud-init.yaml                   # Droplet bootstrap (swap, Node, OpenClaw, hardening, ceo-ai-os, systemd)
└── references/
    ├── 01-prerequisites.md               # doctl, API token + contexts, SSH-key upload, billing checks
    ├── 02-network-and-security.md        # Cloud Firewall, hardening, the "dangerous install" threat model, cost
    ├── 03-openclaw-config.md             # Telegram pairing, all three LLM providers, workspace seeding
    ├── 04-troubleshooting.md             # Failure modes incl. the power-off-still-bills trap
    └── 05-marketplace-and-workshop.md    # DO Marketplace 1-Click alternative + workshop shared-token mode
```

## Cost ceiling

`s-2vcpu-4gb` running 24/7 ≈ **$24/mo**; the budget `s-1vcpu-2gb` ≈ **$12/mo** (cloud-init adds 2 GB swap so it survives). **A powered-off Droplet bills the same as a running one** — to stop paying, snapshot + destroy, or just destroy. See `references/02` and `references/04` §7.

## Scope

Fresh DigitalOcean Droplets only. For Yandex Cloud Kazakhstan use [`install-openclaw-to-yc`](../install-openclaw-to-yc/); for AWS/GCP/Azure or DO App Platform/Kubernetes this skill refuses. For a local-machine install use `openclaw/install.sh` in the ceo-ai-os repo.

## License

MIT.
