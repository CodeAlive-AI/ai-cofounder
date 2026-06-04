# Network & security choices

This skill defaults to **public IP + open SSH ingress (key-only auth + fail2ban) + outbound-anywhere** because it's the simplest model that survives a single non-DevOps user, a workshop room with shared Wi-Fi, three follow-up days from a hotel, and — critically — an automation AI agent that makes frequent SSH calls from a changing IP.

Read this only if the user asks "why this and not …" or if you need to tighten the rules.

## Why a public IP (and not NAT Gateway)

A NAT Gateway gives outbound-only connectivity — you save on public-IP hours, but the user can't SSH in directly. To recover SSH access you need a jump host (another VM with a public IP), Yandex Cloud Serial Console (clunky), or Tailscale/wireguard (extra moving parts).

For a 2-day workshop the math is clear: public IP costs ~1.0 ₸/hour ≈ 50 ₸ for the workshop. Jump host = another VM = ~100 ₸/day + setup time. **Public IP wins.**

For a long-running personal-CEO bot, switching to NAT later is one command:

```bash
yc compute instance update --name openclaw-bot --network-interface index=0,nat-ip-version=none
# then attach to a NAT subnet, but that's a separate skill
```

## Why SSH ingress is open (0.0.0.0/0), not IP-locked

The wizard opens port 22 to `0.0.0.0/0` and does **not** lock it to any single IP. Two reasons:

1. **Dynamic IPs.** The user and the automation AI agent that manages this box both move around (home, hotel, shared workshop Wi-Fi, CI runner) — pinning ingress to one `/32` breaks SSH the moment the IP changes and forces a security-group edit the non-DevOps user can't do without help.
2. **An automation agent must never be IP-banned or rate-limited.** Deployment and ongoing maintenance are driven by an AI agent that makes frequent, already-authenticated SSH connections. A per-IP lock (or a connection rate-limit) drops those legitimate connections and effectively bans the agent.

So security does **not** rest on the network ingress CIDR. It rests on:

- **Key-only auth** — `PasswordAuthentication no`, `PubkeyAuthentication yes`, `AuthenticationMethods publickey`. A scanner hitting an open port 22 with no valid key never gets in.
- **fail2ban brute-force defense** — bans only on repeated FAILED authentications. A key-authenticated user or the automation agent never fails auth, so frequent legitimate SSH is never banned or throttled.

