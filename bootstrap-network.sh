#!/usr/bin/env bash
# ##############################################################################
# Mac mini 2018 (T2) First-Boot Network & SSH Bootstrap Script
# Solves no-network and no-SSH on fresh Arch Linux install.
# Configures onboard Ethernet (enp1s0) / USB Ethernet dongles, DNS, and openssh.
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

if [[ "${EUID}" -ne 0 ]]; then
    err "This bootstrap script must be run with sudo or as root."
    echo "Usage: sudo bash $0"
    exit 1
fi

header "1. Detecting Network Interfaces"
if systemctl is-active --quiet NetworkManager; then
    err "NetworkManager is already running. Use nmcli/nmtui; do not start a second network manager."
    exit 1
fi
WIRED_IFACES=()
for iface in /sys/class/net/en*; do
    if [[ -d "${iface}" ]]; then
        name="$(basename "${iface}")"
        if udevadm info -q property "$iface" | grep -qx 'ID_MODEL=Apple_T2_Controller'; then
            log "Skipping internal Apple T2 interface: $name"
            continue
        fi
        WIRED_IFACES+=("${name}")
        log "Found wired interface: ${BOLD}${name}${RESET}"
    fi
done

if [[ ${#WIRED_IFACES[@]} -eq 0 ]]; then
    warn "No interface matching 'en*' found in /sys/class/net/."
    warn "Listing all network links:"
    ip -br link
    exit 1
else
    log "Wired interfaces detected: ${WIRED_IFACES[*]}"
fi

header "2. Configuring systemd-networkd DHCP for Wired Interfaces"
mkdir -p /etc/systemd/network
cat <<EOF > /etc/systemd/network/20-wired.network
[Match]
Name=${WIRED_IFACES[*]}

[Network]
DHCP=yes
EOF
log "Created /etc/systemd/network/20-wired.network for detected external wired interfaces."

header "3. Enabling and Starting systemd-networkd & systemd-resolved"
systemctl enable --now systemd-networkd
systemctl enable --now systemd-resolved

# Ensure DNS resolv.conf points to systemd-resolved stub
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
log "Linked /etc/resolv.conf -> systemd-resolved stub resolver."

header "4. Bringing Up Wired Links"
for iface in "${WIRED_IFACES[@]}"; do
    log "Bringing up ${iface}..."
    ip link set "${iface}" up || true
done

# Restart networkd to trigger DHCP lease acquisition
systemctl restart systemd-networkd

log "Waiting for DHCP lease (up to 6 seconds)..."
sleep 4

header "5. Verifying IP Address & Connectivity"
ip -br addr show

if ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
    log "Internet connectivity verified (ping 1.1.1.1 OK)."
else
    warn "Could not ping 1.1.1.1 yet. Waiting 4 more seconds..."
    sleep 4
    if ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
        log "Internet connectivity verified."
    else
        warn "Ping failed. Check that Ethernet cable is firmly plugged into Mac mini or router."
    fi
fi

header "6. Installing and Enabling OpenSSH Server"
if command -v pacman >/dev/null 2>&1; then
    log "Updating package database and installing openssh, git, networkmanager..."
    pacman -Syu --needed --noconfirm openssh git networkmanager
    systemctl enable --now sshd
    log "OpenSSH server is running and enabled on boot."
fi

header "Mac mini Ready for Remote SSH!"
CURRENT_IPS="$(ip -br addr show | grep -E 'enp|wlan' | awk '{print $1 " -> " $3}' || true)"
echo ""
echo "${GREEN}${BOLD}You can now disconnect the keyboard and monitor from your Mac mini!${RESET}"
echo "Current network status:"
echo "${CURRENT_IPS}"
echo ""
echo "Log in from your Mac / laptop terminal using:"
USER_NAME="${SUDO_USER:-stu}"
for ip_entry in $(ip -br addr show | grep -E 'enp|wlan' | awk '{print $3}' | cut -d'/' -f1); do
    echo "  ${BOLD}ssh ${USER_NAME}@${ip_entry}${RESET}"
done
echo ""
