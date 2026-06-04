# Troubleshooting playbook

The seven failure modes the wizard can hit, in order of how often they actually happen. Each one has a copy-paste fix that doesn't require guessing.

For any error not listed: dump `cat /var/log/openclaw-bootstrap.log` and `sudo journalctl -u openclaw-gateway -n 200` from the VM and surface to the user. Don't extrapolate from a tail of 5 lines.

---

## §1. `hcloud` returns auth or quota errors

The most common Hetzner-side trip points.

### §1a. `unauthorized` on `hcloud server list` or `hcloud server create`

**Symptom.** `hcloud server list` works, but `hcloud server create ...` fails with `unauthorized` / `403`. Or both fail with `unauthorized`.

**Causes (in order of likelihood):**

1. Token has read-only scope (passes list, fails write).
2. Token belongs to a different project than the user thinks.
3. Token was revoked or expired (Hetzner tokens don't auto-expire, but admins can revoke).
4. Pasted with a leading/trailing space or only partial token.

**Fix.**

```bash
# 1. Check which context is active and probe
hcloud context list
hcloud context active   # shows the current context name
hcloud server list      # if this works, token is at least read-valid

# 2. Confirm the project — the project name shows in the console URL
#    https://console.hetzner.cloud/projects/<PROJECT_ID>/servers
#    Make sure the user's expected project matches.

# 3. Regenerate the token (read & write scope)
#    Console → Security → API Tokens → Generate New
#    Then update the wizard context:
hcloud context delete openclaw-install
echo "hv2-NEW-TOKEN" | hcloud context create openclaw-install
hcloud context use openclaw-install
```

### §1b. `verification_required` on `hcloud server create`

**Symptom.** Token is valid (`hcloud server list` returns 200), but `hcloud server create` errors with `action_failed` / `error.code = "verification_required"`.

**Cause.** Hetzner account hasn't completed fraud-review verification. Common for fresh accounts; sometimes also triggers on accounts that recently changed payment method or were dormant for months.

**Fix.**

1. Open https://console.hetzner.cloud → look for a verification banner in the dashboard. Complete whatever it asks (ID document upload, video call, etc.).
2. If no banner appears but the error persists: email `cda-review@hetzner.com` with the account email. Response time is hours to days during EU business hours.
3. **Do not** create another Hetzner account thinking it will be faster — multiple unverified accounts trigger stricter review and may block all of them.

The wizard should NOT retry in a loop while waiting for verification. Pause politely; ask the user to message you when verification completes.

### §1c. `resource_unavailable` after both `cax11` and `cx22` were tried

**Symptom.** `hcloud server create --type cax11 ... --location fsn1` fails with `server_type_unavailable` or `resource_unavailable`. Auto-recovery retries with `cx22` — also fails.

**Cause.** Both ARM and x86 small types are sold out in `fsn1` simultaneously. This is rare but happens during peak demand (Black Friday-style ML capacity squeezes have hit Hetzner before).

**Fix — pick another EU location.**

```bash
# Inventory: which locations have what
for L in fsn1 nbg1 hel1; do
  echo "=== $L ==="
  for T in cax11 cx22; do
    AVAIL=$(hcloud server-type describe $T -o json 2>/dev/null | jq -r --arg L "$L" '.prices[] | select(.location==$L) | .price_hourly.gross // "n/a"')
    echo "$T: $AVAIL EUR/hour"
  done
done
```

Then retry with another location (note that `--without-ipv4` is NOT what to flip — that would break SSH):

```bash
hcloud server create --name openclaw-bot --type cax11 \
  --image ubuntu-24.04 --location nbg1 \   # Nuremberg, also DE, same eu-central zone
  --ssh-key ... --firewall ... --user-data-from-file /tmp/openclaw-cloud-init.yaml
```

`nbg1` and `hel1` are both in the `eu-central` network zone — outbound latency to Telegram / Anthropic is comparable to `fsn1`. The wizard should ask the user once before switching location, since they may have picked `fsn1` deliberately.

### §1d. `limit_reached` on `hcloud server create`

**Symptom.** `error.code = "limit_reached"` or `server_limit_reached`.

**Cause.** This project already has the maximum allowed number of servers (default 20 per project, but new accounts often start with a lower per-project quota — sometimes as low as 3-5).

**Fix.**

```bash
# Check what's there
hcloud server list

# Either delete unused servers:
hcloud server delete <other-server>

# Or request a quota increase: console.hetzner.cloud → Account → Limits → Request change
# Approval is usually within EU business hours.
```

---

## §2. Cloud-init log shows `npm install -g openclaw failed`

**Symptom.** `/var/log/openclaw-bootstrap.log` line: `npm ERR! 404 Not Found` or `EACCES` or `network timeout`.

**Cause hierarchy.**

1. NodeSource setup script failed (no internet on first boot — rare, but happens if the cloud-side firewall denied outbound; this skill never adds outbound rules, so this shouldn't happen unless the user attached a different firewall).
2. npm registry was flaky.
3. ARM-specific: a native module had no `linux-arm64` build and tried to compile from source, hitting a missing build dep.

**Fix.**

```bash
# Check internet from the VM
ssh openclaw@$IP 'curl -fsS https://registry.npmjs.org/openclaw/latest | jq .version'
# If that fails: outbound is broken. Check Hetzner firewall outbound rules:
hcloud firewall describe openclaw-bot-fw | jq '.firewall.rules[] | select(.direction=="out")'
# Empty array = default-allow-all outbound (correct). If any rules exist that don't allow 443/tcp to 0.0.0.0/0, fix them or remove them.

# If outbound is fine: re-run the install manually
ssh openclaw@$IP 'export PATH=$HOME/.npm-global/bin:$PATH; npm install -g openclaw@latest && openclaw --version'

# ARM-specific: install build deps before retrying
ssh openclaw@$IP 'sudo apt-get install -y build-essential python3 && npm install -g openclaw@latest'

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
ssh openclaw@$IP 'sudo journalctl -u openclaw-gateway -n 40 --no-pager'
# Look for "[gateway] ready" — when that appears, RPC works.
```

If after 4 minutes there's still no `[gateway] ready`:

```bash
# Force-restart the gateway. Watch journalctl in another terminal.
ssh openclaw@$IP 'sudo systemctl restart openclaw-gateway && sleep 120 && curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:18789/health'
# Expect 200.
```

**Known pitfall:** Hetzner sometimes throttles new-VM outbound for the first 60 seconds (DDoS heuristics on fresh public IPs). Don't claim failure until you've waited the full 4 minutes.

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

This was the wizard's silent-failure bug before 0.5.0 of the YC variant: the jq filter used `.chatId` / `.code` which don't exist in the `DevicePairRequestedEventSchema` (`src/gateway/protocol/schema/devices.ts`). The real fields are `.senderId` (Telegram user id) and `.requestId` (primary key). The Hetzner variant inherits the defensive filter from day one.

Inspect the pending requests directly:

```bash
ssh openclaw@$IP 'openclaw pairing list telegram --format json' | jq .
```

You should see entries like `{requestId: "abc123...", senderId: 123456789, channel: "telegram", ...}`. Approve the right one:

```bash
ssh openclaw@$IP 'openclaw pairing approve telegram <requestId-or-code>'
```

The CLI accepts the `requestId` from the list OR the human-readable code shown in the bot's DM reply. Try `requestId` first.

After approve:

```bash
ssh openclaw@$IP "
  openclaw config set channels.telegram.dmPolicy allowlist
  openclaw config set channels.telegram.allowFrom '[<chat_id>]'
  sudo systemctl restart openclaw-gateway
"
```

**4d. LLM provider has no credit / not authorized.**

```bash
ssh openclaw@$IP 'sudo journalctl -u openclaw-gateway -n 200 | grep -iE "anthropic|openrouter|openai|credit|billing|unauthorized"'
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

Fix:

```bash
# Anthropic
ssh openclaw@$IP 'openclaw config set agents.defaults.model.primary anthropic/claude-sonnet-4-6'
# OpenRouter
ssh openclaw@$IP 'openclaw config set agents.defaults.model.primary openrouter/moonshotai/kimi-k2.6'
# OpenAI Codex (Pro)
ssh openclaw@$IP 'openclaw config set agents.defaults.model.primary openai-codex/gpt-5.5'
# OpenAI Codex (Plus only)
ssh openclaw@$IP 'openclaw config set agents.defaults.model.primary openai-codex/gpt-4o'

ssh openclaw@$IP 'sudo systemctl restart openclaw-gateway'
```

**4f. Bot replies but in the wrong language.**

The locale pack wasn't appended, or the bot's current session was started before USER.md was updated.

```bash
# Confirm the locale pack is in USER.md
ssh openclaw@$IP 'tail -30 ~/.openclaw/workspace/USER.md'
# If the "Язык общения" / "Sprache" block is missing — append it:
ssh openclaw@$IP "cat /usr/local/share/openclaw-locale-ru.md >> ~/.openclaw/workspace/USER.md"
# Force a session reset so the bot re-reads bootstrap files
ssh openclaw@$IP "openclaw sessions reset --channel telegram --to <chat_id>"
# Then ask the user to message the bot again
```

If the locale pack file doesn't exist on the VM (cloud-init didn't write it): the cloud-init template's `{{USER_LANGUAGE}}` placeholder probably wasn't substituted, or substituted with a code we don't have a pack for (we ship `ru` and `de`; for `en` no pack is needed — that's the ceo-ai-os default). Write the pack inline:

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

**Causes.** (Note: a wrong source IP is **never** the cause — SSH is open to `0.0.0.0/0` + `::/0`, with no per-IP firewall lock and no ufw rate-limit. Don't chase the firewall here.)

1. Wrong username — the cloud-init creates `openclaw`, not `ubuntu` or `root`.
2. Wrong key — server was created with a different SSH key than the user is currently presenting.

**Fix.**

```bash
# 1. Confirm username
ssh -v openclaw@$IP 2>&1 | head -20

# 2. List keys attached to the server
hcloud server describe openclaw-bot -o json | jq '.server.public_net.ssh_keys // "see ssh keys attached at create"'
# Or look at what keys are in the project:
hcloud ssh-key list

# 3. Confirm SSH is open in the firewall (it should be 0.0.0.0/0 + ::/0).
#    This is a sanity check, not a fix — a wrong IP is never the cause anymore.
hcloud firewall describe openclaw-bot-fw -o json | jq '.firewall.rules[] | select(.direction=="in" and .port=="22")'
```

**Last resort — Hetzner Rescue Mode** (works even with a broken SSH config):

1. https://console.hetzner.cloud → server → **Rescue** → enable.
2. Reboot the server.
3. SSH as `root` with the one-time password Hetzner shows.
4. Mount the data disk: `mount /dev/sda1 /mnt`.
5. Fix `/mnt/etc/ssh/sshd_config.d/...` or unban yourself in fail2ban.
6. Reboot back to normal mode.

---

## §6. Forgot the IP, lost SSH, want to start over

**Symptom.** User says "I closed the terminal and don't remember the IP."

**Fix.**

```bash
hcloud server describe openclaw-bot -o json | jq -r '.server.public_net.ipv4.ip'
```

If the user truly wants to start fresh, the wizard's teardown sequence is:

```bash
hcloud server delete openclaw-bot
hcloud firewall delete openclaw-bot-fw
# Primary IPv4 usually auto-deletes with the server, but check:
hcloud primary-ip list
hcloud primary-ip delete <id>   # if any orphaned
```

All four commands are safe to run blindly — they only delete what this wizard creates. The Telegram bot survives in BotFather and can be reused for the next install (the same token). The Anthropic / OpenRouter API key is unchanged.

---

## §7. Cost worry — user wants to pause

```bash
# Stop billing for CPU/RAM. Disk + IPv4 still bill (~€0.54/mo total when stopped).
hcloud server poweroff openclaw-bot
# Resume later:
hcloud server poweron openclaw-bot
```

To delete entirely:

```bash
hcloud server delete openclaw-bot
hcloud firewall delete openclaw-bot-fw
```

Nothing else this wizard created lives outside those two resources.

For long-term users who don't want to pay €0.50/mo for an idle IPv4 but want to come back later: there's no "preserve IP only" option — deleting the server deletes the Primary IP. If the user needs to keep the IP across a delete/recreate cycle, they should detach it first (`hcloud primary-ip set --auto-delete=false ...` before delete) — but for a workshop or personal bot, the simplest thing is to delete everything and re-run the wizard from scratch next time (~15 minutes).
