#!/bin/bash

CONFIG_FILE="/home/$(whoami)/.config/monitorctl/config"

get_value() {
    local variable="$1"
  grep "^$variable=" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' '
}

in_minutes() {
    local time="$1"

    # Check if the format is correct (HH:MM)
    if [[ ! "$time" =~ ^([0-9]{2}):([0-9]{2})$ ]]; then
        echo "Error: Invalid time format '$time'. Use HH:MM." >&2
        return 1
    fi

    local hours=${BASH_REMATCH[1]}
    local minutes=${BASH_REMATCH[2]}

    # Ensures that hours and minutes are valid numbers
    if (( hours < 0 || hours > 23 || minutes < 0 || minutes > 59 )); then
        echo "Error: Time outside valid range (00:00 - 23:59)." >&2
        return 1
    fi

    echo $((hours * 60 + minutes))
}

command(){
    local interval="$1"
    local log_file="$2"

    CRON_COMMAND="*/$interval * * * * /usr/local/lib/monitorctl/monitorctl >> $log_file 2>&1"

    # (crontab -l; echo "$CRON_COMMAND") | crontab -
    (crontab -l | grep -v '/usr/local/lib/monitorctl/monitorctl'; echo "$CRON_COMMAND") | crontab -

    echo "New cron job add:"
    echo "$CRON_COMMAND"
}

delete_log(){

    local log_file="$1"

    if [ -f "$log_file" ]; then
        printf "Log file deleted: $log_file\n"
        rm "$log_file"
    else
        printf "Log file not found: $log_file\n"
    fi
}