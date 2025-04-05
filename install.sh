#!/bin/bash

printf "\nPre-installation ...\n\n"
sudo apt install redshift bc
printf "\nPre-installation Completed Successfully\n"

printf "\nStarting Installation ...\n\n"

# Copy the config file to /etc/monitorctl/config
mkdir -p $HOME/.config/monitorctl
cp ./config $HOME/.config/monitorctl/config
echo "config file copied to $HOME/.config/monitorctl/config"

# Makes the script "brightess.sh" a command
sudo cp brightness.sh /usr/local/bin/brightness
sudo chmod +x /usr/local/bin/brightness
echo "brightness.sh copied to /usr/local/bin/brightness"

sudo mkdir -p /usr/local/lib/monitorctl

# Makes the script "monitorctl.sh" a library
sudo cp monitorctl.sh /usr/local/lib/monitorctl/monitorctl
sudo chmod +x /usr/local/lib/monitorctl/monitorctl
echo "monitorctl.sh copied to /usr/local/lib/monitorctl/monitorctl"

# Makes the script "utils.sh" a library
sudo cp utils.sh /usr/local/lib/monitorctl/utils
echo "utils.sh copied to /usr/local/lib/monitorctl/utils"

printf "\nInstallation Completed Successfully\n"

printf "\nStarting Configuration cron ...\n"

source /usr/local/lib/monitorctl/utils

LOG_FILE=$(get_value 'LOG_FILE')
INTERVAL=$(get_value 'INTERVAL')

# Delete old log file
delete_log $LOG_FILE

command $INTERVAL $LOG_FILE

printf "\nConfiguration cron Completed Successfully\n"
