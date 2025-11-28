#!/usr/bin/env bash

# tmux-session-switcher - Quick session switcher for tmux (Alt+Tab style)
# Author: Claude Code
# Description: Switch between tmux sessions quickly with a visual selector
# Integrated with tmux-sessionizer functionality

# Note: Not using 'set -e' to allow interactive menus to handle errors gracefully

VERSION="2.1.0"

# Get script path at the beginning
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"

# Colors
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"

# Configuration paths
CONFIG_FILE_NAME="tmux-sessionizer.conf"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-sessionizer"
CONFIG_FILE="$CONFIG_DIR/$CONFIG_FILE_NAME"
PANE_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-sessionizer"
PANE_CACHE_FILE="$PANE_CACHE_DIR/panes.cache"

# Load configuration files
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

if [[ -f "$CONFIG_FILE_NAME" ]]; then
    source "$CONFIG_FILE_NAME"
fi

# Setup logging
if [[ $TS_LOG != "true" ]]; then
    if [[ -z $TS_LOG_FILE ]]; then
        TS_LOG_FILE="$HOME/.local/share/tmux-sessionizer/tmux-sessionizer.logs"
    fi
    mkdir -p "$(dirname "$TS_LOG_FILE")"
fi

# Logging function (optimizado con printf)
log() {
    if [[ -z $TS_LOG ]]; then
        return
    elif [[ $TS_LOG == "echo" ]]; then
        echo "$*"
    elif [[ $TS_LOG == "file" ]]; then
        printf '%(%Y-%m-%d %H:%M:%S)T - %s\n' -1 "$*" >> "$TS_LOG_FILE"
    fi
}

# Global variables for command line parsing
session_idx=""
session_cmd=""
user_selected=""
split_type=""

# === CACHE SYSTEM (bash 4.0+) ===
declare -g _CACHE_SESSIONS=""
declare -g _CACHE_SESSIONS_DETAILED=""
declare -g _CACHE_CURRENT_SESSION=""
declare -g _CACHE_PANES=""
declare -g _CACHE_TIMESTAMP=0
declare -g _CACHE_TTL=2  # segundos de validez
declare -gA _CACHE_WINDOWS_BY_SESSION

# Invalidar caché (llamar después de operaciones de modificación)
_cache_invalidate() {
    _CACHE_SESSIONS=""
    _CACHE_SESSIONS_DETAILED=""
    _CACHE_PANES=""
    _CACHE_WINDOWS_BY_SESSION=()
    _CACHE_TIMESTAMP=0
}

# Verificar si el caché es válido
_cache_is_valid() {
    local now
    printf -v now '%(%s)T' -1
    (( now - _CACHE_TIMESTAMP < _CACHE_TTL ))
}

# Obtener sesiones simples (con caché)
_get_sessions() {
    if [[ -z "$_CACHE_SESSIONS" ]] || ! _cache_is_valid; then
        _CACHE_SESSIONS=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | sort)
        printf -v _CACHE_TIMESTAMP '%(%s)T' -1
    fi
    printf '%s' "$_CACHE_SESSIONS"
}

# Obtener sesiones con detalles: nombre|ventanas|attached (con caché)
_get_sessions_detailed() {
    if [[ -z "$_CACHE_SESSIONS_DETAILED" ]] || ! _cache_is_valid; then
        _CACHE_SESSIONS_DETAILED=$(tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_attached}" 2>/dev/null | sort)
        printf -v _CACHE_TIMESTAMP '%(%s)T' -1
    fi
    printf '%s' "$_CACHE_SESSIONS_DETAILED"
}

# Obtener sesión actual (caché permanente durante ejecución)
_get_current_session() {
    if [[ -z "$_CACHE_CURRENT_SESSION" ]] && [[ -n "$TMUX" ]]; then
        _CACHE_CURRENT_SESSION=$(tmux display-message -p '#S' 2>/dev/null)
    fi
    printf '%s' "$_CACHE_CURRENT_SESSION"
}

# Obtener ventanas de una sesión (caché por sesión)
_get_windows() {
    local session="$1"
    local format="${2:-#{window_index}|#{window_name}|#{window_panes}|#{window_active}}"
    local cache_key="${session}:${format}"

    if [[ -z "${_CACHE_WINDOWS_BY_SESSION[$cache_key]}" ]] || ! _cache_is_valid; then
        _CACHE_WINDOWS_BY_SESSION[$cache_key]=$(tmux list-windows -t "$session" -F "$format" 2>/dev/null)
    fi
    printf '%s' "${_CACHE_WINDOWS_BY_SESSION[$cache_key]}"
}

# Obtener todos los panes (con caché)
_get_all_panes() {
    if [[ -z "$_CACHE_PANES" ]] || ! _cache_is_valid; then
        _CACHE_PANES=$(tmux list-panes -a -F "#{pane_id}" 2>/dev/null)
    fi
    printf '%s' "$_CACHE_PANES"
}

# Reordenar sesiones: actual primero, resto en orden original
_reorder_sessions_current_first() {
    local current="$1" sessions="$2"
    [[ -z "$current" ]] && { printf '%s' "$sessions"; return; }

    local current_line="" other_lines=""
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if [[ "$line" == "$current" ]] || [[ "$line" == "${current}|"* ]]; then
            current_line="$line"
        else
            other_lines+="${other_lines:+$'\n'}$line"
        fi
    done <<< "$sessions"

    if [[ -n "$current_line" ]]; then
        printf '%s' "$current_line"
        [[ -n "$other_lines" ]] && printf '\n%s' "$other_lines"
    else
        printf '%s' "$sessions"
    fi
}

# Helper functions
is_tmux_running() {
    # Si estamos dentro de tmux, ya está corriendo
    [[ -n "$TMUX" ]] && return 0
    # Verificar si el servidor tmux está disponible
    tmux list-sessions &>/dev/null
}

