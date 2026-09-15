# Arch Linux + Hyprland on a 2018 Mac mini

A personal Arch desktop configuration for a **Macmini8,1 with Apple T2 and Intel UHD 630 graphics**, using Hyprland, Waybar, Rofi, Foot, Mako, and PipeWire.

This repository contains a **post-install setup script**, desktop configuration, and a network recovery script. It does not partition disks or install the base operating system. It does not install Omarchy.

Reviewed against the repository and running machine on **September 14, 2026**. The desktop repairs below have been checked on this Mac; a complete fresh installation using the revised scripts has **not** been tested end to end. [HANDOVER.md](HANDOVER.md) records the repair history; its older sections include superseded instructions.

## 1. Current desktop

| Component | Current configuration |
| --- | --- |
| System | Arch Linux, T2 kernel, Hyprland 0.56.2 |
| Display | Dell U4021QW on DP-1, 5120×2160 at 30 Hz, 100% scaling |
| Networking | NetworkManager with systemd-resolved; wired internet on enp1s0 |
| Internal T2 network interface | Automatic DHCP disabled on its existing NetworkManager profile |
| Audio | Stereo external speakers through the 3.5 mm jack; user confirmed working |
| Volume keys | Bottom-center volume/mute popup using Mako |
| Window controls | Super+T toggles tiled/floating; Super+J changes split direction; keyboard/mouse resizing |
| Help | Super+K opens the searchable shortcut list |
| Settings | Super+, or the top-bar gear opens graphical desktop settings |

The default configuration uses dark Catppuccin-style colors. Settings now provides four coordinated themes, an accent-color picker, and wallpaper controls; choosing a theme is optional.

### Change the desktop without editing configuration files

Open **Settings** using **Super+,** (Command+comma on an Apple keyboard), the **gear in the top bar**, or by searching for **Settings** in the application launcher (Super+Space).

- **Appearance:** choose Midnight, Northern sky, Forest, or Warm paper, optionally pick an accent color, then click Apply theme. This updates window borders, the bar, launcher, notifications, and colors in newly opened Foot terminals. Other applications may have their own theme settings.
- **Wallpaper:** choose one of the three included backgrounds or browse for your own image, choose how it fits, then apply. It applies to all connected monitors; a managed copy is kept so moving the original image does not break it.
- **Undo last appearance change:** restores the previous theme or wallpaper change, including across app restarts. This is one-step undo, not a history. It refuses to overwrite configuration files edited elsewhere since that change.
- **Display:** choose a monitor, an advertised resolution/refresh rate, and scaling. Preview changes before keeping them. The dialog reverts after 20 seconds; an independent 25-second recovery timer also runs if the app closes or crashes. Only Keep saves the setting. The existing 5120×2160 at 30 Hz, 100% configuration is unchanged until you choose otherwise.
- **Sound & connections:** open the installed sound, network, Wi-Fi, and Bluetooth controls.
- **Shortcuts & help:** see common shortcuts and open the searchable cheatsheet or this guide.

Settings runs as your regular user and needs no administrator password for appearance changes. It is a small app maintained in this repository, not a complete desktop-environment control center. Lock-screen styling and application-specific preferences are not managed here.

## 2. Install the base system

### Prepare the Mac and installation media

