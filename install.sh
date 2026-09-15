#!/usr/bin/env bash
# ##############################################################################
# Arch Linux + Hyprland Setup & Dotfiles Installer
# Configured for 2018 Mac mini (T2 / Intel UHD 630) and mouse-friendly workflow
# ##############################################################################

set -euo pipefail
trap 'printf "Installation stopped at line %s. Resolve the reported error before rerunning.\n" "$LINENO" >&2' ERR

BOLD="$(tput bold 2>/dev/null || true)"
GREEN="$(tput setaf 2 2>/dev/null || true)"
YELLOW="$(tput setaf 3 2>/dev/null || true)"
BLUE="$(tput setaf 4 2>/dev/null || true)"
RED="$(tput setaf 1 2>/dev/null || true)"
RESET="$(tput sgr0 2>/dev/null || true)"

log()    { echo "${GREEN}${BOLD}[INFO]${RESET} $*"; }
warn()   { echo "${YELLOW}${BOLD}[WARN]${RESET} $*"; }
err()    { echo "${RED}${BOLD}[ERROR]${RESET} $*" >&2; }
header() { echo -e "\n${BLUE}${BOLD}=== $* ===${RESET}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -----------------------------------------------------------------------------
# 0. PRE-FLIGHT CHECKS
# -----------------------------------------------------------------------------
header "0. Pre-Flight Checks"

# Check 1: Root check
if [[ "${EUID}" -eq 0 ]]; then
    err "This installer should NOT be run directly as root."
    err "Building AUR packages and deploying user configs to ~/.config requires a standard user account."
    echo ""
    echo "If you only have a root account right now, create a standard user by running:"
    echo "  ${BOLD}useradd -m -G wheel -s /bin/bash <your-username>${RESET}"
    echo "  ${BOLD}passwd <your-username>${RESET}"
    echo "  ${BOLD}echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel${RESET}"
    echo "  ${BOLD}su - <your-username>${RESET}"
    echo "  ${BOLD}cd ${SCRIPT_DIR} && ./install.sh${RESET}"
    exit 1
fi

# Check 2: Sudo availability
if ! command -v sudo >/dev/null 2>&1; then
    err "'sudo' is not installed."
    echo "Please install sudo and configure your user by running (as root):"
    echo "  ${BOLD}su -c 'pacman -Syu --noconfirm sudo && echo \"%wheel ALL=(ALL:ALL) ALL\" > /etc/sudoers.d/wheel'${RESET}"
    exit 1
fi

# Check 3: Sudo permissions test
if ! sudo -v 2>/dev/null; then
    warn "Testing sudo privileges..."
    if ! sudo true; then
        err "Your user does not have sudo privileges."
        echo "Ensure your user is in the 'wheel' group and wheel has sudo access in /etc/sudoers."
        exit 1
    fi
fi

# Check 4: Internet connectivity
log "Checking network connectivity..."
if ! curl -s --head https://archlinux.org >/dev/null 2>&1 && ! ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
    err "No active internet connection detected."
    echo ""
    echo "To connect to Wi-Fi from the command line, run:"
    echo "  ${BOLD}nmcli device wifi connect 'Your_SSID' password 'Your_Password'${RESET}"
    echo "Or run the interactive menu:"
    echo "  ${BOLD}nmtui${RESET}"
    exit 1
fi
log "Network connection verified."

header "Arch + Hyprland Bootstrap"
echo "This script will install:"
echo " 1. Desktop & graphics drivers (Intel UHD 630, Hyprland, Waybar, Mako, Foot)"
echo " 2. Terminal TUIs (btop, dua-cli, fastfetch, tmux, cliamp)"
echo " 3. Modern shell tools (zoxide, fzf, ripgrep, fd, bat, eza, tldr, yt-dlp)"
echo " 4. Graphical apps (Localsend, Imv, Mpv, Disks, Obsidian, Evince, Xournal++, LibreOffice, Pinta, OBS, Kdenlive)"
echo " 5. Browsers & Messaging (Firefox, Chromium, Zen Browser, Telegram, Discord)"
echo " 6. Development & AI tools (Neovim, GitHub CLI, Ollama, Llama.cpp, LM Studio, CLI Agents)"
echo " 7. Mouse-friendly dotfiles, Super+K cheatsheet, and crash diagnosis"
echo ""

AUTO_YES=false
for arg in "$@"; do
    case "$arg" in
        -y|--yes) AUTO_YES=true ;;
    esac
