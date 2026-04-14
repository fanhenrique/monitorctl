#!/bin/bash

set -euo pipefail

command -v xrandr >/dev/null || { echo "xrandr not found"; exit 1; }
command -v bc >/dev/null || { echo "bc not found"; exit 1; }

MIN_BRIGHTNESS=0.2
MAX_BRIGHTNESS=3.0
# Step Up/Down brightnes by: 5 = ".05", 10 = ".10" ...
STEP=5 #TODO change to use float
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
    printf "  %-30s %s\n" "-c, --current" "Current monitor brightness"
    echo
    echo "Brightness options:"
    printf "  %-30s %-30s %s\n" "-b, --brightness [number]" "Brightness [$MIN_BRIGHTNESS-$MAX_BRIGHTNESS]" "(priority 1)"
    printf "  %-30s %-30s %s\n" "-r, --reset" "Reset brightness to 1.0" "(priority 2)"
    printf "  %-30s %-30s %s\n" "-u, --up" "Increase brightness" "(priority 3)"
    printf "  %-30s %-30s %s\n" "-d, --down" "Decrease brightness" "(priority 4)"
    printf "  %-30s %-30s %s\n" "-s, --step [number]" "Step brightness [default 0.5]" "(requires --up or --down)"
    echo
}

change_brightness() {

    local operation="$1"
    local monitor="$2"
    local step="$3"

    #  Validate: step must be between 0.0 and 1.0
    if ! [[ $(echo "$step >= 0 && $step <= 1" | bc -l) -eq 1 ]]; then
        echo "Error: step must be between 0.0 and 1.0"
        return 1
    fi
    
    # Get current brightness
    local current_brightness
    current_brightness=$(xrandr --verbose --current | grep "^$monitor" -A5 | grep -i brightness | awk '{print $2}')

    # Compute new brightness (with higher internal precision)
    local raw_brightness
    if [[ "$operation" == "up" ]]; then
        raw_brightness=$(echo "scale=4; $current_brightness + $step" | bc -l)
    elif [[ "$operation" == "down" ]]; then
        raw_brightness=$(echo "scale=4; $current_brightness - $step" | bc -l)
    else
        echo "Error: invalid operation"
        return 1
    fi

    # Ensure it does not go below minimum
    if (( $(echo "$raw_brightness < $MIN_BRIGHTNESS" | bc -l) )); then
        raw_brightness=$MIN_BRIGHTNESS
    fi

    # Ensure it does not exceed maximum
    if (( $(echo "$raw_brightness > $MAX_BRIGHTNESS" | bc -l) )); then
        raw_brightness=$MAX_BRIGHTNESS
    fi

    # Round to 2 decimal places
    local new_brightness
    new_brightness=$(printf "%.2f" "$raw_brightness")

    # Apply new brightness
    xrandr --output "$monitor" --brightness "$new_brightness"
}

# Display current brightness
function status(){
    printf "Monitor %s brightness changed to %s\n" \
        "$1" \
        "$(xrandr --verbose --current | grep "^$1" -A5 | tail -n1 | awk '/Brightness/ {print $2}')"
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
            STEP="$2"
            shift 2
            ;;
        -m|--monitor)
            shift
            while [[ $# -gt 0 && "$1" != -* ]]; do
                MONITORS+=("$1")
                shift
            done
            ;;
        -c|--current)
            OPERATION="current"
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
    echo "Error: At least one monitor is required."
    help
    exit 1
fi

if [[ -n "$BRIGHTNESS" ]]; then
    
    if (( $(echo "$BRIGHTNESS < $MIN_BRIGHTNESS" | bc -l) )) || (( $(echo "$BRIGHTNESS > $MAX_BRIGHTNESS" | bc -l) )); then
        echo "Error: Brightness must be between [$MIN_BRIGHTNESS-$MAX_BRIGHTNESS]"
        help
        exit 1
    fi

    for MONITOR in "${MONITORS[@]}"; do
        xrandr --output "$MONITOR" --brightness "$BRIGHTNESS"
        status "$MONITOR"
    done
    exit 0

elif [[ "$OPERATION" == "reset" ]]; then

    for MONITOR in "${MONITORS[@]}"; do
        xrandr --output "$MONITOR" --brightness 1.0
        status "$MONITOR"
    done
    exit 0

elif [[ "$OPERATION" == "up" ]]; then
    
    for MONITOR in "${MONITORS[@]}"; do
        change_brightness "up" "$MONITOR" "$STEP"
        status "$MONITOR"
    done
    exit 0

elif [[ "$OPERATION" == "down" ]]; then
    
    for MONITOR in "${MONITORS[@]}"; do
        change_brightness "down" "$MONITOR" "$STEP"
        status "$MONITOR"
    done
    exit 0

elif [[ "$OPERATION" == "current" ]]; then
    for MONITOR in "${MONITORS[@]}"; do
        status "$MONITOR"
    done
    exit 0
fi

echo "Error: No operation found"
help
exit 1