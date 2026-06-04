# Troubleshooting playbook

Failure modes the wizard can hit on DigitalOcean, in rough order of frequency. Each has a copy-paste fix that doesn't require guessing.

For any error not listed: dump `cat /var/log/openclaw-bootstrap.log` and `journalctl --user -u openclaw-gateway -n 200` from the Droplet and surface to the user. Don't extrapolate from a tail of 5 lines.

All `doctl` commands assume the `openclaw` context — add `--context openclaw` (or `doctl auth switch --context openclaw` once).

---

## §1. `doctl` auth / token problems

### §1a. `doctl auth init` rejects the token

**Symptom.** `Error: ... 401 Unable to authenticate you`.

**Causes & fix.**
- Token truncated on copy (must start `dop_v1_` and be ~64 chars after that). Re-copy from https://cloud.digitalocean.com/account/api/tokens.
- Token expired or revoked. Generate a new one.
- Token is **read-only** but we need write. Re-create with Full Access or read+write on droplet/ssh_key/firewall.

```bash
doctl auth init --context openclaw --access-token "$DO_TOKEN"
doctl account get --context openclaw --format Email,Status,DropletLimit --no-header
```

### §1b. Wrong context active

**Symptom.** Commands hit the user's *other* DO account (unexpected Droplets in `droplet list`).

**Fix.** `doctl auth list` shows contexts; `doctl auth switch --context openclaw`. Always pass `--context openclaw` in scripts to be safe.

---

## §2. `droplet create` fails

### §2a. 422 "not authorized" / payment required

**Symptom.** `droplet create` returns an authorization or "you must add a payment method" error; `doctl account get` shows `droplet_limit: 0`.

**Cause.** No payment method on the account. Promotional credit alone doesn't lift `droplet_limit` until a card/PayPal is verified.

**Fix.** Send the user to https://cloud.digitalocean.com/account/billing → add a card. Then re-run — the wizard picks up from Step 2.

### §2b. "size is not available in region"

**Symptom.** create errors that `s-2vcpu-4gb` isn't orderable in `fra1`.

**Cause.** Temporary capacity or the size isn't offered in that DC.

**Fix.** The wizard auto-retries in `ams3`. To pick manually:

```bash
doctl compute size list --context openclaw --format Slug,Memory,VCPUs,Regions | grep s-2vcpu-4gb
doctl compute region list --context openclaw --format Slug,Available
# create in whichever region lists the size, e.g. ams3 or lon1
```

### §2c. cloud-init log shows `npm install -g openclaw failed`

**Symptom.** `/var/log/openclaw-bootstrap.log`: `npm ERR! 404` / `EACCES` / `network timeout`.

**Cause hierarchy:** NodeSource setup failed (no egress), npm registry flaky, or the Droplet has no outbound (firewall outbound rule missing/wrong).

**Fix.**

```bash
ssh openclaw@$IP 'curl -fsS https://registry.npmjs.org/openclaw/latest | jq .version'   # internet OK?
# If that fails, check the Cloud Firewall outbound rules:
doctl compute firewall list --context openclaw --format ID,Name,OutboundRules --no-header
# Outbound must allow tcp/udp all + icmp to 0.0.0.0/0 and ::/0.

# If outbound is fine, re-run the install (bootstrap is idempotent):
ssh openclaw@$IP 'export PATH=$HOME/.npm-global/bin:$PATH; npm install -g openclaw@latest && openclaw --version'
ssh openclaw@$IP 'sudo /usr/local/sbin/openclaw-bootstrap.sh'
```

---

## §3. `openclaw gateway status` shows `RPC probe: failed` (process running)

**Cause.** Gateway still initializing — plugins (telegram, browser, etc.) take 60–120s on first start.

**Fix.** Wait, watch the journal:

```bash
ssh openclaw@$IP 'journalctl --user -u openclaw-gateway -n 40 --no-pager'   # look for "[gateway] ready"
# Still nothing after 4 min:
ssh openclaw@$IP 'systemctl --user restart openclaw-gateway && sleep 120 && curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:18789/health'  # expect 200
```

---

## §4. Bot doesn't reply in Telegram

Work the ladder in order.

**4a. Token wrong.** `curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe"` must return `{"ok":true,...}`. If `Unauthorized` — fresh token from BotFather.

**4b. Token not saved on the Droplet.** `ssh openclaw@$IP 'cat ~/.openclaw/gateway.env'` must contain `TELEGRAM_BOT_TOKEN=`. If empty, the cloud-init placeholder wasn't substituted — re-write and restart.

**4c. Pairing never happened.** Schema fields are `.senderId` / `.requestId`, not `.chatId` / `.code`:

