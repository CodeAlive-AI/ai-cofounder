# Bundle format and security notes

## Schema (`openclaw-workshop-bundle@1`)

Every bundle file is a single JSON document. `install-openclaw-to-yc` recognises it by the `$schema` field — if that field starts with `openclaw-workshop-bundle@`, the wizard enters Plan B (workshop-key mode) and uses the rest of the document as a drop-in replacement for personal OAuth.

```jsonc
{
  "$schema": "openclaw-workshop-bundle@1",

  // Identification — used in the Telegram-ready message and on cleanup.
  "workshop":   "openclaw-kz-2026-05-30",
  "user":       "user-07",
  "created_at": "2026-05-21T12:00:00Z",
  "expires_at": "2026-06-30T23:59:59Z",   // advisory only — see §4

  // YC realm identifiers — what `install-openclaw-to-yc` passes to `yc config set`.
  "cloud_id":   "b1g1abcd0123efgh4567",
  "folder_id":  "b1gxxxxxxxxxxxxxxxxx",   // participant-specific
  "zone":       "kz1-a",
  "endpoint":   "api.yandexcloud.kz:443",

  // Whom the key belongs to (for human debugging only).
  "service_account": {
    "id":   "ajeyyyyyyyyyyyyyyyyy",
    "name": "sa-openclaw-kz-2026-05-30-user-07"
  },

  // Verbatim output of `yc iam key create`. The participant wizard writes this
  // sub-document to a temp file and runs `yc config set service-account-key <path>`.
  // Don't reshape it — yc expects exactly this layout.
  "key": {
    "id":                 "ajezzzzzzzzzzzzzzzzz",
    "service_account_id": "ajeyyyyyyyyyyyyyyyyy",
    "created_at":         "2026-05-21T12:00:00.000Z",
    "key_algorithm":      "RSA_2048",
    "public_key":         "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----\n",
    "private_key":        "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
  }
}
```

## How the participant wizard uses it

`install-openclaw-to-yc/SKILL.md` §Step 0.5 (Plan B branch) does roughly this:

```bash
BUNDLE=./bundle-07.json
[[ "$(jq -r '."$schema"' "$BUNDLE")" =~ ^openclaw-workshop-bundle@ ]] \
  || die "Not a workshop bundle"

# Carve out the key into the shape yc expects.
jq '.key' "$BUNDLE" > /tmp/openclaw-sa-key.json
chmod 600 /tmp/openclaw-sa-key.json

# Set up a wizard-owned profile so the participant's other yc setups stay clean.
yc config profile create openclaw-workshop 2>/dev/null || true
yc config profile activate openclaw-workshop
yc config set service-account-key /tmp/openclaw-sa-key.json
yc config set endpoint            "$(jq -r '.endpoint'  "$BUNDLE")"
yc config set cloud-id            "$(jq -r '.cloud_id'  "$BUNDLE")"
yc config set folder-id           "$(jq -r '.folder_id' "$BUNDLE")"
yc config set compute-default-zone "$(jq -r '.zone'      "$BUNDLE")"

# From here on the wizard's code path is identical to Plan A.
```

Plan A and Plan B converge after this block — Step 1 onwards (questions, VM create, OpenClaw install, Telegram pairing) sees only an already-configured `yc` profile.

## Why a key + meta-bundle, not just the key

`yc iam key create` produces a JSON containing the service-account-id and the RSA key, but **not** the cloud-id or folder-id. There's no way to derive those from the key alone, because a folder-scoped service account doesn't have `resource-manager.viewer` on the cloud to list things — that would have to be granted separately.

Three alternatives we considered:

1. **Just the key, ask folder-id from the user.** Breaks the "two questions max" rule in `install-openclaw-to-yc`.
2. **Just the key, grant resource-manager.viewer on the cloud.** Lets the participant SEE other participants' folders. Information leak.
3. **Key + meta bundle.** No extra IAM. Participant gets exactly what they need, no more.

(3) is what we ship.

## Security

### File handling

- `provision.sh` writes bundles with `chmod 600`.
- The `keys/` subdirectory under `bundles/<workshop>/` is also `chmod 700` so other local users can't read raw keys.
- Don't `git add` the `bundles/` directory. Add it to `.gitignore` in any repo where this skill lives.

### Threat model

The bundle is **as sensitive as a long-lived API key**. If a participant's laptop is compromised or they post the file in a public channel, the attacker can:

- Create / delete VMs in **their folder only** (`compute.editor`)
- Use the default VPC network in **their folder only** (`vpc.user`)
- Use the SA to launch VMs under that SA identity (`iam.serviceAccounts.user`)

They cannot:

- See other participants' folders (no cloud-level binding)
- Create new folders or service accounts (no `resource-manager` write)
- Touch billing
- Escape to the organizer's own resources outside the workshop folders

So worst case: 2 vCPU / 4 GB of crypto-mining for a few hours until the organizer notices. Manageable. Still, the organizer should:

1. Send each bundle only to the named participant in private Telegram, never in a group.
2. Run `cleanup.sh` immediately after the workshop ends.

### Key rotation

We don't rotate the key during the workshop — the SA has no permission outside its folder, and the folder gets deleted at the end. Rotation only matters if the workshop runs longer than ~30 days (review the `expires_at` field, which is set to creation + 40 days by default).

To rotate one participant's key without disturbing others:

```bash
SA_ID=$(jq -r '.service_account.id' bundle-07.json)
OLD_KEY_ID=$(jq -r '.key.id' bundle-07.json)

# Issue a new key
yc iam key create \
  --service-account-id "$SA_ID" \
  --output /tmp/new-key.json

# Splice it into the bundle
jq --slurpfile new /tmp/new-key.json '.key = $new[0]' bundle-07.json > bundle-07.json.new
mv bundle-07.json.new bundle-07.json

# Delete the old key (does NOT delete the SA)
yc iam key delete "$OLD_KEY_ID"
```

The participant re-runs `install-openclaw-to-yc` with the updated bundle. If they have a running VM, it doesn't lose access (VM access is tied to the SA, not the key).

### Audit

After cleanup, the archived `<workshop>.archived-TIMESTAMP.tar.gz` keeps `manifest.json` plus all `bundle-*.message.md` — enough to audit who got which folder. Private keys are **stripped** from the archive by `tar --exclude='*/keys' --exclude='bundle-*.json'`.

## Versioning

Bumping `$schema` to `openclaw-workshop-bundle@2` is allowed, but `install-openclaw-to-yc` must continue to accept `@1` for at least one workshop cycle. Both skills move together.

If you add a new field, prefer extending the existing schema in a backwards-compatible way (new optional keys) over bumping. Examples of legitimate `@2` reasons: different key algorithm (Ed25519), federated SA tokens instead of long-lived RSA, automatic cleanup metadata.
