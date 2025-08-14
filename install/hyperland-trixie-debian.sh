#!/bin/bash
set -euo pipefail

# Minimal Hyprland installer for Debian
# - Trixie or Sid: install from native
# - Bookworm: run with --bookworm-backports to pull Hyprland + portal from backports
# - Idempotent and safe for re-runs
# - Defaults to systemd-logind, optional --seatd to use seatd daemon

USE_BACKPORTS=0
USE_SEATD=0

# Parse args correctly
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bookworm-backports) USE_BACKPORTS=1 ;;
    --seatd) USE_SEATD=1 ;;
    *) echo "[ERROR] Unknown arg: $1"; exit 1 ;;
  esac
  shift
done

if [[ ${EUID:-0} -eq 0 ]]; then
  echo "[ERROR] Do not run as root. The script uses sudo when needed."
  exit 1
fi

if ! grep -q 'ID=debian' /etc/os-release; then
  echo "[ERROR] Debian only."
  exit 1
fi

# Helpers
is_installed_pkg() { dpkg -s "$1" >/dev/null 2>&1; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }
service_enabled() { systemctl is-enabled "$1" >/dev/null 2>&1; }
service_active() { systemctl is-active "$1" >/dev/null 2>&1; }
user_in_group() { id -nG "$USER" | tr ' ' '\n' | grep -qx "$1"; }

# Detect codename
. /etc/os-release || true
CODENAME="${VERSION_CODENAME:-}"
if [[ -z "$CODENAME" ]] && have_cmd lsb_release; then
  CODENAME="$(lsb_release -sc)"
fi

case "$CODENAME" in
  trixie|sid|unstable)
    echo "[INFO] Debian $CODENAME detected. Using native packages."
    ;;
  bookworm)
    if [[ $USE_BACKPORTS -ne 1 ]]; then
      echo "[ERROR] On Bookworm. Run with --bookworm-backports or upgrade to Trixie."
      exit 1
    else
      echo "[INFO] Bookworm with backports requested."
    fi
    ;;
  *)
    echo "[WARN] Unknown codename '$CODENAME'. Proceeding."
    ;;
esac

# Core sets
COMMON_PACKAGES=(
  xwayland
  wl-clipboard
  grim
  slurp
  xdg-user-dirs
  polkit-kde-agent-1
  pipewire
  wireplumber
  dbus-user-session
  xdg-desktop-portal
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
)

# Nice to have utilities that do not change behavior if already present
EXTRAS=(
  brightnessctl
  libinput-tools
  qt5ct
  qt6ct
  rofi-wayland
)

# Decide hyprland source
TO_INSTALL_NATIVE=()
TO_INSTALL_BKPT=()
ADDED_BACKPORTS=0

hyprland_present=false
if have_cmd Hyprland || have_cmd hyprland || is_installed_pkg hyprland; then
  hyprland_present=true
fi

portal_present=false
is_installed_pkg xdg-desktop-portal-hyprland && portal_present=true

