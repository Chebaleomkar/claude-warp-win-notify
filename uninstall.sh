#!/bin/bash
# claude-warp-win-notify uninstaller
# Reverts the Warp plugin to its original state
#
# Usage: bash uninstall.sh

set -e

echo "🔄 claude-warp-win-notify — Uninstalling Windows notification fix"
echo ""

PLUGIN_BASE="$HOME/.claude/plugins/cache/claude-code-warp/warp"
if [ ! -d "$PLUGIN_BASE" ]; then
    echo "❌ Warp plugin not found. Nothing to uninstall."
    exit 0
fi

PLUGIN_VERSION=$(ls -1 "$PLUGIN_BASE" | sort -V | tail -1)
SCRIPTS_DIR="$PLUGIN_BASE/$PLUGIN_VERSION/scripts"

# Restore backups
for f in warp-notify.sh on-stop.sh on-notification.sh on-permission-request.sh; do
    if [ -f "$SCRIPTS_DIR/$f.bak" ]; then
        mv "$SCRIPTS_DIR/$f.bak" "$SCRIPTS_DIR/$f"
        echo "  ✅ Restored $f"
    fi
done

# Remove added files
for f in win-toast.ps1 win-notify.sh; do
    if [ -f "$SCRIPTS_DIR/$f" ]; then
        rm "$SCRIPTS_DIR/$f"
        echo "  🗑️  Removed $f"
    fi
done

echo ""
echo "✅ Uninstall complete. Original Warp plugin restored."
