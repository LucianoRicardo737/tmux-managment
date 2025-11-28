# tmux Session Switcher

<p align="center">
  <img src="https://img.shields.io/badge/version-2.1.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/tmux-3.2+-orange.svg" alt="tmux">
  <img src="https://img.shields.io/badge/bash-4.0+-yellow.svg" alt="Bash">
</p>

<p align="center">
  <strong>Alt+Tab style session switching for tmux with hierarchical navigation, session persistence, and Claude Code integration.</strong>
</p>

```
╭─────────────────────────────────────────────────────────────╮
│                    tmux Session Manager                      │
╰─────────────────────────────────────────────────────────────╯

  [1] ● development ─────────────────────────── (3 windows)
      └─ windows >

  [2] ○ frontend ────────────────────────────── (2 windows)
      └─ windows >

  [3]   backend ─────────────────────────────── (4 windows)
      └─ windows >

─────────────────────────────────────────────────────────────
  [n] New session    [r] Rename    [k] Kill session
  [d] Search dirs    [q] Quit      [1-9] Switch
─────────────────────────────────────────────────────────────
```

---

## Features

- **Session Manager** - Hierarchical menu with windows navigation
- **Popup Switcher** - Quick 1-9 selection overlay
- **FZF Integration** - Fuzzy search with live preview
- **Directory Search** - Find projects and create sessions
- **Session Persistence** - Auto-save/restore with tmux-resurrect
- **Hydration Scripts** - Auto-setup windows per project
- **Claude Code Integration** - Notifications when AI needs attention

---

## Quick Install

### One Command Install

```bash
# Clone and install everything (base + persistence + Claude hooks)
git clone https://github.com/yourusername/tmux-session-switcher.git
cd tmux-session-switcher
./install.sh --full
```

### Interactive Install

```bash
./install.sh
```

Shows a menu to choose what to install:
1. **Full Install** - Everything included
2. **Basic Install** - Core functionality only
3. **Add Persistence** - tmux-resurrect/continuum
4. **Add Claude Hooks** - Claude Code notifications

### Requirements

- **tmux** >= 3.2 (for popup support)
- **bash** >= 4.0
- **git** (for tmux-resurrect)
- **fzf** (optional, for fuzzy search)
- **python3** (optional, for Claude hooks)

```bash
# Ubuntu/Debian
sudo apt install tmux git fzf

# macOS
brew install tmux git fzf

# Arch
sudo pacman -S tmux git fzf
```

---

## Keybindings Reference

### Complete Keybindings Table

| Shortcut | Mode | Action | Description |
|----------|------|--------|-------------|
| `Alt+m` | Manager | Session Manager | Hierarchical menu with windows |
| `Alt+a` | Popup | Popup Switcher | Quick 1-9 session selection |
| `Alt+s` | FZF | FZF Selector | Fuzzy search with preview |
| `Alt+d` | Search | Directory Search | Find projects, create sessions |
| `Alt+n` | Cycle | Next Session | Switch to next session |
| `Alt+p` | Cycle | Previous Session | Switch to previous session |
| `Alt+x` | Claude | Notification Queue | View Claude notifications |
| `Prefix+Space` | Popup | Popup (Alt) | Alternative if Alt doesn't work |
| `Prefix+a` | Manager | Manager (Alt) | Alternative if Alt doesn't work |
| `Prefix+Ctrl+s` | Persist | Save Session | Manual session save |
| `Prefix+Ctrl+r` | Persist | Restore Session | Manual session restore |

### Controls Inside Menus

**Session Manager (Alt+m):**
| Key | Action |
|-----|--------|
| `1-9` | Switch to session |
| `n` | New session |
| `r` | Rename session |
| `k` | Kill session |
| `d` | Search directories |
| `Enter` on "windows >" | Open windows submenu |
| `q` / `Esc` | Close |

**Window Submenu:**
| Key | Action |
|-----|--------|
| `1-9` | Switch to window |
| `n` | New window |
| `h` | Horizontal split |
| `v` | Vertical split |
| `r` | Rename window |
| `k` | Kill window |
| `b` | Back to sessions |
| `q` | Close |

**Popup Switcher (Alt+a):**
| Key | Action |
|-----|--------|
| `1-9` | Switch to session |
| `D` | Open directory search |
| `Q` / `Esc` | Close |

