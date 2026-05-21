# Plan B — Workshop-Key Mode

The wizard supports two ways to get access to a Yandex Cloud Kazakhstan folder:

- **Plan A** — the user's own YC account, OAuth via `oauth.yandex.kz`.
- **Plan B** — a **workshop bundle** file (`bundle-NN.json`) the workshop organizer sent privately on Telegram.

This file documents Plan B end-to-end. Plan A is the default and is covered in `SKILL.md` Step 0c-e and `01-prerequisites.md`.

## What a bundle looks like

A workshop bundle is a single JSON file produced by the organizer-side skill `prepare-yc-workshop`. It contains everything the wizard needs to point `yc` CLI at one isolated folder inside the organizer's cloud — no OAuth, no personal YC account.

```jsonc
{
  "$schema": "openclaw-workshop-bundle@1",
  "workshop":   "openclaw-kz-2026-05-30",
  "user":       "user-07",
  "created_at": "2026-05-21T12:00:00Z",
  "expires_at": "2026-06-30T23:59:59Z",
  "cloud_id":   "b1g1abcd0123efgh4567",
  "folder_id":  "b1gxxxxxxxxxxxxxxxxx",
  "zone":       "kz1-a",
  "endpoint":   "api.yandexcloud.kz:443",
  "service_account": {
    "id":   "ajeyyyyyyyyyyyyyyyyy",
    "name": "sa-openclaw-kz-2026-05-30-user-07"
  },
  "key": {
    "id":                 "ajezzzzzzzzzzzzzzzzz",
    "service_account_id": "ajeyyyyyyyyyyyyyyyyy",
    "created_at":         "2026-05-21T12:00:00.000Z",
    "key_algorithm":      "RSA_2048",
    "public_key":         "-----BEGIN PUBLIC KEY-----\n…\n-----END PUBLIC KEY-----\n",
    "private_key":        "-----BEGIN PRIVATE KEY-----\n…\n-----END PRIVATE KEY-----\n"
  }
}
```

The `$schema` field is what distinguishes a workshop bundle from a random JSON. **Always check it first** — if it doesn't start with `openclaw-workshop-bundle@`, this is not a bundle and Plan B should refuse.

## Detection

Step 0.5 in `SKILL.md` walks the detection ladder. Re-stated briefly here, in priority order:

1. The user pastes/types a file path → resolve it → JSON whose `$schema` starts with `openclaw-workshop-bundle@` → Plan B.
2. The user said "у меня workshop-ключ" / "вот bundle от организатора" / English equivalents → ask once for the path → validate `$schema` → Plan B.
3. Exactly one `bundle-*.json` file in `$PWD`, `~/Downloads`, or `~/Desktop` whose `$schema` matches → confirm with one yes/no question → Plan B.
4. Nothing matched → Plan A (default).

The wizard does NOT preemptively ask "do you have a workshop key?" at the start. >50% of users have their own YC; asking everyone is friction.

## Configure yc from the bundle

Once detected, configure a wizard-owned `openclaw-workshop` profile from the bundle:

```bash
BUNDLE_PATH="/path/to/bundle-NN.json"

# Use a dedicated profile so the user's other yc setups are untouched.
yc config profile create openclaw-workshop 2>/dev/null || true
yc config profile activate openclaw-workshop

# Extract the SA key into the exact shape `yc config set service-account-key` expects.
KEY_FILE="$(mktemp -t openclaw-sa-key.XXXXXX.json)"
jq '.key' "$BUNDLE_PATH" > "$KEY_FILE"
chmod 600 "$KEY_FILE"

yc config set service-account-key  "$KEY_FILE"
yc config set endpoint             "$(jq -r '.endpoint'  "$BUNDLE_PATH")"
yc config set cloud-id             "$(jq -r '.cloud_id'  "$BUNDLE_PATH")"
yc config set folder-id            "$(jq -r '.folder_id' "$BUNDLE_PATH")"
yc config set compute-default-zone "$(jq -r '.zone'      "$BUNDLE_PATH")"
```

Verify it actually works with one read call:

```bash
yc compute zone list --format json | jq -e '.[] | select(.id=="kz1-a")' >/dev/null \
  || die "Workshop key doesn't work — ask the organizer for a new bundle."
```

After this block, `yc compute / vpc / resource-manager` all work against the organizer's folder. The rest of the wizard (Step 1 onwards) doesn't need to know it's Plan B — the configured profile looks identical to a Plan A setup.

## What Plan B skips vs. keeps