A user who genuinely wants to restrict SSH to a fixed IP or office CIDR can still edit the security group themselves (e.g. replace the ingress rule's `v4-cidrs` with their `<CIDR>`), but that is **not** the default and the wizard never does it automatically — the open default is the right trade-off for dynamic users plus an automation agent.

### Running the controlling agent over SSH (avoid self-inflicted bans)

The wizard removes the server-side throttles (`ufw allow` not `limit`, `MaxStartups 100:30:200`, `MaxSessions 50`, `MaxAuthTries 10`, fail2ban pinned to `mode = normal`). To stay clean from the **client** side, the agent making frequent SSH calls should:

- **Pin the identity:** `ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 openclaw@$IP …`. Without `IdentitiesOnly`, ssh offers every key in your agent/keyring first; on a machine with many keys those probes can rack up auth attempts (the reason `MaxAuthTries` was raised to 10). `IdentitiesOnly` makes ssh present only the one correct key, so auth succeeds on the first try and fail2ban never sees a failure.
- **Reuse the connection (optional but ideal for a busy agent):** multiplex many commands over one TCP connection via `ControlMaster auto` / `ControlPersist 10m` in `~/.ssh/config` (this is why `MaxSessions` is 50), eliminating handshake churn entirely.

With key-only auth + `mode = normal` fail2ban, an authenticated agent is never banned even without these client tweaks — they're defense-in-depth and a latency win, not a requirement.

## What `cloud-init.yaml` hardens on top of YC defaults

Yandex Cloud's Ubuntu 24.04 image is reasonable but plain. The cloud-init layers on a CIS-aligned, Mozilla "Modern" OpenSSH baseline.

### 1. SSH (drop-in at `/etc/ssh/sshd_config.d/99-openclaw-hardening.conf`)

Validated before `systemctl reload ssh` (a bad config would lock us out forever on a fresh VM).

| Directive | Value | Why |
|---|---|---|
| `PermitRootLogin` | `no` | Root SSH is still **on** by default in YC's stock Ubuntu image. Turn it off explicitly. |
| `PasswordAuthentication` | `no` | Key-only. |
| `KbdInteractiveAuthentication` | `no` | Belt and suspenders — `PasswordAuth=no` alone leaves PAM challenge-response paths open in some PAM configs. |
| `PubkeyAuthentication` | `yes` | The only allowed factor. |
| `PermitEmptyPasswords` | `no` | Default, but explicit for audit clarity. |
| `MaxAuthTries` | `10` | Raised from CIS's `3–4`: a controlling automation agent may offer several SSH identities from its agent/keyring before the right key — a low cap exhausts into "Too many authentication failures", which also trips fail2ban and bans the agent. Key-only auth keeps a higher value safe. (The agent should still use `-o IdentitiesOnly=yes`.) |
| `LoginGraceTime` | `30` | Drop slow / scanning connections fast. |
| `AllowUsers` | `openclaw` | Only one user can log in. |
| `MaxSessions` | `50` | Raised high so the automation AI agent's many concurrent SSH sessions are never throttled. A single human wouldn't need this, but the managing agent does. |
| `MaxStartups` | `100:30:200` | Raised so a high-frequency automation agent opening many connections isn't dropped pre-auth (probabilistic drops only start at 100 concurrent *unauth* connections, hard cap 200). Key-only auth keeps the open ceiling safe. |
| `ClientAliveInterval` / `CountMax` | `60` / `3` | Idle sessions disconnected after 3 min. |
| `AllowTcpForwarding` | `no` | OpenClaw never tunnels TCP. Disabling limits blast-radius if the key leaks. |
| `AllowAgentForwarding` | `no` | If the laptop key ever leaks **and** the user had agent-forwarding enabled, attacker could pivot to any other server in the user's SSH chain. Turn it off. |
| `AllowStreamLocalForwarding` | `no` | Same logic for Unix-socket forwarding. |
| `GatewayPorts` | `no` | Default, explicit. |
| `PermitTunnel` | `no` | Default in 9.x, explicit. |
| `X11Forwarding` | `no` | Headless server, never needed. |
| `PermitUserEnvironment` | `no` | Don't honor `~/.ssh/environment`. |
| `Compression` | `no` | CVE-2024-… mitigations: SSH compression has been a vector before. We don't need it. |
| `UseDNS` | `no` | Faster connect; doesn't grant security but avoids DNS-rebinding edge cases. |
| `LogLevel` | `VERBOSE` | Logs SSH key fingerprint of every successful auth — useful for audit. |
| `AuthenticationMethods` | `publickey` | Belt-and-suspenders: even if `PasswordAuthentication yes` is re-introduced by an OS update, only a key still works. |
| `RequiredRSASize` | `3072` | Reject any RSA key smaller than 3072 bits (OpenSSH 9.x+ feature). Our default is Ed25519, so this only matters if the user pastes an RSA key later. |

**Explicit crypto lists (`KexAlgorithms`, `Ciphers`, `MACs`, `HostKeyAlgorithms`):** we pin them rather than relying on defaults. The post-quantum hybrid `sntrup761x25519-sha512` goes first in `KexAlgorithms` (ssh-audit.com 2025 hardening profile), then curve25519, then DH 16/18. `Ciphers` is chacha20-poly1305 + AES-256/128-GCM + AES-256-CTR. `MACs` is encrypt-then-MAC only (`hmac-sha2-*-etm@openssh.com`). Pinning costs nothing since OpenSSH ships these algorithms already; if a future OS upgrade weakens defaults, our list keeps the bar at "modern + PQ".

### 2. ufw (firewall)

| Setting | Value | Why |
|---|---|---|
| Default ingress | `deny` | Everything closed by default. |
| Default egress | `allow` | OpenClaw needs to reach Anthropic / OpenAI / OpenRouter / Telegram / GitHub / npm — locking down outbound by domain is fragile. |
| Port 22 | `allow` (not `limit`) | No rate-limit, so the automation AI agent's frequent legitimate connects aren't dropped. The old `limit` (6 conn / 30s) throttled the agent's already-authenticated sessions. Brute-force defense is delegated entirely to fail2ban, which only acts on FAILED auths. |
| Logging | `low` | One line per blocked packet, no flood. |

### 3. fail2ban (escalating ban on brute force)

**fail2ban is the primary SSH security control** now that ingress is open and there's no ufw rate-limit. It bans **only on repeated FAILED authentications** — so a user (or the automation AI agent) connecting with a valid key never fails auth and is never banned or throttled, no matter how frequently they connect. That's precisely why it's safe to drop the IP lock and the rate-limit and lean on fail2ban: it punishes brute force, not high-frequency authenticated traffic.

Tuned forgiving on purpose. Recovery from a self-inflicted ban on a YC KZ VM requires the serial console (clunky for non-DevOps users), so we'd rather let one extra brute-force packet through than strand the founder for a week.

| Setting | Value | Why |
|---|---|---|
| `backend` | `systemd` | Ubuntu 24.04 sshd logs to journal, not `/var/log/auth.log`. Wrong backend = jail never fires. |
| `bantime` (default) | `1h` | First offense. |
| `findtime` | `10m` | Sliding window for hit counting. |
| `maxretry` (DEFAULT) | `6` | Default for any jail without its own value. |
| `maxretry` (sshd) | `5` | Tuned up from CIS's `3`. With key-only auth a real user already can't fail 5 times in 10 min unless their key file is genuinely wrong; a brute-forcer still hits the cap fast. |
| `banaction` | `ufw` | Bans via `ufw insert 1 deny from <IP>` — persists across fail2ban restarts. |
| `bantime.increment` | `true` | Recidivists get longer bans each time. |
| `bantime.factor` | `2` | 2× previous bantime per repeat (1h, 2h, 4h, …). |
| `bantime.maxtime` | `24h` | Cap at 24h, not 1w. Tuned down — a user who breaks their own SSH at Friday evening shouldn't be locked out until next Friday. |
| `bantime.rndtime` | `5m` | Adds random ± 5 min to break attacker timing. |
| `ignoreself` / `ignoreip` | `true` / `127.0.0.1/8 ::1` | Loopback and the host itself never banned. With ingress open to `0.0.0.0/0`, fail2ban is what stops brute force — but a legitimate user's (or the automation agent's) IP can only be banned after their key is *rejected* at sshd repeatedly, which never happens with a valid key. |

