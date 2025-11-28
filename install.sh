#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════
# tmux Session Switcher - Universal Installer
# ═══════════════════════════════════════════════════════════════════════════
#
# Usage:
#   ./install.sh              Interactive menu
#   ./install.sh --full       Install everything (base + resurrect + claude)
#   ./install.sh --basic      Install base only (keybindings + script)
#   ./install.sh --resurrect  Add tmux-resurrect/continuum for persistence
#   ./install.sh --claude     Add Claude Code notification hooks
#   ./install.sh --uninstall  Remove installation
#
# ═══════════════════════════════════════════════════════════════════════════

set -e

# Colors
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"

# Installation paths
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-sessionizer"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-sessionizer"
LOG_DIR="$HOME/.local/share/tmux-sessionizer"
TPM_DIR="$HOME/.tmux/plugins/tpm"
CLAUDE_HOOKS_DIR="$HOME/.claude/hooks"

SCRIPT_NAME="tmux-session-switcher.sh"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"
CONFIG_FILE="$CONFIG_DIR/tmux-sessionizer.conf"
TMUX_CONF="$HOME/.tmux.conf"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ═══════════════════════════════════════════════════════════════════════════
# Helper Functions
# ═══════════════════════════════════════════════════════════════════════════

print_header() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║       tmux Session Switcher v2.1 - Installer                 ║"
    echo "║   Alt+Tab Style Session Management + Claude Integration      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

check_requirements() {
    local missing=()

    if ! command -v tmux &> /dev/null; then
        missing+=("tmux")
    fi

    if ! command -v git &> /dev/null; then
        missing+=("git (for tmux-resurrect)")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Missing requirements: ${missing[*]}${RESET}"
        echo ""
        echo "Install with:"
        echo "  Ubuntu/Debian: sudo apt install tmux git"
        echo "  Arch: sudo pacman -S tmux git"
        echo "  macOS: brew install tmux git"
        exit 1
    fi

    # Check tmux version
    TMUX_VERSION=$(tmux -V | cut -d' ' -f2 | tr -d 'a-zA-Z')
    TMUX_MAJOR=$(echo "$TMUX_VERSION" | cut -d'.' -f1)
    TMUX_MINOR=$(echo "$TMUX_VERSION" | cut -d'.' -f2)

    if [ "$TMUX_MAJOR" -lt 3 ] || ([ "$TMUX_MAJOR" -eq 3 ] && [ "$TMUX_MINOR" -lt 2 ]); then
        echo -e "${YELLOW}Warning: tmux $TMUX_VERSION detected. Version 3.2+ recommended for popup support.${RESET}"
        echo "Popup features will use FZF fallback on older versions."
    fi
}

