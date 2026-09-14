#!/usr/bin/env bash
# ##############################################################################
# Arch Linux + Hyprland Setup & Dotfiles Installer
# Configured for 2018 Mac mini (T2 / Intel UHD 630) and mouse-friendly workflow
# Curated software suite: TUIs, modern shell, GUIs, browsers, AI tools & Cliamp
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
echo "This script will install your curated workstation suite:"
echo " 1. Desktop & graphics drivers (Intel UHD 630, Hyprland, Waybar)"
echo " 2. Terminal TUIs (btop, dua-cli, fastfetch, tmux, cliamp)"
echo " 3. Modern shell tools (zoxide, fzf, ripgrep, fd, bat, eza, tldr, yt-dlp)"
echo " 4. Graphical apps (Localsend, Imv, Mpv, Disks, Obsidian, Evince, Xournal++, LibreOffice, Pinta, OBS, Kdenlive)"
echo " 5. Browsers (Firefox, Chromium, Zen Browser)"
echo " 6. Development & AI tools (Neovim, GitHub CLI, Ollama, Llama.cpp, LM Studio, CLI Agents)"
echo " 7. Mouse-friendly dotfiles, Super+K cheatsheet, and crash diagnosis"
echo ""

read -rp "Proceed with installation? [y/N]: " confirm
if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
    echo "Installation aborted."
    exit 0
fi

# -----------------------------------------------------------------------------
# 1. UPDATE AND INSTALL PACMAN PACKAGES
# -----------------------------------------------------------------------------
header "1. Installing Packages via pacman"

PACKAGES=(
    # --- Base Build Tools ---
    base-devel
    git
    curl
    jq

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

    # --- Terminal TUIs ---
    btop
    dua-cli
    fastfetch
    tmux

    # --- Modern Shell Replacements ---
    zoxide
    fzf
    ripgrep
    fd
    bat
    eza
    tealdeer
    yt-dlp

    # --- GUI Desktop & Utilities ---
    imv
    mpv
    gnome-disk-utility

    # --- GUI Notes & Office ---
    obsidian
    evince
    xournalpp
    libreoffice-fresh

    # --- GUI Creative & Media ---
    pinta
    obs-studio
    kdenlive

    # --- Development & Code ---
    neovim
    gh

    # --- Web Browsers ---
    firefox
    chromium

    # --- Local AI Models ---
    ollama
    llama.cpp

    # --- Utilities, Desktop Tools & Theming ---
    grim
    slurp
    wl-clipboard
    brightnessctl
    playerctl
    papirus-icon-theme

    # --- Required Fonts ---
    ttf-jetbrains-mono-nerd
    noto-fonts
    noto-fonts-emoji
)

log "Updating pacman mirrors and installing official packages..."
sudo pacman -Syu --needed "${PACKAGES[@]}"

# -----------------------------------------------------------------------------
# 2. SYSTEM SERVICES
# -----------------------------------------------------------------------------
header "2. Enabling Essential Services"

log "Enabling NetworkManager..."
sudo systemctl enable --now NetworkManager

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
header "4. Installing AUR Packages (Zen Browser, LocalSend, Mise, LM Studio)"

if ! command -v yay >/dev/null 2>&1; then
    log "Installing yay (AUR helper)..."
    YAY_BUILD_DIR="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "${YAY_BUILD_DIR}"
    (cd "${YAY_BUILD_DIR}" && makepkg -si --noconfirm)
    rm -rf "${YAY_BUILD_DIR}"
    log "yay installed successfully."
fi

AUR_PACKAGES=(
    zen-browser-bin
    localsend-bin
    mise-bin
    lm-studio-bin
)

log "Installing AUR packages..."
yay -S --needed --noconfirm "${AUR_PACKAGES[@]}" || warn "Some AUR packages could not be installed automatically."

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
if [[ -n "${ZSH_VERSION:-}" || "${SHELL}" =~ zsh$ ]]; then
    SHELL_RC="${HOME}/.zshrc"
fi

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
    eval "$(zoxide init $(basename $SHELL))"
fi

if command -v tealdeer >/dev/null 2>&1; then
    alias tldr="tealdeer"
fi
EOF

# Update tldr cache
if command -v tldr >/dev/null 2>&1; then
    tldr --update 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# 7. T2 LINUX HARDWARE CHECK
# -----------------------------------------------------------------------------
header "7. Hardware Check (Apple T2 Mac mini)"

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
echo "Your desktop and curated software suite are installed and configured."
echo "To launch your session:"
echo "  1. If currently in TTY, launch Hyprland by running:"
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
echo "  - ${BOLD}Toggle Floating:${RESET}      Super + V  (or Super + Middle Click)"
echo "  - ${BOLD}Terminal:${RESET}             Super + Enter (Foot)"
echo "  - ${BOLD}App Launcher:${RESET}         Super + Space (Rofi)"
echo "  - ${BOLD}File Manager:${RESET}         Super + E (Thunar)"
echo "  - ${BOLD}Screenshot Area:${RESET}      Super + Shift + S"
echo ""
