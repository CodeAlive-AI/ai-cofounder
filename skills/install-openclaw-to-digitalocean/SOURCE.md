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
  - v0.1.1 (field-test fixes after a real manual DO install run):
    * cloud-init phase 5: `openclaw onboard --no-prompt` was a silent no-op on
      current CLIs (Commander swallows the unknown flag). Real non-interactive
      mode is `--non-interactive --accept-risk` (confirmed in openclaw CHANGELOG:
      "require --accept-risk for --non-interactive"). Now tries the correct flags
      first, falls back to `--no-prompt` for older builds.
    * troubleshooting §4.5a: document the `systemctl --user` "Failed to connect
      to bus" trap when debugging via `ssh root@` without XDG_RUNTIME_DIR.
    * troubleshooting §4.5b: flag the benign install.sh warnings ("timed out
      during installer finalization probe", "No TTY; run openclaw onboard") so a
      human reading the bootstrap log doesn't mistake them for failures.
    NOTE: the onboard-flag fix (A3) also applies to install-openclaw-to-yc and
    install-openclaw-to-hetzner — same `--no-prompt` line. Not yet ported there.
  - v0.1.2: removed SSH rate-limiting (ufw `allow` instead of `limit`; raised
    MaxStartups 10:30:60 → 100:30:200 and MaxSessions 4 → 50) and the per-IP
    firewall lock (SSH now open to 0.0.0.0/0 + ::/0, dropped the MY_IP/ipify
    detection and SSH_CIDR logic) so an automation AI agent making frequent SSH
    calls from dynamic IPs is never throttled or banned; key-only auth + fail2ban
    remain the controls (fail2ban bans only on FAILED auths, never an
    authenticated key user). Touched cloud-init.yaml, SKILL.md, references/02,
    references/04.
  - v0.1.3: agent-safety hardening pass after audit. Two residual ways a frequent
    SSH agent could still get banned, now closed: (1) `MaxAuthTries 4→10` — a
    controlling agent offering several identities from its keyring would exhaust 4
    attempts into "Too many authentication failures", which is itself a fail2ban
    failure → ban; (2) pinned fail2ban `[sshd] mode = normal` so a future distro
    default of aggressive/ddos can't start counting the agent's pre-auth
    "Connection closed [preauth]" churn. Added a "Running the controlling agent
    over SSH" section (IdentitiesOnly + ControlMaster) to references/02 and fixed
    stale "tight SSH ingress" prose left over from v0.1.2.
  - v0.1.4: second-field-test hardening (Oleg's manual DO install report). Four
    genuine cloud-init bugs fixed, each verified against OpenClaw source via
    CodeAlive MCP BEFORE editing (to avoid another phantom-flag mistake):
    * #2 em-dash/Unicode in cloud-init comments -- one corrupted multibyte char
      (-> lone 0x80) made cloud-init reject the whole YAML and fall back to DO's
      default user-data, so NONE of the bootstrap ran. Template is now pure
      ASCII; the two Cyrillic locale packs are base64 (`encoding: b64`) with
      readable sources in scripts/locale/. Immune to byte mangling in transit.
      Also kills #12 (the blanket sanitizer that mojibake'd the locale).
    * #3 `sshd -t` ran before /run/sshd existed ("Missing privilege separation
      directory") -- a transient race that failed the whole `set -euo pipefail`
      bootstrap. Now `install -d -m 0755 /run/sshd` first.
    * #5 the gateway unit was a `--user` unit carrying system-mode
      Protect*/Restrict* directives, which an unprivileged user manager rejects
      with status=218/CAPABILITIES -- the gateway never started. Switched to a
      systemd SYSTEM service (/etc/systemd/system, User=openclaw): the sandboxing
      now applies and the linger/XDG_RUNTIME_DIR fragility is gone. Kept
      upstream's load-bearing RestartPreventExitStatus=78 / KillMode=control-group
      / SuccessExitStatus=0 143; dropped RestrictNamespaces (can break headless
      Chrome). Swept systemctl --user -> sudo systemctl across SKILL + references,
      rewrote troubleshooting §4.5a (XDG trap -> system-service note), added
      OPENCLAW_SERVICE_REPAIR_POLICY=external so `doctor --fix` can't install a
      competing user unit.
    * #6 was NOT a bug: source confirms `openclaw models auth login --provider
      openai-codex --device-code` is the correct current command and
      `openai-codex/gpt-5.5` a valid model id (a field note wrongly said to
      rename to `codex` + shell out to native `codex login`). Left the flow
      intact; added only a `plugins install clawhub:@openclaw/codex` fallback for
      the "No provider plugins found" edge + a do-not-rename note.
    Telegram raw-HTTP guard from the report was ignored on purpose (env-specific).
notes: |
  Wizard skill (for a code agent: Claude Code / Codex / Cursor / OpenClaw) that
  takes a non-DevOps user from zero to a working OpenClaw bot on a fresh
  DigitalOcean Droplet in ~15 minutes. Sibling of install-openclaw-to-yc; the
  bot config, cloud-init hardening, Telegram pairing and verification are
  identical — only the provider plumbing differs.

  Companion skill `openclaw-guide` is a required runtime dependency; the wizard
  blocks on Step 0a until it is loadable in the same code agent.