has_session() {
    local name="$1"
    local sessions
    sessions=$(_get_sessions)
    [[ $'\n'"$sessions"$'\n' == *$'\n'"$name"$'\n'* ]]
}

sanity_check() {
    if ! command -v tmux &>/dev/null; then
        echo -e "${RED}tmux is not installed. Please install it first.${RESET}"
        exit 1
    fi
}

# Get current session (only if inside tmux) - usando caché
CURRENT_SESSION=""
if [[ -n "$TMUX" ]]; then
    CURRENT_SESSION=$(_get_current_session)
fi

# Pane cache management
init_pane_cache() {
    mkdir -p "$PANE_CACHE_DIR"
    touch "$PANE_CACHE_FILE"
}

get_pane_id() {
    local session_idx="$1"
    local split_type="$2"
    init_pane_cache
    grep "^${session_idx}:${split_type}:" "$PANE_CACHE_FILE" 2>/dev/null | cut -d: -f3
}

set_pane_id() {
    local session_idx="$1"
    local split_type="$2"
    local pane_id="$3"
    init_pane_cache

    # Remove existing entry if it exists
    grep -v "^${session_idx}:${split_type}:" "$PANE_CACHE_FILE" > "${PANE_CACHE_FILE}.tmp" 2>/dev/null || true
    mv "${PANE_CACHE_FILE}.tmp" "$PANE_CACHE_FILE"

    # Add new entry
    echo "${session_idx}:${split_type}:${pane_id}" >> "$PANE_CACHE_FILE"
}

cleanup_dead_panes() {
    init_pane_cache
    local temp_file="${PANE_CACHE_FILE}.tmp"
    local all_panes
    all_panes=$(_get_all_panes)

    while IFS=: read -r idx split pane_id; do
        # Verificar si el pane existe usando bash puro
        if [[ $'\n'"$all_panes"$'\n' == *$'\n'"$pane_id"$'\n'* ]]; then
            echo "${idx}:${split}:${pane_id}" >> "$temp_file"
        fi
    done < "$PANE_CACHE_FILE"

    mv "$temp_file" "$PANE_CACHE_FILE" 2>/dev/null || touch "$PANE_CACHE_FILE"
}

# Session hydration
hydrate() {
    if [[ ! -z $session_cmd ]]; then
        log "skipping hydrate for $1 -- using \"$session_cmd\" instead"
        return
    elif [ -f "$2/.tmux-sessionizer" ]; then
        log "sourcing(local) $2/.tmux-sessionizer"
        tmux send-keys -t "$1" "source $2/.tmux-sessionizer" C-m
    elif [ -f "$HOME/.tmux-sessionizer" ]; then
        log "sourcing(global) $HOME/.tmux-sessionizer"
        tmux send-keys -t "$1" "source $HOME/.tmux-sessionizer" C-m
    fi
}

