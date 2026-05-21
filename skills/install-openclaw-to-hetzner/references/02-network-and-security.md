# Network & security choices

This skill defaults to **public IPv4 + IPv6 + tight SSH ingress + outbound-anywhere** because it's the simplest model that survives a single non-DevOps user, a workshop room with shared Wi-Fi, and three follow-up days from a hotel.

Read this only if the user asks "why this and not …" or if you need to tighten the rules.

## Hetzner firewall model (read first)

Hetzner Cloud has a **cloud-level firewall** that lives outside the VM. It's stateless and attached to one or more servers. Two non-obvious rules:

1. **Inbound is default-DENY when a firewall is attached.** If you create a firewall and attach it to a server *without adding any inbound rules*, the server becomes unreachable on every port — including SSH. This is the opposite of YC's "default policy" approach.
2. **Outbound is default-ALLOW when no outbound rules are set.** The wizard doesn't add any outbound rules, so all egress works out of the box: Telegram Bot API (443), Anthropic (443), OpenRouter (443), npm registry (443), GitHub (443), Hetzner's apt mirror (80/443). If you want to *restrict* outbound, you must add explicit rules — but the default permissive behaviour is what we want for a self-managing bot.

The wizard creates one firewall (`openclaw-bot-fw`) with two inbound rules:

- TCP 22 from `<MY_IP>/32` (SSH from the operator laptop)
- ICMP from `0.0.0.0/0` and `::/0` (so the user can `ping` during diagnostics)

That's it. Outbound is left at default-allow.

## Why a public IPv4 (and not IPv6-only or NAT)

Hetzner charges €0.50/month for a Primary IPv4. IPv6 is free.

