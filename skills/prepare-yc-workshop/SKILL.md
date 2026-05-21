---
name: prepare-yc-workshop
description: >-
  Organizer-side companion to install-openclaw-to-yc. Provisions N isolated
  Yandex Cloud Kazakhstan folders for workshop participants who do NOT have
  their own YC account — one folder per participant, each with a dedicated
  service account, minimum-privilege role bindings, default VPC network, and a
  JSON authorization-key bundle. The bundle file is what the organizer sends
  privately on Telegram to each participant; that participant then feeds it
  into install-openclaw-to-yc as "Plan B" (workshop-key mode) and the wizard
  uses it as a drop-in replacement for personal OAuth. Use when the user says
  prepare YC workshop, provision workshop folders, generate workshop keys,
  organizer setup for OpenClaw workshop, раздать ключи к Яндекс Облаку
  участникам, подготовить Yandex Cloud к воркшопу, or any close paraphrase.
  Runs end-to-end in ~3 minutes for 25 participants. Includes the matching
  cleanup that deletes everything after the workshop. For participant-side
  install, use install-openclaw-to-yc instead.
license: MIT
metadata:
  version: 0.1.0
---

# Prepare YC Workshop (organizer side)

A wizard for the **workshop organizer** that pre-provisions Yandex Cloud Kazakhstan access for participants who don't have their own YC account. The result is one **bundle file** per participant — a single JSON containing a service-account authorization key plus the cloud-id / folder-id / zone it points at. The organizer DM's that file to each participant on Telegram during the workshop; the participant feeds it to `install-openclaw-to-yc`, which runs as if it were a normal personal-cloud install.

## Operating principles

