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

### A. Intel UHD 630 Display Glitches (Horizontal Comb / Sawtooth Shearing)
* **Symptom:** Entire screen suffered from severe horizontal scanline comb artifacts, jagged sawtooth text, sheared UI elements, and a corrupted rectangular comb cursor.
* **Root Cause:** 
  1. Intel hardware **Frame Buffer Compression (FBC)** actively compressing scanout buffers on high-resolution ultrawide outputs.
  2. Aquamarine (Hyprland DRM backend) negotiated Intel's proprietary `Y_TILED_CCS` (Color Control Surface) compressed memory modifiers (`modifier 0x100000000000004`), which misaligned scanlines in the DRM/KMS scanout pipeline.
  3. Intel hardware cursor plane glitching.
* **Fix Applied:**
  - Added `options i915 enable_fbc=0 enable_psr=0` to [`/etc/modprobe.d/i915.conf`](file:///etc/modprobe.d/i915.conf).
  - Appended `i915.enable_fbc=0 i915.enable_psr=0` to `/boot/loader/entries/linux-t2.conf`.
  - Regenerated initramfs via `sudo mkinitcpio -P`. Verified via debugfs: `i915_fbc_status` is `FBC disabled`.
  - Added `AQ_NO_MODIFIERS=1` to [`/etc/environment`](file:///etc/environment), [`~/.bash_profile`](file:///home/stu/.bash_profile), and [`~/.config/hypr/hyprland.conf`](file:///home/stu/.config/hypr/hyprland.conf) to enforce linear buffers.
  - Added `cursor { no_hardware_cursors = true }` in `hyprland.conf` to force software cursor rendering.

### B. Display Connection (Thunderbolt 3 vs Dual-Cable Ghosting)
* **Symptom:** When switching cables, monitor showed a black screen or split workspaces across two virtual monitors.
* **Root Cause:** The Mac mini had two cables connected simultaneously to the Dell U4021QW (a USB-C to HDMI adapter and the Thunderbolt 3 cable). Hyprland treated them as dual displays (`DP-1` and `DP-3`), placing Waybar on one and blank desktop on the other.
* **Fix Applied:**
  - Removed the old HDMI cable. The monitor is now connected via a **single Thunderbolt 3 cable** on connector **`DP-1`**.
  - Configured `monitor = DP-1, 2560x1080@60, 0x0, 1` (with fallback mirror and 5K2K options commented for user preference) in [`hyprland.conf`](file:///home/stu/.config/hypr/hyprland.conf).

### C. Autologin & Direct Desktop Startup
* **Symptom:** User had to type username, password, and `Hyprland` manually on every reboot.
* **Fix Applied:**
  - Configured systemd getty override at [`/etc/systemd/system/getty@tty1.service.d/autologin.conf`](file:///etc/systemd/system/getty@tty1.service.d/autologin.conf) for automatic login of user `stu` on `tty1`.
  - Added automatic Wayland startup hook in [`~/.bash_profile`](file:///home/stu/.bash_profile):
    ```bash
    export AQ_NO_MODIFIERS=1
    if [[ -z "$WAYLAND_DISPLAY" ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
        exec Hyprland
    fi
    ```

### D. Start Button & Quick-Launch Dock (Waybar)
* **Symptom:** User wanted a friendly, intuitive mouse workflow like Omarchy (not strict hotkey-only).
* **Fix Applied:**
  - Added a distinct blue **` Start`** button pill on the top-left of Waybar ([`~/.config/waybar/config.jsonc`](file:///home/stu/.config/waybar/config.jsonc)). Left-clicking opens the Rofi application menu.
  - Added quick-launch icon buttons for Terminal (`foot`), Web Browser, Thunar File Manager, and the Shortcuts Cheatsheet.

### E. Wallpaper Daemon (Hyprpaper v0.8+ Syntax)
* **Symptom:** Wallpaper disappeared on reboot; black screen with falling blue Hyprland triangles.
* **Root Cause:** Hyprpaper v0.8 deprecated legacy `wallpaper = , /path` and requires block syntax (`wallpaper { monitor = ... path = ... }`).
* **Fix Applied:**
  - Updated [`~/.config/hypr/hyprpaper.conf`](file:///home/stu/.config/hypr/hyprpaper.conf) with modern block syntax for `DP-1`, `DP-3`, and universal fallback.
  - Disabled Hyprland default splash text and falling triangle logo animations in `misc { disable_hyprland_logo = true; disable_splash_rendering = true; }`.

### F. GitHub CLI & Git Setup
* **State:** User authenticated via `gh auth login` as **`funstuie-bit`**.
* **Protocol:** HTTPS with git credential helper enabled (`gh auth setup-git`).
* **Repo State:** Local branch `master` is synchronized with remote `origin/master`.

---

## 3. Configuration Map & Important Paths

| Service / Tool | Configuration File Path | Description |
| :--- | :--- | :--- |
| **Hyprland** | `~/.config/hypr/hyprland.conf` | Core window manager config, binds, mouse resize rules, env vars |
| **Waybar** | `~/.config/waybar/config.jsonc` | Status bar modules, Start button, quick launch dock |
| **Waybar CSS** | `~/.config/waybar/style.css` | Translucent pill theme styling and 14px readable font sizing |
| **Hyprpaper** | `~/.config/hypr/hyprpaper.conf` | Wallpaper preloading and monitor assignment |
| **Wallpaper** | `~/.config/hypr/wallpaper.png` | Catppuccin-themed minimalist geometric wallpaper |
| **Rofi (Launcher)**| `~/.config/rofi/config.rasi` | Application launcher and cheatsheet styling (JetBrainsMono 13px) |
| **Foot Terminal** | `~/.config/foot/foot.ini` | Lightweight terminal emulator (Catppuccin Mocha, size 13 font) |
| **Mako Notifications**| `~/.config/mako/config` | Desktop notification styling and positions |
| **Cheatsheet Script**| `~/.config/hypr/bin/shortcuts-menu.sh` | Searchable popup triggered by `Super + K` or `Alt + K` |
| **Agent Selector**| `~/.config/hypr/bin/default-agent.sh` | AI agent launcher (`Super + Shift + A` / `Super + Alt + A`) |
| **Crash Watcher** | `~/.config/hypr/bin/crash-watch.sh` | Monitors `systemd-coredump` and offers 1-click AI fix |
| **Autologin Override**| `/etc/systemd/system/getty@tty1.service.d/autologin.conf` | Systemd autologin configuration for tty1 |
| **Boot Entry** | `/boot/loader/entries/linux-t2.conf` | Kernel command line with `i915.enable_fbc=0` |
| **Modprobe i915** | `/etc/modprobe.d/i915.conf` | `options i915 enable_fbc=0 enable_psr=0` |
| **Guide Repository**| `/home/stu/arch-hyprland-guide/` | Tracked git repository containing installer and dotfiles |

---

## 4. Key Keyboard & Mouse Shortcuts

| Category | Shortcut / Action | Function |
| :--- | :--- | :--- |
| **Launcher** | Click ` Start` on Waybar | Opens mouse-clickable application launcher |
| **Launcher** | `Super + Space` or `Alt + Space` | Opens Rofi application launcher |
| **Cheatsheet**| `Super + K` or `Alt + K` | Opens searchable shortcuts popup |
| **Terminal** | `Super + Return` | Opens Foot terminal |
| **Browser** | `Super + B` | Opens default web browser (Firefox / Zen / Chromium) |
| **Files** | `Super + E` | Opens Thunar file manager |
| **Notes** | `Super + Shift + O` | Opens Obsidian Markdown notes |
| **Monitor** | `Super + Ctrl + T` | Opens `btop` system monitor |
| **Music** | `Super + M` | Launches Cliamp retro music player |
| **AI Agent** | `Super + Shift + A` | Launches default AI agent (`agy`, `claude`, etc.) |
| **Window** | `Super + Q` | Close focused window |
| **Window** | `Super + V` | Toggle floating mode |
| **Window** | `Super + F` | Toggle fullscreen |
| **Mouse** | Hover border & Drag | **Resize window directly without keys** |
| **Mouse** | `Super + Left-Click Drag` | Move window |
| **Mouse** | `Super + Right-Click Drag`| Resize window |
| **Capture** | `Super + Shift + S` | Select area with mouse and copy screenshot |
| **Capture** | `PrintScreen` | Save full screenshot to `~/Pictures/Screenshots/` |

---

## 5. Helpful Commands for the Next Agent

```bash
# 1. Check active monitors, resolutions, and refresh rates:
hyprctl monitors

# 2. Reload Hyprland configuration on the fly:
hyprctl reload

# 3. Check Intel Frame Buffer Compression status (must report disabled):
sudo cat /sys/kernel/debug/dri/1/i915_fbc_status

# 4. Check Apple T2 fan daemon:
systemctl status t2fanrd

# 5. Check Apple T2 audio sink:
wpctl status

# 6. Verify Git status of the guide repo:
cd /home/stu/arch-hyprland-guide && git status
```
