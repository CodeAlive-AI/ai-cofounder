origin: original
source: custom (developed for OpenClaw workshop install flow)
url: —
installed: 2026-05-21
customizations: []
notes: |
  Post-install onboarding skill. Runs immediately after install-openclaw-to-yc
  Step 5 (verification) to collect five fields about the user — identity,
  focus, communication style, tools, anti-patterns — and write them into
  USER.md on the bot's VM via atomic SSH upload, followed by a session reset
  so the bot picks up the new profile from the next Telegram message.

  Also works standalone for later profile updates: reads the existing
  USER.md, pre-fills slots, asks "what changed?" instead of starting over.

  Designed to feel like the last 2-3 minutes of install, not a separate
  survey. One message with all five questions, free-form answers, safe
  defaults for skipped fields, single confirmation before writing.

  Paired with install-openclaw-to-yc version 0.8.0+; older install wizards
  do not auto-trigger onboarding and the user must invoke this skill
  explicitly.