**FZF Selector (Alt+s):**
| Key | Action |
|-----|--------|
| `↑/↓` | Navigate |
| `Enter` | Select session |
| `Ctrl+x` | Delete session |
| `Ctrl+r` | Reload list |
| `Esc` | Cancel |

---

## Customizing Keybindings

### Understanding tmux Keybinding Syntax

```bash
# Format: bind-key [flags] <key> <command>

# -n = No prefix required (direct key)
bind-key -n M-a run-shell "command"     # Alt+a (no prefix)

# Without -n = Requires prefix (Ctrl+b by default)
bind-key a run-shell "command"          # Prefix + a
bind-key Space run-shell "command"      # Prefix + Space

# Key modifiers:
# M- = Alt/Meta
# C- = Ctrl
# S- = Shift
```

### How to Customize

1. **Edit your tmux config:**
   ```bash
   nano ~/.tmux.conf
   ```

2. **Find the Session Switcher section** (added by installer)

3. **Change keybindings as needed:**

   ```bash
   # Example: Change Alt+m to Alt+Tab (if your terminal supports it)
   bind-key -n M-Tab run-shell "~/.local/bin/tmux-session-switcher.sh manager"

   # Example: Use F-keys instead of Alt
   bind-key -n F1 run-shell "~/.local/bin/tmux-session-switcher.sh manager"
   bind-key -n F2 run-shell "~/.local/bin/tmux-session-switcher.sh popup"
   bind-key -n F3 run-shell "~/.local/bin/tmux-session-switcher.sh fzf"

   # Example: Use Prefix + key if Alt doesn't work
   bind-key m run-shell "~/.local/bin/tmux-session-switcher.sh manager"
   bind-key s run-shell "~/.local/bin/tmux-session-switcher.sh fzf"
   ```

4. **Reload tmux config:**
   ```bash
   tmux source-file ~/.tmux.conf
   ```

### Common Customization Examples

```bash
# ═══════════════════════════════════════════════════════════════════
# CUSTOM KEYBINDINGS EXAMPLES
# ═══════════════════════════════════════════════════════════════════

# Using Ctrl instead of Alt
bind-key -n C-Space run-shell "~/.local/bin/tmux-session-switcher.sh popup"

# Using double-tap Prefix
bind-key b run-shell "~/.local/bin/tmux-session-switcher.sh manager"

# Vim-style navigation
bind-key -n M-j run-shell "~/.local/bin/tmux-session-switcher.sh next"
bind-key -n M-k run-shell "~/.local/bin/tmux-session-switcher.sh prev"

# Quick commands with numbers
bind-key -n M-1 run-shell "~/.local/bin/tmux-session-switcher.sh -s 0"
bind-key -n M-2 run-shell "~/.local/bin/tmux-session-switcher.sh -s 1"
```

---

## Session Persistence

### Automatic Save/Restore (Recommended)

The installer can set up **tmux-resurrect** and **tmux-continuum** for automatic session persistence:

```bash
./install.sh --resurrect
```

**What it does:**
- Saves all sessions, windows, panes, and their contents
- Auto-saves every 15 minutes
- Auto-restores on tmux start
- Preserves running programs (vim, htop, etc.)

**Manual save/restore:**
- `Prefix + Ctrl+s` - Save current state
- `Prefix + Ctrl+r` - Restore last saved state

### Hydration Scripts (Project-Specific)

Create `.tmux-sessionizer` in your project directory:

```bash
# ~/projects/my-app/.tmux-sessionizer
#!/bin/bash

# Rename first window
tmux rename-window "editor"
tmux send-keys "nvim ." C-m

# Create server window
tmux new-window -n "server"
tmux send-keys "npm run dev" C-m

# Create test window
tmux new-window -n "tests"
tmux send-keys "npm test -- --watch" C-m

# Go back to editor
tmux select-window -t 1
```

Make it executable:
```bash
chmod +x ~/projects/my-app/.tmux-sessionizer
```

When you create a session from this directory (via Alt+d), the script runs automatically.

### Global Hydration Script

Create `~/.tmux-sessionizer` for default setup in all new sessions:

```bash
# ~/.tmux-sessionizer
#!/bin/bash
tmux rename-window "main"
tmux send-keys "ls -la" C-m
```

---

## Screenshots

### Session Manager (Alt+m)

