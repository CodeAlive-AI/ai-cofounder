#!/usr/bin/env bash
#
# openclaw-user-onboarding / upload-user-md.sh
# Atomically replaces USER.md on the bot's VM and resets the active Telegram
# session so the next message lands in a fresh session with the new profile.
#
# Usage:
#   bash upload-user-md.sh \
#     --ip 84.x.x.x \
#     --user-md /local/path/USER.md \
#     [--chat-id 123456] \
#     [--agent main|routinet] \
#     [--ssh-user openclaw]

set -euo pipefail

IP=""
USER_MD=""
CHAT_ID=""
AGENT="main"
SSH_USER="openclaw"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ip)        IP="$2";        shift 2 ;;
    --user-md)   USER_MD="$2";   shift 2 ;;
    --chat-id)   CHAT_ID="$2";   shift 2 ;;
    --agent)     AGENT="$2";     shift 2 ;;
    --ssh-user)  SSH_USER="$2";  shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -z "$IP" || -z "$USER_MD" ]] && {
  echo "Required: --ip <vm_ip> --user-md <local_path_to_USER.md>" >&2
  exit 2
}
[[ -f "$USER_MD" ]] || { echo "USER.md file not found: $USER_MD" >&2; exit 2; }
[[ -s "$USER_MD" ]] || { echo "USER.md is empty — refusing to upload" >&2; exit 2; }

case "$AGENT" in
  main)     WORKSPACE="/home/$SSH_USER/.openclaw/workspace" ;;
  routinet) WORKSPACE="/home/$SSH_USER/.openclaw/workspace-routinet" ;;
  *) echo "Unknown agent: $AGENT (expected main or routinet)" >&2; exit 2 ;;
esac

REMOTE_TMP="/tmp/openclaw-user-md.$$.md"

if [[ -t 1 ]]; then
  C_OK=$'\033[32m'; C_END=$'\033[0m'
else
  C_OK=""; C_END=""
fi

# 1. SSH ping — fail fast if the VM is unreachable.
ssh -o ConnectTimeout=5 -o BatchMode=yes "$SSH_USER@$IP" true \
  || { echo "SSH to $SSH_USER@$IP failed — onboarding upload aborted" >&2; exit 3; }

# 2. Verify workspace exists.
ssh "$SSH_USER@$IP" "test -d '$WORKSPACE'" \
  || { echo "Workspace missing on VM: $WORKSPACE" >&2; exit 4; }

# 3. Upload to a temp file, then atomic mv inside the workspace.
scp -o StrictHostKeyChecking=accept-new "$USER_MD" "$SSH_USER@$IP:$REMOTE_TMP" >/dev/null

ssh "$SSH_USER@$IP" "
  set -e
  mv '$REMOTE_TMP' '$WORKSPACE/USER.md'
  chown $SSH_USER:$SSH_USER '$WORKSPACE/USER.md'
  chmod 600 '$WORKSPACE/USER.md'
"

echo "${C_OK}✓${C_END} USER.md written to $WORKSPACE/USER.md on $IP"

# 4. Reset the Telegram session (best effort — never block on this).
if [[ -n "$CHAT_ID" ]]; then
  if ssh "$SSH_USER@$IP" "command -v openclaw >/dev/null && openclaw sessions reset --channel telegram --to '$CHAT_ID' 2>/dev/null"; then
    echo "${C_OK}✓${C_END} Telegram session reset for chat_id=$CHAT_ID"
  else
    # Older OpenClaw without `sessions reset` — full gateway restart is heavier
    # but does the job. Don't fail if neither path works.
    if ssh "$SSH_USER@$IP" "systemctl --user restart openclaw-gateway 2>/dev/null"; then
      echo "${C_OK}✓${C_END} Gateway restarted (session reset CLI unavailable)"
      sleep 10
    else
      echo "! Session reset failed — user should send /new in Telegram to pick up the new USER.md" >&2
    fi
  fi
fi

exit 0
