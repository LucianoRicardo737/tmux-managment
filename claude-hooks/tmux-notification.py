#!/usr/bin/env python3
"""
Claude Code Tmux Notification Hook
Handles notifications from Claude Code and displays them as tmux popups
"""

import json
import sys
import os
import subprocess
from datetime import datetime
from pathlib import Path
import uuid
import traceback

# Directories
CACHE_DIR = Path.home() / ".cache" / "claude-notifications"
HOOKS_DIR = Path.home() / ".claude" / "hooks"
LOG_FILE = CACHE_DIR / "hook-debug.log"

def log_debug(message):
    """Log debug messages to file"""
    try:
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(LOG_FILE, 'a') as f:
            f.write(f"[{timestamp}] {message}\n")
    except Exception:
        pass  # Fail silently if logging fails

# Notification types that trigger immediate popups
IMMEDIATE_TYPES = {
    "permission_prompt",
    "idle_prompt",
    "auth_required",
    "elicitation_dialog",
    "error",
    "Stop"  # Stop events should also be immediate
}

def find_tmux_pane_by_cwd(cwd):
    """Find tmux pane that has matching cwd using tmux list-panes"""
    if not cwd:
        return None

    try:
        result = subprocess.run(
            ["tmux", "list-panes", "-a", "-F",
             "#{session_name}:#{window_index}.#{pane_index}|#{pane_current_path}|#{pane_id}|#{window_name}"],
            capture_output=True,
            text=True,
            check=True
        )

        for line in result.stdout.strip().split('\n'):
            if not line:
                continue
            parts = line.split('|')
            if len(parts) >= 2:
                location = parts[0]
                pane_cwd = parts[1]
                pane_id = parts[2] if len(parts) > 2 else ""
                window_name = parts[3] if len(parts) > 3 else ""

                # Check if cwd matches (exact match or starts with)
                if pane_cwd == cwd or cwd.startswith(pane_cwd + "/"):
                    # Parse location
                    loc_parts = location.split(":")
                    session_name = loc_parts[0]
                    window_pane = loc_parts[1] if len(loc_parts) > 1 else "0.0"
                    wp_parts = window_pane.split(".")
                    window_index = wp_parts[0]
                    pane_index = wp_parts[1] if len(wp_parts) > 1 else "0"

                    log_debug(f"Found pane by cwd: {location} (cwd: {pane_cwd})")
                    return {
                        "location": location,
                        "session_name": session_name,
                        "window_index": window_index,
                        "window_name": window_name,
                        "pane_index": pane_index,
                        "pane_id": pane_id
                    }

        log_debug(f"No pane found with cwd: {cwd}")
        return None

    except subprocess.CalledProcessError as e:
        log_debug(f"Failed to list panes: {e}")
        return None
    except Exception as e:
        log_debug(f"Error finding pane by cwd: {e}")
        return None

def play_notification_sound():
    """Play notification sound on client terminal via BEL character"""
    try:
        log_debug("Playing notification sound (BEL)")

        # Method 1: Use tmux run-shell to send BEL to all clients
        # This is the most reliable method for hooks running outside tmux context
        try:
            subprocess.run(
                ["tmux", "run-shell", "-t", ":", "printf '\\a'"],
                check=False,
                stderr=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL
            )
            log_debug("BEL sent via tmux run-shell")
        except Exception as e:
            log_debug(f"Failed tmux run-shell: {e}")

        # Method 2: Send BEL to all tmux client TTYs
        try:
            result = subprocess.run(
                ["tmux", "list-clients", "-F", "#{client_tty}"],
                capture_output=True,
                text=True,
                check=True
            )
            for client_tty in result.stdout.strip().split('\n'):
                if client_tty and os.path.exists(client_tty):
                    try:
                        with open(client_tty, 'w') as tty_file:
                            tty_file.write('\a')
                            tty_file.flush()
                        log_debug(f"BEL sent to client TTY: {client_tty}")
                    except Exception as e:
                        log_debug(f"Failed to write to client TTY {client_tty}: {e}")
        except Exception as e:
            log_debug(f"Failed to list tmux clients: {e}")

        # Method 3: Fallback - try SSH_TTY or direct stdout
        tty = os.environ.get("SSH_TTY")
        if tty and os.path.exists(tty):
            try:
                with open(tty, 'w') as tty_file:
                    tty_file.write('\a')
                    tty_file.flush()
                log_debug(f"BEL sent to SSH_TTY: {tty}")
            except Exception as e:
                log_debug(f"Failed to write to SSH_TTY: {e}")

        log_debug("Notification sound sent successfully")
    except Exception as e:
        log_debug(f"Error playing sound: {e}")
        log_debug(traceback.format_exc())

