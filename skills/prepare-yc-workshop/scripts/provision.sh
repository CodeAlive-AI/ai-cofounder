#!/usr/bin/env bash
#
# prepare-yc-workshop / provision.sh
# Provisions N isolated Yandex Cloud Kazakhstan folders for workshop participants.
#
# Idempotent: re-running with the same --workshop tag picks up where it left off.
# Sequential: ~3 minutes for 25 participants. Do not parallelise.
#
# Usage:
#   bash provision.sh --workshop openclaw-kz-2026-05-30 --count 25 \
#                     --cloud-id b1gxxx --zone kz1-a \
#                     --out ./bundles/openclaw-kz-2026-05-30

set -euo pipefail

WORKSHOP=""
COUNT=""
CLOUD_ID=""
ZONE="kz1-a"
OUT_DIR=""
ENDPOINT="api.yandexcloud.kz:443"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workshop) WORKSHOP="$2"; shift 2 ;;
    --count)    COUNT="$2";    shift 2 ;;
    --cloud-id) CLOUD_ID="$2"; shift 2 ;;
    --zone)     ZONE="$2";     shift 2 ;;
    --out)      OUT_DIR="$2";  shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -z "$WORKSHOP" || -z "$COUNT" || -z "$CLOUD_ID" || -z "$OUT_DIR" ]] && {
  echo "Required: --workshop NAME --count N --cloud-id ID --out DIR" >&2
  exit 2
}
[[ "$COUNT" =~ ^[0-9]+$ ]] || { echo "--count must be an integer" >&2; exit 2; }
command -v yc >/dev/null || { echo "yc CLI not installed" >&2; exit 3; }
command -v jq >/dev/null || { echo "jq not installed" >&2; exit 3; }

mkdir -p "$OUT_DIR/keys"
chmod 700 "$OUT_DIR/keys"

# ANSI helpers (only when stdout is a tty)
if [[ -t 1 ]]; then
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_ERR=$'\033[31m'; C_DIM=$'\033[2m'; C_END=$'\033[0m'
else
  C_OK=""; C_WARN=""; C_ERR=""; C_DIM=""; C_END=""
fi

log() { echo "$@" >&2; }
ok()  { log "${C_OK}✓${C_END} $*"; }
warn(){ log "${C_WARN}!${C_END} $*"; }
err() { log "${C_ERR}✗${C_END} $*"; }

# ---- Confirm sanity: cloud must exist and we have rights to create folders ----
CLOUD_NAME=$(yc resource-manager cloud get "$CLOUD_ID" --format json 2>/dev/null | jq -r '.name // empty')
[[ -z "$CLOUD_NAME" ]] && { err "Cloud $CLOUD_ID not visible to active yc profile"; exit 4; }
log "Cloud: $CLOUD_NAME ($CLOUD_ID)"
log "Workshop tag: $WORKSHOP"
log "Participants: $COUNT"
log "Output: $OUT_DIR"
log ""

MANIFEST="$OUT_DIR/manifest.json"
if [[ ! -f "$MANIFEST" ]]; then
  jq -n --arg ws "$WORKSHOP" --arg cid "$CLOUD_ID" --arg zone "$ZONE" \
        --arg created "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{workshop: $ws, cloud_id: $cid, zone: $zone, created_at: $created, participants: []}' \
        > "$MANIFEST"
fi

OK_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0

