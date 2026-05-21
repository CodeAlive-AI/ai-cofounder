# Prerequisites

Read this first when Step 0 of SKILL.md fails. Fix one item at a time and ask the user to confirm before moving on.

## 1. hcloud CLI installed

```bash
hcloud version
```

If not found:

```bash
# macOS — canonical install
brew install hcloud

# Linux — release binary (preferred over apt, which ships stale versions)
ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -sSLO "https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-${ARCH}.tar.gz"
sudo tar -C /usr/local/bin --no-same-owner -xzf "hcloud-linux-${ARCH}.tar.gz" hcloud
rm "hcloud-linux-${ARCH}.tar.gz"
```

Verify with `hcloud version` (any 1.50+ is fine). **Avoid `apt install hcloud`** — Debian/Ubuntu repos ship significantly outdated versions. There is no official snap package.

## 2. Hetzner API token

### 2a. Create the token

Tokens are **project-scoped**. Whichever project the user creates the token in is the project the VM will live in.

1. Sign in at https://console.hetzner.cloud.
2. Pick (or create) the project where the VM should live.
3. Left sidebar → **Security** → **API Tokens** → **Generate API Token**.
4. Name it `openclaw-install`, permission **Read & Write**.
5. Click **Generate**. The token (starting with `hv2-`) is shown **only once** — copy it before closing the dialog. There is no way to recover it later; if lost, regenerate.

### 2b. Configure `hcloud` to use it

The wizard uses a dedicated context (`openclaw-install`) so it doesn't disturb the user's existing setups:

```bash
# Interactive — prompts for the token, stores it under the given name
hcloud context create openclaw-install
hcloud context use openclaw-install

# Stateless / CI — env var always wins over a saved context
export HCLOUD_TOKEN="hv2-…"
```

Verify:

```bash
hcloud server list
```

`hcloud server list` is the minimal probe — if it returns 200 (even with an empty result), the token is valid. If it returns `unauthorized`, the token is wrong, expired, or was created in a different project.

### 2c. Token scope (read-only vs Read & Write)

There are two scopes:

| Scope | What works | What fails |
|---|---|---|
| **Read** | `hcloud server list`, `hcloud server describe`, `hcloud ssh-key list`, `hcloud firewall list` | Anything that creates / modifies / deletes resources |
| **Read & Write** | Everything the wizard needs | — |

There is **no way to upgrade an existing token's scope**. If the user accidentally created a read-only token, regenerate. The Step 0c probe (`hcloud server list`) passes for both scopes; the failure surfaces in Step 2e (`hcloud server create` returns `unauthorized`).

## 3. Hetzner account verification (one-time, fresh accounts only)

New Hetzner accounts go through fraud-review verification before the first server can be created. Most accounts pass instantly; some take hours, occasionally days.

Symptoms of an unverified account:

- Token works (`hcloud server list` returns 200), but `hcloud server create` errors with `action_failed` / `verification_required`.
- The Hetzner console shows a yellow banner asking for ID / payment-method verification.

Resolution:

1. Open https://console.hetzner.cloud → top-right account menu → check for any verification prompts and complete them.
2. If stuck for more than 24 hours: email `cda-review@hetzner.com` with the account email. They review in EU business hours.
3. **Do not** create a new account hoping the new one will be faster — multiple accounts trigger stricter review.

The wizard should explicitly detect `verification_required` and tell the user. Do NOT retry in a loop — that signals fraud to Hetzner's automated reviewer and delays verification further.

## 4. Local SSH key

```bash
ls ~/.ssh/id_ed25519.pub
```

If missing:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "openclaw-hetzner-$(date +%Y%m%d)"
```

`-N ""` means no passphrase — fine for this single-purpose key on the user's own laptop. Don't reuse a passphrase-protected key here; the wizard's polling step calls SSH non-interactively and would block on the passphrase prompt.

(If the user insists on a passphrase, instruct them to `ssh-add ~/.ssh/id_ed25519` first so the agent caches it.)

The key is uploaded to the Hetzner project in Step 2a of the SKILL flow. Hetzner SSH keys are project-scoped — a key uploaded in project A is not visible in project B. If the user already uploaded the same key to this project (by fingerprint), the wizard reuses it instead of re-uploading.

## 5. Quotas and limits

Hetzner Cloud applies per-project limits to prevent abuse:

| Limit | Default |
|---|---|
| Servers per project | 20 |
| Total vCPU per project | varies (typically 12–24 on new accounts) |
| Floating IPs per project | varies |

For a single-VM OpenClaw install, defaults are far more than enough. If the user has many existing servers and hits the per-project cap, the error is `limit_reached`. Resolution: delete unused resources or request a limit increase from console.hetzner.cloud → Account → **Limits**.

The wizard's Step 2e doesn't try to pre-check quotas (`hcloud` has no limit-introspection command in CLI 1.x) — it relies on the `hcloud server create` error message to surface the issue concretely.

## 6. Existing server with the same name

```bash
hcloud server describe openclaw-bot 2>/dev/null
```

If the command succeeds, a server already exists in this project with that name. **Don't silently overwrite it.** Ask the user one of three things:

1. Reuse it (skip Step 2 in SKILL.md, jump to verification at Step 4)
2. Pick a different name (e.g. `openclaw-bot-2`)
3. Delete and recreate (`hcloud server delete openclaw-bot && hcloud firewall delete openclaw-bot-fw`)

Default to (2) — it's the safest.

## 7. Signup credit (new accounts)

Hetzner offers a **€20 / $20 promotional credit** for new accounts (active as of May 2026, valid 3 months). This is enough for ~4-5 months of a CAX11 bot.

- Sometimes auto-applied at signup.
- If not: console.hetzner.cloud → **Account** → **Promo Codes** → enter code (find current code on hetzner.com/cloud or in Hetzner's affiliate program).
- Check the current balance under **Billing** → **Credit**.

The wizard should NOT promise the credit ("you'll get €20 free") — terms change; promote it only after the user has explicitly mentioned cost as a blocker.

## 8. Pricing summary (so the user can sleep)

| Item | Monthly | Notes |
|---|---|---|
| CAX11 server | ~€3.79 | Pre-April-2026 price; may have risen slightly with Hetzner's 2026-04-01 adjustment — verify live at hetzner.com/cloud |
| Primary IPv4 | €0.50 | Charged even when server is stopped, as long as the IP resource exists |
| 40 GB SSD | €0.00 | Included in server price |
| 20 TB outbound traffic | €0.00 | Included; overage €1.00/TB at EU locations |
| **Total** | **~€4.30/mo (~€0.14/day)** | |

To pause (CPU/RAM stop billing, disk + IPv4 continue):

```bash
hcloud server poweroff openclaw-bot
```

To fully delete (stops all charges):

```bash
hcloud server delete openclaw-bot
hcloud firewall delete openclaw-bot-fw
# Delete the Primary IP if it became a standalone resource (rare, but check):
hcloud primary-ip list
hcloud primary-ip delete <id>
```