done

if [[ "${AUTO_YES}" != true ]]; then
    read -rp "Proceed with installation? [y/N]: " confirm
    if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
        echo "Installation aborted."
        exit 0
    fi
fi

# -----------------------------------------------------------------------------
# 1. UPDATE AND INSTALL OFFICIAL PACMAN PACKAGES
# -----------------------------------------------------------------------------
header "1. Installing Official Packages via pacman"

# Core desktop packages (critical)
CORE_PACKAGES=(
    base-devel
    git
    curl
    jq
    python
    python-gobject
    gtk3
    librsvg
    mesa
    vulkan-intel
    intel-media-driver
    hyprland
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    hyprpolkitagent
    hyprpaper
    hyprlock
    hypridle
    waybar
    rofi
    mako
    libnotify
    foot
    thunar
    thunar-volman
    gvfs
    tumbler
    file-roller
    pipewire
    pipewire-audio
    pipewire-pulse
    pipewire-alsa
    wireplumber
    pavucontrol
    networkmanager
    network-manager-applet
    bluez
    bluez-utils
    blueman
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-emoji
    papirus-icon-theme
    grim
    slurp
    wl-clipboard
    cliphist
    wtype
    brightnessctl
    playerctl
)

# Productivity, apps, and tools
APP_PACKAGES=(
    btop
    dua-cli
    fastfetch
    tmux
    zoxide
    fzf
    ripgrep
    fd
    bat
    eza
    tealdeer
    yt-dlp
    imv
    mpv
    gnome-disk-utility
    obsidian
    evince
    xournalpp
    libreoffice-fresh
    pinta
    obs-studio
    kdenlive
    neovim
    github-cli
    mise
    firefox
    chromium
    telegram-desktop
    discord
    ollama
    llama-cpp
)

log "Updating pacman databases and installing core desktop packages..."
if ! sudo pacman -Syu --needed --noconfirm "${CORE_PACKAGES[@]}"; then
    err "Core desktop installation failed. Stopping before deploying configuration."
    exit 1
fi

log "Installing application and utility packages..."
for pkg in "${APP_PACKAGES[@]}"; do
    sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null || warn "Optional package '$pkg' not found in repos, skipping."
done

# -----------------------------------------------------------------------------
# 2. SYSTEM SERVICES & NETWORKING
# -----------------------------------------------------------------------------
header "2. Enabling Essential Services & Networking"

log "Configuring NetworkManager and disabling conflicting network daemons..."
# If systemd-networkd was used during initial bootstrap, disable it to prevent dual DHCP collisions
sudo systemctl disable --now systemd-networkd 2>/dev/null || true

# IPv6 policy belongs in individual connection profiles, not a global
# [connection] ipv6.method setting (NetworkManager ignores that setting).
# Preserve this host's existing profile and kernel workaround.

# Ensure systemd-resolved stub symlink is correct for musl/glibc binaries (e.g. Codex CLI)
sudo systemctl enable --now systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Prioritize IPv4 in glibc gai.conf
if [[ -f /etc/gai.conf ]]; then
    sudo sed -i 's/^#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/' /etc/gai.conf 2>/dev/null || true
fi

log "Enabling NetworkManager..."
sudo systemctl enable --now NetworkManager

