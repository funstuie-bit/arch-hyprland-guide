# System Handover & Technical State Document
**Host:** `maclinux` (2018 Intel Mac mini / T2)  
**Primary User:** `stu` (`funstuie-bit` on GitHub)  
**Date Updated:** September 14, 2026  
**Repository:** [https://github.com/funstuie-bit/arch-hyprland-guide](https://github.com/funstuie-bit/arch-hyprland-guide) (local clone at `/home/stu/arch-hyprland-guide`)

---

## 1. System Vision & User Design Requirements

This system is pure **Arch Linux** running **Hyprland**, tailored specifically to the user's workflow:
1. **The "Cool" Aesthetic (Inspired by Omarchy/Catppuccin Mocha):**
   - Clean, translucent dark glass floating bar (`rgba(30, 30, 46, 0.88)`).
   - Soft lavender/blue active gradients and borders (`rgba(cba6f7ee) rgba(89b4faee) 45deg`).
   - Sleek Raycast/Spotlight-style Rofi application launcher and searchable shortcuts cheatsheet.
   - Geometric Catppuccin wallpaper.
   - **NO "Start" button text or cheesy Windows 95/10 taskbar buttons.** The menu button is an understated, elegant Arch icon (``) in a subtle dark glass pill.
2. **First-Class Mouse Interaction (Left & Right Click Actually Do Useful Things):**
   - Unlike keyboard-only tiling setups where mouse clicks are ignored, every single element on the status bar and desktop provides intuitive left-click and right-click actions.
   - Direct window border dragging for resizing without touching any keyboard keys.
   - `Cmd + Drag` (or `Alt + Drag`) to move (left-click) or resize (right-click) windows anywhere.
3. **Mac-Native Keyboard Muscle Memory:**
   - Command key (`⌘` / `Super`) as primary modifier.
   - Standard clipboard keys: `Cmd + C` (copy), `Cmd + V` (paste without `Ctrl+Shift+V` gymnastics in terminals), `Cmd + X` (cut), `Cmd + A` (select all).
   - Tabbing: `Cmd + T` (new tab in browser/editor), `Cmd + W` (close tab), `Cmd + L` (focus browser URL bar).
   - Window Tabbing (Groups): `Cmd + G` (toggle Hyprland tab group), `Cmd + [` and `Cmd + ]` (cycle tabs).
   - Window Closing: `Cmd + Q` (quit application).
   - Window Floating: `Cmd + Shift + Space` or `Cmd + Shift + F`.
4. **Rich Suite of Pre-Installed Applications:**
   - Terminal: `foot`
   - File Manager: `thunar`
   - Web Browsers: `firefox`, `zen-browser`, `chromium`
   - System Activity Monitor: `btop`
   - Audio Mixer GUI: `pavucontrol`
   - Music Player: `cliamp` (lo-fi internet radio)
   - Markdown Notes: `obsidian`
   - Local File Sharing: `localsend`
   - Screenshot Utility: `screenshot.sh` (Mac-style `Cmd+Shift+S` area capture + clipboard/file sync)
   - Launcher & Cheatsheet: `rofi` (Spotlight theme) and `shortcuts-menu.sh`

---

## 2. Hardware & Display Architecture

| Component | Details | Notes |
| :--- | :--- | :--- |
| **Model** | Apple Mac mini (2018, `Macmini8,1`) | Intel Coffee Lake-H GT2 platform |
| **Processor** | Intel Core i5/i7 (Coffee Lake) | 6 Cores |
| **Graphics** | Intel UHD Graphics 630 (`i915` driver) | Integrated GPU |
| **Security Chip** | Apple T2 Security Chip (`t2bce_core`) | Manages NVMe, audio, Wi-Fi, fan, power |
| **Audio** | Apple Audio Device (`snd-soc-mact2-audio`) | Managed via `apple-t2-audio-config` + PipeWire |
| **Wi-Fi / BT** | Broadcom BCM4364 | Requires `apple-bcm-firmware` (from AUR) |
| **Ethernet** | Onboard Gigabit/10GbE (`enp1s0`) | Primary wired network interface |
| **Fan Daemon** | `t2fanrd` | Service: `systemctl status t2fanrd` |
| **Connected Display**| Dell U4021QW 40" 5K2K Ultrawide (21:9) | Connected via **Thunderbolt 3** on port **`DP-1`** |
| **Active Kernel** | `linux-t2` (`7.2.4-arch1-Watanare-T2-2-t2`) | Arch MacT2 community kernel |
| **Bootloader** | `systemd-boot` | Entry: `/boot/loader/entries/linux-t2.conf` |
| **Display Server**| Wayland via **Hyprland 0.56.2** | Compositor backend: **Aquamarine 0.15.0** |

### Display & GPU Tuning (UHD 630 on Ultrawide)
* **Comb / Sawtooth Shearing Artifacts Fixed:**
  - Disabled Intel Frame Buffer Compression (FBC) and Panel Self Refresh (PSR) via `/etc/modprobe.d/i915.conf` (`options i915 enable_fbc=0 enable_psr=0`) and kernel command line in `/boot/loader/entries/linux-t2.conf`.
* **Aquamarine Buffer Modifiers:**
  - Set `AQ_NO_MODIFIERS=1` in `/etc/environment` and `~/.config/hypr/hyprland.conf` to prevent DRM tiling conflicts.
* **Cursor:**
  - Configured `cursor { no_hardware_cursors = true, no_warps = true }` in `hyprland.conf`.

---

## 3. First-Boot Network & SSH Bootstrap (Lessons Learned & Solution)

### The Hardware Reality on 2018 Mac mini
On a fresh minimal Arch installation, you cannot use Wi-Fi or SSH immediately:
1. **Wi-Fi is non-functional on fresh install:** The Broadcom BCM4364 wireless chip requires proprietary firmware (`apple-bcm-firmware`) which can only be built from the AUR *after* an internet connection is established.
2. **Minimal Arch has no active DHCP client:** The base Arch install does not start NetworkManager or `systemd-networkd` automatically. Plugging in an Ethernet cable leaves the link `DOWN` with no IP address.
3. **Typing on the physical console is painful:** The user had to manually type configuration files, link resolvers, toggle interfaces, and install packages by hand on the Mac mini before being able to SSH from their laptop.

### The User's Historical Bootstrap Log (What Had to Be Done)
The user executed and discovered the following sequence to bring the network alive:
```bash
# Attempt 1: systemd-networkd wildcard DHCP & resolver setup
printf '[Match]\nName=en*\n\n[Network]\nDHCP=yes\n' | sudo tee /etc/systemd/network/20-wired.network
sudo systemctl enable --now systemd-networkd
sudo systemctl enable --now systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Attempt 2: USB Ethernet dongle (enp0s20f0u4)
sudo ip link set enp0s20f0u4 up
printf '[Match]\nName=enp0s20f0u4\n\n[Network]\nDHCP=yes\n' | sudo tee /etc/systemd/network/20-usb.network
sudo networkctl reload
sudo networkctl reconfigure enp0s20f0u4

# Attempt 3: Onboard Mac mini Ethernet (enp1s0) + manual link UP
sudo rm -f /etc/systemd/network/20-usb.network
sudo ip link set enp1s0 up
sudo systemctl restart systemd-networkd

# Result:
# enp1s0 UP 192.168.1.65/24

# Package installation & SSH activation:
sudo pacman -Syu
sudo pacman -Sy --needed --noconfirm git networkmanager openssh
sudo systemctl enable --now sshd
ip -br a
```

### The Streamlined 2-Step Solution for Next Time

To make future installs seamless, this entire ordeal is condensed into **two quick commands** to run on the Mac mini console:

#### Step 1: Bring Up Network & DNS (1 Line)
Plug an Ethernet cable into the Mac mini onboard port (`enp1s0`) and run:
```bash
printf '[Match]\nName=en*\n\n[Network]\nDHCP=yes\n' | sudo tee /etc/systemd/network/20-wired.network && sudo systemctl enable --now systemd-networkd systemd-resolved && sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf && sudo ip link set enp1s0 up
```

#### Step 2: Enable SSH & Print IP (1 Line)
```bash
sudo pacman -Sy --needed --noconfirm openssh git networkmanager && sudo systemctl enable --now sshd && ip -br a
```

#### Step 3: Switch to Your Mac / Laptop Terminal
Disconnect the monitor and keyboard from the Mac mini. Everything else can be run over SSH:
```bash
ssh stu@<MAC_MINI_IP>
git clone https://github.com/funstuie-bit/arch-hyprland-guide.git
cd arch-hyprland-guide
./install.sh
```

### Automated Script in Repository: `bootstrap-network.sh`
The repository now includes `bootstrap-network.sh` which automates interface detection (onboard `enp1s0` and USB dongles), DHCP configuration, DNS stub linking, link up, and SSH enabling in a single command:
```bash
sudo bash bootstrap-network.sh
```

### Pro-Tip: Skip This Entirely During `archinstall` (Pre-Reboot)
If re-installing via `archinstall`:
1. Under **Network configuration**, do not select "Copy ISO configuration". Choose **systemd-networkd** or **NetworkManager**.
2. Before rebooting `archinstall`, select **"Chroot into installation"** and run:
   ```bash
   printf '[Match]\nName=en*\n\n[Network]\nDHCP=yes\n' > /etc/systemd/network/20-wired.network
   systemctl enable systemd-networkd systemd-resolved sshd
   ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
   ```
3. Type `exit` and reboot. The Mac mini will boot up with Ethernet DHCP, DNS, and SSH server already running!

---

## 4. Mouse Interaction Map (Waybar & Desktop)

| Module / Area | Left-Click Action | Right-Click Action | Scroll / Drag Action |
| :--- | :--- | :--- | :--- |
| **Menu Icon (``)** | Open Application Launcher (Rofi) | Open Terminal (`foot`) | — |
| **Workspaces (`1`, `2`..)**| Switch directly to workspace | Switch directly to workspace | Cycle workspaces forward / backward |
| **Window Title** | Toggle Floating / Tiled mode | Close / Kill active window | — |
| **Center Clock** | Open visual floating 3-month Calendar | Open System Power & Session Menu | — |
| **Volume (`󰕾`)** | Toggle Mute / Unmute | Open Sound Mixer GUI (`pavucontrol`)| Adjust volume up / down |
| **CPU (``)** | Open Activity Monitor (`btop`) | Open Terminal (`foot`) | — |
| **Memory (``)** | Open Activity Monitor (`btop`) | Open Terminal (`foot`) | — |
| **Network (`󰈀` / ``)** | Open Network Connections GUI | Open Terminal Network Setup (`nmtui`)| — |
| **Clipboard (`󰅍`)** | Open Clipboard History picker | Clear clipboard history | — |
| **Shortcuts (`󰌌`)**| Open Searchable Shortcuts Cheatsheet| Open Application Launcher (Rofi) | — |
| **Power (``)** | Open Power & Session Menu | Lock Screen immediately (`hyprlock`)| — |
| **Window Borders** | Click & drag window edge or corner to resize directly without pressing keys | — | Hover reveals resize cursor |
| **Window Surface** | `Cmd + Left-Drag` (or `Alt + Left-Drag`): Move window | `Cmd + Right-Drag` (or `Alt + Right-Drag`): Resize window | `Cmd + Middle-Click`: Toggle float |

---

## 5. Keyboard Shortcuts Reference

All shortcuts use standard Mac muscle memory (`Super` = Command key `⌘`):

| Category | Shortcut | Function |
| :--- | :--- | :--- |
| **Clipboard** | `Cmd + C` | Universal Copy |
| **Clipboard** | `Cmd + V` | Universal Paste (works in Foot terminal without `Ctrl+Shift+V`) |
| **Clipboard** | `Cmd + X` | Universal Cut |
| **Clipboard** | `Cmd + A` | Select All |
| **Clipboard** | `Cmd + Z` | Undo |
| **Clipboard** | `Cmd + Ctrl + V` | Open Clipboard History & Paste (Cliphist) |
| **In-App Tabs**| `Cmd + T` | New Tab in browser / editor |
| **In-App Tabs**| `Cmd + W` | Close Tab in browser / editor |
| **In-App Tabs**| `Cmd + L` | Focus URL / Address Bar in browser |
| **Window Tabs**| `Cmd + G` | Toggle active window into / out of **Hyprland Tab Group** |
| **Window Tabs**| `Cmd + Alt + G` | Eject window from Tab Group |
| **Window Tabs**| `Cmd + [` | Cycle backward through Tab Group |
| **Window Tabs**| `Cmd + ]` | Cycle forward through Tab Group |
| **Window Management** | `Cmd + Q` | Close / quit focused window |
| **Window Management** | `Cmd + Shift + W` | Close / quit focused window |
| **Window Management** | `Alt + F4` | Close / quit focused window |
| **Window Management** | `Cmd + Shift + Space` | Toggle floating mode |
| **Window Management** | `Cmd + Shift + F` | Toggle floating mode |
| **Window Management** | `Cmd + F` | Toggle fullscreen |
| **Window Management** | `Cmd + J` | Toggle tiling split direction (horizontal / vertical) |
| **Window Focus** | `Cmd + Arrow Keys` | Move focus Left / Right / Up / Down |
| **Window Focus** | `Alt + Tab` | Cycle forward through windows |
| **Workspaces** | `Cmd + 1` .. `Cmd + 9`, `0` | Switch to workspace 1 - 10 |
| **Workspaces** | `Cmd + Shift + 1` .. `0` | Move focused window to workspace |
| **Launchers** | `Cmd + Space` or `Alt + Space` | Open Rofi application launcher |
| **Launchers** | `Cmd + Return` | Open Foot terminal |
| **Launchers** | `Cmd + B` or `Cmd + Shift + Return`| Open Web Browser (Firefox / Zen / Chromium) |
| **Launchers** | `Cmd + E` | Open Thunar file manager |
| **Launchers** | `Cmd + Shift + O` | Open Obsidian markdown notes |
| **Launchers** | `Cmd + Ctrl + T` | Open `btop` Activity Monitor |
| **Launchers** | `Cmd + M` | Open Cliamp music player |
| **Cheatsheet** | `Cmd + K` or `Alt + K` | Searchable onscreen shortcuts cheatsheet |
| **Screen Lock** | `Cmd + Ctrl + Q` | Lock screen immediately (`hyprlock`) |
| **Screen Lock** | `Cmd + Ctrl + L` | Lock screen immediately (`hyprlock`) |
| **Power Menu** | `Cmd + Escape` | Power menu (Lock, Logout, Reboot, Shutdown) |
| **Session Exit**| `Cmd + Shift + Q` | Exit Hyprland session to console |
| **Screenshots** | `Cmd + Shift + S` | Interactive rectangular crop & copy to clipboard |
| **Screenshots** | `Cmd + Ctrl + S` or `PrintScreen` | Capture entire screen to `~/Pictures/Screenshots/` |

---

## 6. Configuration File Map

| Component | Host Path | Repository Path | Description |
| :--- | :--- | :--- | :--- |
| **Bootstrap Script**| *(optional)* | `bootstrap-network.sh` | First-boot Ethernet, DHCP, DNS, and SSH enabler |
| **Hyprland** | `~/.config/hypr/hyprland.conf` | `dotfiles/hypr/hyprland.conf` | Compositor, window rules, groupbar, mouse binds |
| **Waybar Config**| `~/.config/waybar/config.jsonc` | `dotfiles/waybar/config.jsonc` | Modules, mouse click actions (left/right), layout |
| **Waybar Style** | `~/.config/waybar/style.css` | `dotfiles/waybar/style.css` | Catppuccin Mocha glass pills, hover highlights |
| **Foot Terminal**| `~/.config/foot/foot.ini` | `dotfiles/foot/foot.ini` | JetBrains Mono font, native Mac paste bindings |
| **Rofi** | `~/.config/rofi/config.rasi` | `dotfiles/rofi/config.rasi` | Spotlight-style application launcher |
| **Cheatsheet** | `~/.config/hypr/bin/shortcuts-menu.sh` | `dotfiles/hypr/bin/shortcuts-menu.sh` | Interactive Rofi shortcuts palette |
| **Clipboard** | `~/.config/hypr/bin/clipboard-history.sh` | `dotfiles/hypr/bin/clipboard-history.sh` | Cliphist searchable popup |
| **Power Menu** | `~/.config/hypr/bin/system-menu.sh` | `dotfiles/hypr/bin/system-menu.sh` | Shutdown, Reboot, Lock, Logout dialog |
| **Startup Shell**| `~/.bash_profile` | *(host local)* | Auto-starts Hyprland via `start-hyprland` on `tty1` |
| **Intel Modprobe**| `/etc/modprobe.d/i915.conf` | *(system level)* | Disables FBC and PSR for UHD 630 stability |
| **Kernel Cmdline**| `/boot/loader/entries/linux-t2.conf` | *(system level)* | Adds `i915.enable_fbc=0 i915.enable_psr=0` |
