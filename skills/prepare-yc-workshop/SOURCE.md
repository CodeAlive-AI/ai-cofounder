origin: original
source: custom (developed for an OpenClaw workshop)
url: —
installed: 2026-05-21
customizations: []
notes: |
  Organizer-side companion to install-openclaw-to-yc. Provisions N isolated
  YC Kazakhstan folders with per-participant service accounts and JSON keys,
  packaged into bundle files that install-openclaw-to-yc consumes as "Plan B"
  (workshop-key mode).

  Idempotent: re-running with the same --workshop tag picks up failures
  without recreating successes. Sequential by design — yc CLI rate limits
  aren't documented and parallelisation isn't worth the recovery complexity
  for a 25-participant batch.

  Hard-coded to YC Kazakhstan endpoint api.yandexcloud.kz:443 and zone
  kz1-a. Roles granted to each per-participant SA are intentionally narrow:
  compute.editor + vpc.user + iam.serviceAccounts.user on the folder only,
  no cloud-level visibility.

  Pairs with install-openclaw-to-yc version 0.8.0+. Older participant-side
  wizards don't recognise the openclaw-workshop-bundle@1 schema and will
  fall through to Plan A.