# The Apple T2 internal USB network interface is not an internet uplink.
# Prevent its auto-generated profile from delaying boot with failed DHCP.
while IFS= read -r profile_uuid; do
    profile_iface="$(nmcli -g connection.interface-name connection show uuid "$profile_uuid")"
    [[ -n "$profile_iface" && -e "/sys/class/net/$profile_iface" ]] || continue
    if udevadm info -q property "/sys/class/net/$profile_iface" | grep -qx 'ID_MODEL=Apple_T2_Controller'; then
        sudo nmcli connection modify uuid "$profile_uuid" connection.autoconnect no
    fi
done < <(nmcli -g UUID connection show)

log "Enabling Bluetooth..."
sudo systemctl enable --now bluetooth

log "Enabling Ollama service (Local AI models)..."
sudo systemctl enable --now ollama 2>/dev/null || true

# -----------------------------------------------------------------------------
# 3. CLIAMP (TERMINAL MUSIC PLAYER)
# -----------------------------------------------------------------------------
header "3. Installing Cliamp Music Player"

if command -v cliamp >/dev/null 2>&1; then
    log "Cliamp is already installed."
else
    log "Downloading Cliamp (Winamp retro music player)..."
    CLIAMP_URL="https://github.com/bjarneo/cliamp/releases/latest/download/cliamp-linux-amd64"
    if sudo curl -fsSL "${CLIAMP_URL}" -o /usr/local/bin/cliamp; then
        sudo chmod +x /usr/local/bin/cliamp
        log "Cliamp installed successfully to /usr/local/bin/cliamp"
    else
        warn "Could not download Cliamp binary directly. You can install it via AUR or cargo."
    fi
fi

# -----------------------------------------------------------------------------
# 4. AUR HELPER (YAY) & AUR PACKAGES
# -----------------------------------------------------------------------------
header "4. Installing AUR Packages (Rofi-Wayland, Zen Browser, LocalSend, Mise, LM Studio)"

if ! command -v yay >/dev/null 2>&1; then
    log "Installing yay (AUR helper)..."
    YAY_BUILD_DIR="$(mktemp -d)"
    if git clone https://aur.archlinux.org/yay-bin.git "${YAY_BUILD_DIR}"; then
        (cd "${YAY_BUILD_DIR}" && makepkg -si --noconfirm) || warn "Failed to build yay-bin."
        rm -rf "${YAY_BUILD_DIR}"
    else
        warn "Could not clone yay-bin repository."
    fi
fi

if command -v yay >/dev/null 2>&1; then
    AUR_PACKAGES=(
        zen-browser-bin
        localsend-bin
        lm-studio-bin
    )
    log "Installing AUR packages..."
    for pkg in "${AUR_PACKAGES[@]}"; do
        log "Installing ${pkg}..."
        yay -S --needed --noconfirm "${pkg}" || warn "Could not install ${pkg} from AUR, skipping."
    done
else
    warn "yay is not available; skipping AUR packages for now."
fi

# -----------------------------------------------------------------------------
# 5. DOTFILES & HELPER SCRIPTS
# -----------------------------------------------------------------------------
header "5. Deploying Dotfiles to ~/.config"

CONFIG_DIR="${HOME}/.config"
BACKUP_DIR="${HOME}/.config_backup_$(date +'%Y%m%d_%H%M%S')"
mkdir -p "${CONFIG_DIR}"

DOTFILES_SOURCE="${SCRIPT_DIR}/dotfiles"
TARGETS=(hypr waybar rofi foot mako)

need_backup=false
for target in "${TARGETS[@]}"; do
    if [[ -d "${CONFIG_DIR}/${target}" || -f "${CONFIG_DIR}/${target}" ]]; then
        need_backup=true
        break
    fi
done

if [[ "${need_backup}" == true ]]; then
    warn "Existing configuration directories detected."
    log "Backing up existing configurations to: ${BACKUP_DIR}"
    mkdir -p "${BACKUP_DIR}"
    for target in "${TARGETS[@]}"; do
        if [[ -e "${CONFIG_DIR}/${target}" ]]; then
            mv "${CONFIG_DIR}/${target}" "${BACKUP_DIR}/"
        fi
    done
fi

