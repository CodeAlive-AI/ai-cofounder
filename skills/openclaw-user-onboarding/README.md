# openclaw-user-onboarding

A short conversational step that runs immediately after a fresh OpenClaw install. Asks the user five intentional questions (identity, focus, communication style, tools, anti-patterns), parses the free-form answer, renders `USER.md`, uploads it atomically to the bot's VM, and resets the active Telegram session so the bot picks up the new profile from the very next message.

Difference it makes:
- **Without this:** the bot's first message reads as "Здравствуйте, чем могу помочь?" — generic, anonymous, requires the user to spend a week training it.
- **With this:** the bot knows the user's name, role, what matters this week, how they prefer to be addressed, and what NOT to do — from message one.

## Install

```bash
# Recommended: skills CLI
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-user-onboarding -g
```

Manual install paths per agent are the same as `install-openclaw-to-yc/README.md` — copy the folder into `~/.claude/skills/`, `~/.codex/skills/`, etc.

## Use — two paths

### 1. Auto-triggered after install (default)

When `install-openclaw-to-yc` finishes Step 5 (verification), it hands off to this skill automatically before the final summary. The user just continues the same conversation — there's no separate command to remember.

### 2. Standalone (later, to update)

```
обнови мой профиль для бота
let's redo onboarding
расскажу о себе ещё раз — обнови USER.md
```

In standalone mode the skill reads the current `USER.md` from the VM, pre-fills the slots, and asks "что поменялось?" instead of starting from scratch.

## What you need

| Input | Where it comes from | Required? |
|---|---|---|
| VM public IPv4 | install-openclaw-to-yc Step 2, or `yc compute instance get` for standalone | yes |
| SSH user (`openclaw`) | hard-coded | yes |
| Telegram chat_id | install-openclaw-to-yc Step 4 (auto-detected) | recommended (used for session reset) |
| User language (`ru`/`en`/`kk`) | install-openclaw-to-yc Step 0 (auto-detected) | recommended (defaults to `ru`) |
| Agent type (`main` / `routinet`) | hard-coded to `main` unless overridden | no |

SSH must already work. This skill does NOT debug SSH — that's `install-openclaw-to-yc/references/04-troubleshooting.md` §5's job.

## Five fields collected

1. **Identity** — name, role, company/project, stage
2. **Focus** — what matters in the next 1-2 weeks
3. **Style** — language(s), emoji yes/no, formality, direct vs. soft feedback
4. **Tools** — email, calendar, messengers, code agent
5. **Anti-patterns** — what the bot should NOT do

The user can answer in any format (bullets, paragraph, voice-to-text transcribed by the agent). Skipped fields get safe defaults — the skill never grills.

## What it writes

A single file: `/home/openclaw/.openclaw/workspace/USER.md` (or `…/workspace-routinet/USER.md` for the routinet agent). Mode 600, owned by `openclaw:openclaw`. Full replacement, not append — USER.md is human-curated and we are the human's representative.

Template and worked example are in `references/02-user-md-template.md`.

## What it does NOT cover

- The bot's persona, voice, runtime behaviour → `SOUL.md` (separate, agent-owned)
- Strategic context (company stage, OKRs, constraints) → `MEMORY.md` (human-curated, separate)
- Daily logs and conversation memory → `memory/YYYY-MM-DD.md` (agent-owned, append-only)
- Adding skills / channels / MCP servers → use `openclaw-guide`

## Folder layout

```
openclaw-user-onboarding/
├── SKILL.md                              # wizard instructions
├── SOURCE.md                             # origin tracking
├── README.md                             # this file
├── scripts/
│   └── upload-user-md.sh                 # atomic scp + chown + session reset
└── references/
    ├── 01-questions.md                   # full question variants (ru/en/kk), rationale for each field, slot table
    └── 02-user-md-template.md            # USER.md template, worked example, what NOT to write
```

## Companion skills

- **`install-openclaw-to-yc`** — triggers this skill automatically after Step 5
- **`openclaw-guide`** — owns ongoing consultation after onboarding

## License

MIT — see `LICENSE` at repo root.
