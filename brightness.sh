#!/bin/bash

set -euo pipefail

command -v xrandr >/dev/null || { echo "xrandr not found"; exit 1; }

XRANDR_OUTPUT=$(xrandr --verbose --current)
XRANDR_SIMPLE=$(xrandr)

MIN_BRIGHTNESS=0.3
MAX_BRIGHTNESS=3.0
# Step value (float between 0.0 and 1.0)
STEP=0.1

OPERATION=""
BRIGHTNESS=""
MONITORS=()

function help() {
    echo
    echo "Usage: $0 [OPTIONS...]"
    echo
    echo "Help:"
    printf "  %-30s %s\n" "-h, --help" "Show this help message"
    echo
    echo "Monitor options:"
    printf "  %-30s %s\n" "-m, --monitor [monitor name]" "Monitor (required)"
    printf "  %-30s %s\n" "-f, --find" "Find monitor name"
    printf "  %-30s %s\n" "--status" "Current monitor brightness"
    echo
    echo "Brightness options:"
    printf "  %-30s %-30s %s\n" "-b, --brightness [number]" "Brightness [$MIN_BRIGHTNESS-$MAX_BRIGHTNESS]" "(priority 1)"
    printf "  %-30s %-30s %s\n" "-r, --reset" "Reset brightness to 1.0" "(priority 2)"
    printf "  %-30s %-30s %s\n" "-u, --up" "Increase brightness" "(priority 3)"
    printf "  %-30s %-30s %s\n" "-d, --down" "Decrease brightness" "(priority 4)"
    printf "  %-30s %-30s %s\n" "-s, --step [number]" "Step brightness [default 0.1]" "(requires --up or --down)"
    echo
}

function is_connected() {
    grep -q "^$1 connected" <<< "$XRANDR_SIMPLE"
}

function get_brightness() {
    awk -v m="$1" '
    $0 ~ "^"m" " {found=1; next}
    found && /Brightness:/ {print $2; exit}
    found && /^[^ \t]/ {exit}
    ' <<< "$XRANDR_OUTPUT"
}

function change_brightness() {

    local operation="$1"
    local monitor="$2"
    local step="$3"

    # Validate monitor
    if ! is_connected "$monitor"; then
        echo "Error: monitor '$monitor' not found"
        return 1
    fi

    #  Validate: step must be between 0.0 and 1.0
    if ! awk -v s="$step" 'BEGIN { exit !(s >= 0 && s <= 1) }'; then
        echo "Error: step must be between 0.0 and 1.0 (precision 1 decimal)"
        return 1
    fi
    
    # Get current brightness
    local current_brightness
    current_brightness=$(get_brightness "$monitor")
    
    if [[ -z "$current_brightness" ]]; then
        echo "Warning: could not detect brightness for '$monitor'"
        return 0
    fi

    # Compute new brightness (with higher internal precision)
    local raw_brightness
    if [[ "$operation" == "up" ]]; then
        raw_brightness=$(awk -v a="$current_brightness" -v b="$step" 'BEGIN {printf "%.4f", a + b}')
    elif [[ "$operation" == "down" ]]; then
        raw_brightness=$(awk -v a="$current_brightness" -v b="$step" 'BEGIN {printf "%.4f", a - b}')
    else
        echo "Error: invalid operation"
        return 1
    fi

    # Ensure it does not go below minimum
    if awk -v a="$raw_brightness" -v b="$MIN_BRIGHTNESS" 'BEGIN {exit !(a < b)}'; then
        raw_brightness=$MIN_BRIGHTNESS
    fi

    # Ensure it does not exceed maximum
    if awk -v a="$raw_brightness" -v b="$MAX_BRIGHTNESS" 'BEGIN {exit !(a > b)}'; then
        raw_brightness=$MAX_BRIGHTNESS
    fi

    # Round to 2 decimal places
    local new_brightness
    new_brightness=$(printf "%.2f" "$raw_brightness")

    # Apply new brightness
    xrandr --output "$monitor" --brightness "$new_brightness"
}

# Display current status brightness
function status() {
    local monitor="$1"
    local value
    value=$(get_brightness "$monitor")

    if [[ -z "$value" ]]; then
        value="unknown"
    fi
    printf "Monitor %s brightness: %s\n" "$monitor" "$value"
}

function findMonitor(){
    # Find monitor name with: xrandr | grep "connected"
    xrandr | grep "connected"
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -b|--brightness)
            [[ $# -lt 2 ]] && { echo "Missing value for $1"; exit 1; }
            BRIGHTNESS="$2"
            shift 2
            ;;
        -r|--reset)
            OPERATION="reset"
            shift
            ;;
        -u|--up)
            [[ "$OPERATION" != 'reset' ]] && OPERATION="up"
            shift
            ;;
        -d|--down)
            [[ "$OPERATION" != 'reset' && "$OPERATION" != 'up' ]] && OPERATION="down"
            shift
            ;;
        -s|--step)
            [[ $# -lt 2 ]] && { echo "Missing value for $1"; exit 1; }
            STEP="$2"
            if ! awk -v s="$STEP" 'BEGIN {exit !(s >= 0 && s <= 1)}'; then
                echo "Error: step must be between 0.0 and 1.0"
                exit 1
            fi
            shift 2
            ;;
        -m|--monitor)
            shift
            while [[ $# -gt 0 && "$1" != -* ]]; do
                MONITORS+=("$1")
                shift
            done
            ;;
        --status)
            OPERATION="status"
            shift
            ;;
        -f|--find)
            findMonitor
            exit 0
            ;;
        -h|--help)
            help
            exit 0
            ;;
        *)
            echo "Invalid option: $1"
            help
            exit 1
            ;;
    esac
done

if [[ ${#MONITORS[@]} -eq 0 ]]; then
    if [[ "$OPERATION" == "status" ]]; then
        # Auto-detect all monitors
        mapfile -t MONITORS < <(xrandr | awk '/ connected/ {print $1}')
    else
        echo "Error: At least one monitor is required."
        help
        exit 1
    fi
fi

if [[ -n "$BRIGHTNESS" ]]; then

    if awk -v a="$BRIGHTNESS" -v min="$MIN_BRIGHTNESS" -v max="$MAX_BRIGHTNESS" 'BEGIN {exit !(a < min || a > max)}'; then
        echo "Error: Brightness must be between [$MIN_BRIGHTNESS-$MAX_BRIGHTNESS]"
        help
        exit 1
    fi

    for monitor in "${MONITORS[@]}"; do
        xrandr --output "$monitor" --brightness "$BRIGHTNESS"
        status "$monitor"
    done
    exit 0

elif [[ "$OPERATION" == "reset" ]]; then
    for monitor in "${MONITORS[@]}"; do
        xrandr --output "$monitor" --brightness 1.0
        status "$monitor"
    done
    exit 0

elif [[ "$OPERATION" == "up" ]]; then
    for monitor in "${MONITORS[@]}"; do
        change_brightness "up" "$monitor" "$STEP"
        status "$monitor"
    done
    exit 0

elif [[ "$OPERATION" == "down" ]]; then
    
    for monitor in "${MONITORS[@]}"; do
        change_brightness "down" "$monitor" "$STEP"
        status "$monitor"
    done
    exit 0

elif [[ "$OPERATION" == "status" ]]; then
    for monitor in "${MONITORS[@]}"; do
        status "$monitor"
    done
    exit 0
fi

echo "Error: No operation found"
help
exit 1