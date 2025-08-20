#!/usr/bin/env zsh
PATH=/usr/sbin:/usr/bin:/sbin:/bin:$HOME/.local/bin:$HOME/bin:$PATH
set -euo pipefail 2>/dev/null || true
setopt pipefail

# =========================
# Battery notifications
# Debian Trixie + Hyprland + Mako
# Idempotent setup/destroy script
# =========================

# --- tweakables ---
: "${THRESHOLDS:=50 20 10 5 1}"   # fire when level <= these, on discharge
: "${COOLDOWN_MIN:=20}"           # minutes between repeats for same bucket

# --- paths ---
BIN="$HOME/.local/bin/battery-notify"
STATE_DIR="$HOME/.cache/battery-notify"
UNIT_DIR="$HOME/.config/systemd/user"
SVC="$UNIT_DIR/battery-notify.service"
TMR="$UNIT_DIR/battery-notify.timer"

# --- ui ---
blue(){  print -P "%F{4}[*]%f $*"; }
ok(){    print -P "%F{2}[ok]%f $*"; }
warn(){  print -P "%F{3}[warn]%f $*"; }
err(){   print -P "%F{1}[err]%f $*"; exit 1; }

have(){ command -v "$1" >/dev/null 2>&1; }

need_user_systemd(){
  systemctl --user show-environment >/dev/null 2>&1 || \
    err "User systemd not active. Log in with a systemd user session."
}

# safe writer, no dirname, no shadowing $path
write_file(){
  local target="$1" content="$2" dir tmp
  dir="${target:h}"
  [[ -n "$dir" ]] && mkdir -p "$dir"
  tmp="$(mktemp)"
  print -r -- "$content" > "$tmp"
  if [[ -f "$target" ]] && cmp -s "$tmp" "$target"; then
    rm -f "$tmp"
    ok "unchanged: $target"
  else
    mv "$tmp" "$target"
    ok "wrote: $target"
  fi
}

make_exec(){ chmod +x "$1"; ok "chmod +x $1"; }

install_deps_hint(){
  have notify-send || warn "notify-send missing. Install: sudo apt update && sudo apt install -y libnotify-bin"
  have upower || warn "upower not found. Install: sudo apt update && sudo apt install -y upower"
}

battery_script(){
  cat <<'SH'
#!/usr/bin/env bash
set -euo pipefail

THRESHOLDS=(${THRESHOLDS:-50 20 10 5 1})
COOLDOWN_MIN=${COOLDOWN_MIN:-20}
STATE_DIR="${STATE_DIR:-$HOME/.cache/battery-notify}"

mkdir -p "$STATE_DIR"
log(){ printf "[battery-notify] %s\n" "$*"; }

detect_bat(){
  local bat
  if command -v upower >/dev/null 2>&1; then
    bat=$(upower -e | awk '/battery/{print; exit}')
    [[ -n "$bat" ]] && { echo "$bat"; return 0; }
  fi
  bat=$(ls /sys/class/power_supply 2>/dev/null | grep -E '^BAT' | head -n1 || true)
  [[ -n "$bat" ]] && { echo "/sys/class/power_supply/$bat"; return 0; }
  echo ""; return 1
}

read_level_and_state(){
  local dev="$1" level state info
  if [[ "$dev" =~ ^/sys/class/power_supply ]]; then
    level=$(cat "$dev/capacity")
    state=$(tr '[:upper:]' '[:lower:]' < "$dev/status")
  else
    info="$(upower -i "$dev")"
    level=$(awk -F': *' '/percentage/{gsub("%","",$2); print $2}' <<<"$info")
    state=$(awk -F': *' '/state/{print tolower($2)}' <<<"$info")
  fi
  echo "$level" "$state"
}

bucket_for(){
  local lvl="$1" b="100"
  for t in "${THRESHOLDS[@]}"; do
    if (( lvl <= t )); then b="$t"; fi
  done
  echo "$b"
}

should_notify(){
  local bucket="$1" now last_file="$STATE_DIR/last_$bucket"
  now=$(date +%s)
  if [[ -f "$last_file" ]]; then
    local last tsdiff
    last=$(<"$last_file")
    tsdiff=$(( (now - last)/60 ))
    (( tsdiff < COOLDOWN_MIN )) && return 1
  fi
  echo "$now" > "$last_file"
  return 0
}

urgency_for(){
  local bucket="$1"
  if   (( bucket <= 10 )); then echo critical
  elif (( bucket <= 20 )); then echo normal
  else                        echo low
  fi
}

icon_for(){
  local lvl="$1"
  if   (( lvl <= 5 ));   then echo battery-caution-symbolic
  elif (( lvl <= 10 ));  then echo battery-empty-symbolic
  elif (( lvl <= 20 ));  then echo battery-low-symbolic
  elif (( lvl <= 50 ));  then echo battery-medium-symbolic
  else                       echo battery-good-symbolic
  fi
}

send_note(){
  local urgency="$1" title="$2" body="$3" icon="$4"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send --app-name="Battery" --urgency="$urgency" --icon="$icon" "$title" "$body"
  else
    log "notify-send not found. Skipping notification."
  fi
}

main(){
  local dev level state
  dev=$(detect_bat) || { log "no battery device found"; exit 0; }
  read -r level state < <(read_level_and_state "$dev")

  # testing hooks
  if [[ -n "${BAT_FAKE_LEVEL:-}" ]]; then level="$BAT_FAKE_LEVEL"; fi
  if [[ -n "${BAT_FORCE_STATE:-}" ]]; then state="$BAT_FORCE_STATE"; fi
  if [[ "${BAT_FORCE:-0}" = "1" ]]; then state="discharging"; fi

  case "$state" in
    discharging|unknown) ;;  # proceed
    *) exit 0 ;;             # only notify on discharge
  esac

  local bucket urgency icon
  bucket="$(bucket_for "$level")"
  (( level > ${THRESHOLDS[0]} )) && exit 0

  if should_notify "$bucket"; then
    urgency="$(urgency_for "$bucket")"
    icon="$(icon_for "$level")"
    local label
    if   (( bucket <= 1 ));  then label="Battery critically low"
    elif (( bucket <= 5 ));  then label="Battery very low"
    elif (( bucket <= 10 )); then label="Battery low"
    elif (( bucket <= 20 )); then label="Battery warning"
    else                       label="Battery at ${bucket}%"
    fi
    send_note "$urgency" "$label" "$level% remaining" "$icon"
  fi
}
main "$@"
SH
}

