# Clean Arch Linux + Hyprland on 2018 Mac mini

A lightweight, transparent, and independently configured Arch Linux + Hyprland desktop designed for the **2018 Intel Mac mini (T2 / Intel UHD 630)**.

This setup extracts the best productivity innovations of Omarchy into a **clean, modular "Lite" build**—without DHH's monolithic Lua layer, forced branding, proprietary update mechanisms, or opinionated bloat.

### Key Features
- **🤖 Built-in AI Agent & 1-Click Crash Diagnosis:** System crashes monitored via `systemd-coredump` send a notification. Clicking it opens a dedicated Foot terminal running your default agent (`agy`, `claude`, `codex`, `opencode`, or `omp`) with the crash trace and resolution prompt pre-loaded.
- **⌨️ `Super + K` Cheatsheet Popup:** Searchable, categorized hotkey and mouse guide powered by Rofi. No memorization required.
- **🎵 Cliamp Retro Music Player:** Terminal-based music player inspired by Winamp 2.x with built-in lo-fi streams (`Super + M`).
- **📦 Curated Software Suite:** Fast TUIs (`btop`, `dua-cli`, `fastfetch`, `tmux`), modern CLI replacements (`zoxide`, `fzf`, `ripgrep`, `fd`, `bat`, `eza`, `tldr`, `yt-dlp`), and graphical apps (`obsidian`, `localsend`, `libreoffice`, `imv`, `mpv`, `pinta`, `obs-studio`, `kdenlive`, `firefox`, `zen-browser`, `chromium`, `ollama`, `llama.cpp`).
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
1. Download the pre-patched **T2 Arch Linux ISO** directly from GitHub Releases:
   - **Direct ISO Download:** [t2linux/archiso-t2 Releases](https://github.com/t2linux/archiso-t2/releases) (e.g., [Release 2026.03.07](https://github.com/t2linux/archiso-t2/releases/tag/2026.03.07))
   - **Installation Documentation:** [T2 Linux Arch Installation Guide](https://wiki.t2linux.org/distributions/arch/installation/)
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

Once booted into your new Arch Linux terminal:

### Step 1: Connect to Internet (if on Wi-Fi)
```bash
# Connect directly:
nmcli device wifi connect "Your_SSID" password "Your_Password"

# Or use the interactive text menu:
nmtui
```

### Step 2: Enable SSH (Recommended for Easy Setup & Copy-Pasting)
Enabling SSH lets you log in from your Mac/laptop terminal so you can easily copy and paste commands:

1. **On your Mac mini (in the TTY):**
   ```bash
   sudo pacman -Sy --needed --noconfirm openssh
   sudo systemctl enable --now sshd
   ip -br a
   ```
   *(Find the `192.168.x.x` address next to `wlan0` or Ethernet)*

2. **From your laptop terminal:**
   ```bash
   ssh yourusername@<MAC_MINI_IP>
   ```

*(Optional: Transfer your logged-in `agy` token directly from your Mac to the Mac mini:)*
```bash
# Run this from your Mac terminal:
ssh yourusername@<MAC_MINI_IP> "mkdir -p ~/.gemini/antigravity-cli"
scp ~/.gemini/antigravity-cli/antigravity-oauth-token yourusername@<MAC_MINI_IP>:~/.gemini/antigravity-cli/
```

### Step 3: Ensure Git and Sudo Are Ready
On a minimal Arch install, `git` is not installed by default. Install it:
```bash
sudo pacman -Sy --needed --noconfirm git
```
*(If you are logged in as `root`, create your standard user and configure sudo first:)*
```bash
useradd -m -G wheel -s /bin/bash yourusername
passwd yourusername
pacman -Sy --needed --noconfirm sudo
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
su - yourusername
```

### Step 4: Clone and Run the Setup
As your regular user:
```bash
git clone https://github.com/funstuie-bit/arch-hyprland-guide.git
cd arch-hyprland-guide
./install.sh
```

The script includes automatic pre-flight checks and will:
1. Install Intel UHD 630 drivers, Hyprland, Waybar, Rofi, Foot, PipeWire audio, fonts, and utilities.
2. Install your curated software suite (TUIs, modern shell, GUIs, browsers, and AI tools).
3. Install **Cliamp** terminal music player directly into `/usr/local/bin/cliamp`.
4. Install `yay` and AUR packages (`zen-browser-bin`, `localsend-bin`, `mise-bin`, `lm-studio-bin`).
5. Enable `NetworkManager`, `bluetooth`, and `ollama` system services.
6. Back up existing configs and deploy mouse-friendly dotfiles to `~/.config/`.
7. Set up the AI crash diagnosis daemon and default agent configuration.

To start your graphical desktop, run:
```bash
Hyprland
```

---

## 4. Software Suite Installed in This Build

### 1. Terminal Utilities & TUIs
* **`cliamp`**: Retro Winamp 2.x music player with built-in lo-fi streams (`Super + M`).
* **`btop`**: Beautiful resource monitor for CPU, RAM, disks, and processes (`Super + Ctrl + T`).
* **`dua-cli`**: Fast interactive disk space explorer (`dua i`).
* **`fastfetch`**: Fast, modern system information banner.
* **`tmux`**: Terminal multiplexer for persistent sessions, tabs, and splits.

### 2. Enhanced Shell Replacements
* **`zoxide` (`z`)**: Intelligent directory jumper that learns your habits (`z doc` jumps straight to `~/Documents/...`).
* **`fzf`**: Interactive fuzzy finder for files and shell history (`Ctrl + R`).
* **`ripgrep` (`rg`)**: Ultra-fast regex text search through entire projects.
* **`fd`**: Intuitive, colorized replacement for `find`.
* **`bat`**: Syntax-highlighted `cat` with line numbers and git diffs.
* **`eza`**: Modern, colorized `ls` with tree views and icons.
* **`tealdeer` (`tldr`)**: Instant, practical command examples instead of 20-page man pages.
* **`yt-dlp`**: Download video and audio from hundreds of sites directly from the terminal.

### 3. Graphical Applications (GUIs)
* **`localsend`**: Cross-platform, private AirDrop alternative for local network sharing.
* **`obsidian`**: Extensible Markdown note-taking app (`Super + Shift + O`).
* **`evince`**: Clean GNOME document and PDF viewer.
* **`xournalpp`**: PDF annotation, highlighting, and handwriting tool.
* **`libreoffice-fresh`**: Full office suite (Writer, Calc, Impress).
* **`pinta`**: Simple paint and image editing program.
* **`obs-studio`**: Screen recording and live streaming studio.
* **`kdenlive`**: Multi-track video editor.
* **`gnome-disk-utility`**: Format drives, check SMART health, and manage partitions.
* **`imv`**: Ultra-fast Wayland image viewer.
* **`mpv`**: Minimalist media player with hardware video acceleration.
* **`pavucontrol`**: Audio mixer and volume control GUI.

### 4. Web Browsers
* **`firefox`**: Native Wayland Firefox browser.
* **`zen-browser`**: Modern Firefox fork focused on vertical tabs, spaces, and speed.
* **`chromium`**: Fast open-source Chromium browser.

### 5. Communication & Chat
* **`telegram-desktop`**: Official fast, native Telegram messaging app.
* **`discord`**: Official Discord voice, video, and community chat client.

### 6. Development & AI Tools
* **`neovim`**: Modern terminal code editor.
* **`mise-bin`**: Universal runtime manager for Node.js, Python, Ruby, Go, and Rust.
* **`gh`**: Official GitHub command-line interface.
* **`ollama`**: Local model runner for open-weights models like Llama 3 (`systemctl status ollama`).
* **`llama.cpp`**: Fast local LLM inference engine.
* **`lm-studio`**: Desktop GUI for downloading and chatting with local AI models.
* **AI Coding Agents**: Compatible with `agy` (Google Antigravity), `claude` (Claude Code), `codex`, `opencode`, and `omp` (Oh My Pi).

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
| **Toggle Floating** | Hold `Super` + Middle-Click (or `Super + T`) |
| **Switch Workspaces** | Hold `Super` + Mouse Scroll Wheel |

### Interactive Status Bar (Waybar) & Omarchy Menu
- **Omarchy / Arch Menu Icon (``):** Sleek top-left icon in a translucent pill. Left-click opens the Rofi application launcher (`Super + Space`), right-click opens a new Foot terminal (`Super + Return`).
- **Workspaces:** Minimalist workspace numbers showing active and urgent states.
- **Audio:** Scroll to increase/decrease volume. Left-click to toggle mute. Right-click to open `pavucontrol` mixer.
- **Hardware & Network:** Live CPU usage, RAM utilization, and network connection status.
- **Clipboard History Icon (`󰅍`):** Quick mouse click to open the `cliphist` clipboard manager.
- **Shortcuts Cheatsheet Icon (`󰌌`):** Quick mouse click to open the `Super + K` popup cheatsheet.
- **Clock:** Clean formatted date/time with interactive calendar popup.
- **Power:** Click power icon or press `Super + Escape` for the system shutdown/reboot/lock menu.


---

## 6. Shortcuts Cheatsheet

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| `Super + C` | **Universal Copy** | Copies selection to clipboard (`Cmd + C`) |
| `Super + V` | **Universal Paste** | Pastes clipboard (`Cmd + V` — works in terminal & GUI alike!) |
| `Super + X` | **Universal Cut** | Cuts selection (`Cmd + X`) |
| `Super + A` | **Select All** | Selects all (`Cmd + A`) |
| `Super + Ctrl + V` | **Clipboard History** | Opens searchable clipboard manager (Cliphist) |
| `Super + W` | **Close Window** | Closes the focused window (`Cmd + W`) |
| `Super + Q` | **Close Window** | Closes the focused window (`Cmd + Q` / Linux standard) |
| `Super + T` | **Toggle Floating** | Detaches window from tiling grid |
| `Super + J` | **Toggle Split** | Toggles split direction (horizontal / vertical) |
| `Super + F` | **Fullscreen** | Toggles fullscreen for active window |
| `Super + K` | **Shortcuts Cheatsheet** | Searchable popup listing all key/mouse shortcuts |
| `Super + Space` | **App Launcher** | Opens Rofi application search (mouse clickable) |
| `Super + Return` | **Terminal** | Opens Foot terminal emulator |
| `Super + Shift + Return`| **Web Browser** | Opens default web browser |
| `Super + B` | **Web Browser** | Opens default web browser (Firefox/Zen/Chromium) |
| `Super + E` | **File Manager** | Opens Thunar graphical file manager |
| `Super + Shift + O`| **Obsidian** | Opens Obsidian notes |
| `Super + Ctrl + T` | **Activity Monitor** | Opens `btop` system monitor in floating window |
| `Super + M` | **Cliamp Music** | Launches retro terminal music player |
| `Super + Shift + A`| **Launch AI Agent** | Opens default agent (`agy`, `claude`, `codex`, `opencode`, `omp`) |
| `Super + Alt + A` | **Pick AI Agent** | Select / change default AI agent |
| `Super + Escape` | **System Menu** | Opens power menu (Lock, Logout, Reboot, Shutdown) |
| `Super + L` | **Lock Screen** | Locks session via `hyprlock` |
| `Super + Shift + S`| **Screenshot Area** | Select rectangular area with mouse and copy to clipboard |
| `PrintScreen` | **Full Screenshot** | Saves screenshot to `~/Pictures/Screenshots/` |
| `Super + 1 .. 9, 0`| **Workspaces** | Switch to workspaces 1 through 10 |
| `Super + Shift + 1..0`| **Move to Workspace**| Move active window to chosen workspace |
| `Super + Arrow Keys`| **Focus Window** | Move focus to left, right, up, or down window |

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
    │       ├── default-agent.sh   # AI agent selector & launcher (agy, claude, codex, opencode, omp)
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

### Apple T2 Kernel, Wi-Fi & Audio
The installer automatically detects Apple T2 hardware and configures the official `[arch-mact2]` repository and packages. If configuring manually, add the repository to `/etc/pacman.conf`:
```ini
[arch-mact2]
Server = https://mirror.funami.tech/arch-mact2/os/x86_64
SigLevel = Never
```
Then install `linux-t2`, `linux-t2-headers`, `apple-t2-audio-config`, `apple-bcm-firmware`, and `t2fanrd`:
```bash
sudo pacman -Sy --needed linux-t2 linux-t2-headers apple-t2-audio-config apple-bcm-firmware t2fanrd
sudo systemctl enable --now t2fanrd
```

### Intel UHD 630 Graphics Glitch Prevention (Sawtooth / Comb Artifacts)
On the 2018 Mac mini (Coffee Lake Intel UHD 630), Wayland compositors can suffer from severe horizontal shearing and comb-like artifacts caused by Intel hardware Frame Buffer Compression (FBC) and Color Control Surface (CCS) buffer modifiers. 

To permanently prevent this:
1. **Disable i915 Frame Buffer Compression & PSR:**
   Create `/etc/modprobe.d/i915.conf`:
   ```ini
   options i915 enable_fbc=0 enable_psr=0
   ```
   And append `i915.enable_fbc=0 i915.enable_psr=0` to the `options` line in `/boot/loader/entries/linux-t2.conf`, then run `sudo mkinitcpio -P`.
2. **Disable DRM Modifiers in Wayland:**
   Add to `/etc/environment` and `~/.bash_profile`:
   ```bash
   export AQ_NO_MODIFIERS=1
   ```
   And in `~/.config/hypr/hyprland.conf`:
   ```ini
   env = AQ_NO_MODIFIERS,1
   cursor {
       no_hardware_cursors = true
   }
   ```

### Thunderbolt 3 & High-Resolution Ultrawide Displays
- For high-resolution displays (such as the Dell U4021QW 5K2K 40" Ultrawide), connect directly via a **Thunderbolt 3 cable** to the Mac mini's USB-C ports (detected as `DP-1`).
- Avoid connecting multiple display cables (e.g. HDMI and Thunderbolt simultaneously) to the same monitor, as Hyprland will treat them as two separate displays.
- If text/icons appear too small, open `~/.config/hypr/hyprland.conf` and adjust the monitor scaling line:
```ini
# Native resolution with 1.5x or 1.6x HiDPI scaling
monitor = DP-1, preferred, auto, 1.5
```

### Automatic Login & Direct Desktop Startup
To boot directly into Hyprland without typing your username, password, or `Hyprland` command:
1. **Autologin on tty1:** Create `/etc/systemd/system/getty@tty1.service.d/autologin.conf`:
   ```ini
   [Service]
   ExecStart=
   ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin yourusername %I $TERM
   ```
   Then reload systemd: `sudo systemctl daemon-reload`.
2. **Auto-launch Hyprland:** Add to `~/.bash_profile`:
   ```bash
   export AQ_NO_MODIFIERS=1
   if [[ -z "$WAYLAND_DISPLAY" ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
       exec Hyprland
   fi
   ```

### Reloading Hyprland
Whenever you edit `~/.config/hypr/hyprland.conf`, Hyprland reloads automatically. If needed, force a reload and check for syntax errors:
```bash
hyprctl reload
hyprctl configerrors
```

