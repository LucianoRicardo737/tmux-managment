#!/usr/bin/env bash

# Quick installer for tmux-session-switcher
# Usage: ./install.sh

set -e

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   tmux Session Switcher v2.0 - Installer            ║"
echo "║   Alt+Tab Style with tmux-sessionizer Integration   ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}Error: tmux is not installed${RESET}"
    echo "Please install tmux first:"
    echo "  Ubuntu/Debian: sudo apt install tmux"
    echo "  Arch: sudo pacman -S tmux"
    echo "  macOS: brew install tmux"
    exit 1
fi

# Installation directories
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-sessionizer"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-sessionizer"
LOG_DIR="$HOME/.local/share/tmux-sessionizer"

SCRIPT_NAME="tmux-session-switcher.sh"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"
CONFIG_FILE="$CONFIG_DIR/tmux-sessionizer.conf"

# Create directories if they don't exist
echo -e "${CYAN}Creating directories...${RESET}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$CACHE_DIR"
mkdir -p "$LOG_DIR"
echo -e "${GREEN}✓ Directories created${RESET}"

# Copy script
echo -e "${CYAN}Installing script to $SCRIPT_PATH...${RESET}"
cp "$SCRIPT_NAME" "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"
echo -e "${GREEN}✓ Script installed${RESET}"

# Copy config example if config doesn't exist
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}⚠ Config file already exists at $CONFIG_FILE${RESET}"
    echo "  Skipping config installation (your settings preserved)"
else
    echo -e "${CYAN}Installing example configuration...${RESET}"
    if [ -f "config.example" ]; then
        cp "config.example" "$CONFIG_FILE"
        echo -e "${GREEN}✓ Configuration installed to $CONFIG_FILE${RESET}"
        echo -e "${CYAN}  Edit this file to customize search paths and commands${RESET}"
    else
        echo -e "${YELLOW}⚠ config.example not found, skipping${RESET}"
    fi
fi

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo -e "${YELLOW}⚠ Warning: $HOME/.local/bin is not in your PATH${RESET}"
    echo "Add this line to your ~/.bashrc or ~/.zshrc:"
    echo -e "${CYAN}  export PATH=\"\$HOME/.local/bin:\$PATH\"${RESET}"
fi

# Check if fzf is installed
if command -v fzf &> /dev/null; then
    echo -e "${GREEN}✓ fzf is installed${RESET}"
else
    echo -e "${YELLOW}⚠ fzf is not installed (optional but recommended)${RESET}"
    echo "Install fzf for better experience:"
    echo "  Ubuntu/Debian: sudo apt install fzf"
    echo "  Arch: sudo pacman -S fzf"
    echo "  macOS: brew install fzf"
fi

# Configure tmux
echo ""
echo -e "${CYAN}Configuring tmux...${RESET}"

TMUX_CONF="$HOME/.tmux.conf"
BACKUP_CONF="$HOME/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)"

# Backup existing config
if [ -f "$TMUX_CONF" ]; then
    echo -e "${YELLOW}Backing up existing tmux.conf to $BACKUP_CONF${RESET}"
    cp "$TMUX_CONF" "$BACKUP_CONF"
fi

# Configuration to add
CONFIG="
# ============================================
# tmux Session Switcher v2.0
# Added by installer on $(date)
# ============================================

# Alt+m - Session Manager (RECOMMENDED - full hierarchical menu)
bind-key -n M-m run-shell \"$SCRIPT_PATH show-menu '#{client_name}'\"

# Alt+a - Popup switcher (Alt-tab style, 'a' = alt-tab alternative)
bind-key -n M-a run-shell \"$SCRIPT_PATH popup\"

# Alt+s - FZF session switcher (full features)
bind-key -n M-s run-shell \"tmux neww $SCRIPT_PATH fzf\"

# Alt+d - Search directories and create session
bind-key -n M-d run-shell \"$SCRIPT_PATH search\"

# Alt+n - Next session
bind-key -n M-n run-shell \"$SCRIPT_PATH next\"

# Alt+p - Previous session
bind-key -n M-p run-shell \"$SCRIPT_PATH prev\"

# Alternative bindings (if Alt doesn't work in your terminal):
# bind-key a run-shell \"$SCRIPT_PATH popup\"         # Prefix + a
"

# Check if already configured
if grep -q "tmux-session-switcher" "$TMUX_CONF" 2>/dev/null; then
    echo -e "${YELLOW}Configuration already exists in $TMUX_CONF${RESET}"
    echo "Skipping automatic configuration..."
else
    echo "$CONFIG" >> "$TMUX_CONF"
    echo -e "${GREEN}✓ Configuration added to $TMUX_CONF${RESET}"
fi

# Reload tmux config if in tmux
if [ -n "$TMUX" ]; then
    echo ""
    echo -e "${CYAN}Reloading tmux configuration...${RESET}"
    tmux source-file "$TMUX_CONF"
    echo -e "${GREEN}✓ Configuration reloaded${RESET}"
fi

# Success message
echo ""
echo -e "${GREEN}${BOLD}Installation complete!${RESET}"
echo ""
echo -e "${CYAN}${BOLD}Quick Start:${RESET}"
echo "  ${BOLD}Alt+a${RESET}     - Popup switcher (press 1-9 to select sessions)"
echo "  ${BOLD}Alt+s${RESET}     - FZF session switcher (full features with preview)"
echo "  ${BOLD}Alt+d${RESET}     - Search directories and create new sessions"
echo "  ${BOLD}Alt+n/p${RESET}   - Next/Previous session (quick cycling)"
echo ""
echo -e "${CYAN}${BOLD}Popup Switcher Features:${RESET}"
echo "  - Press ${BOLD}1-9${RESET} to instantly switch to that session"
echo "  - Press ${BOLD}D${RESET} to search directories"
echo "  - Press ${BOLD}Q${RESET} to close"
echo "  - ${GREEN}●${RESET} = Current session, ${CYAN}○${RESET} = Attached session"
echo ""
echo -e "${CYAN}${BOLD}FZF Selector Features:${RESET}"
echo "  - Use arrows to navigate, Enter to select"
echo "  - ${BOLD}Ctrl+x${RESET} to delete a session"
echo "  - ${BOLD}Ctrl+r${RESET} to reload the list"
echo "  - Preview panel shows windows of each session"
echo ""
echo -e "${CYAN}${BOLD}Advanced Features:${RESET}"
echo "  ${BOLD}Session Commands:${RESET}"
echo "    $SCRIPT_NAME -s 0              # Execute TS_SESSION_COMMANDS[0]"
echo "    $SCRIPT_NAME -s 1 --vsplit    # Execute in vertical split"
echo "    $SCRIPT_NAME -s 2 --hsplit    # Execute in horizontal split"
echo ""
echo "  ${BOLD}Configuration:${RESET}"
echo "    Edit: $CONFIG_FILE"
echo "    Set search paths, session commands, and more"
echo ""
echo "  ${BOLD}Hydration Scripts:${RESET}"
echo "    Create ~/.tmux-sessionizer for global setup"
echo "    Create .tmux-sessionizer in project dirs for per-project setup"
echo ""
echo -e "${CYAN}${BOLD}Documentation:${RESET}"
echo "  README.md      - Full documentation"
echo "  CHEATSHEET.md  - Quick reference"
echo "  config.example - Configuration examples"
echo ""
echo -e "${YELLOW}${BOLD}Try it now!${RESET} ${YELLOW}Press Alt+a inside tmux to see the popup switcher${RESET}"
echo -e "${CYAN}Note: Alt+s (FZF mode) is already confirmed working on your system${RESET}"