The wizard always creates the server with IPv4+IPv6 (Hetzner's default). Reasons:

- **SSH from anywhere works.** Many mobile networks, hotel Wi-Fi, and corporate VPNs in 2026 still route IPv4 only. An IPv6-only server is unreachable from those.
- **Telegram Bot API is fine over either,** but third-party services (npm registry, some Hetzner mirror nodes) intermittently fail on IPv6 paths. An IPv4 outbound path is the reliable fallback.
- **€0.50/month is rounding error.** Total cost is ~€4.30/mo with IPv4 vs ~€3.80/mo without.

If a power user explicitly asks for IPv6-only:

```bash
hcloud server create ... --without-ipv4
```

Make them say "yes I understand SSH may break from some networks" — out of scope for this skill's default path.

## Why SSH default is "this machine's IP only"

The wizard's default is to detect the user's current public IP (`curl -s https://api.ipify.org`) and open port 22 only to that `/32`. This is dramatically safer than `0.0.0.0/0` for a fresh key.

When SSH is locked to one IP, **the user must update the firewall rule** if their IP changes (going home, switching networks, etc.):

```bash
NEW_IP=$(curl -s https://api.ipify.org)
# Hetzner firewall rules are stateless; you replace the entire rule set
hcloud firewall delete-rule openclaw-bot-fw \
  --direction in --protocol tcp --port 22 --source-ips <old-ip>/32

hcloud firewall add-rule openclaw-bot-fw \
  --direction in --protocol tcp --port 22 \
  --source-ips "$NEW_IP/32" \
  --description "SSH from operator laptop (updated)"
```

If the user objects ("I move around a lot, just open it"), let them pick:

| Choice | What we do |
|---|---|
| Lock to my IP (recommended) | inbound 22/tcp from `<MY_IP>/32` |
| Open to the world | inbound 22/tcp from `0.0.0.0/0`. fail2ban + SSH key-only auth handles 99% of script kiddies. |
| Lock to my office subnet | inbound 22/tcp from `<CIDR>` (user provides) |

Pick option 2 if and only if the user explicitly accepts the trade-off.

## What `cloud-init.yaml` hardens on top of Hetzner defaults

Hetzner's Ubuntu 24.04 image is the upstream Canonical cloud image. It's reasonable but plain. The cloud-init layers on a CIS-aligned, Mozilla "Modern" OpenSSH baseline.

### 1. SSH (drop-in at `/etc/ssh/sshd_config.d/99-openclaw-hardening.conf`)

Validated before `systemctl reload ssh` (a bad config would lock us out forever on a fresh VM).

| Directive | Value | Why |
|---|---|---|
| `PermitRootLogin` | `no` | Root SSH is still **on** by default in Hetzner's stock Ubuntu image. Turn it off explicitly. |
| `PasswordAuthentication` | `no` | Key-only. |
| `KbdInteractiveAuthentication` | `no` | Belt and suspenders. |
| `PubkeyAuthentication` | `yes` | The only allowed factor. |
| `PermitEmptyPasswords` | `no` | Default, but explicit for audit clarity. |
| `MaxAuthTries` | `4` | Disconnect on the 5th try. Tuned up from CIS's `3` because non-DevOps users frequently mistype the key passphrase 2–3 times on first connect. |
| `LoginGraceTime` | `30` | Drop slow / scanning connections fast. |
| `AllowUsers` | `openclaw` | Only one user can log in. |
| `MaxSessions` | `4` | One legit user shouldn't need more. |
| `MaxStartups` | `10:30:60` | Drop unauth connections under flood. |
| `ClientAliveInterval` / `CountMax` | `60` / `3` | Idle sessions disconnected after 3 min. |
| `AllowTcpForwarding` | `no` | OpenClaw never tunnels TCP. |
| `AllowAgentForwarding` | `no` | If the laptop key ever leaks **and** the user had agent-forwarding enabled, attacker could pivot to any other server in the user's SSH chain. |
| `AllowStreamLocalForwarding` | `no` | Same logic for Unix-socket forwarding. |
| `X11Forwarding` | `no` | Headless server. |
| `PermitUserEnvironment` | `no` | Don't honor `~/.ssh/environment`. |
| `Compression` | `no` | SSH compression has been an exploit vector before. We don't need it. |
| `UseDNS` | `no` | Faster connect. |
| `LogLevel` | `VERBOSE` | Logs SSH key fingerprint of every successful auth. |
| `AuthenticationMethods` | `publickey` | Belt-and-suspenders: even if `PasswordAuthentication yes` is re-introduced by an OS update, only a key still works. |
| `RequiredRSASize` | `3072` | Reject RSA keys smaller than 3072 bits. Default is Ed25519 so this only matters if the user pastes an RSA key later. |

**Explicit crypto lists** (`KexAlgorithms`, `Ciphers`, `MACs`, `HostKeyAlgorithms`) — pinned to ssh-audit.com 2025 hardening profile, post-quantum hybrid first.

### 2. ufw (in-VM firewall, defense-in-depth)

The Hetzner cloud-level firewall is the first line. UFW inside the VM is the second — useful if the user later detaches the cloud firewall or if a workload binds to an unexpected port.

| Setting | Value | Why |
|---|---|---|
| Default ingress | `deny` | Everything closed by default. |
| Default egress | `allow` | OpenClaw needs to reach many SaaS APIs. |
| Port 22 | `limit` (not `allow`) | Rate-cap 6 connections / 30s before traffic reaches sshd. |
| Logging | `low` | One line per blocked packet, no flood. |

### 3. fail2ban (escalating ban on brute force)

Tuned forgiving on purpose. Recovery from a self-inflicted ban requires the Hetzner console's VNC (clunky for non-DevOps users), so we'd rather let one extra brute-force packet through than strand the founder for a week.

| Setting | Value | Why |
|---|---|---|
| `backend` | `systemd` | Ubuntu 24.04 sshd logs to journal. |
| `bantime` (default) | `1h` | First offense. |
| `findtime` | `10m` | Sliding window. |
| `maxretry` (sshd) | `5` | A real user with key-only auth can't fail 5 times in 10 min unless their key file is genuinely wrong. |
| `banaction` | `ufw` | Bans persist across fail2ban restarts. |
| `bantime.increment` | `true` | Recidivists get longer bans each time (2× previous). |
| `bantime.maxtime` | `24h` | Cap at 24h, not 1w — recovery via console is painful. |
| `ignoreself` / `ignoreip` | `true` / `127.0.0.1/8 ::1` | Loopback never banned. |

**Deliberately disabled:** `[recidive]` long-memory jail. On a single-user VM the heuristic mis-fires on the legitimate user.

### 3a. Recovery if you locked yourself out

1. Open https://console.hetzner.cloud → click the server → **Console** (or "Open VNC console").
2. Login with username `openclaw` — no password works because of `lock_passwd: true`, so use the rescue mode if you need a root shell:
   - https://console.hetzner.cloud → server → **Rescue** → Enable Rescue → reboot.
   - The server boots into Hetzner's rescue Linux with SSH from anywhere via a one-time password Hetzner shows in the console.
   - Mount the real disk (`mount /dev/sda1 /mnt`), fix the SSH config or unban yourself, reboot back to normal mode.
3. Alternative (faster if fail2ban locked you): use VNC console to run `sudo fail2ban-client unban --all`.

Rescue mode is the recovery channel of last resort. The wizard never uses it; only humans do, and only when something else has gone very wrong.

### 4. unattended-upgrades

| Setting | Value | Why |
|---|---|---|
| `Allowed-Origins` | `noble`, `noble-security`, ESM apps + infra | Including the base codename is required so security patches can pull dependency upgrades. |
| `AutoFixInterruptedDpkg` | `true` | Recovers automatically from killed runs. |
| `MinimalSteps` | `true` | Easier to interrupt cleanly. |
| `Automatic-Reboot` | `true` | Apply kernel CVEs without manual touch. |
| `Automatic-Reboot-WithUsers` | `false` | Don't reboot mid-SSH-session. |
| `Automatic-Reboot-Time` | `03:30` UTC | Off-hours in most timezones. |
| `Remove-Unused-Kernel-Packages` | `true` | Stops `/boot` filling up. |
| `SyslogEnable` | `true` | Surface results to journal. |

### 4a. Defensive snapd purge

Hetzner's Ubuntu 24.04 cloud image ships with `snapd` (it's the upstream Canonical image — Hetzner doesn't strip it). CVE-2026-3888 (LPE in snapd; any local user → root) means a vulnerable snapd is a real risk. OpenClaw doesn't use snaps, so the bootstrap purges it and adds an apt-pin to prevent reinstall.

```bash
apt-get purge -y snapd
cat > /etc/apt/preferences.d/no-snapd <<'PIN'
Package: snapd
Pin: release a=*
Pin-Priority: -1
PIN
```

### 4b. Sudo I/O logging

```
Defaults log_input, log_output
Defaults logfile="/var/log/sudo.log"
Defaults iolog_dir="/var/log/sudo-io"
```

Relevant because we keep `NOPASSWD: ALL`. If the SSH key leaks, this preserves a forensic trail.

### 5. systemd hardening (gateway unit)

The `openclaw-gateway.service` user-unit applies `NoNewPrivileges`, `PrivateTmp`, `ProtectControlGroups`, `ProtectKernelModules/Tunables/Logs/Clock`, `RestrictRealtime`, `RestrictSUIDSGID`, `LockPersonality`, `RestrictNamespaces`. All defaults-compatible — OpenClaw doesn't need any of these capabilities, so locking them off costs nothing.

## What we deliberately don't do

- **No SELinux / AppArmor profile tuning.** Ubuntu 24.04 ships AppArmor enforcing for system services. Writing a custom profile for `openclaw gateway run` creates more breakage than security on a single-user VM.
- **No kernel sysctl hardening.** Most of the floating snippets are already kernel defaults on Ubuntu 24.04. The few that aren't would break `npm install` and AppArmor namespacing.
- **No SSH certificate authority.** Plain Ed25519 keys are fine for one user.
- **No CrowdSec / Lynis / OSSEC.** Great in production with a team to triage alerts; for a workshop bot they add noise and RAM.
- **No SSH host-key fingerprint pinning before first connect.** The wizard uses `accept-new` (TOFU). The MITM window is the 30 seconds between VM creation and our first SSH — practically zero given Hetzner provisioning speed.
- **No `NOPASSWD` removal.** Removing it forces an interactive password during cloud-init, which kills the autonomy goal.

If the user asks for any of the above, redirect them to a real DevOps engagement — out of scope for this skill.

## Outbound destinations OpenClaw needs

For reference if the user wants to switch to a stricter egress policy later:

| Service | Port | Why |
|---|---|---|
| Anthropic API (`api.anthropic.com`) | 443 | LLM calls (default model: claude-sonnet-4-6) |
| OpenAI API (`api.openai.com` + `auth.openai.com`) | 443 | If user picked Codex OAuth (Step 3.5) and any fallback model |
| OpenRouter API (`openrouter.ai`) | 443 | If user picked OpenRouter |
| `api.telegram.org` | 443 | Bot adapter |
| Telegram MTProto endpoints | 443/80 | Polling |
| GitHub (`github.com`, `raw.githubusercontent.com`) | 443 | ceo-ai-os clone, updates |
| npm registry (`registry.npmjs.org`) | 443 | `npm install -g openclaw@latest` |
| Hetzner mirror (`mirror.hetzner.com`) | 80/443 | `apt update` |
| `api.ipify.org` / `icanhazip.com` | 443 | Public-IP discovery (one-time during install only) |

Locking down outbound by port (`only 443/tcp`) works. Locking down by destination domain is unstable — Telegram cycles IP ranges, npm CDN ranges shift. Don't go there for a personal bot.

## Cost ceiling (so the user can sleep)

A VM created by this wizard with public IPv4+IPv6, in `fsn1`, running 24/7, costs approximately:

| Resource | Monthly | Notes |
|---|---|---|
| CAX11 server | ~€3.79 | Pre-April-2026 price |
| Primary IPv4 | €0.50 | Even when stopped |
| 40 GB SSD | €0.00 | Included |
| 20 TB outbound traffic | €0.00 | Included; overage €1.00/TB |
| **Total** | **~€4.30/mo (~€0.14/day)** | |

Annual estimate: ~€51/year for the VM, plus LLM provider costs (Anthropic ~$3/M input tokens for Sonnet, OpenRouter +5%, Codex covered by ChatGPT subscription).

If the user wants to pause (server stopped, disk + IPv4 still bill):

```bash
hcloud server poweroff openclaw-bot
```

This drops CPU/RAM billing — disk continues at ~€0.04/mo for 40 GB SSD, IPv4 continues at €0.50/mo. Roughly €0.54/mo when fully stopped.

If the user wants to delete everything:

```bash
hcloud server delete openclaw-bot
hcloud firewall delete openclaw-bot-fw
# Check for an unattached Primary IP — should auto-delete, but check:
hcloud primary-ip list
hcloud primary-ip delete <id>   # if any
```

Nothing else this wizard created lives outside those resources.
