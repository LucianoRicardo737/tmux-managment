#!/usr/bin/env bash
#
# Claude Code Notification Queue Viewer
# Display all notifications and allow selection/navigation
#

set -euo pipefail

CACHE_DIR="$HOME/.cache/claude-notifications"
POPUP_SCRIPT="$HOME/.claude/hooks/claude-popup.sh"

# Create cache dir if it doesn't exist
mkdir -p "$CACHE_DIR"

# Get all notifications sorted by timestamp (newest first)
mapfile -t NOTIFICATIONS < <(
    find "$CACHE_DIR" -name "*.json" -type f 2>/dev/null | \
    xargs -r ls -t 2>/dev/null || true
)

# Count notifications
TOTAL_COUNT=${#NOTIFICATIONS[@]}
UNREAD_COUNT=0

if [[ $TOTAL_COUNT -eq 0 ]]; then
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║            Claude Code Notification Queue                      ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "No notifications found."
    echo ""
    echo "Press any key to close..."
    read -r -n 1
    exit 0
fi

# Parse notifications and build display
declare -a DISPLAY_LINES
declare -a NOTIFICATION_IDS

for i in "${!NOTIFICATIONS[@]}"; do
    NOTIF_FILE="${NOTIFICATIONS[$i]}"
    NOTIF_ID=$(basename "$NOTIF_FILE" .json)
    NOTIFICATION_IDS+=("$NOTIF_ID")

    # Extract data
    if command -v jq &>/dev/null; then
        MESSAGE=$(jq -r '.message // "No message"' "$NOTIF_FILE")
        TYPE=$(jq -r '.type // "unknown"' "$NOTIF_FILE")
        TIMESTAMP=$(jq -r '.timestamp // ""' "$NOTIF_FILE")
        SESSION_NAME=$(jq -r '.tmux.session_name // "unknown"' "$NOTIF_FILE")
        WINDOW_NAME=$(jq -r '.tmux.window_name // "unknown"' "$NOTIF_FILE")
        IS_READ=$(jq -r '.read // false' "$NOTIF_FILE")
    else
        MESSAGE=$(python3 -c "import json, sys; print(json.load(sys.stdin).get('message', 'No message'))" < "$NOTIF_FILE")
        TYPE=$(python3 -c "import json, sys; print(json.load(sys.stdin).get('type', 'unknown'))" < "$NOTIF_FILE")
        TIMESTAMP=$(python3 -c "import json, sys; print(json.load(sys.stdin).get('timestamp', ''))" < "$NOTIF_FILE")
        SESSION_NAME=$(python3 -c "import json, sys; print(json.load(sys.stdin).get('tmux', {}).get('session_name', 'unknown'))" < "$NOTIF_FILE")
        WINDOW_NAME=$(python3 -c "import json, sys; print(json.load(sys.stdin).get('tmux', {}).get('window_name', 'unknown'))" < "$NOTIF_FILE")
        IS_READ=$(python3 -c "import json, sys; print(str(json.load(sys.stdin).get('read', False)).lower())" < "$NOTIF_FILE")
    fi

    # Count unread
    if [[ "$IS_READ" != "true" ]]; then
        ((UNREAD_COUNT++)) || true
    fi

    # Format timestamp
    if [[ -n "$TIMESTAMP" ]]; then
        DISPLAY_TIME=$(date -d "$TIMESTAMP" "+%H:%M:%S" 2>/dev/null || echo "$TIMESTAMP")
    else
        DISPLAY_TIME="??:??:??"
    fi

    # Truncate message
    MAX_MSG_LEN=50
    if [[ ${#MESSAGE} -gt $MAX_MSG_LEN ]]; then
        DISPLAY_MSG="${MESSAGE:0:$MAX_MSG_LEN}..."
    else
        DISPLAY_MSG="$MESSAGE"
    fi

    # Build display line
    INDEX=$((i + 1))
    READ_MARKER=""
    if [[ "$IS_READ" == "true" ]]; then
        READ_MARKER="[✓]"
    else
        READ_MARKER="[•]"
    fi

    DISPLAY_LINE=$(printf "%2d %3s %-8s %-15s %-10s | %s" \
        "$INDEX" \
        "$READ_MARKER" \
        "$DISPLAY_TIME" \
        "$SESSION_NAME" \
        "$WINDOW_NAME" \
        "$DISPLAY_MSG")

    DISPLAY_LINES+=("$DISPLAY_LINE")
done

# Display queue
while true; do
    clear
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║              Claude Code Notification Queue                            ║"
    echo "╚════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Total: $TOTAL_COUNT | Unread: $UNREAD_COUNT"
    echo ""
    echo "────────────────────────────────────────────────────────────────────────"
    echo "#  Status Time     Session         Window     | Message"
    echo "────────────────────────────────────────────────────────────────────────"

    for line in "${DISPLAY_LINES[@]}"; do
        echo "$line"
    done

    echo "────────────────────────────────────────────────────────────────────────"
    echo ""
    echo "Actions:"
    echo "  [1-$TOTAL_COUNT] View notification"
    echo "  [c] Clear all read notifications"
    echo "  [C] Clear ALL notifications"
    echo "  [r] Refresh"
    echo "  [q] Close"
    echo ""
    echo -n "Select action: "

    read -r action

    case "$action" in
        [1-9]|[1-9][0-9]|[1-9][0-9][0-9])
            # Check if valid index
            if [[ $action -ge 1 && $action -le $TOTAL_COUNT ]]; then
                # Get notification ID
                INDEX=$((action - 1))
                SELECTED_ID="${NOTIFICATION_IDS[$INDEX]}"

                # Show popup for this notification
                if [[ -x "$POPUP_SCRIPT" ]]; then
                    "$POPUP_SCRIPT" "$SELECTED_ID"
                else
                    echo "Error: Popup script not found or not executable"
                    sleep 2
                fi

                # Refresh the queue (user might have marked as read)
                exec "$0"
            else
                echo "Invalid selection: $action"
                sleep 1
            fi
            ;;
        c)
            # Clear read notifications
            CLEARED=0
            for NOTIF_FILE in "${NOTIFICATIONS[@]}"; do
                if command -v jq &>/dev/null; then
                    IS_READ=$(jq -r '.read // false' "$NOTIF_FILE")
                else
                    IS_READ=$(python3 -c "import json, sys; print(str(json.load(sys.stdin).get('read', False)).lower())" < "$NOTIF_FILE")
                fi

                if [[ "$IS_READ" == "true" ]]; then
                    rm -f "$NOTIF_FILE"
                    ((CLEARED++)) || true
                fi
            done

            echo "Cleared $CLEARED read notifications"
            sleep 1

            # Refresh
            exec "$0"
            ;;
        C)
            # Clear ALL notifications
            echo "Are you sure you want to delete ALL notifications? (y/N): "
            read -r -n 1 confirm
            echo ""

            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                rm -f "$CACHE_DIR"/*.json
                echo "All notifications cleared"
                sleep 1
                exit 0
            fi
            ;;
        r|R)
            # Refresh
            exec "$0"
            ;;
        q|Q)
            # Quit
            exit 0
            ;;
        *)
            echo "Invalid option"
            sleep 1
            ;;
    esac
done