1. **One question.** Ask the organizer only for **how many participants** (N). Everything else — workshop name, zone, role set, key algorithm — is decided from safe defaults. If N is missing, default to 25.
2. **Idempotent.** Re-running with the same `--workshop-name` reuses existing folders, only creates what's missing. Never silently destroys someone else's resources.
3. **Quota first.** Refuse to start if the compute quota in the organizer's cloud isn't large enough for `N × 2 vCPU + 4 GB` plus 10% headroom. Print the exact `yc` command to request a quota bump and **stop** — quota requests aren't instant and creating folders ahead of the bump just wastes time.
4. **Bundles are the deliverable.** The only thing the organizer ever has to look at after the run is the `bundles/` directory. The wizard produces, for each participant, one `bundle-NN.json` (machine-readable, fed into the participant's agent) plus one `bundle-NN.message.md` (human copy-paste text for the Telegram DM).
5. **Cleanup is a single command.** After the workshop, `scripts/cleanup.sh` deletes every folder, SA, and key by the workshop tag. No GUI clicks.
6. **No emojis** unless the organizer's prompt used them.

## Do NOT ask the organizer for these

| Don't ask | Why | Default |
|---|---|---|
| Workshop name | Auto-derived from current date + `openclaw-kz`. | `openclaw-kz-YYYY-MM-DD` |
| Zone | Only zone in YC KZ. | `kz1-a` |
| Roles to grant | Minimum-privilege set is determined by what `install-openclaw-to-yc` needs to do. | `compute.editor`, `vpc.user`, `iam.serviceAccounts.user` on the folder |
| Key algorithm | YC default is fine. | `RSA_2048` |
| Output directory | Always under the current working directory. | `./bundles/<workshop-name>/` |
| Cleanup date | The organizer decides when to run `cleanup.sh`. The wizard does NOT schedule auto-deletion. | n/a |

## When to invoke

Trigger on:
- "prepare YC workshop", "provision workshop folders", "generate workshop keys"
- "I'm running an OpenClaw workshop, set up access for 25 people"
- "раздать ключи Yandex Cloud участникам воркшопа", "подготовь облако к воркшопу"

Do NOT use this skill for:
- Participant install → that's `install-openclaw-to-yc` (Plan B mode picks up bundles produced by this skill)
- Other YC regions (RU, etc.) — hard-coded for `kz1-a`
- Running the actual VMs / OpenClaw install — this skill only sets up the *credentials*; the VM creation is participant-side

## Inputs (the only question)

| # | Input | Default |
|---|---|---|
| 1 | **Number of participants (N)** | 25 |

That's it. Ask in one message:

> Сколько участников ждём на воркшопе? (по умолчанию 25)

Accept any positive integer. If the organizer pastes a roster of names instead of a number — count the lines and confirm: "Вижу N имён — создаю N folder'ов?".

## Wizard flow

### Step 0 — Silent preflight

**a. `yc` CLI present and authorised.** Same check as `install-openclaw-to-yc/SKILL.md` §Step 0a-d. Organizer is expected to already have `yc` working against KZ on their own cloud — this skill does NOT walk them through OAuth setup. If `yc config get token` returns empty, tell them once: "Сначала настрой свой `yc` для Яндекс Облако Казахстан — see `install-openclaw-to-yc/references/01-prerequisites.md` §2c". Then stop.

**b. Resolve cloud-id.** The organizer's active profile must point at a real KZ cloud. `yc resource-manager cloud list --format json | jq -r '.[0].id'`. Empty → wrong realm / wrong token → tell the organizer one line and stop.

**c. Pick a workshop tag.** Defaults to `openclaw-kz-$(date +%Y-%m-%d)`. If today already has bundles in `./bundles/openclaw-kz-YYYY-MM-DD/`, append `-2`, `-3`, etc. until a fresh directory.

**d. Check vCPU quota.** This is the single hard preflight gate.

```bash
NEEDED_VCPU=$((N * 2 + 4))     # 2 vCPU per VM + 10% headroom rounded up
NEEDED_RAM=$((N * 4 + 8))      # 4 GB per VM + headroom

CURRENT_VCPU=$(yc quota get --service-id compute --resource-id total-core-count \
  --format json 2>/dev/null | jq -r '.limit // 0')

if (( CURRENT_VCPU < NEEDED_VCPU )); then
  cat <<EOF
Compute vCPU quota is $CURRENT_VCPU but we need >= $NEEDED_VCPU for $N participants.

Open https://kz.console.yandex.cloud/quotas?service=compute and request a bump to >= $NEEDED_VCPU vCPU and >= $NEEDED_RAM GB RAM. The bump is usually approved within an hour but can take a day — submit it now and re-run this skill once it's granted.
EOF
  exit 1
fi
```

Don't continue past this gate. Quota bumps aren't instant — pretending we'll "ask forgiveness later" wastes 20+ minutes during folder creation.

**e. Confirm the plan.** One short message to the organizer:

> Создам **{N} folder'ов** в облаке `{CLOUD_NAME}`, тег `{WORKSHOP_NAME}`. Для каждого — отдельный service account с правами `compute.editor` + `vpc.user` + `iam.serviceAccounts.user`, default network в зоне `kz1-a`, RSA-2048 ключ. Bundle'ы (JSON + готовый текст для Telegram) сложу в `./bundles/{WORKSHOP_NAME}/`. Поехали? (~3 минуты)

Default "yes" if no response in 10 seconds.

### Step 1 — Run the provision script

The provisioning is implemented in `scripts/provision.sh`. The wizard either invokes it directly or — if the agent's environment makes shell execution awkward — replays the same commands inline using the participant index `i` from 1 to N.

```bash
bash scripts/provision.sh \
  --workshop "$WORKSHOP_NAME" \
  --count "$N" \
  --cloud-id "$CLOUD_ID" \
  --zone kz1-a \
  --out "./bundles/$WORKSHOP_NAME"
```

The script:

1. For each `i` in `1..N`:
   - Creates folder `${WORKSHOP_NAME}-user-${ii}` (zero-padded) with `--default-network-flag true` (creates VPC + subnets in all KZ zones immediately — no separate `vpc create` call needed).
   - Creates service account `sa-${WORKSHOP_NAME}-user-${ii}` inside that folder.
   - Adds folder-level access bindings: `compute.editor`, `vpc.user`, `iam.serviceAccounts.user`.
   - Creates an authorization key, capturing the JSON output to `keys/key-${ii}.json` (mode 600).
   - Writes the **bundle**: `bundle-${ii}.json` (machine-readable) and `bundle-${ii}.message.md` (Telegram-ready Russian text with `bundle-${ii}.json` as an attachment).

2. After the loop, writes `manifest.json` to the output directory — a single index of every folder-id / SA-id / key-id that was created, for the cleanup script and for debugging.

The script runs sequentially (not parallel). Folder creation is fast (~1-2 s each); SA + role binding + key creation are also fast (~1 s each). 25 participants takes 2-3 minutes end-to-end. Don't try to parallelise — `yc` CLI rate-limits aren't documented and a single rejected call mid-batch is annoying to recover from.

If any single participant fails mid-way:
- The script appends `bundle-${ii}.error.log` with the full `yc` error output.
- Continues with the next participant — the organizer can re-run for the failed indices later (the script is idempotent: it skips a participant if `bundle-${ii}.json` already exists and a `yc resource-manager folder get` for the matching name succeeds).

### Step 2 — Hand off

When the script finishes, summarise:

```
Готово. {N_OK}/{N} bundle'ов в ./bundles/{WORKSHOP_NAME}/

Что делать дальше:
  • Открой ./bundles/{WORKSHOP_NAME}/bundle-01.message.md — там готовый текст для Telegram.
  • Каждому участнику в личку: текст + файл bundle-NN.json.
  • На воркшопе участник скажет своему агенту: «У меня workshop-ключ, вот файл» — install-openclaw-to-yc подхватит автоматически.

После воркшопа:
  bash scripts/cleanup.sh --workshop {WORKSHOP_NAME}
  # удалит все {N} folder'ов, SA, ключей. Без подтверждений, идёт по manifest.json.
```

If any failed (`N_OK < N`): list the failed indices and one-liner per failure type. Don't auto-retry — the organizer probably wants to look at the error before re-running.

## Bundle format

The participant-side wizard expects the bundle in a specific shape. Don't break this without bumping the version.

```jsonc
{
  "$schema": "openclaw-workshop-bundle@1",
  "workshop": "openclaw-kz-2026-05-30",
  "user": "user-07",
  "created_at": "2026-05-21T12:00:00Z",
  "expires_at": "2026-06-30T23:59:59Z",      // organizer-set; advisory only

  "cloud_id":  "b1g1abcd0123efgh4567",        // organizer's cloud
  "folder_id": "b1gxxxxxxxxxxxxxxxxx",        // per-participant folder
  "zone":      "kz1-a",
  "endpoint":  "api.yandexcloud.kz:443",

  "service_account": {
    "id":   "ajeyyyyyyyyyyyyyyyyy",
    "name": "sa-openclaw-kz-2026-05-30-user-07"
  },

  "key": {
    // VERBATIM output of `yc iam key create --service-account-id ... --format json`
    // (yc config set service-account-key accepts this shape directly when extracted)
    "id":                 "ajezzzzzzzzzzzzzzzzz",
    "service_account_id": "ajeyyyyyyyyyyyyyyyyy",
    "created_at":         "2026-05-21T12:00:00.000Z",
    "key_algorithm":      "RSA_2048",
    "public_key":         "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----\n",
    "private_key":        "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
  }
}
```

The `$schema` field is what `install-openclaw-to-yc` looks at to recognise a bundle (vs. some other JSON the user might paste).

`expires_at` is advisory — service account keys in YC don't expire unless explicitly rotated/deleted. The participant-side wizard does NOT enforce it. Cleanup deletes the keys server-side.

## Roles granted (minimum-privilege rationale)

| Role | Why participant needs it |
|---|---|
| `compute.editor` | Create / start / stop / delete VMs, disks, snapshots, images in this folder. |
| `vpc.user` | Read & use existing networks/subnets — the default network was created by `--default-network-flag true`; participant only needs to attach to it. |
| `iam.serviceAccounts.user` | Allow the participant's VM to optionally run *as* a service account later (e.g. for backups). Not strictly required by `install-openclaw-to-yc` but cheap to grant. |

Roles explicitly NOT granted:
- `editor` / `admin` on the folder — too broad
- Anything on the cloud level — the SA can only see its own folder
- `iam.serviceAccounts.tokenCreator` — not needed; participant uses the JSON key directly via the wizard

If the participant later wants to do something out of this scope (e.g. KMS-encrypted disks), they ask the organizer in-channel and the organizer extends with `yc resource-manager folder add-access-binding`.

## Cleanup

After the workshop:

```bash
bash scripts/cleanup.sh --workshop "$WORKSHOP_NAME"
```

The script reads `bundles/<workshop>/manifest.json` and:

1. Lists every folder in the manifest.
2. Asks the organizer once: "Удалить N folder'ов вместе со всем содержимым? Это необратимо."
3. On confirmation, deletes each folder with `--async` (returns immediately, YC reaps in the background).
4. Archives the bundles directory to `bundles/<workshop>.archived-<timestamp>.tar.gz` and removes the live folder.

Folder deletion in YC also deletes all resources inside (VMs, disks, networks, SAs, keys). The archive keeps the bundle filenames and IDs around for audit but does NOT keep the private keys (those are stripped on archive).

The cleanup is safe to re-run — already-deleted folders are skipped without error.

## What this skill does NOT cover

- The actual VM install (use `install-openclaw-to-yc` on the participant side)
- Distribution of bundle files (organizer sends them in Telegram DMs manually — this skill produces the file plus a ready-to-paste message, but the *sending* is a human step)
- Per-participant onboarding chat (organizer's job)
- Cost monitoring during the workshop (negligible: ~$0.30/participant for a 4-hour workshop on YC KZ — see `references/01-quota-check.md` for breakdown)

## References

- `references/01-quota-check.md` — exact `yc quota` commands, default limits, bump request flow, KZ pricing math
- `references/02-bundle-format.md` — full bundle JSON schema, what `install-openclaw-to-yc` extracts from it, security notes (private key handling, file mode, when to rotate)
- `scripts/provision.sh` — the actual provisioning loop (sequential, idempotent, per-participant error isolation)
- `scripts/cleanup.sh` — the post-workshop teardown (folder delete, archive, key strip)

## Companion skill (paired)

`install-openclaw-to-yc` is the participant-side counterpart. Bundles produced here are designed to be drop-in inputs there. Both skills together cover the whole organizer + participant workflow for an OpenClaw workshop in YC Kazakhstan.

Install both:

```bash
npx skills add CodeAlive-AI/ceo-ai-os@prepare-yc-workshop  -g
npx skills add CodeAlive-AI/ceo-ai-os@install-openclaw-to-yc -g
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-guide        -g
```