for i in $(seq 1 "$COUNT"); do
  II=$(printf "%02d" "$i")
  FOLDER_NAME="${WORKSHOP}-user-${II}"
  SA_NAME="sa-${WORKSHOP}-user-${II}"
  BUNDLE="$OUT_DIR/bundle-${II}.json"
  MESSAGE="$OUT_DIR/bundle-${II}.message.md"
  KEY_FILE="$OUT_DIR/keys/key-${II}.json"
  ERR_LOG="$OUT_DIR/bundle-${II}.error.log"

  # Idempotency: if the bundle is already there AND the folder still exists, skip.
  if [[ -f "$BUNDLE" ]]; then
    FOLDER_ID=$(jq -r '.folder_id' "$BUNDLE")
    if yc resource-manager folder get "$FOLDER_ID" --format json >/dev/null 2>&1; then
      ok "[$II] already provisioned (folder $FOLDER_ID); skipping"
      SKIP_COUNT=$((SKIP_COUNT+1))
      continue
    fi
    warn "[$II] bundle exists but folder gone — re-provisioning"
    rm -f "$BUNDLE" "$MESSAGE" "$KEY_FILE"
  fi

  log "[$II] provisioning $FOLDER_NAME ..."
  rm -f "$ERR_LOG"

  # 1. Create folder (with default network + subnets in all KZ zones).
  if ! FOLDER_JSON=$(yc resource-manager folder create \
        --cloud-id "$CLOUD_ID" \
        --name "$FOLDER_NAME" \
        --description "OpenClaw workshop participant $II" \
        --labels "workshop=$WORKSHOP,user=user-$II" \
        --format json 2>"$ERR_LOG"); then
    # Idempotent retry: maybe the folder already exists from a previous failed run.
    FOLDER_JSON=$(yc resource-manager folder list --cloud-id "$CLOUD_ID" --format json 2>/dev/null \
      | jq --arg n "$FOLDER_NAME" '.[] | select(.name==$n)')
    if [[ -z "$FOLDER_JSON" ]]; then
      err "[$II] folder create failed; see $ERR_LOG"
      FAIL_COUNT=$((FAIL_COUNT+1))
      continue
    fi
    warn "[$II] folder existed; reusing"
  fi
  FOLDER_ID=$(echo "$FOLDER_JSON" | jq -r '.id')

  # 2. Ensure default network + subnet in the new folder.
  #    --default-network-flag on `folder create` is best-effort across yc versions;
  #    create explicitly if missing so we don't depend on that quirk.
  if ! yc vpc network get --name default --folder-id "$FOLDER_ID" --format json >/dev/null 2>&1; then
    yc vpc network create --name default --folder-id "$FOLDER_ID" --format json \
      >> "$ERR_LOG" 2>&1 || true
  fi
  if ! yc vpc subnet get --name "default-${ZONE}" --folder-id "$FOLDER_ID" --format json >/dev/null 2>&1; then
    NET_ID=$(yc vpc network get --name default --folder-id "$FOLDER_ID" --format json | jq -r '.id')
    yc vpc subnet create \
      --name "default-${ZONE}" \
      --folder-id "$FOLDER_ID" \
      --network-id "$NET_ID" \
      --zone "$ZONE" \
      --range "10.13$((i % 10)).0.0/24" \
      --format json >> "$ERR_LOG" 2>&1 || warn "[$II] subnet create returned non-zero (may be retry); ignoring"
  fi

  # 3. Service account in the new folder.
  if ! SA_JSON=$(yc iam service-account create \
        --name "$SA_NAME" \
        --folder-id "$FOLDER_ID" \
        --format json 2>>"$ERR_LOG"); then
    SA_JSON=$(yc iam service-account get --name "$SA_NAME" --folder-id "$FOLDER_ID" --format json 2>/dev/null || true)
    if [[ -z "$SA_JSON" ]]; then
      err "[$II] service-account create failed; see $ERR_LOG"
      FAIL_COUNT=$((FAIL_COUNT+1))
      continue
    fi
  fi
  SA_ID=$(echo "$SA_JSON" | jq -r '.id')

  # 4. Folder-level role bindings (minimum-privilege).
  for ROLE in compute.editor vpc.user iam.serviceAccounts.user; do
    yc resource-manager folder add-access-binding "$FOLDER_ID" \
      --role "$ROLE" \
      --subject "serviceAccount:$SA_ID" \
      --async \
      >> "$ERR_LOG" 2>&1 || warn "[$II] role $ROLE binding returned non-zero; check $ERR_LOG"
  done

  # 5. Authorisation key (the secret participant will use).
  if ! yc iam key create \
        --service-account-id "$SA_ID" \
        --folder-id "$FOLDER_ID" \
        --description "openclaw-workshop $WORKSHOP user-$II" \
        --output "$KEY_FILE" \
        >> "$ERR_LOG" 2>&1; then
    err "[$II] key create failed; see $ERR_LOG"
    FAIL_COUNT=$((FAIL_COUNT+1))
    continue
  fi
  chmod 600 "$KEY_FILE"

  # 6. Bundle = key + folder/cloud metadata, written under the schema participant-side expects.
  CREATED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  EXPIRES_AT=$(date -u -v+40d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
               || date -u -d "+40 days" +%Y-%m-%dT%H:%M:%SZ)
  jq -n \
    --arg ws "$WORKSHOP" \
    --arg user "user-$II" \
    --arg created "$CREATED_AT" \
    --arg expires "$EXPIRES_AT" \
    --arg cloud "$CLOUD_ID" \
    --arg folder "$FOLDER_ID" \
    --arg zone "$ZONE" \
    --arg endpoint "$ENDPOINT" \
    --arg sa_id "$SA_ID" \
    --arg sa_name "$SA_NAME" \
    --slurpfile key "$KEY_FILE" \
    '{
      "$schema": "openclaw-workshop-bundle@1",
      workshop: $ws,
      user: $user,
      created_at: $created,
      expires_at: $expires,
      cloud_id: $cloud,
      folder_id: $folder,
      zone: $zone,
      endpoint: $endpoint,
      service_account: { id: $sa_id, name: $sa_name },
      key: $key[0]
     }' > "$BUNDLE"
  chmod 600 "$BUNDLE"

  # 7. Telegram-ready message (the organizer pastes this + attaches bundle-NN.json).
  cat > "$MESSAGE" <<EOF