log "Copying new configuration files..."
for target in "${TARGETS[@]}"; do
    if [[ -d "${DOTFILES_SOURCE}/${target}" ]]; then
        cp -r "${DOTFILES_SOURCE}/${target}" "${CONFIG_DIR}/"
        log "  Installed ~/.config/${target}"
    fi
done

# Ensure helper scripts in ~/.config/hypr/bin/ are executable
if [[ -d "${CONFIG_DIR}/hypr/bin" ]]; then
    chmod +x "${CONFIG_DIR}/hypr/bin/"*.sh
    log "  Made ~/.config/hypr/bin scripts executable"
fi

# Install desktop entry for Cliamp
mkdir -p "${HOME}/.local/share/applications"
if [[ -f "${DOTFILES_SOURCE}/applications/cliamp.desktop" ]]; then
    cp "${DOTFILES_SOURCE}/applications/cliamp.desktop" "${HOME}/.local/share/applications/"
    log "  Installed Cliamp desktop entry"
fi

# Install the local Settings app and its launcher.
mkdir -p "${HOME}/.local/share/desktop-settings/app/wallpapers" "${HOME}/.local/bin"
install -m644 "${SCRIPT_DIR}/settings/app.py" "${SCRIPT_DIR}/settings/backend.py" "${HOME}/.local/share/desktop-settings/app/"
install -m644 "${SCRIPT_DIR}/settings/wallpapers/"*.svg "${HOME}/.local/share/desktop-settings/app/wallpapers/"
install -m755 "${SCRIPT_DIR}/settings/desktop-settings" "${HOME}/.local/bin/desktop-settings"
install -m644 "${DOTFILES_SOURCE}/applications/desktop-settings.desktop" "${HOME}/.local/share/applications/desktop-settings.desktop"

# Set default agent if none configured
if [[ ! -f "${CONFIG_DIR}/default-agent" ]]; then
    echo "agy" > "${CONFIG_DIR}/default-agent"
    log "  Set default AI agent to 'agy' (change via Super+Alt+A or ~/.config/default-agent)"
fi

# Ensure pictures/screenshots folder exists
mkdir -p "${HOME}/Pictures/Screenshots"

# -----------------------------------------------------------------------------
# 6. SHELL ENHANCEMENTS (BASH / ZSH)
# -----------------------------------------------------------------------------
header "6. Setting Up Shell Aliases & Hooks"

SHELL_RC="${HOME}/.bashrc"
if [[ -n "${ZSH_VERSION:-}" || "${SHELL:-}" =~ zsh$ ]]; then
    SHELL_RC="${HOME}/.zshrc"
fi

touch "${SHELL_RC}"
if ! grep -q "Modern CLI Aliases" "${SHELL_RC}" 2>/dev/null; then
    log "Adding convenient aliases and hooks to ${SHELL_RC}..."
    cat << 'EOF' >> "${SHELL_RC}"

# --- Modern CLI Aliases & Tools ---
if command -v eza >/dev/null 2>&1; then
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -la --icons --group-directories-first"
    alias lt="eza --tree --level=2 --icons"
fi

if command -v bat >/dev/null 2>&1; then
    alias cat="bat --paging=never"
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init $(basename ${SHELL:-bash}))"
fi

if command -v tealdeer >/dev/null 2>&1; then
    alias tldr="tealdeer"
fi
EOF
fi

# Update tldr cache
if command -v tldr >/dev/null 2>&1; then
    tldr --update 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# 7. T2 LINUX HARDWARE CONFIGURATION
# -----------------------------------------------------------------------------
header "7. Hardware Setup (Apple T2 Mac mini)"

if lspci | grep -iq "Apple Inc. T2" || uname -r | grep -iq "t2"; then
    log "Apple T2 hardware detected!"

    # 1. Add [arch-mact2] repository if not already in pacman.conf
    if ! grep -q "\[arch-mact2\]" /etc/pacman.conf 2>/dev/null; then
        log "Adding [arch-mact2] repository to /etc/pacman.conf..."
        sudo tee -a /etc/pacman.conf << 'EOF'