# Directory search function
find_dirs() {
    # Default search paths if not configured
    [[ -n "$TS_SEARCH_PATHS" ]] || TS_SEARCH_PATHS=(~/ ~/personal ~/personal/dev/env/.config)

    # Add extra search paths
    if [[ ${#TS_EXTRA_SEARCH_PATHS[@]} -gt 0 ]]; then
        TS_SEARCH_PATHS+=("${TS_EXTRA_SEARCH_PATHS[@]}")
    fi

    # List TMUX sessions (usando caché)
    local current_session=""
    [[ -n "${TMUX}" ]] && current_session=$(_get_current_session)

    local sessions_list
    sessions_list=$(_get_sessions)
    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        # Skip current session if inside tmux
        [[ -n "$current_session" ]] && [[ "$name" == "$current_session" ]] && continue
        echo "[TMUX] $name"
    done <<< "$sessions_list"

    # Search for directories in configured paths
    for entry in "${TS_SEARCH_PATHS[@]}"; do
        # Check if entry has :number suffix for depth
        if [[ "$entry" =~ ^([^:]+):([0-9]+)$ ]]; then
            path="${BASH_REMATCH[1]}"
            depth="${BASH_REMATCH[2]}"
        else
            path="$entry"
            depth="${TS_MAX_DEPTH:-1}"
        fi

        [[ -d "$path" ]] && find "$path" -mindepth 1 -maxdepth "${depth}" -path '*/.git' -prune -o -type d -print 2>/dev/null
    done
}

switch_to() {
    if [[ -z $TMUX ]]; then
        log "attaching to session $1"
        tmux attach-session -t "$1"
    else
        log "switching to session $1"
        tmux switch-client -t "$1"
    fi
}

# Function to switch with fzf (simple session list)
switch_with_fzf() {
    local current_session="$1"
    local FZF_BIN="${HOME}/.fzf/bin/fzf"

    # Check if fzf is available
    if ! command -v "$FZF_BIN" &>/dev/null && ! command -v fzf &>/dev/null; then
        echo -e "${RED}fzf is required${RESET}"
        read -p "Press Enter to close..."
        exit 1
    fi

    # Use installed fzf if available, otherwise use system fzf
    [[ -x "$FZF_BIN" ]] && local FZF_CMD="$FZF_BIN" || local FZF_CMD="fzf"

    # Get all sessions with details (usando caché)
    local sessions
    sessions=$(_get_sessions_detailed)

    if [ -z "$sessions" ]; then
        echo -e "${RED}No sessions found${RESET}"
        read -p "Press Enter to close..."
        exit 1
    fi

    # Format sessions for fzf
    local formatted_sessions=""
    while IFS='|' read -r name windows attached; do
        local marker="  "
        local color=""

        if [ "$name" = "$current_session" ]; then
            marker="● "
            color="${GREEN}"
        elif [ "$attached" = "1" ]; then
            marker="○ "
            color="${CYAN}"
        fi

        formatted_sessions+="${color}${marker}${name}${RESET} ${DIM}(${windows}w)${RESET}\n"
    done <<< "$sessions"

    # Use fzf to select session
    local selected
    selected=$(echo -e "$formatted_sessions" | \
        "$FZF_CMD" --ansi \
            --no-sort \
            --reverse \
            --border=rounded \
            --prompt="Sesión > " \
            --header="Actual: ${current_session} | ● actual ○ attached | Ctrl+x=eliminar" \
            --preview="tmux list-windows -t {2} -F '  [#{window_index}] #{window_name} #{?window_active,✓,}'" \
            --preview-window=right:50%:wrap \
            --expect='ctrl-x' \
            --header-first)

    if [ -z "$selected" ]; then
        exit 0
    fi

    # Parse result: first line is key, second is selection (bash puro)
    local key="${selected%%$'\n'*}"
    local choice="${selected##*$'\n'}"

    if [[ -z "$choice" ]]; then
        exit 0
    fi

    # Extract session name (bash puro: quitar marcador y obtener primera palabra)
    local session_name="${choice#[●○ ]}"
    session_name="${session_name#"${session_name%%[![:space:]]*}"}"
    session_name="${session_name%% *}"

    # Handle action
    case "$key" in
        ctrl-x)
            # Delete session
            if [ -n "$session_name" ]; then
                tmux confirm-before -p "¿Eliminar sesión $session_name? (y/n)" "kill-session -t $session_name"
            fi
            ;;
        "")
            # Enter pressed - switch to session
            if [ -n "$session_name" ] && [ "$session_name" != "$current_session" ]; then
                tmux switch-client -t "$session_name"
            fi
            ;;
    esac
}

# Hierarchical session/window switcher with fzf (flat hierarchical view)
switch_with_fzf_hierarchical() {
    local current_session="$1"
    local FZF_BIN="${HOME}/.fzf/bin/fzf"

    # Check if fzf is available
    if ! command -v "$FZF_BIN" &>/dev/null && ! command -v fzf &>/dev/null; then
        tmux display-message "fzf is required for hierarchical mode"
        return 1
    fi

    # Use installed fzf if available, otherwise use system fzf
    [[ -x "$FZF_BIN" ]] && local FZF_CMD="$FZF_BIN" || local FZF_CMD="fzf"

    # Get sessions - sorted alphabetically (usando caché)
    local all_sessions
    all_sessions=$(_get_sessions_detailed)

    if [[ -z "$all_sessions" ]]; then
        tmux display-message "No sessions found"
        return 1
    fi

    # Reorder: current session first (usando función helper)
    local sessions
    sessions=$(_reorder_sessions_current_first "$current_session" "$all_sessions")

    # Build hierarchical list: sessions with windows indented below
    local formatted=""
    formatted+="ACTION::new::::${CYAN}[+]${RESET} Nueva sesión\n"

    while IFS='|' read -r name windows attached; do
        [[ -z "$name" ]] && continue
        # Session line (4 fields for consistency)
        local marker="  "
        local color=""
        [[ "$name" == "$current_session" ]] && marker="● " && color="${GREEN}"
        [[ "$attached" == "1" ]] && [[ "$name" != "$current_session" ]] && marker="○ " && color="${CYAN}"
        formatted+="SESSION::${name}::::${color}${marker}${name}${RESET} ${DIM}(${windows}w)${RESET}\n"

        # Windows under this session (usando caché)
        local win_list
        win_list=$(_get_windows "$name" "#{window_index}|#{window_name}|#{window_panes}|#{window_active}")
        # Only process windows if we have data
        [[ -n "$win_list" ]] && while IFS='|' read -r idx wname panes active; do
            local wmarker="  "
            [[ "$active" == "1" ]] && wmarker="${GREEN}✓${RESET} "
            formatted+="WINDOW::${name}::${idx}::  ${wmarker}[${idx}] ${wname} ${DIM}(${panes}p)${RESET}\n"
        done <<< "$win_list"
    done <<< "$sessions"

    # Select with fzf with action keys
    local result
    result=$(echo -e "$formatted" | \
        "$FZF_CMD" \
            --ansi \
            --no-sort \
            --reverse \
            --height=80% \
            --border=rounded \
            --prompt='> ' \
            --header='Enter=ir | ^n=sesión | ^w=ventana | ^r=rename | ^x=eliminar | ^v/h=split' \
            --with-nth=4.. \
            --delimiter='::' \
            --expect='ctrl-n,ctrl-w,ctrl-x,ctrl-r,ctrl-v,ctrl-h' \
            --header-first)

    if [ -z "$result" ]; then
        return 0
    fi

    # Parse result: first line is the key pressed, second line is the selection (bash puro)
    local key="${result%%$'\n'*}"
    local selected="${result##*$'\n'}"

    if [[ -z "$selected" ]]; then
        return 0
    fi

    # Parse selection (format: TYPE::session::window::display_text) - bash puro
    local type="${selected%%::*}"
    local temp="${selected#*::}"
    local session_name="${temp%%::*}"
    temp="${temp#*::}"
    local window_idx="${temp%%::*}"

    # Handle action based on key pressed
    case "$key" in
        ctrl-n)
            # Create new session
            tmux command-prompt -p "Nueva sesión:" "new-session -ds '%%'; switch-client -t '%%'"
            ;;
        ctrl-w)
            # Create new window in selected session
            if [ "$type" = "SESSION" ] || [ "$type" = "WINDOW" ]; then
                tmux command-prompt -p "Nueva ventana en $session_name:" "new-window -t $session_name -n '%%'"
            fi
            ;;
        ctrl-x)
            # Delete selected item
            if [ "$type" = "SESSION" ]; then
                tmux confirm-before -p "¿Eliminar sesión $session_name? (y/n)" "kill-session -t $session_name"
            elif [ "$type" = "WINDOW" ]; then
                tmux confirm-before -p "¿Eliminar ventana $session_name:$window_idx? (y/n)" "kill-window -t $session_name:$window_idx"
            fi
            ;;
        ctrl-r)
            # Rename selected item
            if [ "$type" = "SESSION" ]; then
                tmux command-prompt -I "$session_name" -p "Renombrar sesión:" "rename-session -t '$session_name' '%%'"
            elif [ "$type" = "WINDOW" ]; then
                local current_name=$(tmux list-windows -t "$session_name:$window_idx" -F "#{window_name}" 2>/dev/null)
                tmux command-prompt -I "$current_name" -p "Renombrar ventana:" "rename-window -t '$session_name:$window_idx' '%%'"
            fi
            ;;
        ctrl-v)
            # Vertical split
            if [ "$type" = "WINDOW" ]; then
                tmux select-window -t "$session_name:$window_idx"
                tmux switch-client -t "$session_name"
                tmux split-window -v
            elif [ "$type" = "SESSION" ]; then
                tmux switch-client -t "$session_name"
                tmux split-window -v
            fi
            ;;
        ctrl-h)
            # Horizontal split
            if [ "$type" = "WINDOW" ]; then
                tmux select-window -t "$session_name:$window_idx"
                tmux switch-client -t "$session_name"
                tmux split-window -h
            elif [ "$type" = "SESSION" ]; then
                tmux switch-client -t "$session_name"
                tmux split-window -h
            fi
            ;;
        "")
            # Enter pressed - navigate to selection
            case "$type" in
                SESSION)
                    # Switch to session
                    tmux switch-client -t "$session_name"
                    ;;
                WINDOW)
                    # Switch to specific window in session
                    tmux select-window -t "$session_name:$window_idx"
                    tmux switch-client -t "$session_name"
                    ;;
                ACTION)
                    # Create new session action
                    if [ "$session_name" = "new" ]; then
                        tmux command-prompt -p "Nueva sesión:" "new-session -ds '%%'; switch-client -t '%%'"
                    fi
                    ;;
                SEPARATOR)
                    # Ignore separator lines
                    ;;
            esac
            ;;
    esac
}

