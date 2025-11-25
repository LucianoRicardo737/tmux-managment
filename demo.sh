#!/usr/bin/env bash

# Demo script - Creates sample sessions to test the session switcher

set -e

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${CYAN}Creating demo sessions...${RESET}"

# Check if we're in tmux
if [ -z "$TMUX" ]; then
    echo -e "${RED}Error: This script must be run from within tmux${RESET}"
    echo "Start tmux first with: tmux"
    exit 1
fi

# Create demo sessions if they don't exist
create_session() {
    local session_name=$1
    local description=$2

    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo -e "${YELLOW}Session '$session_name' already exists, skipping...${RESET}"
    else
        tmux new-session -d -s "$session_name"
        echo -e "${GREEN}✓ Created session: $session_name ($description)${RESET}"

        # Add some windows to make it interesting
        tmux new-window -t "$session_name:" -n "window-2"
        if [ "$session_name" = "development" ] || [ "$session_name" = "frontend" ]; then
            tmux new-window -t "$session_name:" -n "window-3"
        fi
    fi
}

# Create demo sessions
create_session "development" "Main development work"
create_session "frontend" "Frontend projects"
create_session "backend" "Backend services"
create_session "devops" "DevOps and infrastructure"
create_session "testing" "Testing and QA"

echo ""
echo -e "${GREEN}Demo sessions created!${RESET}"
echo ""
echo -e "${CYAN}Now try the session switcher:${RESET}"
echo "  1. Press ${GREEN}Alt+s${RESET} to open the session switcher"
echo "  2. Use arrows to navigate between sessions"
echo "  3. Press ${GREEN}Enter${RESET} to switch to a session"
echo "  4. Try ${GREEN}Alt+n${RESET} and ${GREEN}Alt+p${RESET} to cycle through sessions"
echo ""
echo -e "${CYAN}Available demo sessions:${RESET}"
tmux list-sessions -F "  - #{session_name} (#{session_windows} windows)"
echo ""
echo -e "${YELLOW}To clean up: tmux kill-session -t <session-name>${RESET}"
