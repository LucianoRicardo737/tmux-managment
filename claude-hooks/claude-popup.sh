#!/usr/bin/env bash
#
# Claude Code Notification Popup
# Display notification details and allow navigation to source session
#

# Only exit on unset variables, but allow commands to fail
set -u

CACHE_DIR="$HOME/.cache/claude-notifications"
LOG_FILE="$HOME/.cache/claude-notifications/popup-debug.log"
NOTIFICATION_ID="${1:-}"

# Function to log debug messages
log_debug() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE" 2>/dev/null || true
}

log_debug "=== Popup script started ==="
log_debug "Notification ID: $NOTIFICATION_ID"

if [[ -z "$NOTIFICATION_ID" ]]; then
    echo "Error: No notification ID provided"
    log_debug "ERROR: No notification ID provided"
    echo "Press any key to exit..."
    read -r -n 1
    exit 1
fi

NOTIFICATION_FILE="$CACHE_DIR/${NOTIFICATION_ID}.json"
log_debug "Notification file: $NOTIFICATION_FILE"

if [[ ! -f "$NOTIFICATION_FILE" ]]; then
    echo "Error: Notification not found: $NOTIFICATION_ID"
    echo "File: $NOTIFICATION_FILE"
    log_debug "ERROR: Notification file not found"
    echo ""
    echo "Press any key to exit..."
    read -r -n 1
    exit 1
fi

# Read notification data
log_debug "Reading notification data..."

# Try to extract fields - use simpler approach
MESSAGE=$(python3 -c "import json; data=json.load(open('$NOTIFICATION_FILE')); print(data.get('message', 'No message'))" 2>/dev/null || echo "Error reading message")
TYPE=$(python3 -c "import json; data=json.load(open('$NOTIFICATION_FILE')); print(data.get('type', 'unknown'))" 2>/dev/null || echo "unknown")
TIMESTAMP=$(python3 -c "import json; data=json.load(open('$NOTIFICATION_FILE')); print(data.get('timestamp', ''))" 2>/dev/null || echo "")
CWD=$(python3 -c "import json; data=json.load(open('$NOTIFICATION_FILE')); print(data.get('cwd', 'Unknown'))" 2>/dev/null || echo "Unknown")
SESSION_NAME=$(python3 -c "import json; data=json.load(open('$NOTIFICATION_FILE')); print(data.get('tmux', {}).get('session_name', 'unknown'))" 2>/dev/null || echo "unknown")
WINDOW_NAME=$(python3 -c "import json; data=json.load(open('$NOTIFICATION_FILE')); print(data.get('tmux', {}).get('window_name', 'unknown'))" 2>/dev/null || echo "unknown")
WINDOW_INDEX=$(python3 -c "import json; data=json.load(open('$NOTIFICATION_FILE')); print(data.get('tmux', {}).get('window_index', '0'))" 2>/dev/null || echo "0")
LOCATION=$(python3 -c "import json; data=json.load(open('$NOTIFICATION_FILE')); print(data.get('tmux', {}).get('location', 'unknown'))" 2>/dev/null || echo "unknown")

log_debug "Extracted data: TYPE=$TYPE, SESSION=$SESSION_NAME, WINDOW=$WINDOW_NAME, LOCATION=$LOCATION, CWD=$CWD"

# If location is unknown, try to find pane by CWD
if [[ "$LOCATION" == "unknown" || "$LOCATION" == "None" || -z "$LOCATION" ]]; then
    log_debug "Location unknown, attempting to find pane by CWD: $CWD"
    if [[ -n "$CWD" && "$CWD" != "Unknown" ]]; then
        # Search for pane with matching CWD
        FOUND_LOCATION=$(tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}|#{pane_current_path}" 2>/dev/null | \
            grep -F "|$CWD" | head -1 | cut -d'|' -f1)
        if [[ -n "$FOUND_LOCATION" ]]; then
            LOCATION="$FOUND_LOCATION"
            # Also extract session name from location
            SESSION_NAME="${LOCATION%%:*}"
            log_debug "Found pane by CWD: LOCATION=$LOCATION, SESSION=$SESSION_NAME"
        else
            log_debug "No pane found with exact CWD match"
            # Try partial match (pane cwd is parent of notification cwd)
            FOUND_LOCATION=$(tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}|#{pane_current_path}" 2>/dev/null | \
                while IFS='|' read -r loc pane_cwd; do
                    if [[ "$CWD" == "$pane_cwd"* ]]; then
                        echo "$loc"
                        break
                    fi
                done)
            if [[ -n "$FOUND_LOCATION" ]]; then
                LOCATION="$FOUND_LOCATION"
                SESSION_NAME="${LOCATION%%:*}"
                log_debug "Found pane by partial CWD match: LOCATION=$LOCATION"
            fi
        fi
    fi
