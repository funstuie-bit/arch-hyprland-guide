# Screen sharing from the MacBook

Configured September 15, 2026 with Arch's WayVNC 0.10.1. This shares the **existing Hyprland desktop**, not a separate session. People at the Mac mini see and control the same applications.

## Connect and control

1. Keep both machines on the home LAN and the Mac mini awake with Hyprland running.
2. On the MacBook, open Finder → Go → Connect to Server (**Command+K**).
3. Connect to **`vnc://192.168.1.66`**. Apple Screen Sharing should open.
4. Use the separate, case-sensitive VNC password—not the Linux login password. On the Mac mini, find it in **Settings → Sound & connections → Screen sharing → Show password**.

The Screen sharing panel can change the password, choose a current local address, and enable/disable sharing now and at login. Use exactly **eight printable ASCII characters without spaces** for the password, then Save changes. Saving restarts an active server and disconnects viewers; it does not start a stopped server. Enable sharing starts it afterwards. Close the panel with its title-bar close button or **Super+W**; closing the panel does not disable sharing.

The server shares 5120×2160 and prevents viewers from changing the physical monitor resolution. Use the Mac viewer's scaling/fit controls. VNC does not carry audio. Remote unlocking, sleep, cold boot, disconnected-monitor/headless behaviour, and physical MacBook input have not been validated. This setup is for the running desktop.

## Security and addressing

The user explicitly chose direct home-LAN access instead of an SSH tunnel. [WayVNC's documentation](https://github.com/any1/wayvnc#des-authentication-legacy) explains the legacy DES authentication required by Apple's client: **the session is unencrypted**, and only eight password characters count. Use this only on a trusted network. For untrusted networks use SSH tunnelling or a VPN. **Never forward port 5900 on the router.**

The server binds to **192.168.1.66:5900**, not every interface. This is not a source-IP firewall rule: routed networks or router forwarding could still expose it. No firewall, router, or SSH settings were changed. The address is assigned by DHCP; a router reservation is advisable for a stable address. If it changes, choose the new address in the panel, save, and enable sharing.

The private password lives in `~/.config/wayvnc/config` (mode 0600; directory 0700), never in GitHub. Do not post that file with diagnostics.

## Implementation and verification

- User service: `~/.config/systemd/user/wayvnc.service`, capturing DP-1 with `--disable-resizing --max-fps=30`.
- `screen-sharing-start.sh` imports the Wayland environment after Hyprland starts and starts the service **only if enabled**. This session does not activate `graphical-session.target` itself.
- Panel: `~/.local/share/desktop-settings/app/sharing.py`.
- The desktop installer supplies the optional service and panel but **does not install WayVNC, generate credentials, or enable VNC by default**.

Useful checks:

```bash
systemctl --user status wayvnc.service
ss -ltn 'sport = :5900'
wayvncctl output-list
wayvncctl client-list
journalctl --user -u wayvnc.service -n 30
```

The opt-in local test `python tests/vnc_smoke.py --live` passed wrong-password rejection, correct authentication, native desktop dimensions, and live one-pixel capture. It never prints the password or sends keyboard/mouse events. Actual MacBook connection still needs user confirmation.

For deliberate setup on another machine: install `wayvnc` with pacman, deploy the unit and startup helper, create the private config with the correct local `address`, `port=5900`, `enable_auth=true`, and a unique eight-character `password`. Apple-compatible direct mode also requires `relax_encryption=true` and `allow_broken_crypto=true`, accepting the warning above. Adjust DP-1 in the unit if necessary. Then reload systemd user units, import the session's WAYLAND_DISPLAY, and enable/start the unit. Never use a published example password.
