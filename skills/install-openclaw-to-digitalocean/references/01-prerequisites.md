# Prerequisites

Read this first when Step 0 of SKILL.md fails. Fix one item at a time and ask the user to confirm before moving on.

DigitalOcean is dramatically simpler than Yandex Cloud here: one global API, one token, no endpoint/region/cloud-id/folder-id juggling. Most of this file is about the token, contexts, and the SSH-key upload that DO requires.

## 1. doctl CLI installed

```bash
doctl version
```

If not found:

```bash
# macOS
brew install doctl

# Linux (or no Homebrew) — grab the latest release tarball for your arch
OS=$(uname -s | tr '[:upper:]' '[:lower:]')          # darwin | linux
ARCH=$(uname -m); case "$ARCH" in x86_64) ARCH=amd64;; arm64|aarch64) ARCH=arm64;; esac
VER=$(curl -fsSL https://api.github.com/repos/digitalocean/doctl/releases/latest | jq -r .tag_name | sed 's/^v//')
curl -fsSL "https://github.com/digitalocean/doctl/releases/download/v${VER}/doctl-${VER}-${OS}-${ARCH}.tar.gz" | tar -xz
sudo mv doctl /usr/local/bin/
doctl version
```

Any 1.100+ is fine. Official install doc: https://docs.digitalocean.com/reference/doctl/how-to/install/

## 2. API token + a dedicated context

### 2a. Get the token

The user creates a Personal Access Token at https://cloud.digitalocean.com/account/api/tokens → **Generate New Token**:

- **Name:** `openclaw` (so it's easy to revoke later).
- **Scopes:** Full Access is simplest. If the user wants least-privilege, the minimum is **read + write** on: `droplet`, `ssh_key`, `firewall`, `account` (read), `tag` (write), `region`/`image`/`size` (read).
- **Expiry:** 90 days is plenty for a setup + a few months of management. The token is only needed for provisioning and teardown — the running bot does not use it.

The token is shown **once** and starts with `dop_v1_`. Treat it as a password: anyone with it can create and destroy resources on the whole account (or the scoped subset).

### 2b. Initialize a context (don't clobber the user's `default`)

`doctl` stores credentials in **contexts** inside `~/.config/doctl/config.yaml`. The user may already use `doctl` for other work — never overwrite their `default` context. Use a dedicated one:

```bash
doctl auth init --context openclaw --access-token "$DO_TOKEN"
doctl auth switch --context openclaw     # optional; or pass --context openclaw per command
```

Verify it works and the account can actually create Droplets:

```bash
doctl account get --context openclaw --output json | jq '{email,status,droplet_limit}'
# Expect: status == "active", droplet_limit > 0
```

To return to their previous setup later: `doctl auth switch --context default`.

### 2c. Token via environment variable (alternative)

For a fully non-interactive run you can skip `auth init` and export the token:

```bash
export DIGITALOCEAN_ACCESS_TOKEN="$DO_TOKEN"
doctl account get        # uses the env var
```

The skill prefers a named context (survives across shell sessions, doesn't leak the token into the process environment of unrelated commands), but the env var is a valid fallback if writing `~/.config/doctl/` fails (read-only home, etc.).

## 3. Active billing / payment method

This is the DigitalOcean equivalent of "is billing active" — and unlike YC, you **can** check it before creating anything:

```bash
doctl account get --context openclaw --format Status,DropletLimit --no-header
```

| Result | Meaning | Action |
|---|---|---|
| `active  10` (or any limit > 0) | Account is in good standing with a payment method. | Proceed. |
| `active  0` | No payment method on file — Droplet limit is 0, every `create` will 422. | Send the user to https://cloud.digitalocean.com/account/billing to add a card or PayPal. |
| `locked` / `warning` | Account flagged (unpaid invoice, fraud review, etc.). | User must resolve it in the dashboard; nothing the wizard can do. |

New accounts often come with a **promotional credit** ($200 / 60 days is common via referral links). That credit covers ~8 months of an `s-2vcpu-4gb` Droplet. The credit still requires a verified payment method on file before `droplet_limit` becomes non-zero.

## 4. Local SSH key

```bash
ls ~/.ssh/id_ed25519.pub
```

If missing:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "openclaw-do-$(date +%Y%m%d)"
```

`-N ""` means no passphrase — fine for this single-purpose key on the user's own laptop. The wizard's polling steps call SSH non-interactively and would block on a passphrase prompt. (If the user insists on a passphrase, have them `ssh-add ~/.ssh/id_ed25519` first.)

## 5. SSH key uploaded to the DO account (the step people miss)

**DigitalOcean does not accept a raw public-key file at Droplet-create time.** The key must be registered in the account first; `droplet create --ssh-keys` then takes a fingerprint or numeric ID. This trips up everyone coming from Yandex Cloud / AWS where you can pass the key inline.

```bash
# Local key's MD5 fingerprint (DO's identifier format: colon-hex)
FP=$(ssh-keygen -E md5 -lf ~/.ssh/id_ed25519.pub | awk '{print $2}' | sed 's/^MD5://')

# Is it already in the account?
doctl compute ssh-key list --context openclaw --format ID,FingerPrint,Name --no-header

# Upload if not present (idempotent — match on $FP first)
doctl compute ssh-key import "openclaw-$(date +%Y%m%d)" \
  --public-key-file ~/.ssh/id_ed25519.pub \
  --context openclaw
```

If `import` errors with **"SSH key is already in use on your account"** (HTTP 422), the key is already there under a different name — just read its fingerprint back from `ssh-key list` and use that. The skill's Step 0e does exactly this.

Note: DO also injects every key passed via `--ssh-keys` into the **root** account on the Droplet. Our cloud-init additionally drops the same key into the `openclaw` user's `authorized_keys` and disables root SSH login — so we always connect as `openclaw`, never root.

## 6. Region availability

DigitalOcean has no Central-Asia datacenter. For a Kazakhstan / CIS / EU audience, latency order is `fra1` (Frankfurt) < `ams3` (Amsterdam) < `lon1` (London) < `blr1` (Bangalore). The skill defaults to `fra1` and falls back to `ams3`.

Confirm a region + size combination is actually orderable:

```bash
doctl compute size list --context openclaw --format Slug,Memory,VCPUs,PriceMonthly,Regions \
  | grep s-2vcpu-4gb
doctl compute region list --context openclaw --format Slug,Name,Available
```

If `s-2vcpu-4gb` isn't available in `fra1` on this account (rare — usually capacity), the skill retries in `ams3` automatically.

## 7. Existing Droplet with the same name

```bash
doctl compute droplet list --context openclaw --format Name --no-header | grep -qx openclaw-bot
```

If it matches, a Droplet already exists. **Don't silently overwrite it.** Offer the user:

1. Reuse it (skip Step 2, jump to verification at Step 4).
2. Pick a different name (e.g. `openclaw-bot-2`) — the safe default.
3. Delete and recreate:
   ```bash
   ID=$(doctl compute droplet list --context openclaw --format ID,Name --no-header | awk '$2=="openclaw-bot"{print $1}')
   doctl compute droplet delete "$ID" --context openclaw --force
   # firewall is a separate resource — delete it too
   FW=$(doctl compute firewall list --context openclaw --format ID,Name --no-header | awk '$2=="openclaw-bot-fw"{print $1}')
   doctl compute firewall delete "$FW" --context openclaw --force
   ```

Default to (2).
