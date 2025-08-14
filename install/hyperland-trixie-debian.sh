#!/bin/bash

set -euo pipefail

# Minimal Hyprland installer for Debian
# - Installs Hyprland and essential runtime packages via apt only
# - Idempotent: does nothing if everything already present

USE_BACKPORTS=0
if [[ "${1:-}" == "--bookworm-backports" ]]; then
  USE_BACKPORTS=1
fi

if [[ ${EUID:-0} -eq 0 ]]; then
  echo "[ERROR] Do not run as root. This script uses sudo as needed."
  exit 1
fi

if ! grep -q 'ID=debian' /etc/os-release; then
  echo "[ERROR] This script targets Debian. For other distros, install Hyprland using your distro's packages."
  exit 1
fi

# Helpers
is_installed_pkg() {
  dpkg -l | awk '$1=="ii" {print $2}' | grep -qx "$1"
}
user_in_group() {
  id -nG "$USER" | tr ' ' '\n' | grep -qx "$1"
}
service_enabled() {
  systemctl is-enabled "$1" >/dev/null 2>&1
}
service_active() {
  systemctl is-active "$1" >/dev/null 2>&1
}

# Detect Debian codename
CODENAME=""
. /etc/os-release || true
CODENAME="${VERSION_CODENAME:-}"
if [[ -z "${CODENAME}" ]] && command -v lsb_release >/dev/null 2>&1; then
  CODENAME="$(lsb_release -sc)"
fi

case "${CODENAME}" in
  trixie|sid|unstable)
    echo "[INFO] Detected Debian codename: ${CODENAME}. Proceeding with native packages."
    ;;
  bookworm)
    if [[ ${USE_BACKPORTS} -ne 1 ]]; then
      echo "[ERROR] Detected Debian ${CODENAME}. Hyprland is unreliable in stable."
      echo "        Either upgrade to Debian 13 (Trixie) or rerun with --bookworm-backports to install from backports."
      exit 1
    else
      echo "[INFO] Detected Debian ${CODENAME}. Using bookworm-backports for Hyprland."
    fi
    ;;
  *)
    echo "[WARN] Unknown Debian codename '${CODENAME}'. Proceeding may fail."
    ;;
 esac

# Define package sets
COMMON_PACKAGES=(
  xdg-desktop-portal
  xwayland
  wl-clipboard
  grim
  slurp
  seatd
  polkit-kde-agent-1
  pipewire
  wireplumber
  xdg-user-dirs
)

# Determine what needs installing (idempotent checks)
TO_INSTALL_NATIVE=()
TO_INSTALL_BKPT=()

# Hyprland check: prefer binary presence (may be from source)
HYPRLAND_PRESENT=0
if command -v Hyprland >/dev/null 2>&1 || command -v hyprland >/dev/null 2>&1; then
  HYPRLAND_PRESENT=1
elif is_installed_pkg hyprland; then
  HYPRLAND_PRESENT=1
fi

# Portal-hyprland check via package db
PORTAL_PKG=xdg-desktop-portal-hyprland
PORTAL_PRESENT=0
if is_installed_pkg "$PORTAL_PKG"; then
  PORTAL_PRESENT=1
fi

# Backports logic for Bookworm
ADDED_BACKPORTS=0
if [[ "${CODENAME}" == "bookworm" && ${USE_BACKPORTS} -eq 1 ]]; then
  # Only enqueue backports packages if missing
  if [[ ${HYPRLAND_PRESENT} -eq 0 ]]; then
    TO_INSTALL_BKPT+=(hyprland)
  fi
  if [[ ${PORTAL_PRESENT} -eq 0 ]]; then
    TO_INSTALL_BKPT+=($PORTAL_PKG)
  fi
  if [[ ${#TO_INSTALL_BKPT[@]} -gt 0 ]]; then
    if ! grep -Rqs "^deb .* bookworm-backports" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
      echo "[INFO] Enabling bookworm-backports..."
      echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list.d/bookworm-backports.list >/dev/null
      ADDED_BACKPORTS=1
    fi
  fi
else
  # Non-bookworm: install from native if missing
  if [[ ${HYPRLAND_PRESENT} -eq 0 ]]; then
    TO_INSTALL_NATIVE+=(hyprland)
  fi
  if [[ ${PORTAL_PRESENT} -eq 0 ]]; then
    TO_INSTALL_NATIVE+=($PORTAL_PKG)
  fi
fi

# Common packages: add only those missing
for p in "${COMMON_PACKAGES[@]}"; do
  if ! is_installed_pkg "$p"; then
    TO_INSTALL_NATIVE+=("$p")
  fi
done

# Decide whether to apt update
if [[ ${ADDED_BACKPORTS} -eq 1 || ${#TO_INSTALL_NATIVE[@]} -gt 0 || ${#TO_INSTALL_BKPT[@]} -gt 0 ]]; then
  echo "[INFO] Updating package index..."
  sudo apt update -y
fi

# Install missing packages
if [[ ${#TO_INSTALL_BKPT[@]} -gt 0 ]]; then
  echo "[INFO] Installing from bookworm-backports: ${TO_INSTALL_BKPT[*]}"
  sudo apt -t bookworm-backports install -y "${TO_INSTALL_BKPT[@]}"
fi

if [[ ${#TO_INSTALL_NATIVE[@]} -gt 0 ]]; then
  echo "[INFO] Installing native packages: ${TO_INSTALL_NATIVE[*]}"
  sudo apt install -y "${TO_INSTALL_NATIVE[@]}"
fi

# seatd setup (only if installed)
if is_installed_pkg seatd; then
  if ! service_enabled seatd.service || ! service_active seatd.service; then
    echo "[INFO] Enabling seatd service..."
    sudo systemctl enable --now seatd.service || true
  fi
  for grp in seat input; do
    if getent group "$grp" >/dev/null && ! user_in_group "$grp"; then
      echo "[INFO] Adding $USER to group: $grp"
      sudo usermod -aG "$grp" "$USER" || true
    fi
  done
fi

# Initialize XDG user dirs if the tool exists
if command -v xdg-user-dirs-update >/dev/null 2>&1; then
  xdg-user-dirs-update || true
fi

# Final checks
if command -v Hyprland >/dev/null 2>&1 || command -v hyprland >/dev/null 2>&1; then
  echo "[OK] Hyprland present."
else
  echo "[WARN] Hyprland not detected in PATH."
fi

if [[ ${ADDED_BACKPORTS} -eq 0 && ${#TO_INSTALL_NATIVE[@]} -eq 0 && ${#TO_INSTALL_BKPT[@]} -eq 0 ]]; then
  echo "[OK] Nothing to do. System already satisfies requirements."
fi

cat <<'EOF'
[INFO] All set.
- Start Hyprland from a TTY by logging out of any graphical session and running: Hyprland
- For screen sharing/portals, xdg-desktop-portal-hyprland is installed (or already present).
- You may need to log out/in (or reboot) for new group memberships to take effect.

If you are on Debian 12 (Bookworm), this script can use backports when invoked with --bookworm-backports.
For best results, use Debian 13 (Trixie) or Sid.

Optional extras you can install yourself later (not included here): waybar, kitty/foot, swaync, swww, rofi-wayland.
EOF
