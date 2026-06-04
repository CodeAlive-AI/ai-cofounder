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
notes: |
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
