# OpenClaw Setup Guide

The skills in this repo work in any agent, but with OpenClaw you get the full autonomous CEO OS experience: the agent lives in your Telegram/WhatsApp/Discord, proactively sends you insights, runs daily recaps, tracks hypotheses across sessions, and nudges you when you're drifting from the constraint. It's not a tool you open — it's a Chief of Staff that works in the background.

## Prerequisites

- [OpenClaw](https://openclaw.ai) installed and running
- A messaging channel connected (Telegram, WhatsApp, Discord, or Slack)
- An AI provider configured (OpenAI, Anthropic, or Google)

## Installation

### Option 1: Install script (recommended)

Installs all 48 skills, bootstrap files, and memory system in one command:

```bash
git clone https://github.com/CodeAlive-AI/ai-cofounder.git
cd ai-cofounder/openclaw
./install.sh
```

### Option 2: Remote server

```bash
git clone https://github.com/CodeAlive-AI/ai-cofounder.git
cd ai-cofounder

# Copy bootstrap files
scp -r openclaw/workspace/* user@server:~/.openclaw/workspace/

# Copy all skills
scp -r skills/* user@server:~/.openclaw/workspace/skills/

# Fix permissions
ssh user@server 'chown -R openclaw:openclaw ~/.openclaw/workspace/'
```

### Option 3: Cherry-pick skills

If you only want specific skills:

```bash
cd ai-cofounder

# Copy bootstrap files (required)
cp openclaw/workspace/SOUL.md ~/.openclaw/workspace/
cp openclaw/workspace/AGENTS.md ~/.openclaw/workspace/
cp openclaw/workspace/IDENTITY.md ~/.openclaw/workspace/
cp openclaw/workspace/USER.md ~/.openclaw/workspace/
cp openclaw/workspace/MEMORY.md ~/.openclaw/workspace/

# Copy specific skills
cp -r skills/hypothesis-tracker ~/.openclaw/workspace/skills/
cp -r skills/decision-playbook ~/.openclaw/workspace/skills/
# ... add the ones you want

# Create memory system
mkdir -p ~/.openclaw/workspace/memory/weekly
echo '{"hypotheses": []}' > ~/.openclaw/workspace/memory/hypotheses.json
```

Update AGENTS.md to list only the skills you installed.

## After Installation

### 1. Customize your workspace

Edit the template files — see [CUSTOMIZATION.md](CUSTOMIZATION.md) for details:

- `IDENTITY.md` — Name your agent
- `USER.md` — Tell it about yourself
- `MEMORY.md` — Fill in your company context (most important step)

### 2. Start a new session

Send `/new` in your chat to load the workspace.

### 3. Verify it works

Try saying "run a strategic review of my current positioning" or "show me the decision playbook for changing ICP". The agent should load the skill and walk you through the framework.

## Optional: Adding Tools

The base CEO OS works without external tools. But for full power, you can add:

- **PostHog** — product analytics (see [../docs/adding-tools.md](../docs/adding-tools.md))
- **Exa Search** — company/people research
- **agent-browser** — web browsing

These require [mcporter](https://github.com/steipete/mcporter) for MCP bridge support.

## Recommended Model

The CEO OS works best with reasoning-capable models:
- **Claude Sonnet 4** or **Claude Opus 4** (recommended)
- **GPT-4o** or **o3**
- **Gemini 2.5 Pro**

Simpler models may struggle with multi-step skills like `ceo-weekly-review` or `strategic-review`.

## Troubleshooting

### Agent doesn't use skills
- Check that AGENTS.md lists the skills correctly
- Run `/new` to reload the workspace
- Verify skills are in `~/.openclaw/workspace/skills/`

### Bootstrap too large
- OpenClaw has a context budget (default ~15,000 chars for bootstrap files)
- Keep MEMORY.md < 3KB, AGENTS.md < 2KB, SOUL.md < 3KB
- Skills load on-demand and don't count toward bootstrap budget

### Memory not persisting
- Check that `memory/` directory exists and is writable
- After server restarts, verify file permissions: `chown -R openclaw:openclaw ~/.openclaw/workspace/`
