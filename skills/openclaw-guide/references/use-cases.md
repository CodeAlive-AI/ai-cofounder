# Use cases — what to build on top of a working bot

Recurring patterns that most CEO / founder bots end up running. Each section: **what it does**, **which skills to install**, **minimal cron/config**, **gotchas**. Skills live at https://github.com/CodeAlive-AI/ceo-ai-os/tree/main/skills — install with `npx skills add CodeAlive-AI/ceo-ai-os@<skill>` and (re-)sync the workspace to the VM.

## 1. Morning brief + evening recap

**What.** Bot sends a one-message digest at the start and end of the day: yesterday's wins, today's calendar, the metric that needs a decision, anything overdue. Saves a full standup of context-switching every morning.

**Skills.** `daily-recap` covers both halves. The skill knows to call `metrics-briefing` if PostHog is configured.

**Cron setup (Europe/Berlin timezone shown):**

```bash
# Morning brief at 09:30
sudo -u openclaw openclaw cron add \
  --name morning-brief \
  --cron "30 9 * * *" \
  --tz Europe/Berlin \
  --session-key agent:main:cron-morning-brief \
  --timeout-seconds 600 \
  --announce --channel telegram --to <CHAT_ID> \
  --message "Run daily-recap morning brief skill."

# Evening recap at 21:00
sudo -u openclaw openclaw cron add \
  --name evening-recap \
  --cron "0 21 * * *" \
  --tz Europe/Berlin \
  --session-key agent:main:cron-evening-recap \
  --timeout-seconds 600 \
  --announce --channel telegram --to <CHAT_ID> \
  --message "Run daily-recap evening recap skill."
```

**Gotchas.**