# Function to switch with native tmux menu (fallback)
switch_with_menu() {
    local current_session="$1"

    # Build menu items (usando caché)
    local menu_items=""
    local sessions
    sessions=$(_get_sessions)

    if [ -z "$sessions" ]; then
        tmux display-message "No sessions found"
        exit 1
    fi

    while IFS= read -r session; do
        if [ "$session" = "$current_session" ]; then
            menu_items+="\"● $session\" '' \"switch-client -t $session\" "
        else
            menu_items+="\"  $session\" '' \"switch-client -t $session\" "
        fi
    done <<< "$sessions"

    # Show menu
    eval "tmux display-menu -T 'Switch Session (● = current)' $menu_items"
}

# Session command handlers
handle_window_session_cmd() {
    local current_session="$1"
    start_index=$((69 + $session_idx))
    target="$current_session:$start_index"

    log "target: $target command $session_cmd has-session=$(tmux has-session -t="$target" 2> /dev/null)"
    if tmux has-session -t="$target" 2> /dev/null; then
        switch_to "$target"
    else
        log "executing session command: tmux neww -dt $target $session_cmd"
        tmux neww -dt $target "$session_cmd"
        hydrate "$target" "$selected"
        tmux select-window -t $target
    fi
}

handle_split_session_cmd() {
    local current_session="$1"
    cleanup_dead_panes

    # Check if pane already exists
    local existing_pane_id=$(get_pane_id "$session_idx" "$split_type")
    local all_panes
    all_panes=$(_get_all_panes)

    if [[ -n "$existing_pane_id" ]] && [[ $'\n'"$all_panes"$'\n' == *$'\n'"$existing_pane_id"$'\n'* ]]; then
        log "switching to existing pane $existing_pane_id"
        tmux select-pane -t "$existing_pane_id"
        if [[ -z $TMUX ]]; then
            tmux attach-session -t "$current_session"
        else
            tmux switch-client -t "$current_session"
        fi
    else
        # Create new split
        local split_flag=""
        if [[ "$split_type" == "vsplit" ]]; then
            split_flag="-h"  # horizontal layout (vertical split)
        else
            split_flag="-v"  # vertical layout (horizontal split)
        fi

        log "creating new split: tmux split-window $split_flag -c $(pwd) $session_cmd"
        local new_pane_id=$(tmux split-window $split_flag -c "$(pwd)" -P -F "#{pane_id}" "$session_cmd")

        if [[ -n "$new_pane_id" ]]; then
            set_pane_id "$session_idx" "$split_type" "$new_pane_id"
            log "created pane $new_pane_id for session_idx=$session_idx split_type=$split_type"
        fi
    fi
}

handle_session_cmd() {
    log "executing session command $session_cmd with index $session_idx split_type=$split_type"
    if ! is_tmux_running; then
        echo -e "${RED}Error: tmux is not running. Please start tmux first before using session commands.${RESET}"
        exit 1
    fi

    current_session=$(tmux display-message -p '#S')

    if [[ -n "$split_type" ]]; then
        handle_split_session_cmd "$current_session"
    else
        handle_window_session_cmd "$current_session"
    fi
    exit 0
}

