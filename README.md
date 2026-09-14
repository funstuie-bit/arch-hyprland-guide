# Clean Arch Linux + Hyprland on 2018 Mac mini

A lightweight, transparent, and independently configured Arch Linux + Hyprland desktop designed for the **2018 Intel Mac mini (T2 / Intel UHD 630)**.

This setup extracts the best productivity innovations of Omarchy into a **clean, modular "Lite" build**—without DHH's monolithic Lua layer, forced branding, proprietary update mechanisms, or opinionated bloat.

### Key Features
- **🤖 Built-in AI Agent & 1-Click Crash Diagnosis:** System crashes monitored via `systemd-coredump` send a notification. Clicking it opens a dedicated Foot terminal running your default agent (`agy`, `claude`, `codex`, or `opencode`) with the crash trace and resolution prompt pre-loaded.
- **⌨️ `Super + K` Cheatsheet Popup:** Searchable, categorized hotkey and mouse guide powered by Rofi. No memorization required.
- **🎵 Cliamp Retro Music Player:** Terminal-based music player inspired by Winamp 2.x with built-in lo-fi streams (`Super + M`).
- **🖱️ Mouse-Friendly Hybrid Workflow:** Natural border-hover resizing (no keys required), `Super + Left-Click Drag` to move, `Super + Right-Click Drag` to resize, and `Super + Middle-Click` to toggle floating.
- **⚡ Wayland-Native Performance:** Foot terminal, Waybar, Rofi-Wayland, Mako notifications, and Thunar file manager with zero unnecessary overhead.
- **🚀 1-Command Automated Installer:** Run `./install.sh` on a fresh Arch installation to set up packages, services, and dotfiles.

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
   - **Profile:** Minimal / No desktop environment initially
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
1. Install Intel UHD 630 drivers, Hyprland, Waybar, Rofi, Foot, PipeWire audio, fonts, and utilities.
2. Install **Cliamp** terminal music player directly into `/usr/local/bin/cliamp`.
3. Enable `NetworkManager` and `bluetooth` system services.
4. Back up existing configs and deploy mouse-friendly dotfiles to `~/.config/`.
5. Set up the AI crash diagnosis daemon and default agent configuration.

To start your graphical desktop, run:
```bash
Hyprland
```

---

## 4. "Lite" Omarchy Features Explained

### 🤖 AI Agent Integration & Crash Diagnosis
* **Crash Watcher:** A background service (`~/.config/hypr/bin/crash-watch.sh`) monitors `journalctl` for process segfaults via `systemd-coredump`.
* **1-Click Diagnosis:** When an application crashes, a desktop notification appears:  
  *`"Process crashed: [name] — Click to diagnose with AI"`*  
  Clicking the toast instantly launches your default AI agent in a dedicated Foot window, pre-loaded with the coredump stack trace and a prompt asking how to fix it.
* **Launch Agent Anytime:** Press **`Super + Shift + A`** to launch your default agent in a floating terminal.
* **Switch Default Agent:** Press **`Super + Alt + A`** (or edit `~/.config/default-agent`) to choose between `agy` (Google Antigravity CLI), `claude` (Claude Code), `codex`, or `opencode`.

### ⌨️ Interactive `Super + K` Cheatsheet
Pressing **`Super + K`** triggers a floating, searchable Rofi popup displaying all system shortcuts categorized by function (Apps, AI, Mouse, Audio, Window management). You can filter with fuzzy search or select items with the mouse.

### 🎵 Cliamp Music Player
Press **`Super + M`** (or `Super + Shift + Alt + M`) to launch [Cliamp](https://www.cliamp.stream/), a retro Winamp 2.x-inspired terminal music player with built-in lo-fi and radio streams.

---

## 5. Mouse-Friendly Hyprland Workflow

Unlike strict keyboard-only setups, this configuration is optimized for natural mouse use:

### Natural Border Resizing
Hover your mouse over any window border or corner and drag to resize, exactly like macOS and Windows—no modifier keys required:
```ini
general {
    resize_on_border = true
    extend_border_grab_area = 15
    hover_icon_on_border = true
}
```

### Stable Cursor Position
```ini
cursor {
    no_warps = true
}
```
Your mouse cursor will not jump or snap across windows when switching focus.

### Mouse Window Controls
| Action | Binding |
| :--- | :--- |
| **Resize window directly** | Hover over border/corner and click-drag |
| **Move window** | Hold `Super` + Left-Click Drag |
| **Resize window** | Hold `Super` + Right-Click Drag |
| **Toggle Floating** | Hold `Super` + Middle-Click (or `Super + V`) |
| **Switch Workspaces** | Hold `Super` + Mouse Scroll Wheel |

### Interactive Status Bar (Waybar)
- **Workspaces:** Click any number to jump to that workspace.
- **Audio:** Scroll to increase/decrease volume. Left-click to mute. Right-click to open `pavucontrol` mixer.
- **Network:** Click to open network connection manager (`nm-connection-editor`).
- **Clock:** Displays formatted date/time with interactive calendar tooltip.
- **Power:** Click power icon to lock screen or display power options.

---

## 6. Shortcuts Cheatsheet

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| `Super + K` | **Shortcuts Cheatsheet** | Searchable popup listing all key/mouse shortcuts |
| `Super + Space` | **App Launcher** | Opens Rofi application search (mouse clickable) |
| `Super + Enter` | **Terminal** | Opens Foot terminal emulator |
| `Super + Shift + A` | **Launch AI Agent** | Opens default agent (`agy`, `claude`, etc.) |
| `Super + Alt + A` | **Pick AI Agent** | Select / change default AI agent |
| `Super + M` | **Cliamp Music** | Launches retro terminal music player |
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

## 7. Repository Structure

```text
arch-hyprland-guide/
├── install.sh                  # Automated bootstrap script
├── README.md                   # Complete guide & documentation
└── dotfiles/
    ├── applications/
    │   └── cliamp.desktop      # Desktop launcher entry for Cliamp
    ├── hypr/
    │   ├── hyprland.conf       # Hyprland config (mouse borders, keybinds, rules)
    │   ├── hyprpaper.conf      # Wallpaper daemon config
    │   └── bin/
    │       ├── shortcuts-menu.sh  # Super + K searchable cheatsheet
    │       ├── default-agent.sh   # AI agent selector & launcher
    │       ├── crash-watch.sh     # Background systemd coredump monitor
    │       └── crash-diagnose.sh  # Auto-diagnosis prompt generator
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
