# Monitor Control Service 

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

### i3WM

Control screen brightness with i3WM. Add to i3wm configuration file.

```bash
bindsym $mod+period exec --no-startup-id brightness --up --step 10 --monitor HDMI-A-0
```
```bash
bindsym $mod+comma exec --no-startup-id brightness --down --step 10 --monitor HDMI-A-0
```
```bash
bindsym $mod+m exec --no-startup-id brightness --reset --monitor HDMI-A-0
```