# Función genérica para ciclar sesiones (optimizado)
_cycle_session() {
    local direction="$1" current_session="$2"
    local sessions
    sessions=$(_get_sessions)

    # Usar mapfile para construir array eficientemente (bash 4.0+)
    local -a session_array
    mapfile -t session_array <<< "$sessions"

    local total=${#session_array[@]}
    if (( total <= 1 )); then
        tmux display-message "Only one session available"
        return 0
    fi

    # Encontrar índice actual
    local current_index=-1 i
    for i in "${!session_array[@]}"; do
        if [[ "${session_array[$i]}" == "$current_session" ]]; then
            current_index=$i
            break
        fi
    done

    # Calcular índice objetivo según dirección
    local target_index
    if [[ "$direction" == "next" ]]; then
        target_index=$(( (current_index + 1) % total ))
    else
        target_index=$(( (current_index - 1 + total) % total ))
    fi

    local target_session="${session_array[$target_index]}"
    tmux switch-client -t "$target_session"
    tmux display-message "Switched to: $target_session"
}

# Wrappers para cycle_next y cycle_prev
cycle_next() { _cycle_session "next" "$1"; }
cycle_prev() { _cycle_session "prev" "$1"; }

# Popup mode with numeric selection and inline windows (optimizado v2.1)
switch_with_popup() {
    local current_session="$1"

    # Precalcular datos de sesiones usando caché
    local sessions_data
    sessions_data=$(_get_sessions_detailed)

    if [[ -z "$sessions_data" ]]; then
        tmux display-message "No sessions found"
        return 1
    fi

    # Precalcular ventanas para cada sesión (máx 9 sesiones, 3 ventanas cada una)
    local -a session_names=()
    local -a session_windows_count=()
    local -a session_attached=()
    local -a session_windows_data=()

    local idx=0
    while IFS='|' read -r name windows attached; do
        [[ -z "$name" ]] && continue
        (( idx >= 9 )) && break

        session_names+=("$name")
        session_windows_count+=("$windows")
        session_attached+=("$attached")

        # Obtener primeras 3 ventanas
        local win_data=""
        local win_count=0
        local win_list
        win_list=$(_get_windows "$name" "#{window_name}|#{window_active}")
        while IFS='|' read -r w_name w_active; do
            [[ -z "$w_name" ]] && continue
            (( win_count >= 3 )) && break
            win_data+="${w_name}:${w_active};"
            ((win_count++))
        done <<< "$win_list"
        session_windows_data+=("$win_data")

        ((idx++))
    done <<< "$sessions_data"

    # Codificar datos para pasar al popup (sin archivo temporal)
    local encoded_sessions=""
    for i in "${!session_names[@]}"; do
        encoded_sessions+="${session_names[$i]}|${session_windows_count[$i]}|${session_attached[$i]}|${session_windows_data[$i]}"$'\x1E'
    done

    # Ejecutar popup inline con bash -c (sin archivo temporal)
    local selected
    if [[ -n "$TMUX" ]]; then
        selected=$(tmux display-popup -w 80% -h 70% -E bash -c '
# Colores
CYAN="\033[0;36m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"
RED="\033[0;31m"; BOLD="\033[1m"; DIM="\033[2m"; RESET="\033[0m"

current_session="$1"
encoded_data="$2"

# Decodificar sesiones
declare -a session_names=()
declare -a session_windows=()
declare -a session_attached=()
declare -a session_win_data=()

while IFS=$'\''\x1E'\'' read -r entry; do
    [[ -z "$entry" ]] && continue
    IFS="|" read -r name windows attached wins <<< "$entry"
    session_names+=("$name")
    session_windows+=("$windows")
    session_attached+=("$attached")
    session_win_data+=("$wins")
done <<< "$encoded_data"

# Display UI
clear
echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}║${RESET}              ${BOLD}SESSION MANAGER${RESET}                   ${DIM}v$3${RESET}  ${BOLD}${CYAN}║${RESET}"
echo -e "${BOLD}${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"
echo ""

for i in "${!session_names[@]}"; do
    num=$((i + 1))
    name="${session_names[$i]}"
    windows="${session_windows[$i]}"
    attached="${session_attached[$i]}"

    if [ "$name" = "$current_session" ]; then
        marker="●"; color="$GREEN"
    elif [ "$attached" = "1" ]; then
        marker="○"; color="$CYAN"
    else
        marker=" "; color=""
    fi

    echo -e "  ${BOLD}[${num}]${RESET} ${color}${marker} ${name}${RESET} ${DIM}(${windows}w)${RESET}"

    # Mostrar ventanas precalculadas
    IFS=";" read -ra wins <<< "${session_win_data[$i]}"
    for win in "${wins[@]}"; do
        [[ -z "$win" ]] && continue
        IFS=":" read -r w_name w_active <<< "$win"
        w_marker=" "
        [ "$w_active" = "1" ] && w_marker="✓"
        echo -e "       ${DIM}${w_marker} ${w_name}${RESET}"
    done
    echo ""
done

echo -e "${BOLD}${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"
echo -e "  ${BOLD}[D]${RESET} Buscar dirs   ${BOLD}[X]${RESET} Eliminar   ${BOLD}[N]${RESET} Nueva   ${BOLD}[Q]${RESET} Salir"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -ne "${YELLOW}Selección:${RESET} "

read -n 1 -s choice
echo ""

case "$choice" in
    [1-9])
        idx=$((choice - 1))
        if [ $idx -lt ${#session_names[@]} ]; then
            echo "${session_names[$idx]}"
        fi
        ;;
    [dD]) echo "__SEARCH_DIRS__" ;;
    [xX]) echo "__KILL_SESSION__" ;;
    [nN]) echo "__NEW_SESSION__" ;;
    *) exit 0 ;;
esac
' _ "$current_session" "$encoded_sessions" "$VERSION")
    else
        # Fallback para fuera de tmux - mostrar mensaje
        echo -e "${RED}Error: Must be run from within tmux${RESET}"
        return 1
    fi

    # Handle selection
    case "$selected" in
        "__SEARCH_DIRS__")
            search_and_create_session
            ;;
        "__KILL_SESSION__")
            local sessions_list
            sessions_list=$(_get_sessions)
            local session_to_kill
            session_to_kill=$(echo "$sessions_list" | fzf --prompt="Kill session: " --height=40% --reverse --border=rounded)
            if [[ -n "$session_to_kill" ]]; then
                tmux confirm-before -p "Kill session $session_to_kill? (y/n)" "kill-session -t \"$session_to_kill\""
            fi
            ;;
        "__NEW_SESSION__")
            tmux command-prompt -p "New session name:" "new-session -ds '%%'; switch-client -t '%%'"
            ;;
        ""|"$current_session")
            # Nada o sesión actual seleccionada
            ;;
        *)
            log "Switching to session: $selected"
            tmux switch-client -t "$selected"
            ;;
    esac
}

