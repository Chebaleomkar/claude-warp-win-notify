#!/bin/bash
# claude-warp-win-notify installer
# Patches the Warp Claude Code plugin to support Windows notifications
#
# Usage: bash install.sh
# Or:    curl -sSL https://raw.githubusercontent.com/Chebaleomkar/claude-warp-win-notify/main/install.sh | bash

set -e

echo "🔧 claude-warp-win-notify — Windows notification fix for Warp + Claude Code"
echo ""

# --- Locate the Warp plugin ---
PLUGIN_BASE="$HOME/.claude/plugins/cache/claude-code-warp/warp"
if [ ! -d "$PLUGIN_BASE" ]; then
    echo "❌ Warp plugin not found at $PLUGIN_BASE"
    echo "   Install the Warp plugin first: claude plugin marketplace add warpdotdev/claude-code-warp"
    exit 1
fi

# Find the latest version
PLUGIN_VERSION=$(ls -1 "$PLUGIN_BASE" | sort -V | tail -1)
SCRIPTS_DIR="$PLUGIN_BASE/$PLUGIN_VERSION/scripts"

if [ ! -d "$SCRIPTS_DIR" ]; then
    echo "❌ Plugin scripts directory not found: $SCRIPTS_DIR"
    exit 1
fi

echo "📁 Found Warp plugin v$PLUGIN_VERSION at: $SCRIPTS_DIR"

# --- Check prerequisites ---
if ! command -v powershell &>/dev/null; then
    echo "❌ PowerShell not found. This fix requires PowerShell (included with Windows)."
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "⚠️  jq not found. Install it for rich notification content:"
    echo "   choco install jq  OR  winget install jqlang.jq"
    echo "   Continuing without jq (notifications will have basic text)..."
fi

# --- Backup originals ---
echo "📦 Backing up original scripts..."
for f in warp-notify.sh on-stop.sh on-notification.sh on-permission-request.sh; do
    if [ -f "$SCRIPTS_DIR/$f" ] && [ ! -f "$SCRIPTS_DIR/$f.bak" ]; then
        cp "$SCRIPTS_DIR/$f" "$SCRIPTS_DIR/$f.bak"
    fi
done

# --- Get the installer's script directory ---
INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If running from curl pipe, download scripts from GitHub
if [ ! -f "$INSTALLER_DIR/scripts/win-toast.ps1" ]; then
    echo "📥 Downloading scripts from GitHub..."
    REPO_URL="https://raw.githubusercontent.com/Chebaleomkar/claude-warp-win-notify/main"
    INSTALLER_DIR="/tmp/claude-warp-win-notify"
    mkdir -p "$INSTALLER_DIR/scripts"
    curl -sSL "$REPO_URL/scripts/win-toast.ps1" -o "$INSTALLER_DIR/scripts/win-toast.ps1"
    curl -sSL "$REPO_URL/scripts/win-notify.sh" -o "$INSTALLER_DIR/scripts/win-notify.sh"
    curl -sSL "$REPO_URL/scripts/warp-notify.sh" -o "$INSTALLER_DIR/scripts/warp-notify.sh"
fi

# --- Copy new scripts ---
echo "📋 Installing Windows notification scripts..."
cp "$INSTALLER_DIR/scripts/win-toast.ps1" "$SCRIPTS_DIR/win-toast.ps1"
cp "$INSTALLER_DIR/scripts/win-notify.sh" "$SCRIPTS_DIR/win-notify.sh"
cp "$INSTALLER_DIR/scripts/warp-notify.sh" "$SCRIPTS_DIR/warp-notify.sh"
chmod +x "$SCRIPTS_DIR/win-notify.sh" "$SCRIPTS_DIR/warp-notify.sh"

# --- Patch hook scripts to call win-notify.sh ---
echo "🔗 Patching hook scripts..."

patch_hook() {
    local file="$1"
    local event_type="$2"
    local call_line='"$SCRIPT_DIR/win-notify.sh"'

    if ! grep -q "win-notify.sh" "$file" 2>/dev/null; then
        # Add win-notify.sh call after the warp-notify.sh call
        if [ "$event_type" = "idle_prompt" ]; then
            sed -i '/warp-notify.sh.*warp:\/\/cli-agent/a\
"$SCRIPT_DIR/win-notify.sh" "$NOTIF_TYPE" "$INPUT"' "$file"
        else
            sed -i '/warp-notify.sh.*warp:\/\/cli-agent/a\
"$SCRIPT_DIR/win-notify.sh" "'"$event_type"'" "$INPUT"' "$file"
        fi
        echo "  ✅ Patched $file"
    else
        echo "  ⏭️  $file already patched"
    fi
}

patch_hook "$SCRIPTS_DIR/on-stop.sh" "stop"
patch_hook "$SCRIPTS_DIR/on-notification.sh" "idle_prompt"
patch_hook "$SCRIPTS_DIR/on-permission-request.sh" "permission_request"

# --- Test ---
echo ""
echo "🧪 Sending test notification..."
powershell -ExecutionPolicy Bypass -NoProfile -File "$SCRIPTS_DIR/win-toast.ps1" \
    -Title "✅ Installation Complete" \
    -Body "claude-warp-win-notify is ready!" &>/dev/null &

echo ""
echo "✅ Installation complete!"
echo ""
echo "You should see a test notification. If not, check:"
echo "  1. Windows notification settings (Settings → System → Notifications)"
echo "  2. Focus Assist / Do Not Disturb is off"
echo ""
echo "Notifications will now appear when Claude Code:"
echo "  ✅ Completes a task"
echo "  ⏳ Waits for your input"
echo "  🔐 Needs permission to run a tool"
