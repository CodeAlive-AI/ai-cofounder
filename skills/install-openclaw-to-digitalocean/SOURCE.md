origin: original
source: custom (derived from install-openclaw-to-yc)
url: https://github.com/CodeAlive-AI/ai-cofounder/tree/main/skills/install-openclaw-to-yc
installed: 2026-06-04
customizations:
  - Ported the install-openclaw-to-yc wizard from Yandex Cloud to DigitalOcean.
  - Replaced `yc` CLI with `doctl`; dropped the entire KZ/RU endpoint +
    cloud-id/folder-id complexity (DigitalOcean is a single global API).
  - API-token auth via a dedicated `doctl` context instead of Yandex OAuth.
  - SSH key must be uploaded to the DO account first (`ssh-key import`) — DO
    does not accept a raw pubkey at droplet-create time (new step 0e).
  - DO Cloud Firewall (separate, droplet-attached resource) instead of a YC
    security group; kept host-level ufw + fail2ban as a second layer.
  - Default region fra1 (Frankfurt) — DigitalOcean has no Central-Asia DC;
    fra1 is the lowest-latency DC for KZ/CIS/EU. Fallback ams3.
  - cloud-init adds a 2 GB swapfile (phase 0) and purges snapd (DO's stock
    image ships it, unlike YC's minimal image).
  - Documented the DigitalOcean billing trap: powered-off Droplets STILL bill;
    only destroy (optionally snapshot first) stops the charge. The YC skill's
    cheap "stop the VM" pause does not exist here.
  - Added an explicit "dangerous install" threat-model section (references/02
    §0) surfacing OpenClaw's full-shell-access / plaintext-credential risk.
  - references/05 covers the DO Marketplace 1-Click image (and why automation
    skips it) + a simplified workshop shared-token mode — no SA-key bundle
    pipeline like YC's prepare-yc-workshop is needed.
notes: |
  Wizard skill (for a code agent: Claude Code / Codex / Cursor / OpenClaw) that
  takes a non-DevOps user from zero to a working OpenClaw bot on a fresh
  DigitalOcean Droplet in ~15 minutes. Sibling of install-openclaw-to-yc; the
  bot config, cloud-init hardening, Telegram pairing and verification are
  identical — only the provider plumbing differs.

  Companion skill `openclaw-guide` is a required runtime dependency; the wizard
  blocks on Step 0a until it is loadable in the same code agent.