# Search directories and create session
search_and_create_session() {
    if ! command -v fzf &>/dev/null; then
        tmux display-message "fzf is required for directory search"
        return 1
    fi

    local selected
    selected=$(find_dirs | fzf --prompt="Select directory: " --height=40% --reverse --border=rounded)

    if [[ -z $selected ]]; then
        return 0
    fi

    # Handle existing tmux session selection
    if [[ "$selected" =~ ^\[TMUX\]\ (.+)$ ]]; then
        selected="${BASH_REMATCH[1]}"
        switch_to "$selected"
        return 0
    fi

    # Create new session from directory (bash puro)
    selected_name="${selected##*/}"
    selected_name="${selected_name//./_}"

    if ! is_tmux_running; then
        tmux new-session -ds "$selected_name" -c "$selected"
        hydrate "$selected_name" "$selected"
        switch_to "$selected_name"
    elif ! has_session "$selected_name"; then
        tmux new-session -ds "$selected_name" -c "$selected"
        hydrate "$selected_name" "$selected"
        switch_to "$selected_name"
    else
        switch_to "$selected_name"
    fi
}

# ============================================================================
# MENU-BASED SESSION MANAGER (v2.0) - Using native tmux display-menu
# ============================================================================

# Create direct tmux binding for SSH compatibility
create_menu_binding() {
    local current_session="$(tmux display-message -p '#S' 2>/dev/null || echo '')"

    # Build display-menu command directly (no run-shell)
    local cmd="display-menu -T 'SESSION MANAGER' -x C -y C"

    # Header
    cmd+=" '═══ SESIONES ═══' '' ''"
    cmd+=" '' '' ''"

    # List sessions with inline windows
    local idx=1
    while IFS='|' read -r name windows attached; do
        [[ -z "$name" ]] && continue

        # Session marker
        local marker=" "
        if [ "$name" = "$current_session" ]; then
            marker="●"
        elif [ "$attached" != "0" ]; then
            marker="○"
        fi

        # Session line
        cmd+=" '${marker} ${name} (${windows}w)' '${idx}' 'switch-client -t \"${name}\"'"
        cmd+=" '  ✕ eliminar' '' 'confirm-before -p \"Kill ${name}? (y/n)\" \"kill-session -t \\\"${name}\\\"\"'"

        # List first 3 windows
        local win_count=0
        while IFS='|' read -r w_idx w_name w_active w_panes; do
            [[ -z "$w_idx" ]] && continue
            ((win_count++))

            if [ $win_count -le 3 ]; then
                local w_marker=" "
                [ "$w_active" = "1" ] && w_marker="✓"
                cmd+=" '    ${w_marker} ${w_name} (${w_panes}p)' '' 'switch-client -t \"${name}\"; select-window -t \"${name}:${w_idx}\"'"
            fi
        done < <(tmux list-windows -t "$name" -F "#{window_index}|#{window_name}|#{window_active}|#{window_panes}" 2>/dev/null)

        # Separator
        cmd+=" '' '' ''"

        ((idx++))
        [ $idx -gt 9 ] && break
    done < <(tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_attached}" 2>/dev/null | sort)

    # Actions
    cmd+=" '═══ ACCIONES ═══' '' ''"
    cmd+=" '+ Nueva sesión' 'n' 'command-prompt -p \"Nombre:\" \"new-session -ds \\\"%%\\\"; switch-client -t \\\"%%\\\"\"'"
    cmd+=" '⎘ Renombrar' 'r' 'command-prompt -I \"#S\" -p \"Nuevo nombre:\" \"rename-session \\\"%%\\\"\"'"
    cmd+=" '🔍 Buscar dirs' 'd' 'run-shell \"${SCRIPT_PATH} search\"'"

    # Execute tmux bind-key directly - need eval to handle quotes properly
    eval "tmux bind-key -n M-m $cmd"
    echo "✓ Alt+m binding created successfully"
}

# Print display-menu command for SSH-compatible execution
print_menu_command() {
    local client_name="${1:-}"
    local current_session="$(tmux display-message -p '#S' 2>/dev/null || echo '')"

    # Start building command - include client for SSH compatibility
    local cmd="tmux display-menu"
    [[ -n "$client_name" ]] && cmd+=" -c '$client_name'"
    cmd+=" -T 'SESSION MANAGER' -x C -y C"

    # Build menu items (simplified version of create_menu_binding logic)
    cmd+=" '═══ SESIONES ═══' '' ''"
    cmd+=" '' '' ''"

    local idx=1
    while IFS='|' read -r name windows attached; do
        [[ -z "$name" ]] && continue
        local marker=" "
        [ "$name" = "$current_session" ] && marker="●" || { [ "$attached" != "0" ] && marker="○"; }
        cmd+=" '${marker} ${name} (${windows}w)' '${idx}' 'switch-client -t \"${name}\"'"
        ((idx++))
        [ $idx -gt 9 ] && break
    done < <(tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_attached}" 2>/dev/null | sort)

    cmd+=" '' '' ''"
    cmd+=" '═══ ACCIONES ═══' '' ''"
    cmd+=" '+ Nueva' 'n' 'command-prompt -p \"Nombre:\" \"new-session -ds %%%%\"'"

    echo "$cmd"
}

