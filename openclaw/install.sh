#!/bin/bash
# AI Cofounder — OpenClaw installer
# Installs all 48 skills + bootstrap files + memory system to your OpenClaw workspace

set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Installing AI Cofounder to $WORKSPACE"
echo ""

# Create workspace if needed
mkdir -p "$WORKSPACE/skills"

# Copy bootstrap files (SOUL.md, AGENTS.md, etc.)
cp -r "$SCRIPT_DIR/workspace/"* "$WORKSPACE/"

# Copy all 48 skills
cp -r "$REPO_ROOT/skills/"* "$WORKSPACE/skills/"

# Ensure memory directories exist
mkdir -p "$WORKSPACE/memory/weekly"

# Initialize state files if they don't exist
if [ ! -f "$WORKSPACE/memory/hypotheses.json" ]; then
  echo '{"hypotheses": []}' > "$WORKSPACE/memory/hypotheses.json"
fi

if [ ! -f "$WORKSPACE/memory/heartbeat-state.json" ]; then
  echo '{"today": "", "messagesCount": 0, "lastMessageAt": null, "lastMessageType": null, "lastRecapDate": null}' > "$WORKSPACE/memory/heartbeat-state.json"
fi

SKILL_COUNT=$(ls -d "$REPO_ROOT/skills/"*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')

echo "Done! $SKILL_COUNT skills + bootstrap files installed."
echo ""
echo "Next steps:"
echo "  1. Edit $WORKSPACE/IDENTITY.md  — name your agent"
echo "  2. Edit $WORKSPACE/USER.md      — tell it about yourself"
echo "  3. Edit $WORKSPACE/MEMORY.md    — fill in your company context"
echo "  4. Send /new in your chat to start a new session"
echo ""
echo "See agents/openclaw/CUSTOMIZATION.md for detailed instructions."
