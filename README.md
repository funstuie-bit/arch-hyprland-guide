# Clean Arch Linux + Hyprland on 2018 Mac mini

A lightweight, transparent, and independently configured Arch Linux + Hyprland desktop designed for the **2018 Intel Mac mini (T2 / Intel UHD 630)**.

This repository provides both a complete guide and pre-configured dotfiles tailored for a **hybrid mouse + keyboard workflow**:
- **Natural mouse interaction**: Resize windows simply by dragging their borders (no modifier keys required), drag and position windows with `Super + Left Click`, and toggle floating with `Super + Middle Click`.
- **Fast keyboard control**: Launch apps, switch workspaces, and manage windows with clean, intuitive shortcuts.
- **Lightweight & modular**: Fast Wayland components (`hyprland`, `waybar`, `rofi-wayland`, `foot`, `thunar`, `mako`) with zero bloated layers or unwanted third-party dependencies.
- **Automated setup**: A single, clean `install.sh` script to install packages, configure services, and deploy dotfiles.

---

## 1. Pre-Installation: 2018 Mac mini (T2 Chip) Checklist

The 2018 Mac mini contains Apple's **T2 Security Chip**, which secures the internal NVMe drive, Wi-Fi (Broadcom BCM4364), Bluetooth, and audio. Before installing Linux, you must perform these steps in macOS:

### Step 1: Disable Apple Secure Boot
1. Shut down the Mac mini.
2. Hold down **`Command (⌘) + R`** immediately after pressing the power button until you see the Apple logo.
3. In macOS Recovery, navigate to the top menu bar: **Utilities > Startup Security Utility**.
4. Authenticate as an administrator.
5. Set **Secure Boot** to **"No Security"**.
6. Set **Allowed Boot Media** to **"Allow booting from external media"**.
7. Restart the Mac.

