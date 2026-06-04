# Network & security choices (and the "dangerous install" threat model)

This skill defaults to **public IPv4 + tight SSH ingress (Cloud Firewall) + outbound-anywhere + host-level ufw/fail2ban**. It's the simplest model that survives a single non-DevOps user on a laptop that roams between networks.

Read the first section even if you skip the rest — it's the honest accounting of why an OpenClaw install is a "dangerous" thing to stand up, and what this wizard does and doesn't fix.

## 0. Why this is called a "dangerous install"

OpenClaw is not a sandboxed SaaS. On the box it runs on, it is effectively a remote-controlled operator:

| Risk | Reality | What we do about it |
|---|---|---|
| **Full shell access** | The gateway runs an LLM that can execute arbitrary commands (that's the point — it's an agent). A prompt-injection or a confused-deputy moment can run anything the `openclaw` user can run. | Dedicated non-root `openclaw` user; systemd sandboxing (`NoNewPrivileges`, `ProtectKernel*`, `RestrictNamespaces`); the box holds nothing but the bot. |
| **Plaintext credentials** | Provider API keys and the Telegram token sit in `~/.openclaw/gateway.env` (mode 600) and `auth-profiles.json`. Anyone who gets the SSH key or root can read them. | Tight SSH ingress, key-only auth, ufw + fail2ban, sudo I/O logging for forensics. Keys are scoped/cheap to rotate (a $5 Anthropic key, a revocable bot token). |
| **Bootstrap secrets in metadata** | DO keeps the rendered cloud-init (with the injected secrets) at `169.254.169.254/metadata/v1/user-data` for the Droplet's life. No API wipes it. | We scrub the on-disk copy; we treat the Droplet as single-tenant and tell the user not to add other users. |
| **Standing cloud token** | The DO API token can create/destroy across the account. | Use a **scoped, named, expiring** token (`openclaw`, 90 days); the running bot never uses it — only provisioning/teardown does. Revoke it after setup if you won't manage via CLI for a while. |
| **Outbound to anywhere** | The bot can reach any internet host (needed for LLM + Telegram + tools). Data exfil is possible if the agent is subverted. | Accepted trade-off for a personal CEO bot. Egress lockdown by domain is fragile (see §Outbound). |

**The one rule to give the user:** *put nothing on this Droplet you can't afford to lose or leak.* No prod credentials, no customer data, no password-manager exports. If they need that, it's a real DevOps engagement, not this wizard.

This is the same risk profile as the Yandex Cloud sibling skill and as a local OpenClaw install — calling it out explicitly is the only "extra" the word "dangerous" buys you.

## Why a public IP (and not a private-only Droplet)

A private-only Droplet (DO's 2026 VPC-only feature, `--enable-public-networking=false`) has no inbound path for SSH — you'd need a bastion/jump Droplet or a VPN. For a single non-DevOps user that's more moving parts than security. A public IP with a Cloud Firewall locked to one `/32` is the right trade-off.

A public IPv4 is included in the Droplet price on DO (no separate hourly charge like some clouds), so there's no cost argument against it either.

## Why SSH default is "this machine's IP only"

The wizard detects the user's current public IP (`curl -s https://api.ipify.org`) and opens port 22 only to that `/32` via the Cloud Firewall. Much safer than `0.0.0.0/0` for a fresh key.

When the user's IP changes (home ↔ office ↔ café), they must update the firewall:

```bash
FW=$(doctl compute firewall list --context openclaw --format ID,Name --no-header | awk '$2=="openclaw-bot-fw"{print $1}')
NEW_IP=$(curl -s https://api.ipify.org)
doctl compute firewall add-rules "$FW" --context openclaw \
  --inbound-rules "protocol:tcp,ports:22,address:${NEW_IP}/32"
# (optionally remove the old rule)
doctl compute firewall remove-rules "$FW" --context openclaw \
  --inbound-rules "protocol:tcp,ports:22,address:<OLD_IP>/32"
```

If the user objects ("I roam a lot, just open it"), let them pick:

| Choice | What we do |
|---|---|
| Lock to my IP (recommended) | inbound 22/tcp from `<MY_IP>/32` |
| Open to the world | inbound 22/tcp from `0.0.0.0/0` + `::/0`. fail2ban + key-only auth handle 99% of scanners. |
| Lock to my office subnet | inbound 22/tcp from `<CIDR>` (user provides) |

Pick option 2 only if the user explicitly accepts the trade-off.

## Two firewalls, on purpose

| Layer | Where | What it does |
|---|---|---|
| **DO Cloud Firewall** | DigitalOcean network edge, before packets reach the Droplet | Default-deny inbound except SSH from `<MY_IP>/32`; allow all outbound. A separate resource, attached by Droplet ID. |
| **ufw (host)** | Inside the Droplet | Default-deny inbound, `limit 22/tcp` (rate-cap 6 conn/30s), allow all outbound. |

Defense in depth: if someone detaches or misconfigures the Cloud Firewall, ufw still holds; if ufw is reset, the Cloud Firewall still holds. The gateway port `18789` is opened by **neither** — it binds to loopback and is reached only over SSH.

## What `cloud-init.yaml` hardens on top of DO defaults

DigitalOcean's stock Ubuntu 24.04 image enables root SSH login and ships `snapd` + `do-agent`. The cloud-init layers on a CIS-aligned, Mozilla "Modern" baseline. The full directive-by-directive rationale is identical to the Yandex Cloud sibling skill; the highlights:

### 1. SSH (drop-in `/etc/ssh/sshd_config.d/99-openclaw-hardening.conf`)

Validated with `sshd -t` **before** reload (a bad config would lock us out of a fresh Droplet). Key changes: `PermitRootLogin no` (DO's image leaves it on), `PasswordAuthentication no`, `AllowUsers openclaw`, `MaxAuthTries 4`, all forwarding off, post-quantum-first KEX, ETM-only MACs, `RequiredRSASize 3072`. See the YC skill's `02-network-and-security.md` §1 for the per-directive table — it applies verbatim.

### 2. ufw

Default deny in / allow out; `limit 22/tcp` instead of `allow` to rate-cap before sshd; `logging low`.

### 3. fail2ban

`backend = systemd` (Ubuntu 24.04 logs sshd to the journal — wrong backend = jail never fires), `maxretry 5` for sshd, escalating `bantime` capped at 24h, `[recidive]` deliberately **off** (too easy to self-lock a 1-user box for a week). Recovery if you lock yourself out is via the **DigitalOcean Recovery Console** (Droplet → Access → Launch Recovery Console) — see §Recovery below.

### 4. unattended-upgrades

Auto security patches, reboot at 03:30 UTC only if no user is logged in, prune old kernels/deps.

### 4a. Defensive snapd purge

Unlike YC, DO's stock image **does** ship `snapd`. We stop and `apt purge` it (CVE-2026-3888, LPE → root). OpenClaw needs none of it.

### 5. systemd hardening (gateway unit)

`NoNewPrivileges`, `PrivateTmp`, `ProtectControlGroups/KernelModules/KernelTunables/KernelLogs/Clock`, `RestrictRealtime/SUIDSGID/Namespaces`, `LockPersonality`, plus `MemoryHigh=1500M` / `MemoryMax=2500M` with `Restart=always` for self-recovery. Combined with the 2 GB swapfile the bootstrap adds, this survives the gateway's slow RSS creep even on a 2 GB Droplet.

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
