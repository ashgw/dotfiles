#!/usr/bin/env bash
set -euo pipefail
BASEDIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Restoring APT sources (Debian/Ubuntu)…"
if [[ -d /etc/apt && -d "$BASEDIR/apt-sources" ]]; then
  sudo cp -a "$BASEDIR/apt-sources/sources.list" /etc/apt/ 2>/dev/null || true
  [[ -d "$BASEDIR/apt-sources/sources.list.d" ]] && sudo cp -a "$BASEDIR/apt-sources/sources.list.d" /etc/apt/ 2>/dev/null || true
  [[ -d "$BASEDIR/apt-keys/trusted.gpg.d"    ]] && sudo cp -a "$BASEDIR/apt-keys/trusted.gpg.d"    /etc/apt/ 2>/dev/null || true
  [[ -f "$BASEDIR/apt-keys/apt-key-export.gpg" ]] && sudo apt-key add "$BASEDIR/apt-keys/apt-key-export.gpg" 2>/dev/null || true
  sudo apt update || true
fi

echo "==> Installing APT manual packages…"
[[ -f "$BASEDIR/apt-installed.txt" ]] && xargs -a "$BASEDIR/apt-installed.txt" -r sudo apt install -y

echo "==> (Optional) Replaying dpkg selections…"
if [[ -f "$BASEDIR/dpkg-selections.txt" ]]; then
  sudo dpkg --set-selections < "$BASEDIR/dpkg-selections.txt" || true
  sudo apt-get dselect-upgrade -y || true
fi

echo "==> Restoring Snap…"
if command -v snap >/dev/null && [[ -f "$BASEDIR/snap-list.txt" ]]; then
  awk 'NR>1 {print $1}' "$BASEDIR/snap-list.txt" | while read -r s; do
    [[ -n "$s" ]] && sudo snap install "$s" || true
  done
fi

echo "==> Restoring Flatpak…"
if command -v flatpak >/dev/null; then
  [[ -f "$BASEDIR/flatpak-remotes-system.txt" ]] && awk 'NR>1{print $1,$2}' "$BASEDIR/flatpak-remotes-system.txt" | while read -r name url; do
    flatpak remote-add --if-not-exists "$name" "$url" --system || true
  done
  [[ -f "$BASEDIR/flatpak-remotes-user.txt" ]] && awk 'NR>1{print $1,$2}' "$BASEDIR/flatpak-remotes-user.txt" | while read -r name url; do
    flatpak remote-add --if-not-exists "$name" "$url" --user || true
  done
  [[ -f "$BASEDIR/flatpak-system.txt" ]] && awk '{print $1}' "$BASEDIR/flatpak-system.txt" | xargs -r -n1 flatpak install -y --system || true
  [[ -f "$BASEDIR/flatpak-user.txt"   ]] && awk '{print $1}' "$BASEDIR/flatpak-user.txt"   | xargs -r -n1 flatpak install -y --user   || true
fi

echo "==> Restoring pip3…"
[[ -f "$BASEDIR/pip3-freeze.txt" ]] && command -v pip3 >/dev/null && pip3 install -U -r "$BASEDIR/pip3-freeze.txt" || true

echo "==> Restoring pipx…"
if command -v pipx >/dev/null && [[ -f "$BASEDIR/pipx-list.json" ]]; then
python3 - "$BASEDIR/pipx-list.json" <<'PY'
import json, subprocess, sys
j=json.load(open(sys.argv[1]))
for p in j.get("venvs",{}).keys():
    try: subprocess.run(["pipx","install",p],check=False)
    except: pass
PY
fi

echo "==> Restoring npm/pnpm globals…"
[[ -f "$BASEDIR/npm-global.txt"  ]] && command -v npm  >/dev/null && xargs -a "$BASEDIR/npm-global.txt"  -r npm  i -g || true
[[ -f "$BASEDIR/pnpm-global.txt" ]] && command -v pnpm >/dev/null && xargs -a "$BASEDIR/pnpm-global.txt" -r pnpm add -g || true

echo "==> Restoring Cargo & Rust toolchains…"
[[ -f "$BASEDIR/cargo-crates.txt"      ]] && command -v cargo  >/dev/null && xargs -a "$BASEDIR/cargo-crates.txt" -r -n1 cargo install || true
[[ -f "$BASEDIR/rustup-toolchains.txt" ]] && command -v rustup >/dev/null && awk '{print $1}' "$BASEDIR/rustup-toolchains.txt" | xargs -r -n1 rustup toolchain install || true

echo "==> Restoring Homebrew (if present)…"
if command -v brew >/dev/null && [[ -d "$BASEDIR/brew" ]]; then
  [[ -f "$BASEDIR/brew/taps.txt"   ]] && xargs -a "$BASEDIR/brew/taps.txt"   -r brew tap   || true
  [[ -f "$BASEDIR/brew/leaves.txt" ]] && xargs -a "$BASEDIR/brew/leaves.txt" -r brew install || true
  [[ -f "$BASEDIR/brew/casks.txt"  ]] && xargs -a "$BASEDIR/brew/casks.txt"  -r brew install --cask || true
fi

echo "==> GNOME keybindings (optional)…"
[[ -f "$BASEDIR/keybindings.dconf" ]] && command -v dconf >/dev/null && dconf load /org/gnome/settings-daemon/plugins/media-keys/ < "$BASEDIR/keybindings.dconf" || true

echo "==> Done."