def get_current_tmux_location():
    """Get current tmux session:window.pane location where hook is executing"""
    tmux_pane = os.environ.get("TMUX_PANE", "")
    if not tmux_pane:
        return None

    try:
        result = subprocess.run(
            ["tmux", "display-message", "-p", "-t", tmux_pane,
             "#{session_name}:#{window_index}.#{pane_index}"],
            capture_output=True,
            text=True,
            check=True
        )
        current_location = result.stdout.strip()
        log_debug(f"Current tmux location: {current_location}")
        return current_location
    except subprocess.CalledProcessError:
        log_debug("Failed to get current tmux location")
        return None

def get_tmux_context():
    """Capture current tmux session, window, and pane information"""
    tmux_pane = os.environ.get("TMUX_PANE", "")
    if not tmux_pane:
        return None

    try:
        # Get session:window.pane format
        result = subprocess.run(
            ["tmux", "display-message", "-p", "-t", tmux_pane,
             "#{session_name}:#{window_index}.#{pane_index}"],
            capture_output=True,
            text=True,
            check=True
        )
        location = result.stdout.strip()

        # Also get window name for display
        result = subprocess.run(
            ["tmux", "display-message", "-p", "-t", tmux_pane, "#{window_name}"],
            capture_output=True,
            text=True,
            check=True
        )
        window_name = result.stdout.strip()

        # Parse location
        parts = location.split(":")
        session_name = parts[0]
        window_pane = parts[1] if len(parts) > 1 else "0.0"
        window_parts = window_pane.split(".")
        window_index = window_parts[0]
        pane_index = window_parts[1] if len(window_parts) > 1 else "0"

        return {
            "location": location,
            "session_name": session_name,
            "window_index": window_index,
            "window_name": window_name,
            "pane_index": pane_index,
            "pane_id": tmux_pane
        }
    except subprocess.CalledProcessError:
        return None

def get_last_claude_message(transcript_path, max_chars=500):
    """Read the last Claude message from transcript file"""
    if not transcript_path:
        return None

    transcript_file = Path(transcript_path)
    if not transcript_file.exists():
        log_debug(f"Transcript file not found: {transcript_path}")
        return None

    try:
        with open(transcript_file, 'r') as f:
            lines = f.readlines()

        # Search backwards for the last assistant message
        for line in reversed(lines):
            try:
                data = json.loads(line.strip())
                if data.get("type") == "assistant":
                    # Extract text from message content
                    message = data.get("message", {})
                    if isinstance(message, dict):
                        content = message.get("content", [])
                        if isinstance(content, list):
                            for block in content:
                                if isinstance(block, dict) and block.get("type") == "text":
                                    text = block.get("text", "")
                                    if text:
                                        # Return truncated text
                                        result = text[:max_chars]
                                        if len(text) > max_chars:
                                            result += "..."
                                        log_debug(f"Found Claude message: {result[:100]}...")
                                        return result
            except json.JSONDecodeError:
                continue

        log_debug("No assistant message found in transcript")
        return None

    except Exception as e:
        log_debug(f"Error reading transcript: {e}")
        return None

def create_notification(hook_data, tmux_context):
    """Create notification object with all metadata"""
    notification_id = str(uuid.uuid4())
    timestamp = datetime.now().isoformat()

    # Extract hook data - use hook_event_name as fallback for notification_type
    notification_type = hook_data.get("notification_type") or hook_data.get("hook_event_name", "unknown")
    message = hook_data.get("message", "No message")
    cwd = hook_data.get("cwd", os.environ.get("CLAUDE_PROJECT_DIR", ""))
    session_id = hook_data.get("session_id", "")
    transcript_path = hook_data.get("transcript_path", "")

    log_debug(f"Notification type resolved to: {notification_type}")

    # If message is not useful, try to get the last Claude message from transcript
    if message in ["No message", ""] or not message:
        log_debug("No useful message, trying to get from transcript")
        last_message = get_last_claude_message(transcript_path)
        if last_message:
            message = last_message
            log_debug(f"Got message from transcript: {message[:100]}...")

    # Determine if this is an immediate notification
    is_immediate = notification_type in IMMEDIATE_TYPES

    # For Stop hook, check if it's an error or just completion
    if notification_type.lower() == "stop":
        # If there's an error indicator, make it immediate
        if "error" in message.lower() or "failed" in message.lower():
            is_immediate = True
        # Stop events without errors are also important - make them immediate
        is_immediate = True

    notification = {
        "id": notification_id,
        "timestamp": timestamp,
        "type": notification_type,
        "message": message,
        "cwd": cwd,
        "session_id": session_id,
        "is_immediate": is_immediate,
        "read": False,
        "transcript_path": transcript_path  # Save for reference
    }

    # Add tmux context if available
    if tmux_context:
        notification["tmux"] = tmux_context

    return notification

def save_notification(notification):
    """Save notification to cache directory"""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    notification_file = CACHE_DIR / f"{notification['id']}.json"
    with open(notification_file, 'w') as f:
        json.dump(notification, f, indent=2)

    return notification_file