fi

# Format timestamp for display
if [[ -n "$TIMESTAMP" && "$TIMESTAMP" != "None" ]]; then
    DISPLAY_TIME=$(date -d "$TIMESTAMP" "+%H:%M:%S" 2>/dev/null || echo "${TIMESTAMP:11:8}")
else
    DISPLAY_TIME="Unknown time"
fi

# Truncate CWD for display (show last 50 chars)
if [[ ${#CWD} -gt 50 ]]; then
    DISPLAY_CWD="...${CWD: -47}"
else
    DISPLAY_CWD="$CWD"
fi

# Truncate message if too long
MAX_MSG_LEN=200
if [[ ${#MESSAGE} -gt $MAX_MSG_LEN ]]; then
    DISPLAY_MESSAGE="${MESSAGE:0:$MAX_MSG_LEN}..."
else
    DISPLAY_MESSAGE="$MESSAGE"
fi

# Clear screen and display notification
clear

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                    Claude Code Notification                            ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Type: $TYPE"
echo "Time: $DISPLAY_TIME"
echo ""
echo "Session: $SESSION_NAME"
echo "Window:  $WINDOW_NAME (#$WINDOW_INDEX)"
echo "Dir:     $DISPLAY_CWD"
echo ""
echo "────────────────────────────────────────────────────────────────────────"
echo "Message:"
echo "$DISPLAY_MESSAGE"
echo "────────────────────────────────────────────────────────────────────────"
echo ""
echo "Actions:"
echo "  [1] Go to session"
echo "  [2] View full details"
echo "  [3] Mark as read & close"
echo "  [q] Close without marking as read"
echo ""
echo -n "Select action (1-3, q): "

# Read user input
read -r -n 1 action
echo ""

log_debug "User selected action: $action"

case "$action" in
    1)
        # Navigate to session - schedule the switch to run AFTER popup closes
        log_debug "User wants to switch to: $LOCATION"

        # Mark as read before switching
        python3 -c "
import json
try:
    with open('$NOTIFICATION_FILE', 'r') as f:
        data = json.load(f)
    data['read'] = True
    with open('$NOTIFICATION_FILE', 'w') as f:
        json.dump(data, f, indent=2)
except Exception as e:
    print(f'Error marking as read: {e}')
" 2>/dev/null || log_debug "Failed to mark as read"

        if [[ "$LOCATION" != "unknown" && "$LOCATION" != "None" && -n "$LOCATION" ]]; then
            log_debug "Scheduling switch to: $LOCATION, window: ${SESSION_NAME}:${WINDOW_INDEX}"

            # Use tmux run-shell with a small delay to let the popup close first
            # The -b flag runs it in background, and sleep ensures popup is closed
            tmux run-shell -b "sleep 0.1 && tmux switch-client -t '$SESSION_NAME' && tmux select-window -t '${SESSION_NAME}:${WINDOW_INDEX}'" 2>/dev/null

            log_debug "Switch scheduled, exiting popup"
            exit 0
        else
            echo "Error: Unknown session location"
            log_debug "ERROR: Location is unknown, cannot switch"
            sleep 2
            exit 1
        fi
        ;;
    2)
        # View full details
        clear
        echo "Full Notification Details:"
        echo "═════════════════════════════════════════════════════════════════"
        cat "$NOTIFICATION_FILE" 2>/dev/null || echo "Error reading file"
        echo ""
        echo "═════════════════════════════════════════════════════════════════"
        echo "Log file: $LOG_FILE"
        echo ""
        echo "Press any key to continue..."
        read -r -n 1

        # Re-run this script to show menu again
        log_debug "Re-running popup script"
        exec "$0" "$NOTIFICATION_ID"
        ;;
    3)
        # Mark as read and close
        python3 -c "
import json
try:
    with open('$NOTIFICATION_FILE', 'r') as f:
        data = json.load(f)
    data['read'] = True
    with open('$NOTIFICATION_FILE', 'w') as f:
        json.dump(data, f, indent=2)
    print('Marked as read')
except Exception as e:
    print(f'Error: {e}')
" 2>/dev/null || echo "Failed to mark as read"
        log_debug "Marked as read and closing"
        sleep 1
        ;;
    q|Q)
        # Close without marking as read
        log_debug "Closing without marking as read"
        echo "Closing..."
        ;;
    *)
        # Invalid option
        log_debug "Invalid option selected: $action"
        echo "Invalid option. Closing..."
        ;;
esac

log_debug "=== Popup script ended ==="
exit 0