**Deliberately disabled:** the `[recidive]` long-memory jail (1w ban / 1d window / maxretry 3) is **off**. It catches slow-rate attackers across days, but on a single-user VM the same heuristic mis-fires on the legitimate user (typo on day 1, typo on day 2, typo on day 3 → 1 week lockout). The mainline `bantime.increment` already handles realistic brute-force in less hostile fashion.

### 3a. Recovery if you locked yourself out

This is the failure mode the soft-tuning above is designed to avoid, but it can still happen — e.g. user pastes their public key to `~/.ssh/authorized_keys` by hand and trashes the file. Path forward:

1. Open https://kz.console.yandex.cloud → Compute Cloud → click the VM → **Serial console**.
2. Login with username `openclaw` (no password works because of `lock_passwd: true`, but Serial Console drops into a root shell on YC if you press Enter at the boot menu within 5s of restart).
3. Unban yourself:
   ```bash
   sudo fail2ban-client unban --all
   ```
4. Or, if it's an SSH config break (not a ban), restore the drop-in:
   ```bash
   sudo rm /etc/ssh/sshd_config.d/99-openclaw-hardening.conf  # last-resort: drop the override
   sudo systemctl reload ssh
   ```

The serial console is the recovery channel of last resort. The wizard never uses it; only humans do, and only when something else has gone very wrong.

### 4. unattended-upgrades

| Setting | Value | Why |
|---|---|---|
| `Allowed-Origins` | `noble`, `noble-security`, ESM apps + infra security | Including the base codename (`noble`) is required so security patches can pull dependency upgrades from the regular pool — without it `dpkg` can stall on unmet deps. ESM channels apply when the host registers Ubuntu Pro (free for personal use); harmless if not. |
| `AutoFixInterruptedDpkg` | `true` | If a previous unattended run was killed mid-install, recover automatically. |
| `MinimalSteps` | `true` | Process upgrades in small batches — easier to interrupt cleanly if needed. |
| `Automatic-Reboot` | `true` | Apply kernel CVEs without manual touch. |
| `Automatic-Reboot-WithUsers` | `false` | Don't reboot mid-SSH-session if the founder happens to be logged in at 03:30. |
| `Automatic-Reboot-Time` | `03:30` UTC | Off-hours in most timezones — wakes up before founder's morning. |
| `Remove-Unused-Kernel-Packages` | `true` | Stops `/boot` filling up over months. |
| `Remove-Unused-Dependencies` | `true` | Trims attack surface from leftover packages. |
| `SyslogEnable` | `true` | Surface upgrade results to journal for `journalctl -u unattended-upgrades`. |

### 4a. Defensive snapd purge

YC's Ubuntu 24.04 minimal cloud image does **not** ship `snapd`, but we defensively `apt purge snapd` during bootstrap. Rationale: CVE-2026-3888 (LPE in snapd; any local user → root if vulnerable snapd is reachable). If a future YC image revision starts shipping snapd, we want it gone before anyone can exploit it.

### 4b. Sudo I/O logging (drop-in `/etc/sudoers.d/99-openclaw-logging`)