# Main menu: List sessions with inline windows (dynamic view)
switch_with_menu_v2() {
    local current_session="${1:-$(tmux display-message -p '#S' 2>/dev/null || echo '')}"

    # Build menu array
    local -a menu_items=()

    # Header
    menu_items+=("═══ SESIONES ═══" "" "")
    menu_items+=("" "" "")

    # List sessions with inline windows
    local idx=1
    while IFS='|' read -r name windows attached; do
        [[ -z "$name" ]] && continue

        # Session marker
        local marker=" "
        if [ "$name" = "$current_session" ]; then
            marker="●"
        elif [ "$attached" != "0" ]; then
            marker="○"
        fi

        # Session line with number shortcut
        menu_items+=("${marker} ${name} (${windows}w)" "${idx}" "switch-client -t '${name}'")
        menu_items+=("  ✕ eliminar" "" "confirm-before -p 'Kill ${name}? (y/n)' 'kill-session -t \"${name}\"'")

        # List windows inline (up to 3)
        local win_count=0
        while IFS='|' read -r w_idx w_name w_active w_panes; do
            [[ -z "$w_idx" ]] && continue
            ((win_count++))

            # Show first 3 windows
            if [ $win_count -le 3 ]; then
                local w_marker=" "
                [ "$w_active" = "1" ] && w_marker="✓"
                menu_items+=("    ${w_marker} ${w_name} (${w_panes}p)" "" "switch-client -t '${name}'; select-window -t '${name}:${w_idx}'")
            fi
        done < <(tmux list-windows -t "$name" -F "#{window_index}|#{window_name}|#{window_active}|#{window_panes}" 2>/dev/null)

        # If more than 3 windows, show "more" link
        if [ $win_count -gt 3 ]; then
            menu_items+=("    ... $((win_count - 3)) más >" "" "run-shell '${SCRIPT_PATH} __window_menu__ \"${name}\"'")
        fi

        # Separator between sessions
        menu_items+=("" "" "")

        ((idx++))
        [ $idx -gt 9 ] && break
    done < <(tmux list-sessions -F "#{session_name}|#{session_windows}|#{session_attached}" 2>/dev/null | sort)

    # Actions
    menu_items+=("═══ ACCIONES ═══" "" "")
    menu_items+=("+ Nueva sesión" "n" "command-prompt -p 'Nombre:' 'new-session -ds \"%%\"; switch-client -t \"%%\"'")
    menu_items+=("⎘ Renombrar sesión" "r" "command-prompt -I '#S' -p 'Nuevo nombre:' 'rename-session \"%%\"'")
    menu_items+=("🔍 Buscar directorios" "d" "run-shell '${SCRIPT_PATH} __search__'")
    menu_items+=("↻ Recargar" "l" "run-shell '${SCRIPT_PATH} __menu__'")

    # Display menu
    tmux display-menu -T "SESSION MANAGER" -x C -y C "${menu_items[@]}"
}

# Submenu: Windows for a specific session
show_window_menu() {
    local session="$1"
    local menu=""

    [[ -z "$session" ]] && {
        tmux display-message "Error: No session specified"
        return 1
    }

    # Verify session exists
    tmux has-session -t "$session" 2>/dev/null || {
        tmux display-message "Error: Session '$session' not found"
        return 1
    }

    # Header
    menu+="'═══ VENTANAS ═══' '' '' "
    menu+="'' '' '' "

    # List windows
    local idx=97  # ASCII 'a'
    local has_windows=0
    while IFS='|' read -r w_idx w_name w_active w_panes; do
        [[ -z "$w_idx" ]] && continue
        has_windows=1

        # Active marker
        local marker=" "
        [ "$w_active" = "1" ] && marker="✓"

        # Window letter
        local letter=$(printf "\\$(printf '%03o' $idx)")

        # Switch to window item
        menu+="'${marker} ${w_name} (${w_panes}p)' '${letter}' 'select-window -t ${session}:${w_idx}; switch-client -t ${session}' "

        ((idx++))
        [ $idx -gt 122 ] && break  # limit to a-z
    done < <(tmux list-windows -t "$session" -F "#{window_index}|#{window_name}|#{window_active}|#{window_panes}" 2>/dev/null)

    if [ $has_windows -eq 0 ]; then
        menu+="'(sin ventanas)' '' '' "
    fi

    # Actions separator
    menu+="'' '' '' "
    menu+="'═══ ACCIONES ═══' '' '' "

    # Window actions
    menu+="'+ Nueva ventana' 'w' 'command-prompt -p \"Nombre de ventana:\" \"new-window -t ${session} -n %%%%\"' "
    menu+="'⎘ Renombrar ventana' 'e' 'command-prompt -I \"#W\" -p \"Nuevo nombre:\" \"rename-window -t ${session}: %%%%\"' "
    menu+="'⊟ Split horizontal' 'h' 'switch-client -t ${session}; split-window -h' "
    menu+="'⊞ Split vertical' 'v' 'switch-client -t ${session}; split-window -v' "
    menu+="'✕ Kill ventana actual' 'x' 'confirm-before -p \"Kill ventana? (y/n)\" \"kill-window -t ${session}:\"' "
    menu+="'← Volver' 'q' 'run-shell \"${SCRIPT_PATH} __menu__\"' "

    # Display menu
    eval "tmux display-menu -T '📁 ${session}' -x C -y C ${menu}"
}