if [[ "$CODENAME" == "bookworm" && $USE_BACKPORTS -eq 1 ]]; then
  if ! hyprland_present; then TO_INSTALL_BKPT+=(hyprland); fi
  if ! portal_present; then TO_INSTALL_BKPT+=(xdg-desktop-portal-hyprland); fi
  if [[ ${#TO_INSTALL_BKPT[@]} -gt 0 ]]; then
    if ! grep -Rqs "^deb .* bookworm-backports" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
      echo "[INFO] Enabling bookworm-backports..."
      echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free non-free-firmware" \
        | sudo tee /etc/apt/sources.list.d/bookworm-backports.list >/dev/null
      ADDED_BACKPORTS=1
    fi
  fi
else
  if ! hyprland_present; then TO_INSTALL_NATIVE+=(hyprland); fi
fi

# Common packages
for p in "${COMMON_PACKAGES[@]}"; do
  is_installed_pkg "$p" || TO_INSTALL_NATIVE+=("$p")
done
# Extras
for p in "${EXTRAS[@]}"; do
  is_installed_pkg "$p" || TO_INSTALL_NATIVE+=("$p")
done

# Update if needed
if [[ $ADDED_BACKPORTS -eq 1 || ${#TO_INSTALL_NATIVE[@]} -gt 0 || ${#TO_INSTALL_BKPT[@]} -gt 0 ]]; then
  echo "[INFO] apt update"
  sudo apt update -y
fi

# Install
if [[ ${#TO_INSTALL_BKPT[@]} -gt 0 ]]; then
  echo "[INFO] Installing from backports: ${TO_INSTALL_BKPT[*]}"
  sudo apt -t bookworm-backports install -y "${TO_INSTALL_BKPT[@]}"
fi
if [[ ${#TO_INSTALL_NATIVE[@]} -gt 0 ]]; then
  echo "[INFO] Installing native: ${TO_INSTALL_NATIVE[*]}"
  sudo apt install -y "${TO_INSTALL_NATIVE[@]}"
fi

# Seat management
# Default: use systemd-logind. Only switch to seatd if requested.
if [[ $USE_SEATD -eq 1 ]]; then
  if ! is_installed_pkg seatd; then
    echo "[INFO] Installing seatd"
    sudo apt install -y seatd
  fi
  if ! service_enabled seatd.service || ! service_active seatd.service; then
    echo "[INFO] Enabling seatd service"
    sudo systemctl enable --now seatd.service || true
  fi
  for grp in seat input video render; do
    if getent group "$grp" >/dev/null && ! user_in_group "$grp"; then
      echo "[INFO] Adding $USER to group: $grp"
      sudo usermod -aG "$grp" "$USER" || true
    fi
  done
else
  echo "[INFO] Using systemd-logind for device access. No seatd daemon."
fi

# PipeWire user services
if have_cmd systemctl; then
  echo "[INFO] Enabling PipeWire and WirePlumber user services"
  systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service || true
fi

# Initialize XDG dirs
have_cmd xdg-user-dirs-update && xdg-user-dirs-update || true

# Simple first-run Hyprland config seed if missing
HYPR_DIR="$HOME/.config/hypr"
HYPR_CONF="$HYPR_DIR/hyprland.conf"
if [[ ! -f "$HYPR_CONF" ]]; then
  mkdir -p "$HYPR_DIR"
  cat > "$HYPR_CONF" <<'HCONF'
# Minimal Hyprland config seed
monitor=,preferred,auto,1
exec-once = xdg-user-dirs-update
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = /usr/lib/polkit-kde-authentication-agent-1

# Example keybinds
bind = SUPER, Return, exec, kitty
bind = SUPER, Q, killactive,
bind = SUPER, E, exec, rofi -show drun
bind = SUPER, F, fullscreen
bind = SUPER, H, movefocus, l
bind = SUPER, L, movefocus, r
bind = SUPER, K, movefocus, u
bind = SUPER, J, movefocus, d

general {
  gaps_in = 6
  gaps_out = 12
  border_size = 2
  col.active_border = 0xff8aadf4
  col.inactive_border = 0x44888888
}

decoration {
  rounding = 8
  drop_shadow = yes
  blur = yes
}
HCONF
  echo "[INFO] Wrote minimal ~/.config/hypr/hyprland.conf"
fi

# Final output
if have_cmd Hyprland || have_cmd hyprland; then
  echo "[OK] Hyprland present."
else
  echo "[WARN] Hyprland not found on PATH."
fi

echo "[INFO] Done.
Log out to TTY, then run: Hyprland
If you used --seatd, re-login or reboot so group membership takes effect.
If screensharing or file pickers act weird, the portals you installed cover it:
  xdg-desktop-portal + xdg-desktop-portal-hyprland + xdg-desktop-portal-gtk."