```
╭─────────────────────────────────────────────────────────────╮
│                    tmux Session Manager                      │
╰─────────────────────────────────────────────────────────────╯

  [1] ● development ─────────────────────────── (3 windows)
      └─ windows >

  [2] ○ frontend ────────────────────────────── (2 windows)
      └─ windows >

  [3]   backend ─────────────────────────────── (4 windows)
      └─ windows >

─────────────────────────────────────────────────────────────
  [n] New session    [r] Rename    [k] Kill session
  [d] Search dirs    [q] Quit      [1-9] Switch
─────────────────────────────────────────────────────────────

● = Current session   ○ = Attached elsewhere
```

### Popup Switcher (Alt+a)

```
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
```

### FZF Selector (Alt+s)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ > development                                                           │
│   frontend                                                              │
│   backend                                                               │
│   devops                                                                │
│                                                                         │
│  4/4 ─────────────────────────────────────────────────────────────────  │
├─────────────────────────────────────────────────────────────────────────┤
│  Preview: development                                                   │
│   1: editor* (2 panes) [nvim]                                          │
│   2: server (1 pane) [npm run dev]                                     │
│   3: tests (1 pane) [npm test]                                         │
│  ─────────────────────────────────────────────────────────────────────  │
│  Ctrl+x: Delete session   Ctrl+r: Reload   Enter: Select               │
└─────────────────────────────────────────────────────────────────────────┘
```

### Directory Search (Alt+d)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ > project                                                               │
│                                                                         │
│   [TMUX] development                                                    │
│   [TMUX] frontend                                                       │
│   ~/projects/my-app                                                     │
│   ~/projects/api-server                                                 │
│   ~/github/dotfiles                                                     │
│                                                                         │
│  8/24 ────────────────────────────────────────────────────────────────  │
├─────────────────────────────────────────────────────────────────────────┤
│  Select a directory to create a new tmux session                       │
│  [TMUX] = Existing session (will switch to it)                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Claude Code Integration

Real-time notifications when [Claude Code](https://claude.ai/code) needs your attention.

### Installation

```bash
./install.sh --claude
```

Or add to existing installation:
```bash
./install.sh
# Select option [4] Add Claude Code Hooks
```

### How It Works

When working with Claude Code in one tmux session while doing other work:

1. **Claude needs permission** → Popup appears + sound alert
2. **Claude is waiting** → Popup appears + sound alert
3. **Task completed** → Popup appears + sound alert

You can:
- Press `1` to jump directly to Claude's session
- Press `2` to view full notification details
- Press `3` to mark as read and close
- Press `Alt+x` anytime to view notification queue

### Notification Popup

```
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
────────────────────────────────────────────────────────────────────────