# Argument parsing
while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -h | --help)
        echo "Usage: tmux-session-switcher [OPTIONS] [MODE] [PATH]"
        echo ""
        echo "Modes:"
        echo "  popup    - Show popup overlay with numeric selection (default)"
        echo "  fzf      - Use fzf selector with preview"
        echo "  menu     - Use native tmux menu"
        echo "  manager  - Full session manager with windows (recommended)"
        echo "  next     - Cycle to next session"
        echo "  prev     - Cycle to previous session"
        echo "  search   - Search directories and create session"
        echo ""
        echo "Session Command Options:"
        echo "  -s, --session <idx>  Execute TS_SESSION_COMMANDS[idx]"
        echo "      --vsplit         Create vertical split for session command"
        echo "      --hsplit         Create horizontal split for session command"
        echo ""
        echo "Other Options:"
        echo "  -h, --help           Display this help message"
        echo "  -v, --version        Show version information"
        echo ""
        echo "Examples:"
        echo "  tmux-session-switcher popup        # Show popup switcher"
        echo "  tmux-session-switcher fzf          # Use fzf mode"
        echo "  tmux-session-switcher -s 0         # Execute session command 0"
        echo "  tmux-session-switcher -s 0 --vsplit  # Execute in vertical split"
        echo "  tmux-session-switcher search       # Search and create session"
        exit 0
        ;;
    -v | --version)
        echo "tmux-session-switcher version $VERSION"
        exit 0
        ;;
    -s | --session)
        session_idx="$2"
        if [[ -z $session_idx ]]; then
            echo -e "${RED}Error: Session index cannot be empty${RESET}"
            exit 1
        fi

        if [[ -z $TS_SESSION_COMMANDS ]]; then
            echo -e "${RED}Error: TS_SESSION_COMMANDS is not set in config${RESET}"
            echo "Set it in: $CONFIG_FILE"
            exit 1
        fi

        if [[ "$session_idx" -lt 0 || "$session_idx" -ge "${#TS_SESSION_COMMANDS[@]}" ]]; then
            echo -e "${RED}Error: Invalid index. Must be between 0 and $((${#TS_SESSION_COMMANDS[@]} - 1))${RESET}"
            exit 1
        fi

        session_cmd="${TS_SESSION_COMMANDS[$session_idx]}"
        shift
        ;;
    --vsplit)
        split_type="vsplit"
        ;;
    --hsplit)
        split_type="hsplit"
        ;;
    popup|fzf|menu|manager|next|prev|search|hierarchical)
        MODE="$1"
        ;;
    print-menu)
        # Print display-menu command for direct execution
        print_menu_command "$2"
        exit 0
        ;;
    show-menu)
        # Execute display-menu directly (SSH-compatible)
        # $2 should be the client name passed from tmux binding
        eval "$(print_menu_command "$2")"
        exit 0
        ;;
    bind-menu)
        # Create direct tmux binding (SSH-compatible solution)
        create_menu_binding
        exit 0
        ;;
    __menu__)
        # Internal: Show main manager menu
        switch_with_menu_v2 "${2:-$(tmux display-message -p '#S' 2>/dev/null || echo '')}"
        exit 0
        ;;
    __window_menu__)
        # Internal: Show window submenu for a session
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: __window_menu__ requires session name${RESET}"
            exit 1
        fi
        show_window_menu "$2"
        exit 0
        ;;
    __search__)
        # Internal: Directory search from menu
        search_and_create_session
        exit 0
        ;;
    *)
        user_selected="$1"
        ;;
    esac
    shift
done

# Validate split options are only used with session commands
if [[ -n "$split_type" && -z "$session_idx" ]]; then
    echo -e "${RED}Error: --vsplit and --hsplit can only be used with -s/--session option${RESET}"
    exit 1
fi

# Run sanity check
sanity_check

# Log execution
log "tmux-session-switcher($VERSION): mode=${MODE:-popup} idx=$session_idx cmd=$session_cmd user_selected=$user_selected split_type=$split_type"

# Handle session commands first
if [[ ! -z $session_cmd ]]; then
    handle_session_cmd
fi

# Handle direct path selection
if [[ ! -z $user_selected ]]; then
    selected="$user_selected"

    # Check if it's a tmux session reference
    if [[ "$selected" =~ ^\[TMUX\]\ (.+)$ ]]; then
        selected="${BASH_REMATCH[1]}"
    fi

    # Extraer nombre de sesión (bash puro)
    selected_name="${selected##*/}"
    selected_name="${selected_name//./_}"

    if ! is_tmux_running; then
        tmux new-session -ds "$selected_name" -c "$selected"
        hydrate "$selected_name" "$selected"
        switch_to "$selected_name"
    elif ! has_session "$selected_name"; then
        tmux new-session -ds "$selected_name" -c "$selected"
        hydrate "$selected_name" "$selected"
        switch_to "$selected_name"
    else
        switch_to "$selected_name"
    fi
    exit 0
fi

# Check if inside tmux for modes that require it
if [[ -z "$TMUX" ]] && [[ "${MODE:-popup}" != "search" ]]; then
    echo -e "${RED}Error: Must be run from within tmux for this mode${RESET}"
    exit 1
fi

# Main mode logic
MODE="${MODE:-popup}"

case "$MODE" in
    popup)
        switch_with_popup "$CURRENT_SESSION"
        ;;
    fzf)
        if command -v fzf &> /dev/null; then
            switch_with_fzf "$CURRENT_SESSION"
        else
            echo -e "${YELLOW}fzf not found, falling back to tmux menu${RESET}"
            switch_with_menu "$CURRENT_SESSION"
        fi
        ;;
    hierarchical)
        FZF_BIN="${HOME}/.fzf/bin/fzf"
        if command -v "$FZF_BIN" &> /dev/null || command -v fzf &> /dev/null; then
            switch_with_fzf_hierarchical "$CURRENT_SESSION"
        else
            echo -e "${YELLOW}fzf not found, falling back to tmux menu${RESET}"
            switch_with_menu "$CURRENT_SESSION"
        fi
        ;;
    menu)
        switch_with_menu "$CURRENT_SESSION"
        ;;
    manager)
        switch_with_menu_v2 "$CURRENT_SESSION"
        ;;
    next)
        cycle_next "$CURRENT_SESSION"
        ;;
    prev)
        cycle_prev "$CURRENT_SESSION"
        ;;
    search)
        search_and_create_session
        ;;
    *)
        echo -e "${RED}Unknown mode: $MODE${RESET}"
        echo "Run with --help for usage information"
        exit 1
        ;;
esac
