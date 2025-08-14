#!/usr/bin/env bash
set -Eeuo pipefail

# Minimal Hyprland installer for Debian trixie
# - Idempotent on re-runs
# - Uses systemd-logind by default; optional --seatd to enable seatd and add groups

USE_SEATD=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --seatd) USE_SEATD=1 ;;
    *) echo "[ERROR] Unknown arg: $1"; exit 1 ;;
  esac
  shift
done

if [[ ${EUID:-0} -eq 0 ]]; then
  echo "[ERROR] Do not run as root. The script uses sudo when needed."
  exit 1
fi

# Helpers
have_cmd() { command -v "$1" >/dev/null 2>&1; }
is_installed_pkg() { dpkg -s "$1" >/dev/null 2>&1; }
service_enabled() { systemctl is-enabled "$1" >/dev/null 2>&1; }
service_active() { systemctl is-active "$1" >/dev/null 2>&1; }
user_in_group() { id -nG "$USER" | tr ' ' '\n' | grep -qx "$1"; }

# OS checks
if ! grep -q 'ID=debian' /etc/os-release; then
  echo "[ERROR] Debian only."
  exit 1
fi
. /etc/os-release || true
CODENAME="${VERSION_CODENAME:-}"
if [[ -z "$CODENAME" && $(have_cmd lsb_release && echo yes || echo no) == "yes" ]]; then
  CODENAME="$(lsb_release -sc || true)"
fi
case "$CODENAME" in
  trixie|sid|unstable) echo "[INFO] Debian $CODENAME detected. Using native packages." ;;
  *) echo "[ERROR] This script targets trixie. Your codename is '$CODENAME'."; exit 1 ;;
esac

# Ensure proper APT components for trixie
ensure_sources() {
  local want='deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware'
  if ! grep -Eq 'deb .* trixie .* main' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
    echo "[INFO] Writing standard trixie sources to /etc/apt/sources.list.d/zzz-trixie.list"
    echo "$want" | sudo tee /etc/apt/sources.list.d/zzz-trixie.list >/dev/null
  else
    # If components are missing, drop an additional file that includes them
    if ! grep -Eq 'contrib|non-free' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
      echo "[INFO] Adding contrib and non-free components via /etc/apt/sources.list.d/zzz-trixie-extra.list"
      echo "$want" | sudo tee /etc/apt/sources.list.d/zzz-trixie-extra.list >/dev/null
    fi
  fi
}
ensure_sources

echo "[INFO] apt update"
sudo apt update -y

# Decide portal package and launcher available in Debian
PORTAL_PKG="xdg-desktop-portal-hyprland"
if ! apt-cache show "$PORTAL_PKG" >/dev/null 2>&1; then
  PORTAL_PKG="xdg-desktop-portal-wlr"
  echo "[INFO] Falling back to $PORTAL_PKG"
fi

LAUNCHER_PKG="wofi"
if ! apt-cache show "$LAUNCHER_PKG" >/dev/null 2>&1; then
  LAUNCHER_PKG="rofi"
  echo "[INFO] Falling back to $LAUNCHER_PKG"
fi

# Build install lists
TO_INSTALL=()
add() { for p in "$@"; do is_installed_pkg "$p" || TO_INSTALL+=("$p"); done; }

# Core
add hyprland xwayland wl-clipboard grim slurp xdg-user-dirs polkit-kde-agent-1 \
    pipewire wireplumber dbus-user-session xdg-desktop-portal xdg-desktop-portal-gtk "$PORTAL_PKG"

# Useful defaults
add brightnessctl libinput-tools qt5ct qt6ct "$LAUNCHER_PKG" kitty

# Install missing
if [[ ${#TO_INSTALL[@]} -gt 0 ]]; then
  echo "[INFO] Installing: ${TO_INSTALL[*]}"
  sudo apt install -y "${TO_INSTALL[@]}"
else
  echo "[INFO] All required packages already present"
fi

# Seat management
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
  echo "[INFO] Using systemd-logind for device access"
fi

# Enable audio services
if have_cmd systemctl; then
  echo "[INFO] Enabling PipeWire and WirePlumber user services"
  systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service || true
fi

# Initialize XDG dirs
have_cmd xdg-user-dirs-update && xdg-user-dirs-update || true

# Minimal Hyprland config
HYPR_DIR="$HOME/.config/hypr"
HYPR_CONF="$HYPR_DIR/hyprland.conf"
mkdir -p "$HYPR_DIR"

if [[ ! -f "$HYPR_CONF" ]]; then
  cat > "$HYPR_CONF" <<'HCONF'
# Minimal Hyprland config for Debian trixie
monitor=,preferred,auto,1

# Keep DBus env sane for portals
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=X-Hyprland
exec-once = xdg-user-dirs-update
exec-once = /usr/lib/polkit-kde-authentication-agent-1

# Keys
# Terminal prefers kitty; falls back to foot or xterm if kitty missing
bind = SUPER, Return, exec, sh -lc 'command -v kitty >/dev/null && exec kitty || command -v foot >/dev/null && exec foot || exec xterm'

# App launcher prefers wofi; falls back to rofi
bind = SUPER, E, exec, sh -lc 'command -v wofi >/dev/null && exec wofi --show drun || exec rofi -show drun'

bind = SUPER, Q, killactive,
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

# Final checks
if have_cmd Hyprland || have_cmd hyprland; then
  echo "[OK] Hyprland installed."
else
  echo "[WARN] Hyprland not found on PATH."
fi

echo
echo "[INFO] Done. From a fresh TTY login run: Hyprland"
echo "[INFO] If you used --seatd, re-login so group membership applies."

