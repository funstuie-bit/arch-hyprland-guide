#!/usr/bin/env bash
# ##############################################################################
# Arch Linux + Hyprland Setup & Dotfiles Installer
# Configured for 2018 Mac mini (T2 / Intel UHD 630) and mouse-friendly workflow
# ##############################################################################

set -euo pipefail

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

# Ensure NOT running as root (pacman and dotfiles must be handled by regular user with sudo)
if [[ "${EUID}" -eq 0 ]]; then
    err "Do NOT run this script directly as root or with sudo."
    err "Run it as your normal user: ./install.sh"
    exit 1
fi

header "Arch + Hyprland Bootstrap"
echo "This script will:"
echo " 1. Install necessary desktop, graphics, audio, and font packages"
echo " 2. Enable NetworkManager and Bluetooth system services"
echo " 3. Back up and install mouse-friendly dotfiles to ~/.config"
echo ""

read -rp "Proceed with installation? [y/N]: " confirm
if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
    echo "Installation aborted."
    exit 0
fi

# -----------------------------------------------------------------------------
# 1. UPDATE AND INSTALL PACKAGES
# -----------------------------------------------------------------------------
header "1. Installing Packages via pacman"

PACKAGES=(
    # --- Graphics Drivers (Intel UHD 630 on 2018 Mac mini) ---
    mesa
    vulkan-intel
    intel-media-driver

    # --- Compositor & Wayland Session ---
    hyprland
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    hyprpolkitagent
    hyprpaper
    hyprlock
    hypridle

    # --- Status Bar & Launcher ---
    waybar
    rofi-wayland
    mako
    libnotify

    # --- Terminal & File Manager ---
    foot
    thunar
    thunar-volman
    gvfs
    tumbler
    file-roller

    # --- Audio (PipeWire) ---
    pipewire
    pipewire-audio
    pipewire-pulse
    pipewire-alsa
    wireplumber
    pavucontrol

    # --- Network & Bluetooth ---
    networkmanager
    network-manager-applet
    bluez
    bluez-utils
    blueman

    # --- Utilities & Theming ---
    grim
    slurp
    wl-clipboard
    brightnessctl
    playerctl
    papirus-icon-theme

    # --- Required Fonts (prevents tofu/broken glyphs) ---
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-emoji
)

log "Updating pacman mirrors and installing packages..."
sudo pacman -Syu --needed "${PACKAGES[@]}"

# -----------------------------------------------------------------------------
# 2. SYSTEM SERVICES
# -----------------------------------------------------------------------------
header "2. Enabling Essential Services"

log "Enabling NetworkManager..."
sudo systemctl enable --now NetworkManager

log "Enabling Bluetooth..."
sudo systemctl enable --now bluetooth

# -----------------------------------------------------------------------------
# 3. DOTFILES INSTALLATION
# -----------------------------------------------------------------------------
header "3. Deploying Dotfiles to ~/.config"

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

# Ensure pictures/screenshots folder exists
mkdir -p "${HOME}/Pictures/Screenshots"

# -----------------------------------------------------------------------------
# 4. T2 LINUX HARDWARE CHECK
# -----------------------------------------------------------------------------
header "4. Hardware Check (Apple T2 Mac mini)"

if uname -r | grep -iq "t2"; then
    log "Apple T2-patched Linux kernel detected! (${BOLD}$(uname -r)${RESET})"
else
    warn "You are currently running kernel: $(uname -r)"
    echo "If Wi-Fi, internal NVMe, or audio have missing devices on your 2018 Mac mini,"
    echo "ensure you add the t2linux repository and install linux-t2:"
    echo "See: https://wiki.t2linux.org/distributions/arch/installation/"
fi

# -----------------------------------------------------------------------------
# COMPLETE
# -----------------------------------------------------------------------------
header "Installation Complete! 🎉"
echo ""
echo "Your desktop is now configured. To launch your session:"
echo "  1. If currently in TTY, launch Hyprland by running:"
echo "       ${BOLD}Hyprland${RESET}"
echo ""
echo "Quick Mouse & Key Shortcuts:"
echo "  - ${BOLD}Resize Window:${RESET}     Hover over any window edge & drag (no keys needed!)"
echo "  - ${BOLD}Move Window:${RESET}       Hold Super (Command) + Left Click Drag"
echo "  - ${BOLD}Resize Window:${RESET}     Hold Super (Command) + Right Click Drag"
echo "  - ${BOLD}Toggle Floating:${RESET}   Super + V  (or Super + Middle Click)"
echo "  - ${BOLD}Launch Terminal:${RESET}   Super + Enter (foot)"
echo "  - ${BOLD}Launch Apps:${RESET}       Super + Space (rofi)"
echo "  - ${BOLD}File Manager:${RESET}      Super + E (thunar)"
echo "  - ${BOLD}Screenshot Area:${RESET}   Super + Shift + S"
echo ""
