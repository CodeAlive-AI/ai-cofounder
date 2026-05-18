# Troubleshooting playbook

The six failure modes the wizard can hit, in order of how often they actually happen. Each one has a copy-paste fix that doesn't require guessing.

For any error not listed: dump `cat /var/log/openclaw-bootstrap.log` and `journalctl --user -u openclaw-gateway -n 200` from the VM and surface to the user. Don't extrapolate from a tail of 5 lines.

---

## §1. `yc` commands return empty or "not found", but the user insists their cloud exists

This is the #1 trip point in YC Kazakhstan. There are three flavours; identify which one first.

### §1a. Endpoint set to RU while user expects KZ

**Symptom.** `yc compute zone list` returns `ru-central1-{a,b,d}` (or empty), not `kz1-a`. `yc compute instance create --zone kz1-a` fails with `zone is not available in this endpoint`.

**Cause.** `yc config get endpoint` returns `api.cloud.yandex.net:443` (RU). The wizard's auto-fix in Step 0 didn't run, or the user has multiple profiles and a wrong one is active.

**Fix.**

```bash
yc config profile list   # is there a KZ-aimed profile already?
# If yes:
yc config profile activate <kz-profile>
# If no:
yc config profile create openclaw-kz
yc config profile activate openclaw-kz
yc config set token <OAUTH_TOKEN_FROM_OAUTH_YANDEX_KZ>
yc config set endpoint api.yandexcloud.kz:443
yc config set compute-default-zone kz1-a
```

Then resolve and pin `cloud-id` + `folder-id` (next subsection).

### §1b. Endpoint is KZ but cloud-id / folder-id still point at RU

**Symptom.** `yc config get endpoint` is correct (`api.yandexcloud.kz:443`), but `yc resource-manager cloud list` returns `[]` or `yc compute instance list` returns nothing — even though the user can see their cloud and VMs in https://kz.console.yandex.cloud.

**Cause.** Flipping the endpoint doesn't touch `cloud-id` or `folder-id`. They still point at RU resource IDs, which simply don't exist when looked up through the KZ realm. The KZ API silently returns "no match" rather than "wrong ID".

**Fix.**

```bash
# Discover what's actually in KZ
yc resource-manager cloud list --format json | jq '.[]|{id,name}'
# Pin the right ones
yc config set cloud-id  <FROM_ABOVE>
yc config set folder-id $(yc resource-manager folder list --cloud-id <CLOUD_ID> --format json | jq -r '.[0].id')
yc config set compute-default-zone kz1-a
```

After this, `yc compute instance list` should show the user's existing VMs (if any), and `yc compute instance create` against KZ will work.

### §1c. OAuth token from RU, used against KZ endpoint (or vice versa)

**Symptom.** Same as §1b — empty `cloud list` despite cloud being visible in the console.

**Cause.** OAuth tokens are tied to the Yandex ID, but the realm-specific access rights aren't. A token created on `oauth.yandex.ru` may not have authorization for the KZ realm if the user's Yandex ID has never logged into KZ console.

**Fix.** Get a fresh token from the KZ host:

```
https://oauth.yandex.kz/authorize?response_type=token&client_id=1a6990aa636648e9b2ef855fa7bec2fb
```

Log in with **the same Yandex ID** the user uses for https://kz.console.yandex.cloud. Then:

```bash
yc config set token <new_token>
```

### §1d. "There is no billing account / billing_disabled"

**Symptom.** `yc compute instance create` errors with `billing account is not active` after endpoint/cloud/folder are all correct.

**Cause.** The KZ cloud exists, but has no active billing account attached. This is the only real "no billing" case — the wizard's Step 0 deliberately does not try to detect it with `yc billing` (that command doesn't exist on the KZ endpoint), so it surfaces here.

**Fix.** Send the user to https://kz.console.yandex.cloud/billing → "Привязать аккаунт" → add a card and pass the 1500₸ deposit check. Then re-run the wizard.

---

## §2. Cloud-init log shows `npm install -g openclaw failed`

**Symptom.** `/var/log/openclaw-bootstrap.log` line: `npm ERR! 404 Not Found` or `EACCES` or `network timeout`.

**Cause hierarchy.**

1. NodeSource setup script failed (no internet on first boot — rare on YC, but happens if security group blocks 443 egress).
2. npm registry was flaky.
3. The user's VM was provisioned without a public IP and there's no NAT.

**Fix.**