service_unit(){
  cat <<EOF
[Unit]
Description=Battery notify check
ConditionPathExistsGlob=/run/user/%u/wayland-*
After=graphical-session.target

[Service]
Type=oneshot
Environment=THRESHOLDS="${THRESHOLDS}"
Environment=COOLDOWN_MIN="${COOLDOWN_MIN}"
Environment=STATE_DIR="${STATE_DIR}"
ExecStart=${BIN}

[Install]
WantedBy=default.target
EOF
}

timer_unit(){
  cat <<'EOF'
[Unit]
Description=Battery notify periodic timer

[Timer]
OnBootSec=2m
OnUnitActiveSec=1m
AccuracySec=15s
Persistent=true
Unit=battery-notify.service

[Install]
WantedBy=timers.target
EOF
}

setup(){
  install_deps_hint
  need_user_systemd

  write_file "$BIN" "$(battery_script)"
  make_exec "$BIN"

  write_file "$SVC" "$(service_unit)"
  write_file "$TMR" "$(timer_unit)"

  systemctl --user daemon-reload
  systemctl --user enable --now battery-notify.timer
  ok "enabled timer battery-notify.timer"

  # first check
  systemctl --user start battery-notify.service
  ok "kicked a first check"
  blue "Tweaks: export THRESHOLDS='50 20 10 5 1' or COOLDOWN_MIN=30 before setup."
}

destroy(){
  need_user_systemd
  systemctl --user stop battery-notify.timer 2>/dev/null || true
  systemctl --user disable battery-notify.timer 2>/dev/null || true
  systemctl --user daemon-reload || true
  rm -f "$SVC" "$TMR"
  ok "removed units"
  rm -f "$BIN"
  ok "removed $BIN"
  rm -rf "$STATE_DIR"
  ok "cleared state dir"
  blue "All cleaned up."
}

test_level(){
  local lvl="${1:-15}"
  THRESHOLDS="$THRESHOLDS" COOLDOWN_MIN="$COOLDOWN_MIN" STATE_DIR="$STATE_DIR" \
  BAT_FORCE=1 BAT_FORCE_STATE=discharging BAT_FAKE_LEVEL="$lvl" "$BIN"
  ok "simulated level $lvl%"
}

usage(){
  cat <<EOF
Usage:
  $0 setup                install script, service, timer
  $0 destroy              remove everything
  $0 test <level>         simulate one notification at <level>%

Env:
  THRESHOLDS="50 20 10 5 1"
  COOLDOWN_MIN=20
EOF
}

case "${1:-}" in
  setup)   setup ;;
  destroy) destroy ;;
  test)    shift; test_level "${1:-15}" ;;
  *)       usage; exit 1 ;;
esac

