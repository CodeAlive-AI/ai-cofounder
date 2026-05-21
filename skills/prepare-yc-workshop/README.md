# prepare-yc-workshop

Organizer-side skill that pre-provisions Yandex Cloud Kazakhstan access for OpenClaw workshop participants who **don't have their own YC account**. Pairs with `install-openclaw-to-yc` (participant-side) — bundles produced here are drop-in inputs there, no manual editing.

For each participant the skill creates:

- One isolated YC folder (`<workshop>-user-NN`) inside the organizer's cloud
- One service account scoped to that folder, with `compute.editor` + `vpc.user` + `iam.serviceAccounts.user`
- Default VPC network and subnet for `kz1-a`
- One RSA-2048 authorisation key
- A `bundle-NN.json` (machine-readable, the participant feeds it to their agent) and a `bundle-NN.message.md` (organizer pastes verbatim in Telegram DM)

End-to-end for 25 participants: **~3 minutes** of sequential `yc` calls. End-to-end cost for a 4-hour workshop in YC KZ: **~430 ₸ (~$1)** — well inside the 24 000 ₸ trial grant.

## Install

```bash
# Recommended: through skills CLI
npx skills add CodeAlive-AI/ceo-ai-os@prepare-yc-workshop -g
# And the participant-side counterpart (used by your participants, not by you)
npx skills add CodeAlive-AI/ceo-ai-os@install-openclaw-to-yc -g
npx skills add CodeAlive-AI/ceo-ai-os@openclaw-guide        -g
```

Manual install paths per agent (Claude Code, Codex, Cursor, …) are the same shape as `install-openclaw-to-yc/README.md` — copy the folder into `~/.claude/skills/`, `~/.codex/skills/`, etc.

## Use

After install, type to your agent:

- "prepare YC workshop for 25 people"
- "provision workshop folders, 30 участников"
- "set me up for an OpenClaw workshop, 20 attendees"
- "раздать ключи Yandex Cloud участникам воркшопа"

The skill asks **one question** (number of participants — defaults to 25) and runs everything itself.

## Prerequisites

1. **`yc` CLI configured** for YC Kazakhstan on the organizer's machine. The skill will NOT walk you through this — it expects you (the organizer) to already have `yc config get token` returning a valid OAuth token for the KZ realm. If you don't, follow `install-openclaw-to-yc/references/01-prerequisites.md` §2 once on your own setup.
2. **Sufficient compute quota** in your cloud — by default a fresh KZ account has ~12 vCPU which is too small for >5 participants. See `references/01-quota-check.md` for the exact `yc quota request submit` commands. Submit the bump **at least 48 hours before the workshop** — approvals can take a day.
3. **`jq` installed** locally — the scripts use it heavily. On macOS: `brew install jq`. On Ubuntu: `sudo apt install jq`.

## What you get

```
bundles/openclaw-kz-2026-05-30/
├── manifest.json                # index of every folder/SA/key for cleanup
├── bundle-01.json               # participant 1 — send this in Telegram DM
├── bundle-01.message.md         # ready-to-paste Russian message for participant 1
├── bundle-02.json
├── bundle-02.message.md
├── ...
└── keys/                        # raw `yc iam key create` outputs (chmod 700)
    ├── key-01.json
    └── ...
```

You DM each participant the `.message.md` text + the matching `.json` file as an attachment. Done.

The participant on their end says to their code-agent:

> У меня workshop-ключ от организатора. Файл `./bundle-NN.json`. Поставь мне бота.

And `install-openclaw-to-yc` recognises the bundle and uses it as Plan B — no personal YC account needed.

## Cleanup (after the workshop)

```bash
bash scripts/cleanup.sh --workshop openclaw-kz-2026-05-30
```

The script reads `manifest.json` and deletes every folder (which cascades to VMs, disks, networks, service accounts, keys). It then archives the bundles directory **without the private keys** and removes the live folder.

Safe to re-run — already-gone folders are skipped without error.

## Folder layout

```
prepare-yc-workshop/
├── SKILL.md                     # wizard instructions (the brain)
├── SOURCE.md                    # origin tracking
├── README.md                    # this file
├── scripts/
│   ├── provision.sh             # create N folders + SA + key + bundle (idempotent, sequential)
│   └── cleanup.sh               # delete everything by workshop tag, archive without keys
└── references/
    ├── 01-quota-check.md        # default limits, bump commands, KZ cost math
    └── 02-bundle-format.md      # schema, security notes, rotation, audit
```

## Security in one paragraph

Each bundle gives its holder `compute.editor` on **one** folder only. They cannot see other participants' folders, can't touch billing, can't escape to the organizer's own resources. Worst case if a bundle leaks: a few vCPU of crypto-mining for the duration of the workshop, capped by the folder's quota. Run `cleanup.sh` after the workshop and the entire attack surface is gone. Full threat model in `references/02-bundle-format.md` §Security.

## Companion skills

- **`install-openclaw-to-yc`** (participant-side) — required. Consumes the bundles produced here.
- **`openclaw-guide`** — required by `install-openclaw-to-yc` for any post-install consulting.

Bundles produced by this skill at version `0.1.0` are consumed by `install-openclaw-to-yc` at version `0.8.0` and later. Older participant-side wizards do not recognise the `$schema` field and will fall through to Plan A. Make sure your participants install the matching version.

## License

MIT — see `LICENSE` at repo root.
