# Caelestia Tailscale widget

A Tailscale icon and popout for the [Caelestia shell](https://github.com/caelestia-dots/shell) bar, based
on the Omarchy [omarchy-tailscale](https://github.com/andrepadez/omarchy-tailscale) script and extended.
Pure QML: it reads `tailscale status --json` and `tailscale debug prefs` and acts through the
`tailscale` CLI.

Built against `caelestia-shell` 2.5.0, `quickshell-git` 0.3.1 and Tailscale 1.102.

## Features

From omarchy-tailscale:
- connection status in the bar
- start/stop Tailscale (`tailscale up` / `down`)
- list and switch accounts, cycle to the next account

Added:
- **Bar icon**: Tailscale logo tinted to the bar colour; dimmed when stopped; accent dot while an
  exit node is in use; red dot when logged out or waiting for approval
- **Devices**: this device and every peer with OS icon, Tailscale IP, online/idle/last seen,
  direct or relayed connection, traffic, expired keys; filter online/all; copy IP (button) or
  MagicDNS name (click the name)
- **Exit node**: pick a peer or none, allow LAN access, run this device as an exit node
- **Accounts**: switch, next account, add an account (`tailscale login`, opens the sign-in page)
- **Settings**: Tailscale DNS, accept subnet routes, shields up, Tailscale SSH, health warnings
  with links, account/tailnet/DNS suffix, widget notifications
- **Log in** button when logged out, admin console and copy-my-IP buttons, toasts on
  connect/disconnect and failed actions

## Permissions

Reading status works as your user. Changing anything (up/down, exit node, settings, switching
accounts) needs root unless your user is Tailscale's operator. The omarchy script uses `sudo` for
this, which a bar widget can't. Instead the popout shows **Allow control**, which runs
`pkexec tailscale set --operator=$USER` once (asks for your password). You can also run it yourself:

```bash
sudo tailscale set --operator=$USER
```

## Install

```bash
./install.sh
kill $(pgrep -x qs); qs -c caelestia -n -d
```

This adds the widget to the user copy of the Caelestia config at `~/.config/quickshell/caelestia`
(created from `/etc/xdg/quickshell/caelestia` if missing), patches four existing files with marked
lines (see `patch.py`) and adds its icon to a shared widget group above the clock (bar entry `plugins` in
`~/.config/caelestia/shell.json`).
It coexists with [caelestia-syncthing](../caelestia-syncthing) and [caelestia-sony](../caelestia-sony).

After a `caelestia-shell` update:

```bash
rm -rf ~/.config/quickshell/caelestia
~/Projects/caelestia-syncthing/install.sh
~/Projects/caelestia-sony/install.sh
~/Projects/caelestia-tailscale/install.sh
~/Projects/caelestia-webcam/install.sh
~/Projects/caelestia-screens/install.sh
```

Every install checks the shared **plugins** bar section (the widget group above the clock) and
creates or repairs it if any part is missing: the group file, the two edits in `Bar.qml` (restored
from Caelestia's own copy if they were mangled), and an enabled `plugins` entry in `bar.entries`.
It ends with `Plugins bar section: OK`, or stops and says what's wrong.

## Placement (optional)

With [caelestia-plugin-switcher](../caelestia-plugin-switcher) installed, this plugin can also be placed
in the dashboard's top strip instead of the right bar. Open **Nexus → Dashboard → Plugin switches**
and pick for this plugin:

- **Off**: hidden everywhere
- **Right bar**: the icon in the plugin group above the clock (default)
- **Top bar**: a tab in the dashboard, next to LocalSend and Notes

The tab is a fixed 840×480 pane with the same content as the popout. The tab uses the same Tailscale logo as the bar icon.

## Uninstall

```bash
./uninstall.sh
```

## Files

| File | Purpose |
| --- | --- |
| `files/services/Tailscale.qml` | Singleton: CLI calls, state, actions, settings |
| `files/modules/bar/components/status/TailscaleStatus.qml` | Bar icon |
| `files/modules/bar/popouts/TailscalePopout.qml` | Popout: header, permission banner, tabs, footer |
| `files/modules/bar/popouts/tailscale/` | Devices, Exit node, Accounts and Settings pages, small components |
| `files/assets/tailscale/tailscale.svg` | Tailscale logo |
| `patch.py` | Adds/removes the marked edits to Caelestia files |

## Credits

Tailscale logo SVG from [selfh.st/icons](https://selfh.st/icons/) (CC BY 4.0). Tailscale and its logo
belong to Tailscale Inc.