[arch-mact2]
Server = https://mirror.funami.tech/arch-mact2/os/x86_64
SigLevel = Never
EOF
    fi

    # 2. Install T2 kernel and drivers
    log "Installing linux-t2 kernel, audio config, Broadcom Wi-Fi firmware, and fan daemon..."
    sudo pacman -Syu --needed --noconfirm linux-t2 linux-t2-headers apple-t2-audio-config apple-bcm-firmware t2fanrd

    # The current audio package covers x2/x4/x6 speaker layouts but omits
    # Macmini8,1 (AppleT2x1). Supply the missing UCM profile only when absent.
    # Prefer the package's profile if a future release provides it.
    if { grep -q 'AppleT2x1 -' /proc/asound/cards 2>/dev/null ||
         grep -qx 'Macmini8,1' /sys/class/dmi/id/product_name 2>/dev/null; } &&
       [[ ! -e /usr/share/alsa/ucm2/conf.d/AppleT2x1/AppleT2x1.conf ]]; then
        sudo install -Dm644 "${SCRIPT_DIR}/system/alsa/ucm2/AppleT2/HiFi-x1.conf" /usr/share/alsa/ucm2/AppleT2/HiFi-x1.conf
        sudo install -Dm644 "${SCRIPT_DIR}/system/alsa/ucm2/conf.d/AppleT2x1/AppleT2x1.conf" /usr/share/alsa/ucm2/conf.d/AppleT2x1/AppleT2x1.conf
        log "Added Mac mini mono speaker / stereo headphone jack audio profile."
    fi

    # 3. Enable fan daemon
    log "Enabling t2fanrd service..."
    sudo systemctl enable --now t2fanrd

    # 4. Configure systemd-boot loader entry if systemd-boot is present
    if [[ -d /boot/loader/entries ]]; then
        EXISTING_ENTRY="$(find /boot/loader/entries -maxdepth 1 -name '*.conf' ! -name 'linux-t2.conf' 2>/dev/null | head -n 1)"
        if [[ -n "$EXISTING_ENTRY" && -f "$EXISTING_ENTRY" ]]; then
            OPTIONS_LINE="$(grep -E '^options[[:space:]]' "$EXISTING_ENTRY" | head -n 1)"
            # Ensure Intel FBC and PSR are disabled to prevent scanout glitches
            if ! echo "${OPTIONS_LINE}" | grep -q "i915.enable_fbc=0"; then
                OPTIONS_LINE="${OPTIONS_LINE} i915.enable_fbc=0 i915.enable_psr=0"
            fi
            log "Creating systemd-boot entry /boot/loader/entries/linux-t2.conf..."
            sudo tee /boot/loader/entries/linux-t2.conf >/dev/null << EOF
title   Arch Linux (linux-t2)
linux   /vmlinuz-linux-t2
initrd  /intel-ucode.img
initrd  /initramfs-linux-t2.img
${OPTIONS_LINE}
EOF
            if [[ -f /boot/loader/loader.conf ]]; then
                if ! grep -q "default[[:space:]]" /boot/loader/loader.conf; then
                    echo "default linux-t2.conf" | sudo tee -a /boot/loader/loader.conf >/dev/null
                else
                    sudo sed -i 's/^default .*/default linux-t2.conf/' /boot/loader/loader.conf
                fi
            fi
            log "Configured systemd-boot default entry: linux-t2.conf"
        fi
    elif command -v grub-mkconfig >/dev/null 2>&1; then
        log "Updating GRUB configuration..."
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

    log "T2 hardware packages and bootloader entry configured successfully!"
else
    warn "Non-T2 hardware detected or Apple T2 device not found."
fi

# -----------------------------------------------------------------------------
# 8. INTEL UHD 630 DISPLAY & DRIVER OPTIMIZATIONS
# -----------------------------------------------------------------------------
header "8. Intel UHD 630 Graphics Glitch Prevention"