```bash
ssh openclaw@$IP 'openclaw pairing list telegram --format json' | jq .
ssh openclaw@$IP 'openclaw pairing approve telegram <requestId>'
ssh openclaw@$IP "openclaw config set channels.telegram.dmPolicy allowlist; openclaw config set channels.telegram.allowFrom '[<chat_id>]'; systemctl --user restart openclaw-gateway"
```

**4d. LLM provider has no credit / not authorized.**

```bash
ssh openclaw@$IP 'journalctl --user -u openclaw-gateway -n 200 | grep -iE "anthropic|openrouter|openai|credit|billing|unauthorized"'
```

| Error pattern | Fix |
|---|---|
| `credit_balance_too_low` (Anthropic) | top up ≥$5 at console.anthropic.com/settings/billing |
| `Insufficient credits` (OpenRouter) | openrouter.ai/credits |
| `Subscription required` (Codex OAuth) | active ChatGPT Plus/Pro needed |
| `expired` / `refresh_token_reused` (Codex) | re-run `openclaw models auth login --provider openai-codex --device-code`; prune orphan profile (openclaw-guide §13) |

**4e. Model not in the configured list.** `ssh openclaw@$IP 'openclaw models status'`, then set primary appropriately and `systemctl --user restart openclaw-gateway`.

**4f. Replies in the wrong language.** Append the locale pack and reset the session:

```bash
ssh openclaw@$IP 'tail -30 ~/.openclaw/workspace/USER.md'   # is the "Язык общения" block there?
ssh openclaw@$IP "cat /usr/local/share/openclaw-locale-ru.md >> ~/.openclaw/workspace/USER.md"
ssh openclaw@$IP "openclaw sessions reset --channel telegram --to <chat_id>"
```

---

## §5. SSH `Permission denied (publickey)`

**Causes:** wrong username (it's `openclaw`, not `root`/`ubuntu`), wrong key, or the firewall doesn't include your current IP.

```bash
ssh -v openclaw@$IP 2>&1 | head -20                 # confirm it's offering the right key
# Firewall includes your IP?
FW=$(doctl compute firewall list --context openclaw --format ID,Name --no-header | awk '$2=="openclaw-bot-fw"{print $1}')
doctl compute firewall get "$FW" --context openclaw --format InboundRules
MY_IP=$(curl -s https://api.ipify.org)
doctl compute firewall add-rules "$FW" --context openclaw --inbound-rules "protocol:tcp,ports:22,address:${MY_IP}/32"
```

Locked out at the host level (fail2ban / broken sshd drop-in)? Use the **Recovery Console**: DO dashboard → Droplet → Access → Launch Recovery Console → `fail2ban-client unban --all` or `rm /etc/ssh/sshd_config.d/99-openclaw-hardening.conf && systemctl reload ssh`.

**Last resort — recreate.** Only with explicit consent (wipes the bot's memory). For a Droplet in its first hour, often faster than spelunking the console.

---

## §6. Forgot the IP / lost SSH

```bash
doctl compute droplet get openclaw-bot --context openclaw --format PublicIPv4 --no-header
# or list everything this skill made:
doctl compute droplet list  --context openclaw --tag-name openclaw --format ID,Name,PublicIPv4
```

---

## §7. Cost worry — user wants to stop paying

**The DigitalOcean trap:** powering off a Droplet does **not** stop billing. You keep paying full price for a stopped Droplet. The only ways to stop paying:

```bash
# Option A — park it: snapshot, then destroy. Recreate later from the snapshot.
ID=$(doctl compute droplet get openclaw-bot --context openclaw --format ID --no-header)
doctl compute droplet-action snapshot "$ID" --snapshot-name openclaw-parked --context openclaw --wait
doctl compute droplet delete "$ID" --context openclaw --force
# Snapshot storage ≈ $0.06/GB/mo (~$5/mo for 80 GB). Recreate:
SNAP=$(doctl compute snapshot list --context openclaw --format ID,Name --no-header | awk '$2=="openclaw-parked"{print $1}')
doctl compute droplet create openclaw-bot --image "$SNAP" --size s-2vcpu-4gb --region fra1 \
  --ssh-keys <fp> --context openclaw --wait

# Option B — delete everything, pay $0.
doctl compute droplet delete openclaw-bot --context openclaw --force
FW=$(doctl compute firewall list --context openclaw --format ID,Name --no-header | awk '$2=="openclaw-bot-fw"{print $1}')
doctl compute firewall delete "$FW" --context openclaw --force
```

The Telegram bot survives in BotFather (reuse the token next time); the LLM key/subscription is untouched. If the user revoked the DO API token after setup, they'll need a fresh one to run teardown.

Do **not** tell the user "just stop the Droplet to save money" — that advice is correct on Yandex Cloud and wrong on DigitalOcean.