| Step | Plan A | Plan B |
|---|---|---|
| 0.5 — mode detection | n/a | **yes**, runs first |
| 0a — companion skill loaded | yes | yes |
| 0b — `yc` CLI present | yes | yes |
| 0c — activate `openclaw-kz` profile | yes | **skipped** (Plan B uses `openclaw-workshop` profile, already activated) |
| 0d — OAuth token | yes (only mandatory user prompt) | **skipped** (bundle has SA key) |
| 0e — cloud-id + folder-id | yes (auto-resolve) | **skipped** (bundle has both) |
| 0f — SSH key | yes | yes |
| 0g — existing VM with same name | yes | yes |
| 1 — two questions (Telegram + LLM) | yes | yes — same questions |
| 2 — VM create | yes | yes — same code path |
| 3 — wait for cloud-init | yes | yes |
| 3.5 — OAuth device flow for Codex | only if `LLM_PROVIDER=openai-codex` | same |
| 4 — Telegram pair + chat_id detection | yes | yes |
| 5 — verify bot answers | yes | yes |

## Failure modes specific to Plan B

| Symptom | Most likely cause | What to tell the user |
|---|---|---|
| `$schema` missing or doesn't start with `openclaw-workshop-bundle@` | Wrong file (e.g. organizer sent raw `yc iam key create` output by mistake). | "Это не похоже на workshop-bundle от организатора. Проверь, что прислали правильный файл." |
| `$schema` is `openclaw-workshop-bundle@2` (or higher) and we don't recognise it | Organizer updated `prepare-yc-workshop` past this wizard's version. | "Bundle новее, чем я умею. Попробую как есть." Try the standard Plan B steps; surface any `yc` error plainly. |
| Required field missing (`cloud_id`, `folder_id`, `zone`, `endpoint`, `key`) | Bundle was edited or partially copy-pasted. | "В bundle не хватает поля `<X>`. Попроси у организатора новый файл." |
| `yc compute zone list` returns empty | SA key revoked OR folder deleted. | "Кажется, организатор уже свернул облако воркшопа. Напиши ему." |
| `yc compute zone list` returns `ru-central1-*` instead of `kz1-a` | Bundle's `endpoint` field was wrong. | "В bundle прописан не тот регион. Это организатор-сайд баг — напиши организатору." |
| `yc compute instance create` errors with `quota_exceeded` | Organizer ran the workshop with too low a compute quota. | "У организатора не хватает квоты vCPU/RAM в облаке. Скажи ему, и подождите минут 30." |
| `yc compute instance create` errors with `permission denied` | The SA wasn't granted the right role on the folder. | "У ключа нет прав создавать VM. Скажи организатору — должно быть `compute.editor` + `vpc.user` + `iam.serviceAccounts.user`." |
| User sends "у меня workshop-ключ" and `expires_at` < now | Workshop is over, key past expiry (advisory). | "Срок жизни ключа истёк. Свяжись с организатором." |

## What NOT to do in Plan B

- **Don't fall through to Plan A.** If we detected Plan B intent but the bundle is broken, telling the user "let's set up your own YC instead" wastes their time — they wouldn't have asked for Plan B if they had their own.
- **Don't ask for cloud-id or folder-id.** Both are in the bundle. Asking re-introduces the friction we eliminated.
- **Don't write the SA key into the user's main `~/.config/yandex-cloud/`** under their default profile. Use the dedicated `openclaw-workshop` profile. Reason: if the user is also a Plan A user on another workshop, those configs should not collide.
- **Don't keep the carved-out `KEY_FILE` after wizard exit.** It's a `mktemp` file — leave it; the OS clears `$TMPDIR` periodically. The bundle itself stays under the user's control.
- **Don't print the private key to the user**, even as a debug message.

## Hand-off back to the organizer

After the wizard succeeds and the VM is running, the user has a working bot in the organizer's folder. The user's day-to-day usage doesn't touch `yc` again — everything happens through Telegram.

When the workshop is over and the organizer runs `prepare-yc-workshop`'s `cleanup.sh`, the folder gets deleted and the user's VM disappears. The wizard does NOT warn them about this proactively — if they want their own bot to keep running past the workshop, they should re-run with Plan A on their own YC account.

Briefly mention this in the final summary if `MODE=plan-b`:

```
Бот работает в облаке организатора. После воркшопа VM будет удалена.
Если хочешь оставить бота на постоянку — открой свой Yandex Cloud Kazakhstan
и запусти меня снова без ключа от организатора (я переустановлю Plan A).
```

## See also

- `prepare-yc-workshop/SKILL.md` — the organizer-side skill that produces bundles.
- `prepare-yc-workshop/references/02-bundle-format.md` — full schema, security notes, rotation procedure.
- `01-prerequisites.md` (this skill) — Plan A OAuth setup, for users who want their own YC account.
