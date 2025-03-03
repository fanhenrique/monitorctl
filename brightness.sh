#!/bin/bash

function help(){
    echo
    echo "Usage: $0 [OPTIONS...]"
    echo
    echo "Brightness options:"
    echo "  -u, --up                        Up brightness"
    echo "  -d, --down                      Down brightness"
    echo "  -r, --reset                     Reset brightness to 1.0"
    echo "  -s, --step [number]             Step brightness (percentage) [default 5]"
    echo
    echo "Monitor options:"
    echo "  -m, --monitor [monitor name]    Monitor"
    echo "  -f, --find                      Find monitor name"
    echo
    echo "  -h, --help                      Show this help message"
    echo
}

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
    [[ "$1" == "reset" ]] && MathBright=100
    [[ "${MathBright:0:1}" == "-" ]] && MathBright=0    # Negative not allowed
    [[ "$MathBright" -gt 999  ]] && MathBright=999      # Can't go over 9.99

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

    # Display current brightness
    printf "Monitor %s:" "$2"
    echo | xrandr --verbose --current | grep ^"$2" -A5 | tail -n1
} 

function findMonitor(){
    # Find monitor name with: xrandr | grep "connected"
    xrandr | grep "connected"
}

STEP=5           # Step Up/Down brightnes by: 5 = ".05", 10 = ".10", etc.
OPERATION=""
MONITOR=""

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -u|--up)
            OPERATION="up"
            shift
            ;;
        -d|--down)
            OPERATION="down"
            shift
            ;;
        -r|--reset)
            OPERATION="reset"
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

brightnes "$OPERATION" "$MONITOR" "$STEP"
exit 0