**OpenClaw workshop · твой доступ к Яндекс Облаку**

Привет! Вот ключ для воркшопа (Plan B — если своего аккаунта в YC Kazakhstan нет).

Прикрепи файл \`bundle-${II}.json\` к этому сообщению и в код-агенте (Claude Code / Codex / Cursor) скажи:

> У меня есть workshop-ключ от организатора OpenClaw. Файл лежит здесь: \`./bundle-${II}.json\`. Поставь мне бота.

Дальше скилл \`install-openclaw-to-yc\` сделает всё сам — спросит только Telegram bot token и доступ к LLM (Anthropic / OpenRouter / Codex).

**Внутри ключа:**
- folder: \`${FOLDER_NAME}\`
- зона: \`${ZONE}\` (Yandex Cloud Kazakhstan, Караганда)
- права: compute.editor + vpc.user (только в твоей folder, чужие ресурсы не трогает)

**Срок жизни:** до \`${EXPIRES_AT}\` (потом я удалю folder вместе с ключом).
**Не делись ключом** — это полный доступ к твоей folder в моём облаке. Если файл утёк — напиши мне, я отзову.
EOF

  # 8. Append to manifest.
  TMP_MANIFEST=$(mktemp)
  jq --arg user "user-$II" \
     --arg folder "$FOLDER_ID" \
     --arg folder_name "$FOLDER_NAME" \
     --arg sa "$SA_ID" \
     --arg sa_name "$SA_NAME" \
     --arg key "$(jq -r '.id' "$KEY_FILE")" \
     --arg bundle "$(basename "$BUNDLE")" \
     '.participants += [{
        user: $user,
        folder_id: $folder,
        folder_name: $folder_name,
        service_account_id: $sa,
        service_account_name: $sa_name,
        key_id: $key,
        bundle_file: $bundle
      }]' "$MANIFEST" > "$TMP_MANIFEST"
  mv "$TMP_MANIFEST" "$MANIFEST"

  ok "[$II] $FOLDER_NAME ready → $BUNDLE"
  OK_COUNT=$((OK_COUNT+1))
done

log ""
log "${C_OK}provisioning complete${C_END}"
log "  ok      : $OK_COUNT"
log "  skipped : $SKIP_COUNT  (already provisioned)"
log "  failed  : $FAIL_COUNT"
log ""
if (( FAIL_COUNT > 0 )); then
  log "Failed participants left .error.log files in $OUT_DIR/"
  log "Fix the underlying cause and re-run the same command — the script skips already-provisioned indices."
  exit 1
fi
