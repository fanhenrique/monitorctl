#!/bin/bash

printf "\nPre-installation ...\n\n"
sudo apt install redshift bc
printf "\nPre-installation Completed Successfully\n"


printf "\nStarting Installation ...\n\n"

# Copy the config file to /etc/monitorctl/config
sudo mkdir -p /etc/monitorctl
sudo cp config /etc/monitorctl
echo "config file copied to /etc/monitorctl/config"

# Makes the script "brightess.sh" a command
sudo cp brightness.sh /usr/local/bin/brightness
sudo chmod +x /usr/local/bin/brightness
echo "brightness.sh copied to /usr/local/bin/brightness"

# Makes the script "monitorctl.sh" a command
sudo cp monitorctl.sh /usr/local/bin/monitorctl
sudo chmod +x /usr/local/bin/monitorctl
echo "monitorctl.sh copied to /usr/local/bin/monitorctl"

# Create a service to control the monitor
sudo cp monitorctl.service /etc/systemd/system/monitorctl.service
echo "monitorctl.service copied to /etc/systemd/system/monitorctl.service"

# Make the service run at a time interval
sudo cp monitorctl.timer /etc/systemd/system/monitorctl.timer
echo "monitorctl.timer copied to /etc/systemd/system/monitorctl.timer"

printf "\nInstallation Completed Successfully\n"


printf "\nStarting the Monitor Control (monitorctl) Service ...\n\n"

sudo systemctl daemon-reload
echo "Reload systemd"

sudo systemctl start monitorctl.service
echo "Start monitorctl service"

sudo systemctl start monitorctl.timer
sudo systemctl enable --now monitorctl.timer
echo "Start monitorctl timer"

printf "\nMonitor Control Service (monitorclt) Started Successfully\n\n"