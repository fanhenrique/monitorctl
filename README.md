# Monitor Control Service 

## Brightness

The [`brightness.sh`](./brightness.sh) script allows you to change the brightness of your monitors.

Copy the script to a global bin directory so it can be used as a command.

```bash
sudo cp brightness.sh /usr/local/bin/brightness
```

Grants permission for any user to execute.
```bash
sudo chmod +x /usr/local/bin/brightness
```

### Example

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
brigtness --brightness 0.7  --monitor HDMI-A-0
```

Reset brightness to 100% on a specific monitor.
```bash
brigtness --reset --monitor HDMI-A-0
```

Increases brightness by 10% on a specific monitor.

```bash
brigtness --up --step 10 --monitor HDMI-1
```

Decreases brightness by 5% on a specific monitor.

```bash
brigtness --down --step 5 --monitor eDP-1
```