```bash
# Check internet from the VM
ssh openclaw@$IP 'curl -fsS https://registry.npmjs.org/openclaw/latest | jq .version'
# If that fails: outbound is broken. Check security group egress rules:
yc vpc security-group get <SG_ID>
# Egress to 0.0.0.0/0 on all ports must exist.

# If outbound is fine: re-run the install manually
ssh openclaw@$IP 'export PATH=$HOME/.npm-global/bin:$PATH; npm install -g openclaw@latest && openclaw --version'

# Then re-run the rest of bootstrap:
ssh openclaw@$IP 'sudo /usr/local/sbin/openclaw-bootstrap.sh'
```

The bootstrap script is idempotent — re-running picks up where it left off.

---

## §3. `openclaw gateway status` shows `RPC probe: failed` (but process is running)

**Symptom.** SSH into VM, run `openclaw gateway status` → "Runtime: running" but "RPC probe: failed (timeout 3000ms)".

**Cause.** Gateway is still initializing — plugins (composio, slack, telegram, browser) take 60–120 seconds on first start; bundled plugin deps may add another minute on fresh installs.

**Fix.** Wait. Verify the gateway is actually starting up:

```bash
ssh openclaw@$IP 'journalctl --user -u openclaw-gateway -n 40 --no-pager'
# Look for "[gateway] ready" — when that appears, RPC works.
```

If after 4 minutes there's still no `[gateway] ready`:

```bash
# Force-restart the gateway. Watch journalctl in another terminal.
ssh openclaw@$IP 'systemctl --user restart openclaw-gateway && sleep 120 && curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:18789/health'
# Expect 200.
```

**Known pitfall:** YC sometimes throttles fresh public-IP traffic for the first 60 seconds. Don't claim failure until you've waited the full 4 minutes.

---

## §4. Bot doesn't reply to messages in Telegram

The most common ladder of causes — work through it in order.

**4a. Token is wrong.**

```bash
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe"
# Must return {"ok":true,"result":{...}}
# If "Unauthorized" — wrong token. Get a fresh one from BotFather.
```

**4b. Token wasn't saved on the VM.**

```bash
ssh openclaw@$IP 'cat ~/.openclaw/gateway.env'
# Must contain TELEGRAM_BOT_TOKEN=...
# If empty: the cloud-init template didn't substitute the placeholder.
# Re-write the file and restart the gateway.
```

**4c. Pairing never happened (or the wizard thought it did).**

This was the wizard's silent-failure bug before 0.5.0: the jq filter used `.chatId` / `.code` which don't exist in the `DevicePairRequestedEventSchema` (`src/gateway/protocol/schema/devices.ts`). The real fields are `.senderId` (Telegram user id) and `.requestId` (primary key).

Inspect the pending requests directly:

```bash
ssh openclaw@$IP 'openclaw pairing list telegram --format json' | jq .
```

You should see entries like `{requestId: "abc123...", senderId: 123456789, channel: "telegram", ...}`. Approve the right one:

```bash
ssh openclaw@$IP 'openclaw pairing approve telegram <requestId-or-code>'
```

The CLI accepts the same token shown by the bot in its DM to the user, OR the `requestId` from the list. Try `requestId` first; if `pairing approve` errors with "code not found", try the human-readable code from the bot's DM reply.

After approve:

```bash
ssh openclaw@$IP "
  openclaw config set channels.telegram.dmPolicy allowlist
  openclaw config set channels.telegram.allowFrom '[<chat_id>]'
  systemctl --user restart openclaw-gateway
"
```

**4d. LLM provider has no credit / not authorized.**

Provider-specific:

```bash
ssh openclaw@$IP 'journalctl --user -u openclaw-gateway -n 200 | grep -iE "anthropic|openrouter|openai|credit|billing|unauthorized"'
```

| Error pattern | Where to fix |
|---|---|
| `credit_balance_too_low` (Anthropic) | https://console.anthropic.com/settings/billing → top up ≥ $5 |
| `insufficient_quota` or `billing` (OpenAI direct) | https://platform.openai.com/account/billing |
| `Insufficient credits` (OpenRouter) | https://openrouter.ai/credits |
| `Subscription required` (Codex OAuth) | Active ChatGPT Plus/Pro subscription needed |
| `expired` / `refresh_token_reused` (Codex OAuth) | Re-run `openclaw models auth login --provider openai-codex --device-code` — see `openclaw-guide` skill §13 for orphan-profile cleanup after re-auth |

**4e. Model is not in the configured list.**

