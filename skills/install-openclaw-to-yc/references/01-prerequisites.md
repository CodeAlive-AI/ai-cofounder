# Prerequisites

Read this first when Step 0 of SKILL.md fails. Fix one item at a time and ask the user to confirm before moving on.

## 1. yc CLI installed

```bash
yc --version
```

If not found:

```bash
curl -fsSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
# new shell, or:
export PATH=$HOME/yandex-cloud/bin:$PATH
```

The installer offers to add `yc` to `~/.bashrc` / `~/.zshrc` — accept it so future sessions see the binary. Verify with `yc --version` (any 0.150+ is fine).

## 2. yc initialized for Yandex Cloud **Kazakhstan**

Critical: there are two endpoints — `api.cloud.yandex.net:443` (Russia) and `api.yandexcloud.kz:443` (Kazakhstan). They are separate clouds with separate billing accounts, separate consoles (https://console.yandex.cloud vs https://kz.console.yandex.cloud), and separate quotas. Creating a VM against the wrong endpoint will charge a billing account the user doesn't have, in a currency they didn't expect — assuming it doesn't silently fail with empty results first (see §2b).

### 2a. The four properties that must move together

`yc config set endpoint` does **not** auto-update the related properties. If you flip the endpoint alone, every subsequent `yc compute / vpc / resource-manager` call sees an empty result because it's looking up RU IDs through the KZ realm — and **no error is shown**, the call just returns `[]`. This is the single biggest "the wizard said no billing but I have billing" failure mode.

Always update all four together:

```bash
yc config set endpoint api.yandexcloud.kz:443
yc config set cloud-id   <KZ_CLOUD_ID>      # from `yc resource-manager cloud list`
yc config set folder-id  <KZ_FOLDER_ID>     # from `yc resource-manager folder list --cloud-id <id>`
yc config set compute-default-zone kz1-a
```

Verify with `yc config list` and `yc compute zone list` (must return `kz1-a`, not `ru-central1-*`).

### 2b. Recommended: use a named profile, not the active config

The user almost certainly has profiles for their other clouds (RU prod, personal sandbox, etc.). Don't clobber them — create a dedicated profile for OpenClaw:

```bash
yc config profile create openclaw-kz
yc config profile activate openclaw-kz
yc config set token       <OAUTH_TOKEN>
yc config set endpoint    api.yandexcloud.kz:443
yc config set compute-default-zone kz1-a
yc config set cloud-id    $(yc resource-manager cloud list  --format json | jq -r '.[0].id')
yc config set folder-id   $(yc resource-manager folder list --format json | jq -r '.[0].id')
```

To return to their previous setup later: `yc config profile activate <previous-profile>`.

### 2c. Getting the OAuth token for KZ

There is exactly one official OAuth client for `yc` CLI; it works for both RU and KZ. Open this URL in a browser, log in with Yandex ID, then copy the `access_token=…` value out of the redirect URL fragment:

```
https://oauth.yandex.kz/authorize?response_type=token&client_id=1a6990aa636648e9b2ef855fa7bec2fb
```

The `oauth.yandex.ru` host works too — both issue the same token type. Use the `.kz` host so the user clearly understands they're authorizing the Kazakhstan side.

### 2d. Don't probe `yc billing account list` to check billing

`yc billing` doesn't exist on the KZ endpoint command set. Calling it errors with `Unknown command 'billing account list' for 'yc'` — and our wizard used to misread that as "no billing account, stop". The real signal for billing problems is the error returned by `yc compute instance create` when the user has no active KZ billing account; surface that one to the user when (and only when) it actually happens.

## 3. Active billing account in Yandex Cloud KZ

New accounts get a **24 000 ₸** grant for **60 days** — more than enough for this workshop. A standard-v3 2 vCPU / 4 GB VM with public IP costs ≈3–5 ₸/hour in KZ, so two workshop days cost <300 ₸.

Check the billing account is linked to the active cloud:

```bash
yc billing account list
```

If empty → user has no billing account → send them to https://kz.console.yandex.cloud/billing/create. The flow asks for a phone number with a +7 prefix and a bank card; first 1 500 ₸ deposit is the only friction.

## 4. Local SSH key

```bash
ls ~/.ssh/id_ed25519.pub
```

If missing:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "openclaw-yc-$(date +%Y%m%d)"
```

`-N ""` means no passphrase — fine for this single-purpose key on the user's own laptop. Don't reuse a passphrase-protected key here; the wizard's polling step calls SSH non-interactively and would block on the passphrase prompt.

(If the user insists on a passphrase, instruct them to `ssh-add ~/.ssh/id_ed25519` first so the agent caches it.)

## 5. Compute quotas

Brand-new YC KZ accounts come with default quotas (≥ 16 vCPU, ≥ 32 GB RAM, ≥ 4 public IPs in the folder) — more than enough for one VM. If the wizard hits `quota_exceeded` during `yc compute instance create`, check current usage:

```bash
yc quota list --service-id compute --format json | jq '.[] | select(.usage > 0)'
```

If a quota is hit:

```bash
# Easy path: delete leftover VMs from previous attempts
yc compute instance list
yc compute instance delete --name <stuck-vm>

# Harder path: request a quota bump in the console
# https://kz.console.yandex.cloud/quotas?service=compute
```

The bump is usually approved within an hour for reasonable amounts (8 vCPU, 4 IPs).

## 6. Existing instance with the same name

```bash
yc compute instance get --name openclaw-bot 2>/dev/null
```

If the command succeeds, an instance already exists. **Don't silently overwrite it.** Ask the user one of three things:

1. Reuse it (skip Step 2 in SKILL.md, jump to verification at Step 4)
2. Pick a different name (e.g. `openclaw-bot-2`)
3. Delete and recreate (`yc compute instance delete --name openclaw-bot && yc vpc security-group delete --name openclaw-bot-sg`)

Default to (2) — it's the safest.