backup_config() {
    if [ -f "$TMUX_CONF" ]; then
        BACKUP="$TMUX_CONF.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$TMUX_CONF" "$BACKUP"
        echo -e "${DIM}Backed up existing config to $BACKUP${RESET}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# Installation Functions
# ═══════════════════════════════════════════════════════════════════════════

install_base() {
    echo -e "\n${CYAN}${BOLD}[1/4] Installing base components...${RESET}"

    # Create directories
    mkdir -p "$INSTALL_DIR" "$CONFIG_DIR" "$CACHE_DIR" "$LOG_DIR"

    # Copy main script
    if [ -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
        cp "$SCRIPT_DIR/$SCRIPT_NAME" "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
        echo -e "${GREEN}  ✓ Script installed to $SCRIPT_PATH${RESET}"
    else
        echo -e "${RED}  ✗ Error: $SCRIPT_NAME not found${RESET}"
        exit 1
    fi

    # Copy config if not exists
    if [ ! -f "$CONFIG_FILE" ]; then
        if [ -f "$SCRIPT_DIR/examples/config.example" ]; then
            cp "$SCRIPT_DIR/examples/config.example" "$CONFIG_FILE"
            echo -e "${GREEN}  ✓ Config installed to $CONFIG_FILE${RESET}"
        fi
    else
        echo -e "${YELLOW}  ⚠ Config exists, skipping (your settings preserved)${RESET}"
    fi

    # Add to tmux.conf if not present
    if ! grep -q "tmux-session-switcher" "$TMUX_CONF" 2>/dev/null; then
        backup_config
        cat >> "$TMUX_CONF" << EOF

# ═══════════════════════════════════════════════════════════════════════════
# tmux Session Switcher v2.1
# Added on $(date)
# ═══════════════════════════════════════════════════════════════════════════

# Session Manager (hierarchical menu with windows)
bind-key -n M-m run-shell "$SCRIPT_PATH manager"

# Popup Switcher (quick 1-9 selection)
bind-key -n M-a run-shell "$SCRIPT_PATH popup"

# FZF Selector (fuzzy search with preview)
bind-key -n M-s run-shell "tmux neww $SCRIPT_PATH fzf"

# Directory Search (find projects)
bind-key -n M-d run-shell "$SCRIPT_PATH search"

# Cycle Sessions
bind-key -n M-n run-shell "$SCRIPT_PATH next"
bind-key -n M-p run-shell "$SCRIPT_PATH prev"

# Prefix alternatives (if Alt doesn't work)
bind-key Space run-shell "$SCRIPT_PATH popup"
bind-key a run-shell "$SCRIPT_PATH manager"
EOF
        echo -e "${GREEN}  ✓ Keybindings added to $TMUX_CONF${RESET}"
    else
        echo -e "${YELLOW}  ⚠ Keybindings exist in tmux.conf, skipping${RESET}"
    fi

    # Check PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo -e "${YELLOW}  ⚠ Add to your shell config:${RESET}"
        echo -e "${DIM}     export PATH=\"\$HOME/.local/bin:\$PATH\"${RESET}"
    fi

    # Check fzf
    if command -v fzf &> /dev/null; then
        echo -e "${GREEN}  ✓ fzf detected${RESET}"
    else
        echo -e "${YELLOW}  ⚠ fzf not found (optional, install for better experience)${RESET}"
    fi
}

install_resurrect() {
    echo -e "\n${CYAN}${BOLD}[2/4] Installing session persistence (tmux-resurrect)...${RESET}"

    # Install TPM if not present
    if [ ! -d "$TPM_DIR" ]; then
        echo -e "${DIM}  Installing TPM (Tmux Plugin Manager)...${RESET}"
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR" 2>/dev/null
        echo -e "${GREEN}  ✓ TPM installed${RESET}"
    else
        echo -e "${GREEN}  ✓ TPM already installed${RESET}"
    fi

    # Add plugins to tmux.conf if not present
    if ! grep -q "tmux-plugins/tmux-resurrect" "$TMUX_CONF" 2>/dev/null; then
        cat >> "$TMUX_CONF" << 'EOF'

# ═══════════════════════════════════════════════════════════════════════════
# Session Persistence (tmux-resurrect + tmux-continuum)
# ═══════════════════════════════════════════════════════════════════════════

# Plugin manager
set -g @plugin 'tmux-plugins/tpm'

# Session save/restore
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Resurrect settings
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-nvim 'session'

# Continuum settings (auto-save every 15 min, auto-restore on start)
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

# Keybindings for manual save/restore
# Prefix + Ctrl+s = Save
# Prefix + Ctrl+r = Restore

# Initialize TPM (keep this at the very end of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
EOF
        echo -e "${GREEN}  ✓ Persistence plugins added to tmux.conf${RESET}"
        echo -e "${YELLOW}  ⚠ Run 'Prefix + I' inside tmux to install plugins${RESET}"
    else
        echo -e "${YELLOW}  ⚠ Persistence plugins already configured${RESET}"
    fi

    echo ""
    echo -e "${CYAN}Session Persistence Keybindings:${RESET}"
    echo "  Prefix + Ctrl+s  = Save session"
    echo "  Prefix + Ctrl+r  = Restore session"
    echo "  Auto-save every 15 minutes"
    echo "  Auto-restore on tmux start"
}

install_claude() {
    echo -e "\n${CYAN}${BOLD}[3/4] Installing Claude Code hooks...${RESET}"

    # Check python3
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}  ✗ python3 required for Claude hooks${RESET}"
        echo "  Install with: sudo apt install python3"
        return 1
    fi

    # Create hooks directory
    mkdir -p "$CLAUDE_HOOKS_DIR"
    mkdir -p "$HOME/.cache/claude-notifications"

    # Copy hook files
    if [ -d "$SCRIPT_DIR/claude-hooks" ]; then
        cp "$SCRIPT_DIR/claude-hooks/tmux-notification.py" "$CLAUDE_HOOKS_DIR/"
        cp "$SCRIPT_DIR/claude-hooks/claude-popup.sh" "$CLAUDE_HOOKS_DIR/"
        cp "$SCRIPT_DIR/claude-hooks/notification-queue.sh" "$CLAUDE_HOOKS_DIR/"
        chmod +x "$CLAUDE_HOOKS_DIR"/*.sh
        echo -e "${GREEN}  ✓ Hook scripts installed to $CLAUDE_HOOKS_DIR${RESET}"
    else
        echo -e "${RED}  ✗ claude-hooks directory not found${RESET}"
        return 1
    fi

    # Add notification queue keybinding
    if ! grep -q "notification-queue" "$TMUX_CONF" 2>/dev/null; then
        cat >> "$TMUX_CONF" << 'EOF'

# ═══════════════════════════════════════════════════════════════════════════
# Claude Code Notification Integration
# ═══════════════════════════════════════════════════════════════════════════

# Alt+x - Notification Queue (view all Claude notifications)
bind-key -n M-x run-shell "tmux display-popup -E -w 85% -h 60% -T 'Claude Code Notifications' ~/.claude/hooks/notification-queue.sh"
EOF
        echo -e "${GREEN}  ✓ Notification keybinding added (Alt+x)${RESET}"
    fi

    # Create/update Claude settings
    CLAUDE_SETTINGS="$HOME/.claude/settings.local.json"
    if [ ! -f "$CLAUDE_SETTINGS" ]; then
        cat > "$CLAUDE_SETTINGS" << 'EOF'
{
  "hooks": {
    "Notification": [
      {
        "matcher": "permission_prompt|idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/tmux-notification.py"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/tmux-notification.py"
          }
        ]
      }
    ]
  }
}
EOF
        echo -e "${GREEN}  ✓ Claude hooks configured${RESET}"
    else
        echo -e "${YELLOW}  ⚠ Claude settings exist - please add hooks manually:${RESET}"
        echo -e "${DIM}     See README.md for Claude Code hook configuration${RESET}"
    fi

    echo ""
    echo -e "${CYAN}Claude Code Integration:${RESET}"
    echo "  Alt+x = View notification queue"
    echo "  Popup appears when Claude needs attention"
    echo "  Sound alert (terminal bell) on notifications"
}

finalize() {
    echo -e "\n${CYAN}${BOLD}[4/4] Finalizing...${RESET}"

    # Reload tmux if running
    if [ -n "$TMUX" ]; then
        tmux source-file "$TMUX_CONF" 2>/dev/null || true
        echo -e "${GREEN}  ✓ tmux configuration reloaded${RESET}"
    else
        echo -e "${YELLOW}  ⚠ Start tmux and run: tmux source-file ~/.tmux.conf${RESET}"
    fi
}

print_success() {
    echo ""
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}${BOLD}                    Installation Complete!                      ${RESET}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
    echo ""
    echo -e "${CYAN}${BOLD}Quick Reference:${RESET}"
    echo ""
    echo -e "  ${BOLD}Core Keybindings:${RESET}"
    echo "    Alt+m     Session Manager (hierarchical menu)"
    echo "    Alt+a     Popup Switcher (quick 1-9 selection)"
    echo "    Alt+s     FZF Selector (fuzzy search)"
    echo "    Alt+d     Directory Search (find projects)"
    echo "    Alt+n/p   Next/Previous session"
    echo ""

    if [ "$INSTALL_RESURRECT" = true ]; then
        echo -e "  ${BOLD}Session Persistence:${RESET}"
        echo "    Prefix + Ctrl+s   Save session"
        echo "    Prefix + Ctrl+r   Restore session"
        echo "    Auto-saves every 15 minutes"
        echo ""
    fi

    if [ "$INSTALL_CLAUDE" = true ]; then
        echo -e "  ${BOLD}Claude Code:${RESET}"
        echo "    Alt+x     View notification queue"
        echo "    Popup appears when Claude needs attention"
        echo ""
    fi

    echo -e "  ${BOLD}Documentation:${RESET}"
    echo "    README.md      Full documentation"
    echo "    CHEATSHEET.md  Quick reference"
    echo ""
    echo -e "${YELLOW}Try it now! Press ${BOLD}Alt+m${RESET}${YELLOW} inside tmux${RESET}"
    echo ""
}

uninstall() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║       tmux Session Switcher - Uninstaller                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"

    echo -e "${YELLOW}This will remove:${RESET}"
    echo "  - Main script ($SCRIPT_PATH)"
    echo "  - Configuration ($CONFIG_DIR)"
    echo "  - Cache files ($CACHE_DIR)"
    echo "  - Log files ($LOG_DIR)"
    echo "  - Claude Code hooks ($CLAUDE_HOOKS_DIR)"
    echo "  - Claude notifications cache"
    echo "  - Keybindings from ~/.tmux.conf"
    echo ""

    read -p "Continue with uninstall? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi

    echo ""
    echo -e "${CYAN}[1/6] Removing main script...${RESET}"
    if [ -f "$SCRIPT_PATH" ]; then
        rm "$SCRIPT_PATH"
        echo -e "${GREEN}  ✓ Removed $SCRIPT_PATH${RESET}"
    else
        echo -e "${DIM}  - Script not found (already removed)${RESET}"
    fi

    echo -e "${CYAN}[2/6] Removing configuration...${RESET}"
    if [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
        echo -e "${GREEN}  ✓ Removed $CONFIG_DIR${RESET}"
    else
        echo -e "${DIM}  - Config directory not found${RESET}"
    fi

    echo -e "${CYAN}[3/6] Removing cache and logs...${RESET}"
    if [ -d "$CACHE_DIR" ]; then
        rm -rf "$CACHE_DIR"
        echo -e "${GREEN}  ✓ Removed $CACHE_DIR${RESET}"
    fi
    if [ -d "$LOG_DIR" ]; then
        rm -rf "$LOG_DIR"
        echo -e "${GREEN}  ✓ Removed $LOG_DIR${RESET}"
    fi

    echo -e "${CYAN}[4/6] Removing Claude Code hooks...${RESET}"
    if [ -d "$CLAUDE_HOOKS_DIR" ]; then
        # Only remove our files, not the whole directory
        [ -f "$CLAUDE_HOOKS_DIR/tmux-notification.py" ] && rm "$CLAUDE_HOOKS_DIR/tmux-notification.py"
        [ -f "$CLAUDE_HOOKS_DIR/claude-popup.sh" ] && rm "$CLAUDE_HOOKS_DIR/claude-popup.sh"
        [ -f "$CLAUDE_HOOKS_DIR/notification-queue.sh" ] && rm "$CLAUDE_HOOKS_DIR/notification-queue.sh"
        echo -e "${GREEN}  ✓ Removed Claude hook scripts${RESET}"

        # Remove deprecated folder if exists
        [ -d "$CLAUDE_HOOKS_DIR/deprecated" ] && rm -rf "$CLAUDE_HOOKS_DIR/deprecated"

        # Remove directory if empty
        if [ -d "$CLAUDE_HOOKS_DIR" ] && [ -z "$(ls -A "$CLAUDE_HOOKS_DIR" 2>/dev/null)" ]; then
            rmdir "$CLAUDE_HOOKS_DIR"
            echo -e "${GREEN}  ✓ Removed empty $CLAUDE_HOOKS_DIR${RESET}"
        fi
    else
        echo -e "${DIM}  - Claude hooks not found${RESET}"
    fi

    # Remove Claude notifications cache
    CLAUDE_CACHE="$HOME/.cache/claude-notifications"
    if [ -d "$CLAUDE_CACHE" ]; then
        rm -rf "$CLAUDE_CACHE"
        echo -e "${GREEN}  ✓ Removed $CLAUDE_CACHE${RESET}"
    fi

    echo -e "${CYAN}[5/6] Cleaning tmux.conf...${RESET}"
    if [ -f "$TMUX_CONF" ]; then
        # Create backup
        BACKUP="$TMUX_CONF.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$TMUX_CONF" "$BACKUP"
        echo -e "${DIM}  Backed up to $BACKUP${RESET}"

        # Remove our sections using sed
        # Remove Session Switcher section
        sed -i '/# ═.*tmux Session Switcher/,/^# ═.*[^S]/{ /^# ═.*[^S]/!d; }' "$TMUX_CONF" 2>/dev/null || true
        sed -i '/# ═.*tmux Session Switcher/d' "$TMUX_CONF" 2>/dev/null || true

        # Remove Session Persistence section
        sed -i '/# ═.*Session Persistence/,/^# ═\|^$/{ /^# ═[^S]/!d; }' "$TMUX_CONF" 2>/dev/null || true
        sed -i '/tmux-resurrect/d' "$TMUX_CONF" 2>/dev/null || true
        sed -i '/tmux-continuum/d' "$TMUX_CONF" 2>/dev/null || true
        sed -i '/@resurrect/d' "$TMUX_CONF" 2>/dev/null || true
        sed -i '/@continuum/d' "$TMUX_CONF" 2>/dev/null || true

        # Remove Claude Code section
        sed -i '/# ═.*Claude Code/,/^# ═\|^$/{ /^# ═[^C]/!d; }' "$TMUX_CONF" 2>/dev/null || true
        sed -i '/notification-queue/d' "$TMUX_CONF" 2>/dev/null || true

        # Remove tmux-session-switcher related lines
        sed -i '/tmux-session-switcher/d' "$TMUX_CONF" 2>/dev/null || true

        # Remove TPM lines (only if we added them)
        sed -i "/@plugin 'tmux-plugins\/tpm'/d" "$TMUX_CONF" 2>/dev/null || true
        sed -i '/run.*\.tmux\/plugins\/tpm\/tpm/d' "$TMUX_CONF" 2>/dev/null || true

        # Clean up multiple empty lines
        sed -i '/^$/N;/^\n$/d' "$TMUX_CONF" 2>/dev/null || true

        echo -e "${GREEN}  ✓ Cleaned tmux.conf${RESET}"
    else
        echo -e "${DIM}  - tmux.conf not found${RESET}"
    fi

    echo -e "${CYAN}[6/6] Optional cleanup...${RESET}"
    echo ""
    read -p "  Remove TPM and plugins (~/.tmux/plugins)? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -d "$HOME/.tmux/plugins" ]; then
            rm -rf "$HOME/.tmux/plugins"
            echo -e "${GREEN}  ✓ Removed ~/.tmux/plugins${RESET}"
        fi
        if [ -d "$HOME/.tmux" ] && [ -z "$(ls -A "$HOME/.tmux" 2>/dev/null)" ]; then
            rmdir "$HOME/.tmux"
            echo -e "${GREEN}  ✓ Removed empty ~/.tmux${RESET}"
        fi
    else
        echo -e "${DIM}  - Keeping TPM and plugins${RESET}"
    fi

    # Reload tmux if running
    if [ -n "$TMUX" ]; then
        echo ""
        echo -e "${CYAN}Reloading tmux configuration...${RESET}"
        tmux source-file "$TMUX_CONF" 2>/dev/null || true
        echo -e "${GREEN}  ✓ Configuration reloaded${RESET}"
    fi

    echo ""
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}${BOLD}                    Uninstall Complete!                         ${RESET}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════════${RESET}"
    echo ""
    echo -e "${CYAN}Removed:${RESET}"
    echo "  - tmux-session-switcher script"
    echo "  - Configuration and cache"
    echo "  - Claude Code hooks"
    echo "  - Keybindings from tmux.conf"
    echo ""
    echo -e "${YELLOW}Note:${RESET} A backup of your tmux.conf was created."
    echo "If you had other customizations, you may need to restore them."
    echo ""
}

show_menu() {
    print_header
    check_requirements

    echo -e "${BOLD}Select installation type:${RESET}"
    echo ""
    echo "  [1] ${BOLD}Full Install${RESET} (Recommended)"
    echo "      Base + Session Persistence + Claude Code hooks"
    echo ""
    echo "  [2] ${BOLD}Basic Install${RESET}"
    echo "      Core functionality only (keybindings + script)"
    echo ""
    echo "  [3] ${BOLD}Add Session Persistence${RESET}"
    echo "      tmux-resurrect + tmux-continuum"
    echo ""
    echo "  [4] ${BOLD}Add Claude Code Hooks${RESET}"
    echo "      Notification integration for Claude Code"
    echo ""
    echo "  [5] ${BOLD}Uninstall${RESET}"
    echo ""
    echo "  [q] Quit"
    echo ""

    read -p "Select option [1-5, q]: " -n 1 -r
    echo ""

    case $REPLY in
        1)
            INSTALL_RESURRECT=true
            INSTALL_CLAUDE=true
            install_base
            install_resurrect
            install_claude
            finalize
            print_success
            ;;
        2)
            INSTALL_RESURRECT=false
            INSTALL_CLAUDE=false
            install_base
            finalize
            print_success
            ;;
        3)
            INSTALL_RESURRECT=true
            install_resurrect
            finalize
            echo -e "${GREEN}Session persistence installed!${RESET}"
            ;;
        4)
            INSTALL_CLAUDE=true
            install_claude
            finalize
            echo -e "${GREEN}Claude Code hooks installed!${RESET}"
            ;;
        5)
            uninstall
            ;;
        q|Q)
            echo "Cancelled."
            exit 0
            ;;
        *)
            echo "Invalid option."
            exit 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════════════════

case "${1:-}" in
    --full)
        print_header
        check_requirements
        INSTALL_RESURRECT=true
        INSTALL_CLAUDE=true
        install_base
        install_resurrect
        install_claude
        finalize
        print_success
        ;;
    --basic)
        print_header
        check_requirements
        INSTALL_RESURRECT=false
        INSTALL_CLAUDE=false
        install_base
        finalize
        print_success
        ;;
    --resurrect)
        check_requirements
        INSTALL_RESURRECT=true
        install_resurrect
        finalize
        echo -e "${GREEN}Session persistence installed!${RESET}"
        ;;
    --claude)
        INSTALL_CLAUDE=true
        install_claude
        finalize
        echo -e "${GREEN}Claude Code hooks installed!${RESET}"
        ;;
    --uninstall)
        uninstall
        ;;
    --help|-h)
        echo "tmux Session Switcher Installer"
        echo ""
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Options:"
        echo "  (none)        Interactive menu"
        echo "  --full        Install everything"
        echo "  --basic       Install base only"
        echo "  --resurrect   Add session persistence"
        echo "  --claude      Add Claude Code hooks"
        echo "  --uninstall   Remove installation"
        echo "  --help        Show this help"
        ;;
    "")
        show_menu
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
