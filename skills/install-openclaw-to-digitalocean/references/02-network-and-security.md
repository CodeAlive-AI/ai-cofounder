# Network & security choices (and the "dangerous install" threat model)

This skill defaults to **public IPv4 + SSH open to all (Cloud Firewall, key-only auth) + outbound-anywhere + host-level ufw/fail2ban**. SSH is intentionally NOT locked to a single IP — users and the automation AI agent that manages the box connect from dynamic IPs and must never be IP-banned or rate-limited (see "Why SSH is open to all" below). The security control is key-only auth + fail2ban, neither of which depends on the source IP.

Read the first section even if you skip the rest — it's the honest accounting of why an OpenClaw install is a "dangerous" thing to stand up, and what this wizard does and doesn't fix.

## 0. Why this is called a "dangerous install"

OpenClaw is not a sandboxed SaaS. On the box it runs on, it is effectively a remote-controlled operator:

| Risk | Reality | What we do about it |
|---|---|---|
| **Full shell access** | The gateway runs an LLM that can execute arbitrary commands (that's the point — it's an agent). A prompt-injection or a confused-deputy moment can run anything the `openclaw` user can run. | Dedicated non-root `openclaw` user; systemd **system**-service sandboxing (`NoNewPrivileges`, `PrivateTmp`, `ProtectKernel*`/`Clock`); the box holds nothing but the bot. |
| **Plaintext credentials** | Provider API keys and the Telegram token sit in `~/.openclaw/gateway.env` (mode 600) and `auth-profiles.json`. Anyone who gets the SSH key or root can read them. | Key-only auth (the SSH key is the only way in), ufw + fail2ban, sudo I/O logging for forensics. Keys are scoped/cheap to rotate (a $5 Anthropic key, a revocable bot token). |
| **Bootstrap secrets in metadata** | DO keeps the rendered cloud-init (with the injected secrets) at `169.254.169.254/metadata/v1/user-data` for the Droplet's life. No API wipes it. | We scrub the on-disk copy; we treat the Droplet as single-tenant and tell the user not to add other users. |
| **Standing cloud token** | The DO API token can create/destroy across the account. | Use a **scoped, named, expiring** token (`openclaw`, 90 days); the running bot never uses it — only provisioning/teardown does. Revoke it after setup if you won't manage via CLI for a while. |
| **Outbound to anywhere** | The bot can reach any internet host (needed for LLM + Telegram + tools). Data exfil is possible if the agent is subverted. | Accepted trade-off for a personal CEO bot. Egress lockdown by domain is fragile (see §Outbound). |

**The one rule to give the user:** *put nothing on this Droplet you can't afford to lose or leak.* No prod credentials, no customer data, no password-manager exports. If they need that, it's a real DevOps engagement, not this wizard.

This is the same risk profile as the Yandex Cloud sibling skill and as a local OpenClaw install — calling it out explicitly is the only "extra" the word "dangerous" buys you.

## Why a public IP (and not a private-only Droplet)