log "Configuring i915 module options to prevent framebuffer tearing and comb artifacts..."
sudo tee /etc/modprobe.d/i915.conf >/dev/null << 'EOF'
options i915 enable_fbc=0 enable_psr=0
EOF

log "Configuring Aquamarine Wayland environment..."
if ! grep -q "AQ_NO_MODIFIERS" /etc/environment 2>/dev/null; then
    echo "AQ_NO_MODIFIERS=1" | sudo tee -a /etc/environment >/dev/null
fi

log "Regenerating initramfs with updated module options..."
sudo mkinitcpio -P

# -----------------------------------------------------------------------------
# 9. SEAMLESS AUTOLOGIN & STARTUP
# -----------------------------------------------------------------------------
header "9. Configuring Automatic Login & Desktop Autostart"

CURRENT_USER="$(id -un)"
log "Setting up autologin for user '${CURRENT_USER}' on tty1..."
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf >/dev/null << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty -o '-p -f -- \\\\u' --noclear --autologin ${CURRENT_USER} %I \$TERM
EOF
sudo systemctl daemon-reload

log "Configuring ~/.bash_profile to autostart Hyprland on login..."
touch "${HOME}/.bash_profile"
if ! grep -q "exec Hyprland" "${HOME}/.bash_profile" 2>/dev/null; then
    cat << 'EOF' >> "${HOME}/.bash_profile"

# Intel UHD 630 / Aquamarine DRM modifier fix (prevents comb/sawtooth artifacts)
export AQ_NO_MODIFIERS=1

# Auto-start Hyprland on login from physical tty1
if [[ -z "$WAYLAND_DISPLAY" ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
    exec Hyprland
fi
EOF
fi

# -----------------------------------------------------------------------------
# COMPLETE
# -----------------------------------------------------------------------------
header "Installation Complete! 🎉"
echo ""
echo "Your desktop, audio, and curated software suite are installed and configured."
echo "Autologin is enabled: rebooting will bring you directly into your desktop."

echo "To launch your session:"
echo "  1. Launch Hyprland by running:"
echo "       ${BOLD}Hyprland${RESET}"
echo ""
echo "Quick Shortcuts Cheatsheet:"
echo "  - ${BOLD}Shortcuts Cheatsheet:${RESET} Super + K (Searchable popup cheatsheet)"
echo "  - ${BOLD}Launch AI Agent:${RESET}      Super + Shift + A (agy, claude, codex, opencode, omp)"
echo "  - ${BOLD}Select AI Agent:${RESET}      Super + Alt + A (Choose default agent)"
echo "  - ${BOLD}Web Browser:${RESET}          Super + B (Firefox / Zen / Chromium)"
echo "  - ${BOLD}Notes (Obsidian):${RESET}     Super + Shift + O"
echo "  - ${BOLD}Activity Monitor:${RESET}     Super + Ctrl + T (btop)"
echo "  - ${BOLD}Cliamp Music:${RESET}         Super + M (lo-fi radio player)"
echo "  - ${BOLD}Resize Window:${RESET}        Hover over window border & drag"
echo "  - ${BOLD}Move Window:${RESET}          Hold Super + Left Click Drag"
echo "  - ${BOLD}Resize Window:${RESET}        Hold Super + Right Click Drag"
echo "  - ${BOLD}Toggle Floating:${RESET}      Super + Shift + Space (or Super + Middle Click)"
echo "  - ${BOLD}Swap Tiled Windows:${RESET}   Super + T"
echo "  - ${BOLD}Close Window:${RESET}         Super + W"
echo "  - ${BOLD}Terminal:${RESET}             Super + Enter (Foot)"
echo "  - ${BOLD}App Launcher:${RESET}         Super + Space (Rofi)"
echo "  - ${BOLD}File Manager:${RESET}         Super + E (Thunar)"
echo "  - ${BOLD}Screenshot Area:${RESET}      Super + Shift + S"
echo ""