```bash
ssh openclaw@$IP 'openclaw models status'
```

The default depends on what the wizard chose. Fix:

```bash
# Anthropic
ssh openclaw@$IP 'openclaw config set agents.defaults.model.primary anthropic/claude-sonnet-4-6'
# OpenRouter
ssh openclaw@$IP 'openclaw config set agents.defaults.model.primary openrouter/moonshotai/kimi-k2.6'
# OpenAI Codex (Pro)
ssh openclaw@$IP 'openclaw config set agents.defaults.model.primary openai-codex/gpt-5.5'
# OpenAI Codex (Plus only)
ssh openclaw@$IP 'openclaw config set agents.defaults.model.primary openai-codex/gpt-4o'

ssh openclaw@$IP 'systemctl --user restart openclaw-gateway'
```

**4f. Bot replies but in the wrong language.**

The locale pack wasn't appended, or the bot's current session was started before USER.md was updated.

```bash
# Confirm the locale pack is in USER.md
ssh openclaw@$IP 'tail -30 ~/.openclaw/workspace/USER.md'
# If the "Язык общения" / "Тіл" block is missing — append it:
ssh openclaw@$IP "cat /usr/local/share/openclaw-locale-ru.md >> ~/.openclaw/workspace/USER.md"
# Force a session reset so the bot re-reads bootstrap files
ssh openclaw@$IP "openclaw sessions reset --channel telegram --to <chat_id>"
# Then ask the user to message the bot again
```

If the locale pack file doesn't exist on the VM (cloud-init didn't write it): the cloud-init template's `{{USER_LANGUAGE}}` placeholder probably wasn't substituted, or substituted with a code we don't have a pack for. Write the pack inline:

```bash
ssh openclaw@$IP 'cat >> ~/.openclaw/workspace/USER.md' <<'EOF'

## Язык общения

Я говорю по-русски. Всегда отвечай мне на русском, естественным дружелюбным тоном.
EOF
ssh openclaw@$IP "openclaw sessions reset --channel telegram --to <chat_id>"
```

---

## §5. SSH `Permission denied (publickey)`

**Symptom.** `ssh openclaw@$IP` immediately fails with key rejection.

**Causes.**

1. Wrong username — the cloud-init creates `openclaw`, not `ubuntu` or `yc-user`.
2. Wrong key — VM was created with a different SSH key than the user is currently presenting.
3. Security group ingress doesn't include the user's current IP.

**Fix.**

```bash
# 1. Confirm username
ssh -v openclaw@$IP 2>&1 | head -20

# 2. List keys on the VM (use serial console if locked out)
yc compute instance get-serial-port-output openclaw-bot --port 1 | grep -A2 "ssh-keys" | head -10

# 3. Check security group
yc vpc security-group get openclaw-bot-sg --format json | jq '.rules[] | select(.direction=="INGRESS")'
# If 22/tcp source CIDR doesn't include your current IP, update:
MY_IP=$(curl -s https://api.ipify.org)
yc vpc security-group update-rules openclaw-bot-sg \
  --add-rule "direction=ingress,port=22,protocol=tcp,v4-cidrs=[$MY_IP/32]"
```

**Last resort — recreate the VM.** Only do this with explicit user consent (it wipes the bot's memory). For a workshop bot in its first hour, it's usually faster than spelunking serial console.

---

## §6. Forgot the IP, lost SSH, want to start over

**Symptom.** User says "I closed the terminal and don't remember the IP."

**Fix.**

```bash
yc compute instance get --name openclaw-bot --format json | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address'
```

If the user truly wants to start fresh, the wizard's teardown sequence is:

```bash
yc compute instance delete --name openclaw-bot
yc vpc security-group delete --name openclaw-bot-sg
```

Both are safe to run blindly — they only delete what this wizard creates. The Telegram bot survives in BotFather and can be reused for the next install (the same token). The Anthropic API key is unchanged.

---

## §7. Cost worry — user wants to pause

```bash
# Stop billing for CPU/RAM (~75% of cost). Disk still bills.
yc compute instance stop --name openclaw-bot
# Resume later:
yc compute instance start --name openclaw-bot
```

A stopped VM costs about **25 ₸/day** for the 30 GB SSD. The 24 000 ₸ trial grant covers **~32 months** of stopped time, so it's effectively free to "park".

To delete entirely:

```bash
yc compute instance delete --name openclaw-bot
yc vpc security-group delete --name openclaw-bot-sg
```

Nothing else this wizard created lives outside those two resources.
