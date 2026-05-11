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

printf "\nStarting Configuration Systemd User Daemon ...\n"

source /usr/local/lib/monitorctl/utils

LOG_FILE=$(get_value 'LOG_FILE')
# INTERVAL=$(get_value 'INTERVAL') # Not used for systemd timer setup here, defined in timer file or could be dynamic

# Delete old log file
delete_log $LOG_FILE

# Remove legacy cron job if exists
(crontab -l 2>/dev/null | grep -v '/usr/local/lib/monitorctl/monitorctl') | crontab -
echo "Removed legacy cron job."

# Install Systemd Units
USER_SYSTEMD_DIR="$HOME/.config/systemd/user"
mkdir -p "$USER_SYSTEMD_DIR"
cp monitorctl.service "$USER_SYSTEMD_DIR/"
cp monitorctl.timer "$USER_SYSTEMD_DIR/"
echo "Copied systemd units to $USER_SYSTEMD_DIR"

systemctl --user daemon-reload
systemctl --user enable --now monitorctl.timer
echo "Systemd timer enabled and started."

printf "\nConfiguration Systemd User Daemon Completed Successfully\n"