### Step 2: Prepare T2-Aware Arch Installation Media
Standard vanilla Arch ISOs lack drivers for Apple T2 NVMe controllers, internal audio, and Wi-Fi.
1. Download the pre-patched **T2 Arch Linux ISO** from the [T2 Linux Arch Guide](https://wiki.t2linux.org/distributions/arch/installation/).
2. Flash the ISO to a USB flash drive using BalenaEtcher, Raspberry Pi Imager, or `dd`:
   ```bash
   sudo dd if=archlinux-t2-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```
3. Insert the USB drive into the Mac mini, power on, and hold the **`Option (⌥)`** key to select the EFI boot drive.

---

## 2. Base Arch Installation

Once booted into the live environment:

1. Connect to Wi-Fi if not using Ethernet:
   ```bash
   iwctl
   # station wlan0 scan
   # station wlan0 get-networks
   # station wlan0 connect <Your-SSID>
   ```
2. Launch the guided installer:
   ```bash
   archinstall
   ```
3. In `archinstall`, select:
   - **Audio:** PipeWire
   - **Network:** NetworkManager
   - **Kernel:** `linux-t2` (if prompted or on T2 ISO) or `linux` (add `t2linux` repository post-install)
   - **Profile:** Minimal / No desktop environment initially (we install Hyprland in the next step)
   - **User:** Create a standard user with `sudo` / `wheel` privileges

Reboot into your new Arch Linux system.

---

## 3. Quick Setup (Automated)

Once logged into your new Arch Linux terminal as your regular user:

```bash
# 1. Clone this repository
git clone https://github.com/funstuie-bit/arch-hyprland-guide.git
cd arch-hyprland-guide

# 2. Run the bootstrap installer
./install.sh
```

The script will:
1. Install all necessary graphics drivers (`mesa`, `vulkan-intel`, `intel-media-driver`), Hyprland desktop packages, audio, fonts, and utilities.
2. Enable `NetworkManager` and `bluetooth` system services.
3. Back up any existing config and link the pre-configured dotfiles into `~/.config/`.

To start your graphical desktop, run:
```bash
Hyprland
```

---

## 4. Mouse-Friendly Hyprland Workflow

Unlike strict keyboard-only configurations, this setup is tuned for comfortable mouse usage:

### Natural Border Resizing
You do not need to press keyboard shortcuts to resize windows. Hover your mouse over any window border or corner and click-drag to resize, exactly like macOS and Windows:
```ini
general {
    resize_on_border = true
    extend_border_grab_area = 15
    hover_icon_on_border = true
}
```

### No Cursor Warping
Tiling compositors often jerk your mouse pointer across screens whenever a window changes focus. This configuration sets:
```ini
cursor {
    no_warps = true
}
```
Your cursor stays wherever you placed it.

### Mouse Window Controls
| Action | Binding |
| :--- | :--- |
| **Move window** | Hold `Super` + Left-Click Drag |
| **Resize window** | Hold `Super` + Right-Click Drag |
| **Toggle Floating** | Hold `Super` + Middle-Click (or `Super + V`) |
| **Switch Workspaces** | Hold `Super` + Mouse Scroll Wheel |

### Interactive Status Bar (Waybar)
- **Workspaces:** Click any workspace number to jump to it.
- **Audio:** Scroll to increase/decrease volume. Left-click to mute. Right-click to open `pavucontrol` mixer.
- **Network:** Click to open network connection manager (`nm-connection-editor`).
- **Clock:** Displays formatted date/time with a calendar tooltip.
- **Power:** Click power icon to lock screen or display power options.

---

## 5. Keyboard Shortcuts Cheatsheet

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| `Super + Space` | **App Launcher** | Opens Rofi application search (mouse clickable) |
| `Super + Enter` | **Terminal** | Opens Foot terminal emulator |
| `Super + E` | **File Manager** | Opens Thunar graphical file manager |
| `Super + Q` | **Close Window** | Closes the focused window |
| `Super + V` | **Toggle Floating** | Detaches window from tiling grid |
| `Super + F` | **Fullscreen** | Toggles fullscreen for active window |
| `Super + L` | **Lock Screen** | Locks session via `hyprlock` |
| `Super + Shift + S` | **Screenshot Area** | Select rectangular area with mouse and copy to clipboard |
| `PrintScreen` | **Full Screenshot** | Saves screenshot to `~/Pictures/Screenshots/` |
| `Super + 1 .. 9, 0` | **Workspaces** | Switch to workspaces 1 through 10 |
| `Super + Shift + 1 .. 0` | **Move to Workspace**| Move active window to chosen workspace |
| `Super + Arrow Keys` | **Focus Window** | Move focus to left, right, up, or down window |

---

## 6. Repository Dotfiles Structure

```text
arch-hyprland-guide/
├── install.sh                  # Automated bootstrap script
├── README.md                   # Installation guide & documentation
└── dotfiles/
    ├── hypr/
    │   ├── hyprland.conf       # Hyprland config (mouse borders, keybinds, rules)
    │   └── hyprpaper.conf      # Wallpaper daemon config
    ├── waybar/
    │   ├── config.jsonc        # Clickable status bar modules
    │   └── style.css           # Modern translucent pill theme
    ├── rofi/
    │   └── config.rasi         # Application launcher with mouse support
    ├── foot/
    │   └── foot.ini            # Lightweight Wayland terminal
    └── mako/
        └── config              # Desktop notification styling
```

---

## 7. Manual Installation & Packages Breakdown

If you prefer installing packages manually without the `install.sh` script:

```bash
sudo pacman -Syu --needed \
  mesa vulkan-intel intel-media-driver \
  hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  hyprpolkitagent hyprpaper hyprlock hypridle \
  waybar rofi-wayland mako libnotify \
  foot thunar thunar-volman gvfs tumbler file-roller \
  pipewire pipewire-audio pipewire-pulse pipewire-alsa wireplumber pavucontrol \
  networkmanager network-manager-applet bluez bluez-utils blueman \
  grim slurp wl-clipboard brightnessctl playerctl papirus-icon-theme \
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
```

Enable system services:
```bash
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
```

Copy dotfiles into place:
```bash
cp -r dotfiles/* ~/.config/
```

---

## 8. 2018 Mac mini Hardware Troubleshooting

### Apple T2 Kernel & Audio
If audio devices or Wi-Fi are not visible after rebooting into the installed system, follow the [T2 Linux Arch Wiki](https://wiki.t2linux.org/distributions/arch/installation/) to add the precompiled T2 repository to `/etc/pacman.conf`:
```ini
[t2linux]
Server = https://github.com/t2linux/arch-wiki-docs/releases/download/packages
```
Then install `linux-t2`, `linux-t2-headers`, and `apple-t2-audio-config`.

### High-DPI / 4K Displays
If you are using a 4K display and the text/icons appear too small, open `~/.config/hypr/hyprland.conf` and adjust the monitor scaling line:
```ini
# Change scale factor (e.g. 1.5 or 2)
monitor = , preferred, auto, 1.5
```

### Reloading Hyprland
Whenever you edit `~/.config/hypr/hyprland.conf`, Hyprland reloads automatically. If needed, force a reload and check for syntax errors:
```bash
hyprctl reload
hyprctl configerrors
```
