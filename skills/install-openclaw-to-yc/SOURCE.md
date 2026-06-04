origin: original
source: custom (developed for an OpenClaw workshop)
url: —
installed: 2026-05-14
customizations:
  - "2026-06-04 (v0.9.1): removed SSH rate-limiting (ufw `allow` instead of `limit`; raised MaxStartups to 100:30:200 and MaxSessions to 50) and the per-IP security-group lock (SSH ingress now open to 0.0.0.0/0) so an automation AI agent making frequent SSH calls from dynamic IPs is never throttled or banned; key-only auth + fail2ban remain the controls. Updated SKILL.md (security-group rule, removed MY_IP detection, Do-NOT-ask / Decided-silently / Auto-recovery tables), references/02-network-and-security.md (SSH ingress rationale, ufw + sshd + fail2ban tables) and references/04-troubleshooting.md (§5 SSH publickey — dropped the wrong-IP cause)."
  - "2026-06-04 (v0.9.2): agent-safety hardening pass after audit — `MaxAuthTries 4→10` (a multi-key agent exhausting 4 attempts hits 'Too many authentication failures', which is a fail2ban failure → ban) and pinned fail2ban `[sshd] mode = normal` (so a future distro default of aggressive/ddos can't count the agent's pre-auth connection churn). Added a 'Running the controlling agent over SSH' section (IdentitiesOnly + ControlMaster) to references/02 and updated the MaxAuthTries directive table row."
  - "2026-06-04 (v0.9.3): ported the DigitalOcean field-test fixes (sibling parity), each verified against OpenClaw source via CodeAlive MCP before editing. cloud-init.yaml: #2 made pure ASCII (em-dashes/arrows in comments -> ASCII; the ru/kk locale packs are now base64 `encoding: b64` with readable sources in scripts/locale/, immune to byte-mangling in transit and fixing the locale-mojibake case); #3 `install -d /run/sshd` before `sshd -t` (the missing-privilege-separation-dir race that failed `set -euo pipefail`); #5 gateway moved from a `--user` unit to a systemd SYSTEM service (/etc/systemd/system, User=openclaw) so the Protect*/Restrict* sandboxing applies instead of dying with status=218/CAPABILITIES -- kept upstream RestartPreventExitStatus=78 / KillMode=control-group / SuccessExitStatus, dropped RestrictNamespaces (headless Chrome), added OPENCLAW_SERVICE_REPAIR_POLICY=external; swept systemctl --user -> sudo systemctl across SKILL + references. #6 (not a bug): kept the correct `openclaw models auth login --provider openai-codex --device-code` flow, added only a `plugins install clawhub:@openclaw/codex` fallback + do-not-rename note."
  - "2026-06-04 (v0.9.4): Codex model-id alignment, verified by read-only SSH checks on a live OpenClaw 2026.5.27 bot. Codex subscription models live in the `openai/` namespace (`openai/gpt-5.5`), not `openai-codex/*` (that profile only backs auth) -- switched model ids `openai-codex/*` -> `openai/*` (canonical; `doctor --fix` migrates the legacy form anyway); fixed the doubly-broken Step 3.5 probe (`models list --provider openai-codex` returns nothing + JSON flag is `--json` not `--format json`) to grep `models list --json` for `openai/gpt-5.5`; replaced stale `gpt-4o`/`gpt-4.5`/`o3` with the current `gpt-5.4`/`gpt-5.4-mini` (Plus) and `gpt-5.5`/`gpt-5.5-pro` (Pro). `--provider openai-codex` + `openai-codex:<email>` profile unchanged."
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
