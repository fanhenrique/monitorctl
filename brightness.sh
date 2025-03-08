#!/bin/bash

MIN_BRIGHTNESS=0.2
MAX_BRIGHTNESS=3.0
# Step Up/Down brightnes by: 5 = ".05", 10 = ".10" ...
STEP=5 #TODO change to use float
OPERATION=""
BRIGHTNESS=""
MONITOR=""

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

# TODO change to use bc
# This function was adapted from the script:
# https://askubuntu.com/questions/1150339/increment-brightness-by-value-using-xrandr
function brightnes(){ 

    CurrBright=$( xrandr --verbose --current | grep ^"$2" -A5 | tail -n1 )
    CurrBright="${CurrBright##* }"  # Get brightness level with decimal place

    Left=${CurrBright%%"."*}        # Extract left of decimal point
    Right=${CurrBright#*"."}        # Extract right of decimal point

    MathBright="0"
    [[ "$1" == "up" && "$Left" != 0 && "$3" -lt 10 ]] && STEP=10   # > 1.0, only .1 works and up
    [[ "$Left" != 0 ]] && MathBright="$Left"00                      # 1.0 becomes "100"
    [[ "${#Right}" -eq 1 ]] && Right="$Right"0                      # 0.5 becomes "50"
    MathBright=$(( MathBright + Right ))

    [[ "$1" == "up" ]] && MathBright=$(( MathBright + STEP ))
    [[ "$1" == "down" ]] && MathBright=$(( MathBright - STEP ))

    [[ "${MathBright:0:1}" == "-" ]] && MathBright=0    # Negative not allowed
    [[ "$MathBright" -gt 299  ]] && MathBright=299      # Can't go over 2.99

    # Ensure MathBright is never less than 0.2
    [[ "$MathBright" -lt 20 ]] &&  MathBright=20
    
    if [[ "${#MathBright}" -eq 3 ]] ; then
        MathBright="$MathBright"000         # Pad with lots of zeros
        CurrBright="${MathBright:0:1}.${MathBright:1:2}"
    else
        MathBright="$MathBright"000         # Pad with lots of zeros
        CurrBright=".${MathBright:0:2}"
    fi

    xrandr --output "$2" --brightness "$CurrBright"   # Set new brightness
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
            MONITOR="$2"
            shift 2
            ;;
        -c|--current)
            status "$2"
            exit 0
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

if [[ -z "$MONITOR" ]]; then
    echo "Error: A monitor name is required."
    help
    exit 1
fi

if [[ -n "$BRIGHTNESS" ]]; then
    
    if (( $(echo "$BRIGHTNESS < $MIN_BRIGHTNESS" | bc -l) )) || (( $(echo "$BRIGHTNESS > $MAX_BRIGHTNESS" | bc -l) )); then
        echo "Error: Brightness must be between [$MIN_BRIGHTNESS-$MAX_BRIGHTNESS]"
        help
        exit 1
    fi

    xrandr --output "$MONITOR" --brightness "$BRIGHTNESS"
    status "$MONITOR"
    exit 0

elif [[ "$OPERATION" == "reset" ]]; then

    xrandr --output "$MONITOR" --brightness 1.0
    status "$MONITOR"
    exit 0

elif [[ "$OPERATION" == "up" ]]; then
    
    brightnes "up" "$MONITOR" "$STEP"
    status "$MONITOR"
    exit 0

elif [[ "$OPERATION" == "down" ]]; then
    
    brightnes "down" "$MONITOR" "$STEP"
    status "$MONITOR"
    exit 0
fi

echo "Error: No operation found"
help
exit 1