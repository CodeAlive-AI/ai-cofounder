origin: original
source: custom (adapted from install-openclaw-to-yc for Hetzner Cloud)
url: —
installed: 2026-05-21
customizations:
  - Hetzner Cloud CLI (hcloud) replaces yc — project-scoped API tokens instead of OAuth
  - Default location fsn1 (Falkenstein, Germany), default server type cax11 (ARM Ampere, 2 vCPU / 4 GB / 40 GB)
  - Public IPv4 + IPv6 by default (+€0.50/mo for IPv4); --without-ipv4 path documented but not default
  - Single mode only — no Plan B / workshop-bundle equivalent (Hetzner has no native multi-tenant analogue of YC folders that fits the bundle pattern; if needed, build a separate `prepare-hetzner-workshop` later)
  - Hetzner firewall model adapted — default-DENY inbound (must add SSH rule explicitly), default-ALLOW outbound (no rule needed for Telegram/Anthropic/OpenRouter/OpenAI egress)
  - Cloud-init reused from YC version (ARM-compatible — no hardcoded eth0); only currency, console URLs, and CLI invocations differ
  - 0.1.1 (2026-06-04) — removed SSH rate-limiting (ufw `allow` instead of `limit`; raised MaxStartups 10:30:60→100:30:200 and MaxSessions 4→50) and per-IP firewall lock (SSH open to 0.0.0.0/0 + ::/0, MY_IP/ipify detection dropped) so an automation AI agent making frequent SSH calls from dynamic IPs is never throttled or banned; key-only auth + fail2ban remain the controls (fail2ban bans only repeated FAILED auths, never an authenticated key user)
  - 0.1.2 (2026-06-04) — agent-safety hardening pass after audit: `MaxAuthTries 4→10` (a multi-key agent exhausting 4 attempts would hit "Too many authentication failures" → a fail2ban failure → ban) and pinned fail2ban `[sshd] mode = normal` (so a future distro default of aggressive/ddos can't start counting the agent's pre-auth connection churn). Added a "Running the controlling agent over SSH" section (IdentitiesOnly + ControlMaster) to references/02 and fixed stale "tight SSH ingress" prose left over from 0.1.1.
  - 0.1.3 (2026-06-04) -- ported the DigitalOcean field-test fixes + fixed one Hetzner-only bug, all verified against OpenClaw source via CodeAlive MCP before editing. #14 (Hetzner-only): the snapd apt-pin heredoc (`cat > ... <<'PIN'`) put its body at column 0 inside the 6-space YAML block scalar, dedenting out of the block and making the ENTIRE cloud-init invalid YAML (same failure class as #2) -- replaced with `printf` so every line stays indented. Ported from DO: #2 cloud-init now pure ASCII with the ru/de locale packs base64'd (`encoding: b64`, readable sources in scripts/locale/); #3 `install -d /run/sshd` before `sshd -t`; #5 gateway switched to a systemd SYSTEM service (/etc/systemd/system, User=openclaw) so Protect*/Restrict* applies instead of status=218/CAPABILITIES (kept RestartPreventExitStatus=78 / KillMode=control-group, dropped RestrictNamespaces for headless Chrome, added OPENCLAW_SERVICE_REPAIR_POLICY=external, swept systemctl --user -> sudo systemctl). #6 (not a bug): kept the openai-codex device-code flow, added a `plugins install clawhub:@openclaw/codex` fallback + do-not-rename note.
  - 0.1.4 (2026-06-04) -- Codex model-id alignment, verified by read-only SSH checks on a live OpenClaw 2026.5.27 bot. Codex subscription models live in the `openai/` namespace (`openai/gpt-5.5`), not `openai-codex/*` (that profile only backs auth) -- switched model ids `openai-codex/*` -> `openai/*` (canonical; `doctor --fix` migrates the legacy form); fixed the doubly-broken Step 3.5 probe (`models list --provider openai-codex` returns nothing + JSON flag is `--json` not `--format json`) to grep `models list --json` for `openai/gpt-5.5`; replaced stale `gpt-4o`/`gpt-4.5`/`o3` with current `gpt-5.4`/`gpt-5.4-mini` (Plus) + `gpt-5.5`/`gpt-5.5-pro` (Pro). `--provider openai-codex` + `openai-codex:<email>` profile unchanged.
  Companion to install-openclaw-to-yc, not a replacement. Pick by the target
  cloud. Both end with the same shape: one VM, one OpenClaw bot paired to
  Telegram, CEO AI OS workspace seeded. Step 5.5 hands off to
  openclaw-user-onboarding identically across both skills.

  CAX11 (ARM) is the default for cost reasons (~€3.79/mo vs Hetzner CX22 x86
  same price but no architectural redundancy). If a future ceo-ai-os skill
  depends on an x86-only native binary, fall back to cx22 — both are 2 vCPU /
  4 GB / 40 GB at the same price.

  Paired with install-openclaw-to-yc version 0.9.0+ (Step 5.5 onboarding
  hand-off pattern is identical).
