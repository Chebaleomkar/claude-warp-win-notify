# claude-warp-win-notify

**Fix desktop notifications for Claude Code's Warp plugin on Windows.**

The official [Warp Claude Code plugin](https://github.com/warpdotdev/claude-code-warp) sends notifications via OSC 777 escape sequences, which works on macOS/Linux but **silently fails on Windows** because Claude Code's hook runner captures all stdio pipes.

This fix bypasses the terminal entirely and sends **native Windows toast notifications** via PowerShell, branded with Warp's icon.

## The Problem

When Claude Code finishes a task, needs input, or requires permission — you get nothing on Windows. No toast, no sound, no notification. You have to keep checking the terminal.

**Root cause:** The plugin writes `\033]777;notify;...` to `/dev/tty`, which fails on Windows Git Bash. The stderr fallback is captured by Claude Code's hook runner. The escape sequence never reaches Warp's terminal emulator. ([Issue #48](https://github.com/warpdotdev/claude-code-warp/issues/48))

## The Fix

Native Windows toast notifications via `[Windows.UI.Notifications]` PowerShell API:

- **Zero dependencies** — uses built-in Windows 10/11 APIs
- **Branded as Warp** — shows Warp's icon and name in the notification
- **Deduplication** — one notification per event (no duplicates from multiple hooks)
- **Context-aware** — different styles for different events with project name

| Event | Notification |
|-------|-------------|
| Task completed | ✅ Task Completed — project-name |
| Input needed | ⏳ Input Needed — project-name |
| Permission required | 🔐 Permission Required — project-name |

## Install

### One-line install

```bash
curl -sSL https://raw.githubusercontent.com/Chebaleomkar/claude-warp-win-notify/main/install.sh | bash
```

### Manual install

```bash
git clone https://github.com/Chebaleomkar/claude-warp-win-notify.git
cd claude-warp-win-notify
bash install.sh
```

### Prerequisites

- [Warp terminal](https://www.warp.dev/) for Windows
- [Claude Code](https://claude.ai/claude-code) CLI
- [Warp plugin](https://github.com/warpdotdev/claude-code-warp) installed: `claude plugin marketplace add warpdotdev/claude-code-warp`
- PowerShell (included with Windows)
- [jq](https://jqlang.github.io/jq/) (optional, for rich notification content): `choco install jq`

## Uninstall

```bash
bash uninstall.sh
```

Or if you used the one-line install:

```bash
curl -sSL https://raw.githubusercontent.com/Chebaleomkar/claude-warp-win-notify/main/uninstall.sh | bash
```

This restores the original Warp plugin scripts from backups.

## How It Works

```
Claude Code event (stop/idle/permission)
    │
    ├── on-stop.sh / on-notification.sh / on-permission-request.sh
    │       │
    │       ├── warp-notify.sh (original — tries /dev/tty, fails on Windows)
    │       │
    │       └── win-notify.sh (new — Windows-only path)
    │               │
    │               ├── Deduplication via mkdir lock (8s window)
    │               ├── Extract event type + project name from hook JSON
    │               └── PowerShell → win-toast.ps1
    │                       │
    │                       ├── Register dev.warp.Warp as notification source
    │                       └── Windows.UI.Notifications.ToastNotification
    │
    └── Native Windows toast appears 🎉
```

## Files

| File | Purpose |
|------|---------|
| `scripts/win-toast.ps1` | PowerShell script that sends Windows toast notifications branded as Warp |
| `scripts/win-notify.sh` | Deduplication + event-type routing + context extraction |
| `scripts/warp-notify.sh` | Patched version with Windows fallback |
| `install.sh` | Patches the existing Warp plugin |
| `uninstall.sh` | Reverts to original plugin |

## Troubleshooting

**No notification appears:**
1. Check Windows Settings → System → Notifications → make sure notifications are enabled
2. Check Focus Assist / Do Not Disturb is off
3. Test manually: `powershell -ExecutionPolicy Bypass -File ~/.claude/plugins/cache/claude-code-warp/warp/2.0.0/scripts/win-toast.ps1 -Title "Test" -Body "Hello"`

**Multiple notifications per event:**
The deduplication uses a filesystem lock at `/tmp/warp-notify-lock`. If it's stuck, remove it: `rmdir /tmp/warp-notify-lock`

## Related

- [Issue #48 — Notifications not working on Windows](https://github.com/warpdotdev/claude-code-warp/issues/48)
- [Blog post — How I Fixed Windows Notifications for Claude Code's Warp Plugin](https://omkarchebale.vercel.app/blogs/how-i-fixed-windows-notifications-for-claude-code-s-warp-plugin)

## License

MIT — see [LICENSE](LICENSE)