def get_active_tmux_client():
    """Get the active tmux client TTY"""
    try:
        # Get the most recently active client
        result = subprocess.run(
            ["tmux", "list-clients", "-F", "#{client_tty}"],
            capture_output=True,
            text=True,
            check=True
        )
        clients = result.stdout.strip().split('\n')
        if clients and clients[0]:
            log_debug(f"Active tmux client: {clients[0]}")
            return clients[0]
    except Exception as e:
        log_debug(f"Failed to get active client: {e}")
    return None


def show_popup(notification_id):
    """Display tmux popup for notification"""
    popup_script = HOOKS_DIR / "claude-popup.sh"

    log_debug(f"show_popup called with ID: {notification_id}")

    if not popup_script.exists():
        log_debug(f"ERROR: Popup script not found at {popup_script}")
        return

    if not os.access(popup_script, os.X_OK):
        log_debug(f"ERROR: Popup script not executable")
        return

    try:
        log_debug(f"Executing tmux display-popup via run-shell with script: {popup_script}")

        # Use tmux run-shell to execute display-popup INSIDE tmux context
        # This is how the manual keybinding (Alt+x) does it and it works correctly
        # The key difference: running display-popup via run-shell keeps it in tmux context
        popup_cmd = f'tmux display-popup -E -w 85% -h 60% -T "Claude Code Notification" "{popup_script}" "{notification_id}"'

        result = subprocess.run(
            ["tmux", "run-shell", popup_cmd],
            check=False
        )

        log_debug(f"Popup exited with code: {result.returncode}")

    except Exception as e:
        log_debug(f"Exception in show_popup: {e}")
        log_debug(traceback.format_exc())

def cleanup_old_notifications(max_age_hours=24):
    """Remove notifications older than max_age_hours"""
    if not CACHE_DIR.exists():
        return

    now = datetime.now()
    for notification_file in CACHE_DIR.glob("*.json"):
        try:
            with open(notification_file, 'r') as f:
                data = json.load(f)

            timestamp = datetime.fromisoformat(data.get("timestamp", ""))
            age_hours = (now - timestamp).total_seconds() / 3600

            if age_hours > max_age_hours:
                notification_file.unlink()
        except (json.JSONDecodeError, ValueError, KeyError):
            # Invalid file, remove it
            notification_file.unlink()

def main():
    """Main hook execution"""
    log_debug("=== Hook started ===")

    try:
        # Read hook data from stdin
        hook_data = json.load(sys.stdin)
        log_debug(f"Received hook data: {json.dumps(hook_data, indent=2)}")
    except json.JSONDecodeError as e:
        log_debug(f"ERROR: Invalid JSON input: {e}")
        sys.exit(0)
    except Exception as e:
        log_debug(f"ERROR reading stdin: {e}")
        log_debug(traceback.format_exc())
        sys.exit(0)

    try:
        # Get tmux context - first try environment variable, then fallback to cwd lookup
        tmux_context = get_tmux_context()
        log_debug(f"Tmux context from env: {tmux_context}")

        # If no context from environment, try to find pane by cwd
        if tmux_context is None:
            cwd = hook_data.get("cwd", "")
            log_debug(f"No tmux context from env, trying to find pane by cwd: {cwd}")
            tmux_context = find_tmux_pane_by_cwd(cwd)
            log_debug(f"Tmux context from cwd lookup: {tmux_context}")

        # Create notification
        notification = create_notification(hook_data, tmux_context)
        log_debug(f"Created notification: ID={notification['id']}, type={notification['type']}, immediate={notification['is_immediate']}")

        # Save to cache
        notification_file = save_notification(notification)
        log_debug(f"Saved notification to: {notification_file}")

        # Always play sound first
        play_notification_sound()

        # Get notification location for display logic
        notification_location = notification.get("tmux", {}).get("location", None)
        log_debug(f"Notification location: {notification_location}")

        # Check if tmux server is running
        tmux_running = False
        try:
            result = subprocess.run(
                ["tmux", "list-sessions"],
                capture_output=True,
                text=True
            )
            tmux_running = result.returncode == 0
            log_debug(f"Tmux server running: {tmux_running}")
        except Exception:
            log_debug("Could not check tmux server status")

        # Show popup if:
        # 1. Notification is immediate
        # 2. Tmux server is running
        # 3. We have a notification location (for navigation)
        if notification["is_immediate"] and tmux_running:
            log_debug("Notification is immediate and tmux is running, showing popup")
            show_popup(notification["id"])
        elif notification["is_immediate"] and not tmux_running:
            log_debug("Notification is immediate but tmux not running, only sound + queued")
        else:
            log_debug("Notification is not immediate, only sound + queued")

        # Cleanup old notifications
        cleanup_old_notifications()
        log_debug("=== Hook completed successfully ===")

    except Exception as e:
        log_debug(f"ERROR in main: {e}")
        log_debug(traceback.format_exc())
        sys.exit(1)

if __name__ == "__main__":
    main()