- Use `--session-key agent:main:cron-<name>`, NOT `--session isolated` — isolated sessions can't deliver to Telegram (pitfall #1).
- Set `--timeout-seconds` explicitly (pitfall #18) — 600 s is comfortable for both halves.
- The bot reads MEMORY.md for company context — keep it curated. A bot that doesn't know your current constraint produces generic briefs.
- If you also use Google Calendar, install the Google Calendar MCP server first (see `references/04-mcp.md`) — the brief becomes meaningfully better.

## 2. Research workflow (company + people)

**What.** Before any sales call, partnership meeting, or hire conversation, ask the bot "research X" and get a one-page profile back in ~30 seconds: positioning, traction, recent moves, key people, where they're vulnerable.

**Skills.**

- `exa-company-research` — full company profile
- `exa-people-research` — find and profile specific individuals
- `exa-lead-gen` — discover companies fitting your ICP
- `exa-personal-site` — find personal blogs / portfolios for a target
- `exa-x-search` — Twitter/X surface for a name or company

**Prerequisites.**

- Exa API key from https://dashboard.exa.ai/api-keys
- Add Exa as an MCP server (one of three flavours — pick whichever matches your dominant query type):

```bash
sudo -u openclaw openclaw mcp set exa-search '{
  "url": "https://mcp.exa.ai/mcp?tools=web_search_advanced_exa&exaApiKey=${EXA_API_KEY}",
  "transport": "streamable-http"
}'
echo "EXA_API_KEY=..." | sudo tee -a /home/openclaw/.openclaw/gateway.env >/dev/null
# Restart gateway via pitfall #20 sequence
```

**Usage.** Just ask the bot — "research Acme Corp before my call with their CEO tomorrow" or "find 10 series-B SaaS companies in fintech with ICP X".

**Gotchas.**

- Exa's `chat` / `deep_search_exa` tools are slow (10–30 s by design) — if a query times out at 600 s, raise `--timeout-seconds` on any cron job that uses them.
- `exa-research-setup` (if it exists) is the per-channel wizard equivalent — useful for onboarding others; the manual flow above is faster for an experienced user.

## 3. Competitive radar (fully autonomous)

**What.** The bot watches 4–10 named competitors daily and pings you only when something **significant** changes — a release, a price page edit, a CMO/VP-Sales hire, a funding announcement. Silent on quiet days; that's the point.

**Skills.** `competitive-analysis`, optionally `signal-scanner` and `pr-opportunity-scanner` for richer surface.

**Setup.** The skill stores its watchlist in `~/.openclaw/workspace/memory/competitors.json`. After installing the skill, talk to the bot once: *"track Acme, Beta Co, Gamma. Sites + blog + GitHub + LinkedIn. Alert me if something significant changes."* It populates the watchlist.

**Cron (daily 07:00 local):**

```bash
sudo -u openclaw openclaw cron add \
  --name competitive-radar \
  --cron "0 7 * * *" \
  --tz Europe/Berlin \
  --session-key agent:main:cron-competitive-radar \
  --timeout-seconds 1200 \
  --best-effort-deliver --channel telegram --to <CHAT_ID> \
  --message "Run competitive-analysis skill. Watchlist in memory/competitors.json. Silent if nothing significant."
```

**Gotchas.**

- Define **what "significant" means** in the prompt or in `competitors.json` — without a threshold the bot pings you for every blog comma.
- 1200 s timeout because the skill makes ~N×4 web fetches and stays on the polite side of rate limits.
- The `--best-effort-deliver` flag means a delivery hiccup doesn't crash the job — important for an unattended overnight task.
- Use the Exa MCP server (above) for higher-signal fetches than naive scraping.

## 4. Decision playbook (thinking partner)

**What.** When you have a hard decision — pricing change, hire/fire, pivot, big customer concession — ask the bot to walk you through structured deliberation. It enforces a process: clarify the decision, list options with kill-criteria, surface what you'd need to believe to be wrong, schedule a review.

**Skills.** `decision-playbook` is the workflow. `anti-pattern-audit` and `fpf-problem-solving` are good companions for diagnostic stages.

**Usage.** No cron, no MCP. Just say: *"help me decide whether to raise prices 30%"*. The skill takes over the conversation, asks the structured questions, and persists the decision and review date to MEMORY.md (with your approval — it's MEMORY.md, human-owned).

**Pattern (what the skill does well):**

1. Clarifies the decision to the level it can be wrong (otherwise you can't review it)
2. Lists 2–4 distinct options, not just "yes/no"
3. Identifies kill-criteria for each — "I'd reverse this if X happens"
4. Schedules a review in 7 / 30 / 90 days depending on reversibility
5. Logs the decision + the assumptions you stated to MEMORY.md

**Gotchas.**

- Decisions are only useful if you review them. The skill writes a review cron when you confirm. Don't dismiss it.
- For irreversible decisions, the skill is more cautious — that's by design; if you're sure, say so explicitly and it'll move on.

## 5. Email handler (multi-mailbox IMAP/SMTP)

**What.** Bot classifies incoming email, surfaces only what needs your attention, drafts replies for routine threads. Works across multiple mailboxes (work + personal + legacy).

**Pattern.** This use case usually deploys as a **second agent** alongside the main CEO bot — for example, a second-bot pattern in the CEO AI OS reference deployment. The second agent is configured in its own workspace (`workspace-second-bot/`) with its own Telegram bot, and IMAP polling runs as a separate systemd service that POSTs new messages to `/hooks/agent` on the gateway.

**Why a second agent.** The main CEO bot's MEMORY.md is strategic (wedge, ICP, constraint). Mixing inbox classification into the same persona dilutes both — the second agent stays sharply on email and personal ops.

**Infrastructure.**

- Per-mailbox IMAP credentials in a `accounts.json` with `chmod 600`
- A polling service (Python systemd timer) that hits each mailbox every ~5 min and posts new messages to the gateway webhook
- Per-account SMTP for outbound, with proper threading headers (`In-Reply-To`, `References`)
- A `mail-send` skill in the second agent's workspace that calls the SMTP bridge

**Multi-agent setup** is out of scope for this single-file walk-through — see `https://github.com/CodeAlive-AI/ceo-ai-os` and look at the `second-bot/` pattern + `imap-bridge/` service for the reference implementation.

**Gotchas.**

- Don't run email through the main CEO bot. The persona conflicts and the MEMORY.md gets noisy. Second agent every time.
- Webhook security: validate the incoming hook signature before forwarding to the agent. The reference deployment uses HMAC-SHA256 on each request.

## 6. Meeting prep + calendar integration

**What.** 30 min before each calendar event, the bot sends a one-message brief: who you're meeting, their recent context, the open thread from your last meeting (if any), three questions worth asking.

**Skills.** `meeting-prep` (uses `exa-company-research` + `exa-people-research` underneath). Calendar source can be Google Calendar via the official MCP server, or a self-hosted CalDAV bridge.

**Setup outline (Google Calendar via MCP):**

```bash
# Install the Google Calendar MCP server (community)
sudo -u openclaw openclaw mcp set gcal '{
  "command": "uvx",
  "args": ["google-calendar-mcp"],
  "env": { "GOOGLE_OAUTH_TOKEN": "${GCAL_TOKEN}" }
}'
# Then a cron that scans the calendar every 5 min and triggers meeting-prep for events in the next 30 min
sudo -u openclaw openclaw cron add \
  --name meeting-prep-watcher \
  --every "5m" \
  --session-key agent:main:cron-meeting-prep \
  --timeout-seconds 600 \
  --no-deliver \
  --message "Check calendar for events in next 30 min. For each new one, run meeting-prep skill and deliver brief 30 min before start."
```

**Gotchas.**

- 5-minute polling is fine for a personal calendar. For a team calendar with hundreds of events, switch to Google Pub/Sub instead (https://docs.openclaw.ai/automation/gmail-pubsub covers the analogue for Gmail).
- The skill needs at least one prior memory of who the person is — pre-warm by running `exa-people-research` on key contacts and saving notes to MEMORY.md.

## Picking which one to install first

If you have to pick one to demonstrate value within the first week of bot ownership, **install the morning brief**. It hits every day, the value is obvious, and it forces you to curate MEMORY.md (which makes every subsequent skill better).

The natural progression after morning brief:

1. **Morning brief** — daily habit, forces MEMORY.md hygiene
2. **Research workflow** — pre-call prep, weekly habit
3. **Decision playbook** — for the next hard call you face
4. **Competitive radar** — once you have 4–10 named competitors to watch
5. **Meeting prep** — once calendar integration is worth the setup time
6. **Email handler** — separate agent, biggest infrastructure lift; deploy when manual triage hurts

Don't try to install all six at once. Each one demands a small amount of MEMORY.md curation and prompt-tuning; spreading them across weeks lets you see what's actually moving the needle.