```
Defaults log_input, log_output
Defaults logfile="/var/log/sudo.log"
Defaults iolog_dir="/var/log/sudo-io"
```

Relevant because we keep `NOPASSWD: ALL` (see "What we don't do" below). If the SSH key leaks, this preserves a forensic trail of every command + its input/output before the attacker has a chance to clean up. `/var/log/sudo-io/` is `0750 root:adm`, `/var/log/sudo.log` is `0640 root:adm`.

### 5. systemd hardening (gateway unit)

The `openclaw-gateway.service` user-unit applies:

| Setting | Effect |
|---|---|
| `NoNewPrivileges=yes` | Process can't gain new caps via setuid binaries. |
| `PrivateTmp=yes` | Private `/tmp` namespace — can't sniff or race other users' tmp files. |
| `ProtectControlGroups=yes`, `ProtectKernelModules=yes`, `ProtectKernelTunables=yes`, `ProtectKernelLogs=yes`, `ProtectClock=yes` | Can't tamper with cgroups, load modules, write `/proc/sys`, read `dmesg`, or set system time. |
| `RestrictRealtime=yes` | No `SCHED_FIFO`/`SCHED_RR` — limits side-channel surface. |
| `RestrictSUIDSGID=yes` | Can't create suid binaries. |
| `LockPersonality=yes` | Can't change architecture personality (used in some exploits). |
| `RestrictNamespaces=yes` | Can't create user / network namespaces — blocks container escape primitives. |

These are all defaults-compatible — OpenClaw doesn't need any of these capabilities, so locking them off costs nothing.

## What we deliberately don't do

- **No SELinux / AppArmor profile tuning.** Ubuntu 24.04 ships AppArmor enforcing for system services; writing a custom profile for `openclaw gateway run` (a Node script that legitimately needs broad fs/net access) creates more breakage than security on a single-user VM.
- **No kernel sysctl hardening.** Most of the floating `99-hardening.sysctl` snippets are already the kernel default on Ubuntu 24.04. The few that aren't (e.g. `kernel.unprivileged_userns_clone=0`) would break `npm install` and AppArmor namespacing — not worth it for one VM.
- **No SSH certificate authority.** Plain Ed25519 keys are fine for one user. CA-signed certs are valuable when you rotate keys across 50+ engineers, not for one founder.
- **No CrowdSec / Lynis / OSSEC.** Great in production with a team to triage alerts. For a workshop bot they add ≥100 MB RAM and noise the user will never read.
- **No SSH host-key fingerprint pinning before first connect.** The wizard uses `accept-new` (TOFU) on first SSH because the YC console gives no out-of-band channel for the fingerprint at create time. The MITM window is the 30 seconds between VM creation and our first SSH — practically zero given how YC provisions.
- **No `NOPASSWD` removal.** Removing it forces an interactive password during cloud-init, which kills the autonomy goal. The risk model is "if attacker has the SSH key, sudo is already done for" — key-only auth + fail2ban carry the protection upstream (ingress is open, so the SSH key is the real gate).

If the user asks for any of the above, redirect them to a real DevOps engagement — out of scope for this skill.

## Outbound destinations OpenClaw needs

For reference if the user wants to switch to a stricter egress policy later:

| Service | Port | Why |
|---|---|---|
| Anthropic API | 443 | LLM calls (default model: claude-sonnet-4-6) |
| OpenAI API | 443 | If user later adds OpenAI as fallback |
| api.telegram.org | 443 | Bot adapter |
| Telegram MTProto endpoints | 443/80 | Polling |
| github.com / raw.githubusercontent.com | 443 | ceo-ai-os clone, updates |
| registry.npmjs.org | 443 | `npm install -g openclaw@latest` |
| api.ipify.org / icanhazip.com | 443 | Public-IP discovery (one-time) |

Locking down outbound by port (`only 443/tcp`) works. Locking down by destination domain is unstable — Telegram cycles IP ranges, npm CDN ranges shift, GitHub fronted by Fastly with broad ranges. Don't go there for a workshop bot.

## Cost ceiling (so the user can sleep)

A VM created by this wizard with public IP, in `kz1-a`, running 24/7, costs about **80–120 ₸/day** at current Yandex Cloud KZ rates (May 2026). The 24 000 ₸ trial grant covers **8–10 months** of continuous run. After the trial converts to paid, the same VM is about **2 500–3 500 ₸/month**.

If the user wants to pause:

```bash
yc compute instance stop --name openclaw-bot   # CPU/RAM stop billing; disk still charged
```

If the user wants to delete everything:

```bash
yc compute instance delete --name openclaw-bot
yc vpc security-group delete --name openclaw-bot-sg
```