Follow the [T2 Linux pre-installation guide](https://wiki.t2linux.org/guides/preinstall/) for partition planning, firmware preparation, and boot settings. In macOS Recovery, Startup Security Utility must allow Linux to boot: set Secure Boot to **No Security** and allow external boot media.

Use the [current T2 Arch ISO](https://github.com/t2linux/archiso-t2/releases/latest). Follow its instructions to write it to a USB drive, then boot while holding Option. Flashing an image overwrites the selected USB drive.

Use the [T2 Arch installation guide](https://wiki.t2linux.org/distributions/arch/installation/) for the base installation. Its guided command is currently:

```bash
t2archinstall
```

Follow the ISO's current instructions if its commands or menus change. Install a T2-capable kernel and configure its boot entry before rebooting. Do not assume a generic Arch kernel provides equivalent T2 support.

For this desktop, use a minimal base system, a regular user with sudo privileges, Bash for the automatic desktop startup described below, and **NetworkManager** for networking. The post-install script supplies PipeWire and the desktop packages.

### Have networking ready before the first reboot

Use onboard Ethernet during setup if available. Wi-Fi depends on suitable firmware, but it is **not inherently an AUR-only, post-install task**: the T2 Arch guide includes `apple-bcm-firmware` in the base installation. See the [T2 Wi-Fi/Bluetooth guide](https://wiki.t2linux.org/guides/wifi-bluetooth/) for firmware alternatives and current driver issues.

While still in the installed system's **chroot**, with working access to its package repositories:

```bash
pacman -Syu --needed networkmanager openssh sudo git curl
systemctl disable systemd-networkd.service systemd-networkd.socket systemd-networkd-wait-online.service
systemctl enable NetworkManager.service systemd-resolved.service sshd.service
ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

These commands enable services for the installed system's next boot; they do not start services inside the chroot. A message that a networkd unit was not enabled is harmless. Ensure the regular user has a password and sudo access through the base installer.

Use one network manager per interface. Do not also enable networkd or a separate DHCP service on the Ethernet interface managed by NetworkManager. NetworkManager and systemd-resolved perform different jobs and can run together.

After boot, verify:

```bash
nmcli device status
ip -4 route
readlink -e /etc/resolv.conf
getent hosts archlinux.org
systemctl is-active NetworkManager systemd-resolved sshd
```

Interface names must be checked on the actual machine. On this Mac, `enp1s0` is the external Ethernet port; `enp2s0f1u1` is the **internal Apple T2 USB network device**, not another internet connection.

### Recovery only: already installed, but no network

A minimal install can lack a configured network service; it does not inevitably lack one.

If NetworkManager is installed, start it and use its tools:

```bash
sudo systemctl enable --now NetworkManager systemd-resolved
sudo ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
nmcli device status
nmtui
```

If NetworkManager is unavailable and this repository is already accessible from local storage or USB, run from the repository directory:

```bash
sudo bash bootstrap-network.sh
```

The script configures networkd for detected external wired interfaces, skips the internal T2 interface, enables resolved, and attempts to install Git, NetworkManager, and OpenSSH. It refuses to run while NetworkManager is active. It needs a working wired uplink and package access; ping failures are warnings, not proof of success.

It leaves networkd handling the recovery connection. The desktop installer later switches to NetworkManager, which can interrupt an SSH session. Prefer completing the NetworkManager setup before remote desktop installation.

Do not run this recovery script on a machine that already has working NetworkManager networking.

## 3. Install this desktop

From the Mac's terminal, or over SSH once networking is verified:

```bash
git clone https://github.com/funstuie-bit/arch-hyprland-guide.git
cd arch-hyprland-guide
./install.sh
```

Run as the regular desktop user, **not** as root or with `sudo ./install.sh`. The script invokes sudo itself. `--yes` skips its overall confirmation prompt; package installation also uses noninteractive options.

### What the installer actually changes

- Runs a full Arch package upgrade with the core desktop packages. Core package failure stops installation before dotfile deployment.
- Attempts optional applications, a downloaded Cliamp binary, and AUR packages. Optional failures can be skipped: the final success banner does not prove every application installed.
- Enables NetworkManager, systemd-resolved, Bluetooth, and attempts to enable Ollama. Disables networkd's service and disables automatic connection on existing profiles identified as the internal T2 device.
- Moves existing `hypr`, `waybar`, `rofi`, `foot`, and `mako` configuration directories to `~/.config_backup_TIMESTAMP/`, then copies repository versions into `~/.config/`.
- Installs the Cliamp desktop entry, makes helper scripts executable, and creates `~/Pictures/Screenshots/`.
- Installs the graphical Settings app, its launcher entry, and three original wallpapers, with Python/GTK dependencies.
- Adds eza/bat aliases and zoxide initialization to the shell configuration. Installing fzf does not itself mean its shell keybindings have been enabled.
- On detected T2 hardware, configures the community `arch-mact2` repository if missing and installs the T2 kernel, audio configuration, firmware, and fan daemon. Adds the missing Mac mini audio profile when applicable.
- Writes this setup's Intel graphics workarounds, rebuilds initramfs, and may modify bootloader configuration.
- Enables **passwordless tty1 autologin** and adds a Bash profile block that launches `Hyprland`.

The script uses a hard-coded community mirror and `SigLevel = Never` when adding `arch-mact2`; that repository is not an official Arch repository, and this setting disables signature checking for it. Consult the [current T2 repository instructions](https://wiki.t2linux.org/distributions/arch/installation/) before a new installation.

The systemd-boot code expects entries under `/boot/loader/entries` and derives kernel options from the first other entry it finds. It is not a general bootloader installer. Review the resulting entry, root options, kernel and initramfs paths before rebooting, especially with encryption or multiple entries.

**Do not rerun the whole installer just to update a shortcut or theme.** Its backup covers the listed desktop directories, not every system file it changes.

### Applications and package sources

The arrays in [install.sh](install.sh) are the authoritative package list.

| Source | Packages or applications |
| --- | --- |
| Official Arch repositories, required by this script | Hyprland, Waybar, Rofi, Foot, Mako, PipeWire, WirePlumber, Thunar, pavucontrol, portals, polkit agent, network/Bluetooth tools, fonts, clipboard and screenshot tools, hyprlock, hypridle |
| Official Arch repositories, attempted as optional apps | btop, dua-cli, fastfetch, tmux, zoxide, fzf, ripgrep, fd, bat, eza, tealdeer, yt-dlp, imv, mpv, gnome-disk-utility, Obsidian, Evince, Xournal++, LibreOffice, Pinta, OBS, Kdenlive, Neovim, github-cli, mise, Firefox, Chromium, Telegram, Discord, Ollama, llama-cpp |
| AUR, through yay | zen-browser-bin, localsend-bin, lm-studio-bin |
| Direct upstream download | Cliamp, to /usr/local/bin/cliamp |
| Community arch-mact2 repository | linux-t2, linux-t2-headers, apple-t2-audio-config, apple-bcm-firmware, t2fanrd |

Rofi and mise are installed by pacman here, not as `rofi-wayland` or `mise-bin`.

### Optional: CodexBar in the top bar

CodexBar **0.60.3** was installed separately on this Mac on September 15, 2026, using the official x86_64 Linux desktop and CLI release archives after verifying both SHA-256 checksums. The base installer does not download CodexBar; for another machine follow the [upstream Linux installation guide](https://github.com/steipete/CodexBar/blob/main/Integrations/Linux/README.md), without `--omarchy`.

- Its small two-bar usage meter appears in Waybar's tray, directly beside the network/IP indicator. Click to open usage; right-click for the app menu and Settings. You can also search for **CodexBar** in the application launcher.
- It uses the existing Codex login. Provider selection, refresh interval, tray visibility, and Start at login are controlled in **CodexBar's own Settings**, not the desktop appearance app. Closing its window leaves the tray app running.
- The CLI and resource bundle live in `~/.local/lib/codexbar-cli/`; `~/.local/bin/codexbar` links there. The desktop executable is `~/.local/bin/codexbar-linux`; preferences are in `~/.config/codexbar/linux.json`. Credentials are not copied into this repository.
- Plain Hyprland does not process XDG autostart entries here, so the optional `codexbar-start.sh` helper starts it at login only when installed and its generated autostart entry is enabled. Disabling Start at login in CodexBar is respected. No Omarchy adapter is installed.
- Qt runtime dependencies are `qt6-base`, `qt6-declarative`, `qt6-svg`, and `qt6-wayland`; they were already installed on this Mac. CodexBar's optional terminal-based sign-in buttons additionally require `xdg-terminal-exec`, which is not installed here. If a new login is needed, run the provider CLI in Foot, then refresh CodexBar.

For upgrades, follow the upstream instructions; preserve the CLI resource bundle. To remove it, quit CodexBar and follow upstream's removal paths. The guarded startup helper does nothing when the app is absent.

### Starting the desktop

On the current machine, tty1 autologin starts the desktop through `start-hyprland` when available, falling back to `Hyprland`. The repository installer currently writes a simpler `exec Hyprland` block; it does not reproduce that wrapper selection.

From a local text console, with no desktop session already running, the installed compositor can be started with:

```bash
Hyprland
```

Do not start a second compositor from an existing graphical terminal or assume starting one over SSH will replace the local session.

Some dotfiles contain `/home/stu` paths, notably Waybar helper actions and wallpaper configuration. For another username, adapt these before deployment:

```bash
rg -n '/home/stu' dotfiles
```

## 4. Keyboard and mouse controls

`Super` is the Command key on an Apple keyboard, or the Windows key on a typical PC keyboard.

**Updated September 15:** core window controls were compared with Omarchy's actual defaults and corrected. Read the [window-controls guide and compatibility audit](docs/window-controls.md) for all mappings and intentional differences.

**Stuck with full-height columns?** Focus a tile and press **Super+J** to turn its pair into a top/bottom split. **Super+T** makes a window float so you can move/resize it independently with **Super+left/right-drag**. **Super+Minus/Equal** resizes width; add **Shift** for height. Tiled resizing adjusts shared dividers, so a full-height tile cannot independently shrink vertically without changing its split or floating it.

**Super+Alt+Space** opens a desktop-controls menu. **Super+L** switches the current workspace between dwindle and scrolling layouts; it no longer acts as the browser address bar (use **Ctrl+L**).

### Windows, tabs, and workspaces

| Shortcut | Action |
| --- | --- |
| Super+T | Toggle tiled / freely floating window |
| Super+W, Super+Q, Super+Shift+W, Alt+F4 | Close the focused window |
| Super+J | Toggle the focused tiling split's orientation |
| Super+Shift+Space | Show/hide the top bar |
| Super+Shift+F | Open file manager |
| Super+Shift+Arrow | Swap window in that direction |
| Super+Minus/Equal | Resize width; add Shift for height (hold to repeat) |
| Super+L | Switch current workspace between dwindle and scrolling |
| Super+Alt+F | Maximize while retaining application tabs |
| Super+O | Toggle floating and pinned across workspaces |
| Super+F | Toggle fullscreen |
| Super+Arrow | Focus the window in that direction |
| Alt+Tab | Cycle window focus |
| Super+1…9,0 | Switch to workspace 1…10 |
| Super+Shift+1…9,0 | Move the focused window to workspace 1…10 and follow it |
| Super+G | Toggle window grouping |
| Super+Alt+G | Move the focused window out of its group |
| Super+[ or Super+] | Previous or next window in the group |
| Ctrl+T / Ctrl+W | Application new-tab / close-tab controls, where supported |
| Super+Shift+T | Send Ctrl+Shift+T, normally reopen a browser tab |
| Ctrl+L / Super+R | Browser address bar / existing refresh alias |

Closing a window is not necessarily quitting every window or background process belonging to that application.

### Launchers, clipboard, and session controls

| Shortcut | Action |
| --- | --- |
| Super+K or Alt+K | Searchable shortcut cheatsheet |
| Super+, | Graphical Settings: appearance, wallpaper, display, and device controls |
| Super+Space or Alt+Space | Rofi application launcher |
| Super+Return | Foot terminal |
| Super+B or Super+Shift+Return | Browser launch command |
| Super+E | Thunar |
| Super+Shift+O | Obsidian |
| Super+Ctrl+T | btop in Foot |
| Super+M | Cliamp in Foot |
| Super+Shift+A / Super+Alt+A | Launch / choose an independently installed agent |
| Super+C | Copy helper: terminal-aware Ctrl+Shift+C or GUI Ctrl+C |
| Super+V | Send Ctrl+V; the bundled Foot config also maps this to paste |
| Super+X / Super+A / Super+Z | Send Ctrl+X / Ctrl+A / Ctrl+Z to the application |
| Super+Ctrl+V | Clipboard history picker; copies selection and attempts Ctrl+V |
| Super+Shift+S or Super+Print | Capture a selected rectangle |
| Print or Super+Ctrl+S | Capture the full desktop |
| Super+Escape | Power/session menu |
| Super+Ctrl+Q or Super+Ctrl+L | Invoke hyprlock |
| Super+Shift+Q | Exit Hyprland directly |
| Volume up/down/mute keys | Adjust default output and show volume popup |
| Media play/next/previous keys | Control players through playerctl |

Clipboard and editing shortcuts are **not universal macOS emulation**: their behavior depends on the application. Ctrl+A in a terminal, for example, need not mean “select all.” Screenshots are saved to `~/Pictures/Screenshots/` and copied to the clipboard.

The browser binding currently tries `xdg-open http://` followed by Firefox, Chromium, then Zen on command failure. This is not a validated browser-selection system; configure your default browser and verify the binding.

### Mouse and bar

- Drag window borders to resize where the layout allows it.
- Super or Alt + left-drag moves windows; right-drag resizes; middle-click toggles floating.
- Super + scroll changes workspaces.
- Arch icon: left-click opens Rofi, right-click opens Foot.
- Window title: left-click toggles floating, right-click closes the focused window.
- Clock: left-click launches a three-month terminal calendar; right-click opens the power menu. The calendar command needs `cal`, which the script does not explicitly install.
- Volume: scroll changes level, left-click toggles mute, right-click opens pavucontrol. The popup is currently wired to **keyboard** controls, not these bar actions.
- CPU or memory: left-click opens btop, right-click opens Foot.
- Network: left-click opens the connection editor, right-click opens nmtui.
- Clipboard: left-click opens history, right-click clears saved history.
- Shortcuts: left-click opens help, right-click opens Rofi.
- Power: left-click opens the session menu, right-click invokes hyprlock.

## 5. Display configuration

The saved setting in [hyprland.conf](dotfiles/hypr/hyprland.conf) is:

```ini
monitor = DP-1, 5120x2160@30, 0x0, 1
```

That gives the full **5120×2160 workspace at 100% scaling**. The user previewed and chose it. This connection exposes native resolution at 30 Hz; its Intel driver filters out the monitor's advertised native 60 Hz mode. Dell documents the older Intel graphics limitation in the [U4021QW manual, page 76](https://dl.dell.com/manuals/all-products/esuprt_electronics_accessories/esuprt_electronics_accessories_monitors/dell-u4021qw-monitor_user%27s-guide_en-us.pdf#page=76).

Check the actual connection with `hyprctl monitors`. On this machine, `preferred` previously selected 2560×1080, so it should not be described as “native resolution.”

Changing the final scale value makes text larger and reduces usable workspace. Tested alternatives at native resolution were `1.333333` (approximately 3840×1620 workspace) and `2` (2560×1080 workspace). The previous smoother, lower-resolution setting was `2560x1080@60` at scale `1`.

The file also contains a DP-3 rule and a fallback rule for other connectors. DP-3 is currently disconnected. Giving two monitors the same position does **not** establish Hyprland mirroring.

### Existing graphics workarounds

This machine retains workarounds applied during earlier artifact troubleshooting:

- `i915.enable_fbc=0 i915.enable_psr=0` in the boot options and corresponding options in `/etc/modprobe.d/i915.conf`.
- `AQ_NO_MODIFIERS=1` in `/etc/environment` and the compositor environment.
- `cursor { no_hardware_cursors = true }` in Hyprland.

These are this setup's existing workarounds, not proof that every UHD 630 machine needs them or that each one caused the improvement. Their performance cost has not been measured independently.

In `/etc/environment`, use `AQ_NO_MODIFIERS=1` **without** `export`. In a Bash startup file, use `export AQ_NO_MODIFIERS=1`.

## 6. Audio jack and volume popup

### Automatic installation

The T2 section of `install.sh` supplies the missing Mac mini profile when it identifies `AppleT2x1` or `Macmini8,1` and the entry file is absent. The hardware section itself requires the script's T2 detection to succeed.

On this machine, `apple-t2-audio-config 0.4.r21.ga973d53-1` only supplied x2/x4/x6 layouts. Without x1, audio fell back to the mono internal speaker. The repository's x1 profile exposes:

- PCM 0: mono internal speaker.
- PCM 2: stereo headphone/external-speaker jack.
- PCM 3: headset microphone input; microphone recording has not been tested here.

The profile is loaded when the audio session next starts. External-speaker playback has been confirmed by the user.

### Add only the audio fix to an existing Mac mini

Run from this repository **on the matching Mac mini**, without rerunning the full installer:

```bash
if [[ ! -e /usr/share/alsa/ucm2/conf.d/AppleT2x1/AppleT2x1.conf ]]; then
    sudo install -Dm644 system/alsa/ucm2/AppleT2/HiFi-x1.conf /usr/share/alsa/ucm2/AppleT2/HiFi-x1.conf
    sudo install -Dm644 system/alsa/ucm2/conf.d/AppleT2x1/AppleT2x1.conf /usr/share/alsa/ucm2/conf.d/AppleT2x1/AppleT2x1.conf
fi
systemctl --user restart wireplumber
```

Restarting WirePlumber briefly interrupts audio. With speakers connected, use pavucontrol's Configuration tab to select the profile containing **Headphones**, then set **External Speakers / Headphones** as the fallback/default output. Use the Playback tab to move existing streams if needed.

For the card and bundled profile on this machine:

```bash
pactl set-card-profile alsa_card.pci-0000_02_00.3 'HiFi (Headphones, Headset)'
pactl set-default-sink alsa_output.pci-0000_02_00.3.HiFi__Headphones__sink
wpctl status
```

The default selection is remembered by WirePlumber. Setting the default alone does not guarantee an already pinned stream moves; use the Playback tab. Active jack playback should link to Codec Output's left and right channels.

These two files under `/usr/share/alsa/ucm2/` are local additions, currently not owned by a package. If a future package supplies the same paths, reconcile the local additions before that upgrade.

### Volume indicator

[volume.sh](dotfiles/hypr/bin/volume.sh) changes the default output in 5% steps, retaining the existing 150% ceiling. Mako shows a bottom-center bar and percentage or mute status for 1.5 seconds. Repeated presses replace the popup; it does not enter notification history.

The visual bar fills at 100%; the text still reports levels above 100%. The installer deploys the helper, bindings, and Mako styling together. To preview without changing volume:

```bash
~/.config/hypr/bin/volume.sh show
```

## 7. Network troubleshooting and known limitations

### Internal T2 interface and slow boot

The internal Apple T2 network device was repeatedly attempting DHCP even after real Ethernet connected. That caused NetworkManager-wait-online to time out after 60 seconds.

Its existing profile was changed to manual activation. On this specific machine:

```bash
sudo nmcli connection modify uuid 8ebe6759-ce54-3b77-83f1-de7ab2161680 connection.autoconnect no
```

Do not reuse that UUID on another installation. Identify the device and profile first:

```bash
nmcli -f NAME,UUID,DEVICE connection show
udevadm info -q property /sys/class/net/enp2s0f1u1
journalctl -b -u NetworkManager --no-pager
```

Here udev identifies `Apple_T2_Controller` / iBridge with driver `cdc_ncm`. The installer disables automatic connection on matching existing profiles, but a profile created later may need the same correction. The wait service subsequently passed within the same second; next-boot timing has not yet been measured.

### DNS and IPv6

The earlier DNS symlink typo was corrected. The intended target is:

```text
/etc/resolv.conf -> /run/systemd/resolve/stub-resolv.conf
```

Check both resolver and network state before changing protocol settings:

```bash
readlink -e /etc/resolv.conf
resolvectl status
nmcli device status
ip -4 route
getent hosts archlinux.org
```

IPv6 is still disabled on this host through the Ethernet profile and `ipv6.disable=1` in the kernel command line. The need for that broad workaround has **not** been established independently. It is not a required setup step in this guide.

NetworkManager logged that global `[connection] ipv6.method=disabled` was an unknown key. That ineffective file was renamed to `/etc/NetworkManager/conf.d/disable-ipv6.conf.disabled`. The installer no longer writes it; it does not automatically undo previously applied IPv6 workarounds.

### Features that are present but not fully verified

- **Lock and idle:** hyprlock/hypridle packages and lock bindings exist, but the repository does not supply a dedicated lock-screen or idle configuration and does not start hypridle. Lock, suspend, and wake behavior still need testing.
- **Agents:** helpers list `agy`, `claude`, `codex`, `opencode`, and `omp`; the installer does not install or authenticate these CLIs. It initially writes `agy` as the default if none is configured. Choose an agent you have installed with Super+Alt+A.
- **Crash diagnosis:** scripts are included and the watcher is launched with Hyprland. This is not a verified one-click crash diagnosis service: journal permissions/event filtering and agent invocation need testing. The report uses `coredumpctl info`, not a guaranteed full debugger backtrace.
- **Optional applications:** a launcher or shortcut can exist even if its package failed to install.
- **Fresh installation:** script syntax and selected error paths were checked; complete installation, bootloader variants, and reboot persistence have not all been tested.

## 8. Configuration, updates, and verification

| Repository path | Installed location or purpose |
| --- | --- |
| [install.sh](install.sh) | Post-install packages, services, dotfiles, boot settings |
| [bootstrap-network.sh](bootstrap-network.sh) | Console network recovery |
| [HANDOVER.md](HANDOVER.md) | Machine history and repair notes |
| [dotfiles/hypr/](dotfiles/hypr/) | ~/.config/hypr/: compositor, wallpaper, helper scripts |
| [dotfiles/waybar/](dotfiles/waybar/) | ~/.config/waybar/: bar layout and style |
| [dotfiles/rofi/](dotfiles/rofi/) | ~/.config/rofi/: launcher style |
| [dotfiles/foot/](dotfiles/foot/) | ~/.config/foot/: terminal and paste bindings |
| [dotfiles/mako/](dotfiles/mako/) | ~/.config/mako/: notifications and volume popup |
| [dotfiles/applications/cliamp.desktop](dotfiles/applications/cliamp.desktop) | ~/.local/share/applications/cliamp.desktop |
| [system/alsa/ucm2/](system/alsa/ucm2/) | Missing Mac mini audio profile, installed under /usr/share/alsa/ucm2/ |

Helper scripts include `shortcuts-menu.sh`, `volume.sh`, `copy.sh`, `clipboard-history.sh`, `screenshot.sh`, `system-menu.sh`, `default-agent.sh`, `crash-watch.sh`, and `crash-diagnose.sh`.

### Repository updates do not automatically update the desktop

From a clean repository checkout:

```bash
git pull --ff-only
```

Review changes and back up the affected live files before deploying them. The installer **copies** dotfiles; they are not symlinked to this checkout. Likewise, local edits are not on GitHub until committed and pushed.

After deliberately updating the relevant live configuration:

```bash
hyprctl reload
hyprctl configerrors
makoctl reload
```

Hyprland normally reloads its config on changes, but `exec-once` commands do not run again on a reload. Other components may require their own reload or restart.

### Read-only checks

```bash
hyprctl monitors
hyprctl configerrors
wpctl status
pactl get-default-sink
systemctl --failed
systemctl --user --failed
systemctl --user is-active hyprpolkitagent
systemd-analyze critical-chain graphical.target
```

For repository edits:

```bash
bash -n install.sh bootstrap-network.sh
for script in dotfiles/hypr/bin/*.sh; do bash -n "$script"; done
git diff --check
```

These checks do not replace a fresh-install test or confirmation that physical audio, display, lock, and suspend behavior is correct.
