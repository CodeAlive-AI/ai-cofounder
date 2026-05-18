# Network & security choices

This skill defaults to **public IP + tight SSH ingress + outbound-anywhere** because it's the simplest model that survives a single non-DevOps user, a workshop room with shared Wi-Fi, and three follow-up days from a hotel.

Read this only if the user asks "why this and not …" or if you need to tighten the rules.

## Why a public IP (and not NAT Gateway)

A NAT Gateway gives outbound-only connectivity — you save on public-IP hours, but the user can't SSH in directly. To recover SSH access you need a jump host (another VM with a public IP), Yandex Cloud Serial Console (clunky), or Tailscale/wireguard (extra moving parts).

For a 2-day workshop the math is clear: public IP costs ~1.0 ₸/hour ≈ 50 ₸ for the workshop. Jump host = another VM = ~100 ₸/day + setup time. **Public IP wins.**

For a long-running personal-CEO bot, switching to NAT later is one command:

```bash
yc compute instance update --name openclaw-bot --network-interface index=0,nat-ip-version=none
# then attach to a NAT subnet, but that's a separate skill
```

## Why SSH default is "this machine's IP only"

The wizard's default is to detect the user's current public IP (`curl -s https://api.ipify.org`) and open port 22 only to that `/32`. This is dramatically safer than `0.0.0.0/0` for a workshop full of brand-new keys.

When SSH is locked to one IP, **the user must change the security-group rule** if their IP changes (going home, switching networks, etc.):

```bash
NEW_IP=$(curl -s https://api.ipify.org)
yc vpc security-group update-rules openclaw-bot-sg \
  --add-rule "direction=ingress,port=22,protocol=tcp,v4-cidrs=[$NEW_IP/32]" \
  --remove-rule-ids <old-rule-id>
```

If the user objects ("I move around a lot, just open it"), let them pick:

| Choice | What we do |
|---|---|
| Lock to my IP (recommended) | ingress 22/tcp from `<MY_IP>/32` |
| Open to the world | ingress 22/tcp from `0.0.0.0/0`. fail2ban+SSH key-only auth handles 99% of script kiddies. |
| Lock to my office subnet | ingress 22/tcp from `<CIDR>` (user provides) |

Pick option 2 if and only if the user explicitly accepts the trade-off.

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
| `MaxAuthTries` | `4` | Disconnect on the 5th try. Tuned up from CIS's `3` because non-DevOps users frequently mistype the key passphrase 2–3 times on first connect — `3` would trip them before they're warmed up. |
| `LoginGraceTime` | `30` | Drop slow / scanning connections fast. |
| `AllowUsers` | `openclaw` | Only one user can log in. |
| `MaxSessions` | `4` | One legit user shouldn't need more. |
| `MaxStartups` | `10:30:60` | Drop unauth connections under flood (start probabilistic drops at 30 concurrent unauth, hard cap 60). |
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
| Port 22 | `limit` (not `allow`) | Rate-cap 6 connections / 30s **before** traffic even reaches sshd. Strict superset of fail2ban — a connection flood that doesn't trigger a fail2ban jail still gets throttled here. |
| Logging | `low` | One line per blocked packet, no flood. |

### 3. fail2ban (escalating ban on brute force)

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
| `ignoreself` / `ignoreip` | `true` / `127.0.0.1/8 ::1` | Loopback and the host itself never banned. Combined with ufw's `<MY_IP>/32` ingress this means a legitimate user's IP can't be banned without their key first being rejected at sshd. |

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
- **No `NOPASSWD` removal.** Removing it forces an interactive password during cloud-init, which kills the autonomy goal. The risk model is "if attacker has the SSH key, sudo is already done for" — fail2ban + ufw + tight ingress carry the protection upstream.

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
