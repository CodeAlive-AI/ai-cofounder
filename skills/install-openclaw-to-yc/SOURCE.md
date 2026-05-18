origin: original
source: custom (developed for an OpenClaw workshop)
url: —
installed: 2026-05-14
customizations: []
notes: |
  Wizard skill that takes a non-DevOps participant from zero to a working
  OpenClaw bot on a fresh Yandex Cloud Kazakhstan VM in ~15 minutes.
  Targets the workshop audience: Telegram bot + Anthropic API key + tight
  SSH ingress + ceo-ai-os workspace seeded by the upstream install.sh.

  Hard-coded for the kz1-a zone — Yandex Cloud Kazakhstan, Karaganda DC,
  api.yandexcloud.kz:443 endpoint, separate billing in tenge. Will refuse
  to run against the Russian endpoint.

  Companion skill `openclaw-guide` is a required dependency: the wizard
  blocks on Step 0 until that skill is loadable in the same code agent.
