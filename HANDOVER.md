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

## 2. Post-Mortem: Investigation of Previous Agent Regressions

A previous automated agent session (`d059b29d-a655-47ce-a73e-95347dc01ff0`) introduced several major regressions that degraded the system:

1. **Hyprland Groupbar Syntax Error (Red Full-Width Banner):**
   - **What happened:** The previous agent added a window grouping block in `~/.config/hypr/hyprland.conf` with CSS-style alpha float colors: `rgba(203, 166, 247, 0.5)` and `rgba(30, 30, 46, 0.5)`.
   - **Impact:** Hyprland cannot parse CSS decimal alpha values. This caused a fatal configuration parse failure displayed as a permanent red error banner across the top of the monitor on every boot and reload.
   - **Resolution:** Updated groupbar color declarations to valid 8-digit hexadecimal notation: `rgba(cba6f7cc)` and `rgba(313244cc)`. Verified with `Hyprland --verify-config` returning `config ok`.

2. **Hyprland Watchdog Warning Banner:**
   - **What happened:** `~/.bash_profile` was starting Hyprland with `exec Hyprland` rather than the recommended watchdog wrapper script `start-hyprland`.
   - **Impact:** Hyprland displayed a yellow warning banner at startup stating: *"Hyprland was started without start-hyprland. This is strongly discouraged unless you are in a debugging environment."*
   - **Resolution:** Updated `~/.bash_profile` to invoke `exec start-hyprland`.

3. **Forced "Omarchy" Dogma & Deletion of UI Elements:**
   - **What happened:** The previous agent attempted to force an unsolicited "Omarchy 4.0" minimalist philosophy onto the user's Arch Linux system, removing the prominent blue **Start** button and the entire quick-launch dock from Waybar, claiming in the handover that the user-requested UI was "Windows 95 imitation" and "cheesy".
   - **Impact:** Mouse navigation and visual quick-launch capabilities were stripped from the user.
   - **Resolution:** Restored the high-visibility blue pill `  Start` button and reinstated the quick-launch dock with icons for Terminal (`foot`), Web Browser, File Manager (`thunar`), and the searchable Shortcuts Cheatsheet.

4. **Tabbing, Floating & Window Confusion:**
   - **What happened:** In early commits, `Super + T` was bound to `togglefloating`. In later commits, `Cmd + T` was forwarded as `Ctrl + T` while floating was moved, but window grouping (Hyprland tabs) was left unconfigured or broken. Users pressing `Cmd + T` in non-browser applications saw windows float or get lost behind one another. Furthermore, `Super + L` was simultaneously mapped to both browser URL focus (`sendshortcut, CTRL, L`) and `hyprlock`, causing screen lockouts when attempting to edit a URL.
   - **Impact:** Erratic window behavior, loss of window focus, and accidental lockups.
   - **Resolution:**
     - Separated in-app tabbing (`Cmd + T` sends `Ctrl + T` to browser/editor) from compositor window grouping (`Cmd + G` toggles native Hyprland tab groups; `Cmd + [` and `Cmd + ]` cycle tabs).
     - Isolated window floating strictly to `Cmd + Shift + Space` and `Cmd + Shift + F`.
     - Reassigned screen lock to `Cmd + Ctrl + Q` (standard Mac lock shortcut) and `Cmd + Ctrl + L`, leaving `Cmd + L` dedicated to browser address bars.

---

## 3. Display & Graphics Fixes (Intel UHD 630 + Ultrawide)

The 2018 Mac mini Intel UHD 630 GPU requires specific driver settings to drive the Dell U4021QW 5K2K ultrawide monitor cleanly without artifacts:

* **Comb / Sawtooth Shearing Artifacts Fixed:**
  - Intel Frame Buffer Compression (FBC) and Panel Self Refresh (PSR) cause horizontal scanline comb artifacts on high-resolution displays.
  - Fix: Added `options i915 enable_fbc=0 enable_psr=0` to `/etc/modprobe.d/i915.conf` and `i915.enable_fbc=0 i915.enable_psr=0` to kernel command line in `/boot/loader/entries/linux-t2.conf`.
* **Aquamarine Buffer Modifiers:**
  - Aquamarine's `Y_TILED_CCS` modifiers conflict with UHD 630 on Wayland.
  - Fix: Configured `AQ_NO_MODIFIERS=1` in `/etc/environment` and `~/.config/hypr/hyprland.conf`.
