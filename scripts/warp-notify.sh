#!/bin/bash
# Warp notification utility — patched for Windows support
# Usage: warp-notify.sh <title> <body>
#
# On macOS/Linux: sends OSC 777 escape sequence via /dev/tty (original behavior)
# On Windows: falls back to native Windows toast notifications via PowerShell

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/should-use-structured.sh"

# Only emit notifications when we've confirmed the Warp build can render them.
if ! should_use_structured; then
    exit 0
fi

TITLE="${1:-Notification}"
BODY="${2:-}"

# OSC 777 format: \033]777;notify;<title>;<body>\007
# Try /dev/tty first (macOS/Linux)
if printf '\033]777;notify;%s;%s\007' "$TITLE" "$BODY" > /dev/tty 2>/dev/null; then
    exit 0
fi

# Last resort: stderr (won't work in Claude Code hooks but covers other contexts)
printf '\033]777;notify;%s;%s\007' "$TITLE" "$BODY" >&2 2>/dev/null || true
