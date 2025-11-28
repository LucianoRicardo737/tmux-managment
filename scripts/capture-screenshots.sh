#!/usr/bin/env bash
#
# Script para capturar screenshots de tmux-session-switcher
# Genera archivos de texto que representan cada pantalla
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCREENSHOTS_DIR="$PROJECT_DIR/screenshots"

mkdir -p "$SCREENSHOTS_DIR"

echo "Generando capturas de pantalla..."

# 1. Session Manager (Alt+m)
cat > "$SCREENSHOTS_DIR/session-manager.txt" << 'EOF'
╭─────────────────────────────────────────────────────────────╮
│                    tmux Session Manager                      │
╰─────────────────────────────────────────────────────────────╯

  [1] ● development ─────────────────────────── (3 windows)
      └─ windows >

  [2] ○ frontend ────────────────────────────── (2 windows)
      └─ windows >

  [3]   backend ─────────────────────────────── (4 windows)
      └─ windows >

  [4]   devops ──────────────────────────────── (1 window)
      └─ windows >

─────────────────────────────────────────────────────────────
  [n] New session    [r] Rename    [k] Kill session
  [d] Search dirs    [q] Quit      [1-9] Switch
─────────────────────────────────────────────────────────────

● = Current session   ○ = Attached elsewhere
EOF

# 2. Popup Switcher (Alt+a)
cat > "$SCREENSHOTS_DIR/popup-switcher.txt" << 'EOF'
╭─────────────────────────────────────────────────────────────╮
│                    tmux sessions                             │
╰─────────────────────────────────────────────────────────────╯

  [1] ● development ─────────────────────────── (3 windows)
  [2] ○ frontend ────────────────────────────── (2 windows)
  [3]   backend ─────────────────────────────── (4 windows)
  [4]   devops ──────────────────────────────── (1 window)

─────────────────────────────────────────────────────────────
  Press 1-9 to switch   D = Search dirs   Q = Quit
─────────────────────────────────────────────────────────────
EOF

# 3. FZF Selector (Alt+s)
cat > "$SCREENSHOTS_DIR/fzf-selector.txt" << 'EOF'
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ > development                                                           │
  │   frontend                                                              │
  │   backend                                                               │
  │   devops                                                                │
  │                                                                         │
  │  4/4 ─────────────────────────────────────────────────────────────────  │
  │                                                                         │
  ├─────────────────────────────────────────────────────────────────────────┤
  │  Preview: development                                                   │
  │  ─────────────────────────────────────────────────────────────────────  │
  │   1: editor* (2 panes) [nvim]                                          │
  │   2: server (1 pane) [npm run dev]                                     │
  │   3: tests (1 pane) [npm test]                                         │
  │                                                                         │
  │  ─────────────────────────────────────────────────────────────────────  │
  │  Ctrl+x: Delete session   Ctrl+r: Reload   Enter: Select               │
  └─────────────────────────────────────────────────────────────────────────┘
EOF

# 4. Directory Search (Alt+d)
cat > "$SCREENSHOTS_DIR/directory-search.txt" << 'EOF'
  ┌─────────────────────────────────────────────────────────────────────────┐
  │ > project                                                               │
  │                                                                         │
  │   [TMUX] development                                                    │
  │   [TMUX] frontend                                                       │
  │   ~/projects/my-app                                                     │
  │   ~/projects/api-server                                                 │
  │   ~/github/dotfiles                                                     │
  │   ~/work/client-portal                                                  │
  │                                                                         │
  │  8/24 ────────────────────────────────────────────────────────────────  │
  │                                                                         │
  ├─────────────────────────────────────────────────────────────────────────┤
  │  Select a directory to create a new tmux session                       │
  │  [TMUX] = Existing session (will switch to it)                         │
  └─────────────────────────────────────────────────────────────────────────┘
EOF

# 5. Window Submenu
cat > "$SCREENSHOTS_DIR/window-submenu.txt" << 'EOF'
╭─────────────────────────────────────────────────────────────╮
│              development: Windows                            │
╰─────────────────────────────────────────────────────────────╯

  [1] ● editor ──────────────────────────────── (2 panes)
  [2]   server ──────────────────────────────── (1 pane)
  [3]   tests ───────────────────────────────── (1 pane)

─────────────────────────────────────────────────────────────
  [n] New window   [h] HSplit   [v] VSplit
  [r] Rename       [k] Kill     [b] Back    [q] Quit
─────────────────────────────────────────────────────────────
EOF

# 6. Claude Notification Popup
cat > "$SCREENSHOTS_DIR/claude-notification.txt" << 'EOF'
╔════════════════════════════════════════════════════════════════════════╗
║                    Claude Code Notification                            ║
╚════════════════════════════════════════════════════════════════════════╝

Type: permission_prompt
Time: 14:32:45

Session: development
Window:  claude (#2)
Dir:     ~/projects/my-app

────────────────────────────────────────────────────────────────────────
Message:
Claude wants to execute: npm install lodash

Do you want to allow this action?
────────────────────────────────────────────────────────────────────────

Actions:
  [1] Go to session (switch to Claude's window)
  [2] View full details (JSON)
  [3] Mark as read & close
  [q] Close without marking as read

Select action (1-3, q): _
EOF

# 7. Notification Queue (Alt+x)
cat > "$SCREENSHOTS_DIR/notification-queue.txt" << 'EOF'
╔════════════════════════════════════════════════════════════════════════╗
║                    Claude Code Notifications                           ║
╚════════════════════════════════════════════════════════════════════════╝

  [1] ● 14:32:45 - permission_prompt - development
      "Claude wants to execute: npm install lodash"

  [2] ● 14:28:12 - Stop - backend
      "Task completed: Fixed authentication bug"

  [3] ○ 14:15:33 - idle_prompt - frontend (read)
      "Waiting for your input..."

  [4] ○ 13:45:00 - Stop - devops (read)
      "Deployment script finished"

────────────────────────────────────────────────────────────────────────
  ● = Unread   ○ = Read

  [1-9] Select notification   [c] Clear read   [C] Clear all   [q] Quit
────────────────────────────────────────────────────────────────────────
EOF

echo "✓ Capturas generadas en $SCREENSHOTS_DIR/"
ls -la "$SCREENSHOTS_DIR/"
