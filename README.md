# Monitor Control 

## Brightness

The [`brightness.sh`](./brightness.sh) script allows you to change the brightness of your monitors.

### Install

Copy the script to a global bin directory so it can be used as a command.

```bash
sudo cp brightness.sh /usr/local/bin/brightness
```

Grants permission for any user to execute.

```bash
sudo chmod +x /usr/local/bin/brightness
```

### Examples

See the help message for more usage details.

```bash
brightness --help
```

Find monitor name.
```bash
brightness --find
```

Set the brightness to 70% on a specific monitor 
```bash
brightness --brightness 0.7 --monitor HDMI-A-0
```

Reset brightness to 100% on a specific monitor.
```bash
brightness --reset --monitor HDMI-A-0
```

Increases brightness by 10% on a specific monitor.

```bash
brightness --up --step 10 --monitor HDMI-1
```

Decreases brightness by 5% on a specific monitor.

```bash
brightness --down --step 5 --monitor eDP-1
```

## i3WM

Control the screen brightness with i3WM. Add the lines below to the i3WM configuration file.

```bash
bindsym $mod+period exec --no-startup-id brightness --up --step 10 --monitor HDMI-A-0
```
```bash
bindsym $mod+comma exec --no-startup-id brightness --down --step 10 --monitor HDMI-A-0
```
```bash
bindsym $mod+m exec --no-startup-id brightness --reset --monitor HDMI-A-0
```

## Cron

The cron command-line utility is a task scheduler for Unix-like operating systems. It allows you to automate the execution of repetitive tasks.

For more information, see [Cron ArchWiki](https://wiki.archlinux.org/title/Cron).

To schedule a brightness filter for continuous execution at intervals defined by cron, run [`install.sh`](./install.sh).

Before installing, review the [`config`](./config) file, which allows you to control the brightness level and the interval for the task to run in cron, as well as the filter's operating schedule.

```bash
chmod +x install.sh
```

```bash
./install.sh
```

> After installation, the configuration file will be in `$HOME/.config/monitorctl/config`.

> If any problems occur, check the log file at `/tmp/monitorctl.log`.
