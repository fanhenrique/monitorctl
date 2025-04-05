#!/bin/bash

export DISPLAY=$(who | awk '{print $5}' | sed 's/(//;s/)//' | head -n1)
export XAUTHORITY=$(xauth info | grep "Authority file" | awk '{ print $3 }')

source /usr/local/lib/monitorctl/utils

DAY_BRIGHTNESS=$(get_value "DAY_BRIGHTNESS")
NIGHT_BRIGHTNESS=$(get_value "NIGHT_BRIGHTNESS")

MONITOR=$(get_value "MONITOR")
INTERVAL=$(get_value "INTERVAL")
LOG_FILE=$(get_value "LOG_FILE")

START_NIGHT=$(get_value "START_NIGHT")
START_NIGHT=$(in_minutes "$START_NIGHT")

END_NIGHT=$(get_value "END_NIGHT")
END_NIGHT=$(in_minutes "$END_NIGHT")

NOW="$(date +"%H:%M")"
NOW=$(in_minutes "$NOW")

# Check if it is night or day
if [[ -n "$NOW" && -n "$START_NIGHT" && -n "$END_NIGHT" ]]; then
    # [00:00-END_NIGHT]
    # 00:00 in seconds = 0
    [[ $NOW -gt 0 && $NOW -lt $END_NIGHT ]] && BRIGHTNESS=$NIGHT_BRIGHTNESS
    # [END_NIGHT-START_NIGHT]
    [[ $NOW -gt $END_NIGHT && $NOW -lt $START_NIGHT ]] && BRIGHTNESS=$DAY_BRIGHTNESS
    # [START_NIGHT-23:59] 
    # 23:59 in seconds = 1439
    [[ $NOW -gt $START_NIGHT && $NOW -lt 1439 ]] && BRIGHTNESS=$NIGHT_BRIGHTNESS
else
    echo "Error: Time variables not set correctly." >&2
fi

CURRENT_BRIGHTNESS="$(xrandr --verbose --current | grep "^HDMI-A-0" -A5 | tail -n1 | awk '/Brightness/ {print $2}')"

# Update cron job if configuration file has changed
command $INTERVAL $LOG_FILE > /dev/null

if [ "$(echo "$CURRENT_BRIGHTNESS > $BRIGHTNESS" | bc -l)" -eq 1 ]; then
    # Unix time at the time of executing the below command
    printf "$(date +%s): "
    # Adjust brightness according to config file
    /usr/local/bin/brightness --brightness $BRIGHTNESS --monitor $MONITOR
fi

exit 0
