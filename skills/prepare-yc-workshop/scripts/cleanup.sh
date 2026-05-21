#!/usr/bin/env bash
#
# prepare-yc-workshop / cleanup.sh
# Deletes every YC resource created by provision.sh for the given workshop tag.
#
# Reads ./bundles/<workshop>/manifest.json and deletes each folder (which
# cascades to all resources inside: VMs, disks, networks, service accounts,
# keys). After deletion, archives the bundle directory to a .tar.gz WITHOUT
# the private keys, and removes the live directory.
#
# Usage:
#   bash cleanup.sh --workshop openclaw-kz-2026-05-30
#   bash cleanup.sh --workshop openclaw-kz-2026-05-30 --yes    # skip confirm

set -euo pipefail

WORKSHOP=""
ASSUME_YES=0
BUNDLES_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workshop)    WORKSHOP="$2"; shift 2 ;;
    --bundles-dir) BUNDLES_DIR="$2"; shift 2 ;;
    --yes|-y)      ASSUME_YES=1; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -z "$WORKSHOP" ]] && { echo "Required: --workshop NAME" >&2; exit 2; }
BUNDLES_DIR="${BUNDLES_DIR:-./bundles/$WORKSHOP}"

[[ -d "$BUNDLES_DIR" ]] || { echo "No bundles directory: $BUNDLES_DIR" >&2; exit 2; }
MANIFEST="$BUNDLES_DIR/manifest.json"
[[ -f "$MANIFEST" ]] || { echo "No manifest: $MANIFEST" >&2; exit 2; }
command -v yc >/dev/null || { echo "yc CLI not installed" >&2; exit 3; }
command -v jq >/dev/null || { echo "jq not installed" >&2; exit 3; }

if [[ -t 1 ]]; then
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_ERR=$'\033[31m'; C_END=$'\033[0m'
else
  C_OK=""; C_WARN=""; C_ERR=""; C_END=""
fi

PARTICIPANTS=$(jq -r '.participants | length' "$MANIFEST")
CLOUD_ID=$(jq -r '.cloud_id' "$MANIFEST")
echo "Workshop : $WORKSHOP"
echo "Cloud    : $CLOUD_ID"
echo "Folders  : $PARTICIPANTS"
echo ""
jq -r '.participants[] | "  \(.user): folder=\(.folder_id) (\(.folder_name))"' "$MANIFEST"
echo ""

if (( ! ASSUME_YES )); then
  read -rp "Удалить эти ${PARTICIPANTS} folder'ов вместе со всем содержимым? Это необратимо. [y/N] " ans
  case "$ans" in
    y|Y|yes|YES|да|ДА) ;;
    *) echo "Cancelled."; exit 0 ;;
  esac
fi

OK_COUNT=0
GONE_COUNT=0
FAIL_COUNT=0

# Iterate participants, delete each folder asynchronously.
while read -r line; do
  USER=$(jq -r '.user' <<<"$line")
  FID=$(jq -r '.folder_id' <<<"$line")
  FNAME=$(jq -r '.folder_name' <<<"$line")

  if ! yc resource-manager folder get "$FID" --format json >/dev/null 2>&1; then
    echo "${C_WARN}-${C_END} $USER: $FNAME ($FID) — already gone"
    GONE_COUNT=$((GONE_COUNT+1))
    continue
  fi

  if yc resource-manager folder delete "$FID" --delete-content --async >/dev/null 2>&1; then
    echo "${C_OK}✓${C_END} $USER: $FNAME ($FID) — delete queued"
    OK_COUNT=$((OK_COUNT+1))
  else
    echo "${C_ERR}✗${C_END} $USER: $FNAME ($FID) — delete failed"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi
done < <(jq -c '.participants[]' "$MANIFEST")

echo ""
echo "deleted (queued): $OK_COUNT"
echo "already gone   : $GONE_COUNT"
echo "failed         : $FAIL_COUNT"

# Archive the bundles directory WITHOUT private keys.
TS=$(date -u +%Y%m%dT%H%M%SZ)
ARCHIVE="bundles/${WORKSHOP}.archived-${TS}.tar.gz"
mkdir -p "bundles"

echo ""
echo "Archiving (private keys stripped) → $ARCHIVE"
tar -czf "$ARCHIVE" \
    --exclude='*/keys' \
    --exclude='bundle-*.json' \
    -C "$(dirname "$BUNDLES_DIR")" \
    "$(basename "$BUNDLES_DIR")"

# Wipe the live bundles directory.
rm -rf "$BUNDLES_DIR"

echo ""
echo "${C_OK}cleanup done${C_END}"
echo "Archive    : $ARCHIVE  (manifest + messages, no keys)"
echo "Live dir   : removed"

if (( FAIL_COUNT > 0 )); then
  echo ""
  echo "${C_WARN}!${C_END} Some deletes failed. Re-run the same command to retry — already-gone folders are skipped."
  exit 1
fi