Actions:
  [1] Go to session (switch to Claude's window)
  [2] View full details (JSON)
  [3] Mark as read & close
  [q] Close without marking as read

Select action (1-3, q): _
```

### Notification Queue (Alt+x)

```
╔════════════════════════════════════════════════════════════════════════╗
║                    Claude Code Notifications                           ║
╚════════════════════════════════════════════════════════════════════════╝

  [1] ● 14:32:45 - permission_prompt - development
      "Claude wants to execute: npm install lodash"

  [2] ● 14:28:12 - Stop - backend
      "Task completed: Fixed authentication bug"

  [3] ○ 14:15:33 - idle_prompt - frontend (read)
      "Waiting for your input..."

────────────────────────────────────────────────────────────────────────
  ● = Unread   ○ = Read

  [1-9] Select notification   [c] Clear read   [C] Clear all   [q] Quit
────────────────────────────────────────────────────────────────────────
```

### Notification Types

| Type | Trigger | Description |
|------|---------|-------------|
| `permission_prompt` | Claude needs approval | Command execution permission |
| `idle_prompt` | Claude waiting | Waiting for user input |
| `elicitation_dialog` | MCP tool input | Tool requires information |
| `error` | Error occurred | Something went wrong |
| `Stop` | Task finished | Work completed |

---

## Configuration

### Main Config File

`~/.config/tmux-sessionizer/tmux-sessionizer.conf`:

```bash
# ═══════════════════════════════════════════════════════════════════
# SEARCH PATHS - Where to look for projects
# ═══════════════════════════════════════════════════════════════════

TS_SEARCH_PATHS=(
    ~/
    ~/projects
    ~/work
    ~/github
)

# Additional paths with custom depth (path:depth)
TS_EXTRA_SEARCH_PATHS=(
    ~/github:3        # Search 3 levels deep
    ~/.config:2       # Search 2 levels deep
)

# Default search depth
TS_MAX_DEPTH=2

# ═══════════════════════════════════════════════════════════════════
# SESSION COMMANDS - Quick commands via -s flag
# ═══════════════════════════════════════════════════════════════════

TS_SESSION_COMMANDS=(
    "htop"                    # 0: System monitor
    "nvim ~/notes.md"         # 1: Quick notes
    "lazygit"                 # 2: Git UI
    "docker ps -a"            # 3: Docker status
    "python3"                 # 4: Python REPL
)

# ═══════════════════════════════════════════════════════════════════
# LOGGING
# ═══════════════════════════════════════════════════════════════════

TS_LOG="file"  # "file", "echo", or empty
TS_LOG_FILE="$HOME/.local/share/tmux-sessionizer/tmux-sessionizer.logs"
```

---

## CLI Reference

```bash
tmux-session-switcher.sh [MODE] [OPTIONS]

MODES:
  manager         Session manager with hierarchical windows
  popup           Quick popup switcher (default)
  fzf             FZF selector with preview
  menu            Native tmux menu
  search          Directory search
  next            Switch to next session
  prev            Switch to previous session
  <path>          Create session from directory path

OPTIONS:
  -s, --session-cmd <idx>    Execute session command by index
  --vsplit                   Run command in vertical split
  --hsplit                   Run command in horizontal split
  -v, --version              Show version
  -h, --help                 Show help

EXAMPLES:
  tmux-session-switcher.sh manager
  tmux-session-switcher.sh ~/projects/my-app
  tmux-session-switcher.sh -s 0 --vsplit
```

---

## Troubleshooting

### Popup doesn't appear

```bash
# Check tmux version (needs 3.2+)
tmux -V

# If older, popups fall back to FZF mode automatically
```

### Alt key not working

Some terminals capture Alt. Use prefix-based bindings:

```bash
# Edit ~/.tmux.conf and use:
bind-key a run-shell "~/.local/bin/tmux-session-switcher.sh popup"
bind-key Space run-shell "~/.local/bin/tmux-session-switcher.sh popup"

# Then use: Ctrl+b a  or  Ctrl+b Space
```

### Claude notifications not working

```bash
# Check hook logs
cat ~/.cache/claude-notifications/hook-debug.log

# Verify hook configuration
cat ~/.claude/settings.local.json

# Test manually
echo '{"hook_event_name": "Stop", "cwd": "'$PWD'"}' | \
  python3 ~/.claude/hooks/tmux-notification.py
```

### Session persistence not working

```bash
# Install plugins (inside tmux)
# Press: Prefix + I

# Check TPM is installed
ls ~/.tmux/plugins/tpm

# Manual save/restore
# Prefix + Ctrl+s = Save
# Prefix + Ctrl+r = Restore
```

### No sound on notifications

Enable terminal bell in your terminal:

- **GNOME Terminal**: Preferences → Profile → Text → Terminal bell
- **Konsole**: Settings → Profile → Terminal Features → System bell
- **iTerm2**: Preferences → Profiles → Terminal → Bell

Test: `printf '\a'`

---

## Examples

See the `examples/` directory:

```bash
# Run basic demo (creates test sessions)
./examples/demo.sh

# Run advanced demo with hydration
./examples/demo-advanced.sh

# Clean up demo sessions
./examples/demo-advanced.sh --clean
```

---

## File Structure

```
~/.local/bin/
└── tmux-session-switcher.sh     # Main script

~/.config/tmux-sessionizer/
└── tmux-sessionizer.conf        # Configuration

~/.tmux/plugins/
├── tpm/                         # Plugin manager
├── tmux-resurrect/              # Session persistence
└── tmux-continuum/              # Auto-save

~/.claude/hooks/                 # Claude Code integration
├── tmux-notification.py
├── claude-popup.sh
└── notification-queue.sh

~/.cache/
├── tmux-sessionizer/            # Session cache
└── claude-notifications/        # Notification cache
```

---

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

## Credits

- Inspired by [tmux-sessionizer](https://github.com/ThePrimeagen/.dotfiles) by ThePrimeagen
- Session persistence via [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)
- Fuzzy finding via [fzf](https://github.com/junegunn/fzf)
- AI integration for [Anthropic's Claude](https://claude.ai)

---

<p align="center">
  Made with love for the tmux community
</p>