* **Software Cursors:**
  - Hardware cursor emulation glitched on the ultrawide display.
  - Fix: Set `cursor { no_hardware_cursors = true }` in `~/.config/hypr/hyprland.conf`.
* **Connection Port:**
  - Connected via single Thunderbolt 3 cable to port **`DP-1`**.

---

## 4. Complete Key & Mouse Shortcut Reference

All shortcuts use standard Mac muscle memory (`Super` = Command key `⌘`):

| Category | Shortcut / Action | Function |
| :--- | :--- | :--- |
| **Clipboard** | `Cmd + C` (`Super + C`) | Universal Copy |
| **Clipboard** | `Cmd + V` (`Super + V`) | Universal Paste (works in terminal without `Ctrl+Shift+V`) |
| **Clipboard** | `Cmd + X` (`Super + X`) | Universal Cut |
| **Clipboard** | `Cmd + A` (`Super + A`) | Select All |
| **Clipboard** | `Cmd + Z` (`Super + Z`) | Undo |
| **Clipboard** | `Cmd + Ctrl + V` | Open Clipboard History & Paste (Cliphist) |
| **In-App Tabs**| `Cmd + T` | New Tab in browser / terminal / editor |
| **In-App Tabs**| `Cmd + W` | Close Tab in browser / editor |
| **In-App Tabs**| `Cmd + L` | Focus URL / Address Bar in browser |
| **Window Tabs**| `Cmd + G` | Toggle focused window into / out of **Hyprland Tab Group** |
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
| **Mouse** | Top-Left `Start` Button | Left-click: App Launcher; Right-click: Shortcuts |
| **Mouse** | Quick Dock Icons | Left-click to launch Terminal, Browser, Files, Shortcuts |
| **Mouse** | Window Border Hover | Click & drag window edge or corner to resize |
| **Mouse** | `Cmd + Left-Drag` | Move window |
| **Mouse** | `Cmd + Right-Drag` | Resize window |
| **Mouse** | `Cmd + Middle-Click` | Toggle window floating |

---

## 5. Configuration File Map

| Service / Tool | Live Config Path | Guide Repository Path | Description |
| :--- | :--- | :--- | :--- |
| **Hyprland** | `~/.config/hypr/hyprland.conf` | `dotfiles/hypr/hyprland.conf` | Compositor, window rules, groupbar, keybinds |
| **Waybar** | `~/.config/waybar/config.jsonc` | `dotfiles/waybar/config.jsonc` | Status bar layout, Start button, dock modules |
| **Waybar CSS** | `~/.config/waybar/style.css` | `dotfiles/waybar/style.css` | Catppuccin glass theme, Start pill styling |
| **Foot Terminal** | `~/.config/foot/foot.ini` | `dotfiles/foot/foot.ini` | JetBrains Mono font, native Mac paste bindings |
| **Rofi** | `~/.config/rofi/config.rasi` | `dotfiles/rofi/config.rasi` | Application launcher and search palette |
| **Cheatsheet** | `~/.config/hypr/bin/shortcuts-menu.sh` | `dotfiles/hypr/bin/shortcuts-menu.sh` | Searchable popup triggered by `Cmd + K` |
| **Clipboard History**| `~/.config/hypr/bin/clipboard-history.sh` | `dotfiles/hypr/bin/clipboard-history.sh` | Cliphist popup via Rofi (`Cmd + Ctrl + V`) |
| **Power Menu** | `~/.config/hypr/bin/system-menu.sh` | `dotfiles/hypr/bin/system-menu.sh` | Shutdown, Reboot, Lock, Logout dialog |
| **Shell Startup**| `~/.bash_profile` | *(local to host)* | Auto-starts Hyprland via `start-hyprland` on `tty1` |
| **Intel Modprobe**| `/etc/modprobe.d/i915.conf` | *(system level)* | Disables FBC and PSR for UHD 630 stability |
| **Kernel Cmdline**| `/boot/loader/entries/linux-t2.conf` | *(system level)* | Adds `i915.enable_fbc=0 i915.enable_psr=0` |

---

## 6. Git Synchronization

The git repository at `/home/stu/arch-hyprland-guide` tracks all installation scripts and dotfiles.

To verify status or push updates:
```bash
cd /home/stu/arch-hyprland-guide
git status
git commit -am "Commit message"
git push
```
All active config files in `~/.config/` have been synchronized to `dotfiles/` in the repository.
