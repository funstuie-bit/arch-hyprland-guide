# System Handover & Technical State Document
**Host:** `maclinux` (2018 Intel Mac mini / T2)  
**Primary User:** `stu` (`funstuie-bit` on GitHub)  
**Date Updated:** September 14, 2026  
**Repository:** [https://github.com/funstuie-bit/arch-hyprland-guide](https://github.com/funstuie-bit/arch-hyprland-guide) (local clone at `/home/stu/arch-hyprland-guide`)

---

## 1. Hardware & System Overview

| Component | Details | Notes |
| :--- | :--- | :--- |
| **Model** | Apple Mac mini (2018, `Macmini8,1`) | Intel Coffee Lake-H GT2 platform |
| **Processor** | Intel Core i5/i7 (Coffee Lake) | 6 Cores |
| **Graphics** | Intel UHD Graphics 630 (`i915` driver) | Integrated GPU |
| **Security Chip** | Apple T2 Security Chip (`t2bce_core`) | Manages NVMe, audio, Wi-Fi, fan, power |
| **Audio** | Apple Audio Device (`snd-soc-mact2-audio`) | Managed via `apple-t2-audio-config` + PipeWire |
| **Wi-Fi / BT** | Broadcom BCM4364 | Requires `apple-bcm-firmware` |
| **Fan Daemon** | `t2fanrd` | Service: `systemctl status t2fanrd` |
| **Connected Display**| Dell U4021QW 40" 5K2K Ultrawide (21:9) | Connected via **Thunderbolt 3** on port **`DP-1`** |
| **Active Kernel** | `linux-t2` (`7.2.4-arch1-Watanare-T2-2-t2`) | Arch MacT2 community kernel |
| **Bootloader** | `systemd-boot` | Entry: `/boot/loader/entries/linux-t2.conf` |
| **Display Server**| Wayland via **Hyprland 0.56.2** | Compositor backend: **Aquamarine 0.15.0** |

---

## 2. Critical Problems Diagnosed & Solved

### A. Universal Mac Clipboard & Keybindings Overhaul
* **Symptom:** Copy-pasting in terminal forced the user to use `Ctrl + Shift + V` / `Ctrl + Shift + C`. Pressing `Cmd + V` (`Super + V`) unexpectedly triggered Hyprland window floating. Pressing `Cmd + W` failed to close windows.
* **Root Cause:**
  1. Default Linux terminals enforce `Ctrl + Shift + V` for paste.
  2. The previous Hyprland configuration bound `Super + V` directly to `togglefloating`, completely hijacking the Mac paste keystroke.
  3. Window closing was only bound to `Super + Q`, while Mac muscle memory expects `Cmd + W` (`Super + W`).
* **Fix Applied:**
  - **Universal Clipboard Dispatchers:** Added Hyprland keybinds to forward `Super + C` (Copy), `Super + V` (Paste), `Super + X` (Cut), `Super + A` (Select All), and `Super + Z` (Undo) straight to the active application window via `sendshortcut, CTRL, <KEY>, activewindow`.
  - **Foot Terminal Native Binds:** Configured `foot.ini` with `Mod4+v`, `Control+v`, and `Control+Shift+v` for paste, and `Mod4+c`, `Control+c`, and `Control+Shift+c` for copy. Now pasting works via `Cmd + V` or `Ctrl + V` everywhere without modifier acrobatics.
  - **Omarchy Standard Float Key:** Moved window floating toggle to **`Super + T`** (matching Omarchy 4.0 standard), freeing `Super + V` exclusively for pasting.
  - **Window Close Binds:** Added **`Super + W`** (`Cmd + W`), **`Super + Q`**, and **`Alt + F4`** to `killactive`.
  - **Clipboard History:** Integrated `cliphist` with automatic watchers for text and images. Accessible via **`Super + Ctrl + V`** or the top bar clipboard icon `󰅍`.

### B. True Omarchy Look & Feel (Waybar Redesign)
* **Symptom:** The top bar looked like a Windows 95 imitation with a bright blue ` Start` button, neon gaming borders (`#33ccff / #00ff99`), and redundant dock buttons cluttering the bar.
* **Root Cause:** The previous agent tried to build a hybrid dock instead of respecting Omarchy's minimalist, keyboard-centric aesthetic.
* **Fix Applied:**
  - Removed the cheesy `Start` text and blue button pill. Replaced it with an authentic Omarchy/Arch icon (``) in a subtle dark glass pill. Left-click opens Rofi application launcher (`Super + Space`), right-click opens Foot terminal (`Super + Return`).
  - Stripped out all redundant quick-launch icons from Waybar.
  - Redesigned the top bar with translucent Catppuccin Mocha styling (`rgba(30, 30, 46, 0.88)`), refined pill radius, and clean borders.
  - Replaced harsh neon green/cyan Hyprland window borders with refined lavender/blue gradient (`rgba(cba6f7ee) rgba(89b4faee) 45deg`) and clean inactive borders (`rgba(313244aa)`).
  - Added quick icons on the right for Clipboard History (`󰅍`), Shortcuts Cheatsheet (`󰌌`), and Power Menu (`⏻`).

### C. Intel UHD 630 Display Glitches (Horizontal Comb / Sawtooth Shearing)
* **Symptom:** Severe horizontal scanline comb artifacts, jagged sawtooth text, and sheared UI elements.
* **Root Cause:** Intel hardware Frame Buffer Compression (FBC) and Aquamarine `Y_TILED_CCS` modifier conflicts on high-resolution ultrawide outputs.
* **Fix Applied:**
  - Added `options i915 enable_fbc=0 enable_psr=0` to `/etc/modprobe.d/i915.conf`.
  - Added `i915.enable_fbc=0 i915.enable_psr=0` to kernel cmdline in `/boot/loader/entries/linux-t2.conf`.
  - Enforced `AQ_NO_MODIFIERS=1` in `/etc/environment` and `~/.config/hypr/hyprland.conf`.
  - Enforced `cursor { no_hardware_cursors = true }` in `hyprland.conf`.

### D. Thunderbolt 3 Display Connection
* **State:** Connected via single Thunderbolt 3 cable on port **`DP-1`** (Dell U4021QW 5K2K ultrawide configured at `2560x1080@60`).

### E. Autologin & Desktop Startup
* **State:** Getty autologin on `tty1` into user `stu`, automatically starting Hyprland via `~/.bash_profile`.

---

## 3. Configuration Map & Important Paths

| Service / Tool | Configuration File Path | Description |
| :--- | :--- | :--- |
| **Hyprland** | `~/.config/hypr/hyprland.conf` | Core window manager config, Omarchy keybindings, lavender-blue styling |
| **Waybar** | `~/.config/waybar/config.jsonc` | Status bar modules, Omarchy menu button, system monitors |
| **Waybar CSS** | `~/.config/waybar/style.css` | Translucent Catppuccin glass pills, elegant typography |
| **Foot Terminal** | `~/.config/foot/foot.ini` | Terminal emulator with `Mod4+v` / `Control+v` paste support |
| **Rofi (Launcher)**| `~/.config/rofi/config.rasi` | Application launcher and menu styling |
| **Clipboard History**| `~/.config/hypr/bin/clipboard-history.sh` | Cliphist popup via Rofi (`Super + Ctrl + V`) |
| **Power Menu** | `~/.config/hypr/bin/system-menu.sh` | System shutdown, reboot, lock menu (`Super + Escape`) |
| **Cheatsheet Script**| `~/.config/hypr/bin/shortcuts-menu.sh` | Searchable popup triggered by `Super + K` or `Alt + K` |
| **Agent Selector**| `~/.config/hypr/bin/default-agent.sh` | AI agent launcher (`Super + Shift + A` / `Super + Alt + A`) |
| **Crash Watcher** | `~/.config/hypr/bin/crash-watch.sh` | Monitors `systemd-coredump` and offers 1-click AI fix |
| **Guide Repository**| `/home/stu/arch-hyprland-guide/` | Tracked git repository containing installer and dotfiles |

---

## 4. Key Keyboard & Mouse Shortcuts (Omarchy / Mac Native)

| Category | Shortcut / Action | Function |
| :--- | :--- | :--- |
| **Clipboard** | `Super + C` | Universal Copy (`Cmd + C`) |
| **Clipboard** | `Super + V` | Universal Paste (`Cmd + V` — no `Ctrl+Shift+V`!) |
| **Clipboard** | `Super + X` | Universal Cut (`Cmd + X`) |
| **Clipboard** | `Super + A` | Select All (`Cmd + A`) |
| **Clipboard** | `Super + Ctrl + V` | Open Clipboard History & Paste (Cliphist) |
| **Window** | `Super + W` | Close focused window (`Cmd + W`) |
| **Window** | `Super + Q` | Close focused window (`Cmd + Q`) |
| **Window** | `Super + T` | Toggle window floating / tiling mode |
| **Window** | `Super + F` | Toggle fullscreen |
| **Window** | `Super + J` | Toggle window split direction (horizontal / vertical) |
| **Launcher** | `Super + Space` or `Alt + Space` | Opens Rofi application launcher |
| **Cheatsheet**| `Super + K` or `Alt + K` | Opens searchable shortcuts popup |
| **Terminal** | `Super + Return` | Opens Foot terminal |
| **Browser** | `Super + Shift + Return` / `Super + B` | Opens default web browser |
| **Files** | `Super + E` | Opens Thunar file manager |
| **Notes** | `Super + Shift + O` | Opens Obsidian Markdown notes |
| **Monitor** | `Super + Ctrl + T` | Opens `btop` activity monitor |
| **Power Menu**| `Super + Escape` | Lock, Logout, Reboot, Shutdown menu |
| **Lock** | `Super + L` | Lock screen immediately |
| **AI Agent** | `Super + Shift + A` | Launches default AI agent |
| **Mouse** | Hover border & Drag | Resize window directly without keys |
| **Mouse** | `Super + Left-Click Drag` | Move window |
| **Mouse** | `Super + Right-Click Drag`| Resize window |
| **Mouse** | `Super + Middle-Click` | Toggle window floating |
| **Capture** | `Super + Shift + S` | Select area with mouse and copy screenshot |
| **Capture** | `PrintScreen` | Save full screenshot to `~/Pictures/Screenshots/` |