A private-only Droplet (DO's 2026 VPC-only feature, `--enable-public-networking=false`) has no inbound path for SSH — you'd need a bastion/jump Droplet or a VPN. For a single non-DevOps user that's more moving parts than security. A public IP with a Cloud Firewall (SSH open to all, but key-only auth + fail2ban as the controls) is the right trade-off.

A public IPv4 is included in the Droplet price on DO (no separate hourly charge like some clouds), so there's no cost argument against it either.

## Why SSH default is open to all (no per-IP lock)

The wizard opens port 22 to everyone (`0.0.0.0/0` + `::/0`) via the Cloud Firewall. It does **not** lock SSH to any single IP. Two reasons:

1. **Dynamic IPs.** Users (and the automation AI agent that deploys and maintains the bot) connect from IPs that change — home ↔ office ↔ café, mobile networks, CI runners. A `/32` lock breaks the moment the IP changes, and a non-DevOps user can't easily fix it.
2. **The automation agent must never be IP-banned or throttled.** Deployment and ongoing work is driven by an AI agent that makes frequent, already-authenticated SSH calls. Locking SSH to one IP — or rate-limiting it — would drop those legitimate connections.

The security model therefore rests on two controls that don't care about source IP:

- **Key-only auth** — `PasswordAuthentication no`, `AuthenticationMethods publickey`, `PermitRootLogin no`, `AllowUsers openclaw`. An open port 22 with no password path is not a meaningful attack surface for scanners.
- **fail2ban** — bans brute-forcers, but **only on repeated FAILED authentications**. A key-authenticated user or the automation agent never fails auth, so it is never rate-limited or banned. This is the whole point: brute force is stopped without ever penalising a successful key login.

A user who *does* want to restrict access by IP/CIDR can edit the firewall (replace the `0.0.0.0/0,::/0` inbound rule with their `<CIDR>`), but the default is open — and an IP-locked firewall is incompatible with running the automation agent from a dynamic IP.

### Running the controlling agent over SSH (avoid self-inflicted bans)

The wizard removes the server-side throttles (`ufw allow` not `limit`, `MaxStartups 100:30:200`, `MaxSessions 50`, `MaxAuthTries 10`, fail2ban pinned to `mode = normal`). To stay clean from the **client** side, the agent making frequent SSH calls should:

- **Pin the identity:** `ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 openclaw@$IP …`. Without `IdentitiesOnly`, ssh offers every key in your agent/keyring first; on a machine with many keys those probes can still rack up auth attempts (the reason `MaxAuthTries` was raised to 10). `IdentitiesOnly` makes ssh present only the one correct key, so auth succeeds on the first try and fail2ban never sees a failure.
- **Reuse the connection (optional but ideal for a busy agent):** multiplex many commands over one TCP connection instead of a fresh handshake each time —
  ```
  # ~/.ssh/config
  Host openclaw-bot
      HostName <IP>
      User openclaw
      IdentityFile ~/.ssh/id_ed25519
      IdentitiesOnly yes
      ControlMaster auto
      ControlPath ~/.ssh/cm-%r@%h:%p
      ControlPersist 10m
  ```
  This collapses dozens of `ssh openclaw-bot 'cmd'` calls into sessions on a single connection (which is exactly why `MaxSessions` is 50), eliminating handshake churn entirely.

With key-only auth + `mode = normal` fail2ban, an authenticated agent is never banned even without these client tweaks — they're defense-in-depth and a latency win, not a requirement.

## Two firewalls, on purpose

| Layer | Where | What it does |
|---|---|---|
| **DO Cloud Firewall** | DigitalOcean network edge, before packets reach the Droplet | Default-deny inbound except SSH open to `0.0.0.0/0` + `::/0` (no per-IP lock — see above); allow all outbound. A separate resource, attached by Droplet ID. |
| **ufw (host)** | Inside the Droplet | Default-deny inbound, `allow 22/tcp` (no rate-limit so the automation agent's frequent connects aren't dropped), allow all outbound. |

Defense in depth: if someone detaches or misconfigures the Cloud Firewall, ufw still holds; if ufw is reset, the Cloud Firewall still holds. The gateway port `18789` is opened by **neither** — it binds to loopback and is reached only over SSH.

## What `cloud-init.yaml` hardens on top of DO defaults

DigitalOcean's stock Ubuntu 24.04 image enables root SSH login and ships `snapd` + `do-agent`. The cloud-init layers on a CIS-aligned, Mozilla "Modern" baseline. The full directive-by-directive rationale is identical to the Yandex Cloud sibling skill; the highlights:

### 1. SSH (drop-in `/etc/ssh/sshd_config.d/99-openclaw-hardening.conf`)

Validated with `sshd -t` **before** reload (a bad config would lock us out of a fresh Droplet). Key changes: `PermitRootLogin no` (DO's image leaves it on), `PasswordAuthentication no`, `AllowUsers openclaw`, `MaxAuthTries 10` (raised so a multi-key automation agent doesn't exhaust auth attempts), all forwarding off, post-quantum-first KEX, ETM-only MACs, `RequiredRSASize 3072`. See the YC skill's `02-network-and-security.md` §1 for the per-directive table — it applies verbatim.

### 2. ufw

Default deny in / allow out; `allow 22/tcp` (**not** `limit`) — no rate-limit, so the automation agent's frequent, already-authenticated SSH connects are never dropped; `logging low`. Brute force is handled by fail2ban (below), which only ever bans on FAILED auths. The sshd drop-in also raises `MaxStartups` to `100:30:200` and `MaxSessions` to `50` so a high-frequency automation agent is never throttled pre-auth.

### 3. fail2ban

`backend = systemd` (Ubuntu 24.04 logs sshd to the journal — wrong backend = jail never fires), `maxretry 5` for sshd, escalating `bantime` capped at 24h, `[recidive]` deliberately **off** (too easy to self-lock a 1-user box for a week). fail2ban stays on for brute-force defense and is the reason SSH itself carries no rate limit: it bans **only on repeated FAILED authentications**, so a key-authenticated user or the automation agent — which never fails auth — is never rate-limited or banned. Recovery if you lock yourself out is via the **DigitalOcean Recovery Console** (Droplet → Access → Launch Recovery Console) — see §Recovery below.

### 4. unattended-upgrades

Auto security patches, reboot at 03:30 UTC only if no user is logged in, prune old kernels/deps.

### 4a. Defensive snapd purge

Unlike YC, DO's stock image **does** ship `snapd`. We stop and `apt purge` it (CVE-2026-3888, LPE → root). OpenClaw needs none of it.

### 5. systemd hardening (gateway unit)

The gateway runs as a systemd **system** service (`/etc/systemd/system/openclaw-gateway.service`, `User=openclaw`) — **not** a `--user` unit. That choice is load-bearing: a user-mode unit can't apply the sandboxing below (an unprivileged user manager rejects `Protect*`/`Restrict*` with `status=218/CAPABILITIES`, so the gateway would refuse to start), and it would need fragile `enable-linger` + `XDG_RUNTIME_DIR` plumbing on a headless box. As a system service none of that applies.

Directives: `NoNewPrivileges`, `PrivateTmp`, `ProtectControlGroups/KernelModules/KernelTunables/KernelLogs/Clock`, `RestrictRealtime/SUIDSGID`, `LockPersonality`, plus `MemoryHigh=1500M` / `MemoryMax=2500M` with `Restart=always` (and upstream's `RestartPreventExitStatus=78` + `KillMode=control-group`) for self-recovery. `RestrictNamespaces` is intentionally **omitted** — OpenClaw can spawn a headless Chrome/browser worker that relies on namespaces. Combined with the 2 GB swapfile the bootstrap adds, this survives the gateway's slow RSS creep even on a 2 GB Droplet.

### Recovery if you lock yourself out

1. DigitalOcean dashboard → the Droplet → **Access** → **Launch Recovery Console** (an in-browser root console; works even when SSH is dead).
2. Unban yourself: `fail2ban-client unban --all`
3. Or, if it's an SSH-config break: `rm /etc/ssh/sshd_config.d/99-openclaw-hardening.conf && systemctl reload ssh`

The wizard never uses the recovery console — only humans do, only when something went very wrong.

## What we deliberately don't do

Same list as the YC skill: no SELinux/AppArmor custom profile, no kernel sysctl beyond swappiness, no SSH CA, no CrowdSec/Lynis/OSSEC, no host-key pinning before first connect (TOFU `accept-new` — the MITM window is the few seconds between create and first SSH), no `NOPASSWD` removal (it would break autonomous cloud-init). If the user asks for any of these, that's a real DevOps engagement — out of scope.

## Outbound destinations OpenClaw needs

| Service | Port | Why |
|---|---|---|
| Anthropic API | 443 | LLM (default claude-sonnet-4-6) |
| OpenAI API | 443 | Codex OAuth / fallback |
| openrouter.ai | 443 | OpenRouter provider |
| api.telegram.org + MTProto | 443/80 | Bot adapter / polling |
| github.com / raw.githubusercontent.com | 443 | ceo-ai-os clone, updates |
| registry.npmjs.org + deb.nodesource.com | 443 | install |
| api.ipify.org / icanhazip.com | 443 | public-IP discovery (one-time) |

Locking egress by port (only 443) works; by domain it doesn't (Telegram cycles IP ranges, npm/GitHub are behind broad CDN ranges). Don't go there for a personal bot.

## Cost ceiling

| State | Cost (USD) | Notes |
|---|---|---|
| `s-2vcpu-4gb` running 24/7 | **~$24/mo** ($0.036/hr) | Default size. Per-second billing, 60-second minimum, monthly cap at 672 hrs. |
| `s-1vcpu-2gb` running 24/7 | **~$12/mo** | Budget option; cloud-init adds 2 GB swap so it survives. |
| Droplet **powered off** | **same as running** | ⚠️ DO bills powered-off Droplets in full. Power-off saves nothing. |
| Droplet **destroyed** | **$0** | The only way to stop paying. |
| Snapshot kept after destroy | ~$0.06/GB/mo (~$5/mo for an 80 GB image) | Optional — lets you recreate later without re-running the wizard. |

To pause without paying for the live Droplet, the pattern is **snapshot → destroy**, then recreate from the snapshot later:

```bash
doctl compute droplet-action snapshot <id> --snapshot-name openclaw-parked --context openclaw --wait
doctl compute droplet delete <id> --context openclaw --force
# later:
SNAP=$(doctl compute snapshot list --context openclaw --format ID,Name --no-header | awk '$2=="openclaw-parked"{print $1}')
doctl compute droplet create openclaw-bot --image "$SNAP" --size s-2vcpu-4gb --region fra1 --ssh-keys <fp> --context openclaw --wait
```

To delete everything and pay nothing:

```bash
doctl compute droplet delete openclaw-bot --context openclaw --force
doctl compute firewall delete <fw-id>     --context openclaw --force
```
