#!/usr/bin/env zsh
# setup-notify-heat.zsh v6 - portable CPU temp notifier and Waybar helper
# actions: setup | destroy | status | test <C> | test-sweep

emulate -L zsh
setopt err_return pipefail no_unset

# ---------- defaults ----------
: "${HEAT_THRESHOLDS:=60 65 70}"   # summer thresholds
: "${HEAT_COOLDOWN_MIN:=10}"       # minutes between same-bucket pings

BIN_NOTIFY="$HOME/.local/bin/heat-notify"
BIN_PRINT="$HOME/.local/bin/cpu-temp"
STATE_DIR="$HOME/.cache/heat-notify"
UNIT_DIR="$HOME/.config/systemd/user"
SVC="$UNIT_DIR/heat-notify.service"
TMR="$UNIT_DIR/heat-notify.timer"
SELF="${(%):-%N}"

ok()   { print -P "%F{2}[ok]%f $*"; }
warn() { print -P "%F{3}[warn]%f $*"; }
err()  { print -P "%F{1}[err]%f $*"; exit 1; }

need_user_systemd() {
  systemctl --user show-environment >/dev/null 2>&1 || err "user systemd not active"
}

write_file() {
  local target="$1" content="$2" dir tmp
  dir="${target:h}"
  [[ -n "$dir" ]] && mkdir -p "$dir"
  tmp="$(mktemp)" || err "mktemp failed"
  print -r -- "$content" > "$tmp"
  if [[ -f "$target" ]] && cmp -s "$tmp" "$target"; then
    rm -f "$tmp"
    ok "unchanged: $target"
  else
    mv "$tmp" "$target" || err "write failed: $target"
    ok "wrote: $target"
  fi
}

make_exec() { chmod +x "$1" || err "chmod +x $1"; ok "chmod +x $1"; }

# ---------- payload shared detection/logic (bash) ----------
# heat-notify doubles as printer: `heat-notify --print` prints temp in C
heat_notify_payload() { cat <<'BASH'
#!/usr/bin/env bash
set -o pipefail

# env knobs:
#   HEAT_THRESHOLDS="60 65 70"
#   HEAT_COOLDOWN_MIN=10
#   HEAT_STATE_DIR="$HOME/.cache/heat-notify"
#   HEAT_CPU_PATH="/sys/.../temp*_input"  optional override

read_temp_file() {
  local p="$1" v
  [[ -r "$p" ]] || return 1
  v=$(<"$p") || return 1
  [[ -n "$v" ]] || return 1
  # normalize to C if millidegrees
  if [[ "$v" -gt 200 ]]; then printf "%d" $((v/1000)); else printf "%d" "$v"; fi
}

detect_temp() {
  local t

  # explicit override
  if [[ -n "${HEAT_CPU_PATH:-}" ]]; then
    t="$(read_temp_file "$HEAT_CPU_PATH")" && { echo "$t"; return 0; }
  fi

  # thermal_zone first - stable on many Intel/ARM
  shopt -s nullglob
  for z in /sys/class/thermal/thermal_zone*; do
    [[ -f "$z/type" && -f "$z/temp" ]] || continue
    read -r typ <"$z/type" || true
    typ="${typ,,}"
    case "$typ" in
      x86_pkg_temp|*cpu*thermal*|*pkg*temp*|soc_thermal)
        t="$(read_temp_file "$z/temp")" && { echo "$t"; return 0; }
      ;;
    esac
  done

  # hwmon by name or label
  for h in /sys/class/hwmon/hwmon*; do
    [[ -r "$h/name" ]] || continue
    read -r nm <"$h/name" || true
    nm="${nm,,}"
    case "$nm" in
      coretemp|k10temp|zenpower|acpitz|pch_cannonlake|pch_cometlake)
        # prefer labeled inputs
        for l in "$h"/temp*_label; do
          [[ -r "$l" ]] || continue
          lbl="$(tr '[:upper:]' '[:lower:]' <"$l")"
          case "$lbl" in
            *tctl*|*tdie*|*package*|*cpu*)
              t="$(read_temp_file "${l/_label/_input}")" && { echo "$t"; return 0; }
          esac
        done
        # fallback
        for i in "$h"/temp*_input; do
          t="$(read_temp_file "$i")" && { echo "$t"; return 0; }
        done
      ;;
    esac
  done

  # lm-sensors parse fallback
  if command -v sensors >/dev/null 2>&1; then
    t="$(sensors 2>/dev/null | awk '/(Tctl|Tdie|Package id 0|CPU)/{match($0,/[0-9]+(\.[0-9])?/,m); if(m[0]!=""){printf "%.0f\n", m[0]; exit}}')" || true
    [[ -n "$t" ]] && { echo "$t"; return 0; }
  fi

  return 1
}

bucket_for() {
  local c="$1" b=0
  # shellcheck disable=SC2206
  local THS=(${HEAT_THRESHOLDS:-60 65 70})
  for t in "${THS[@]}"; do
    [[ "$c" -ge "$t" ]] && b="$t"
  done
  echo "$b"
}

urgency_for() {
  local b="$1"
  if   [[ "$b" -ge 70 ]]; then echo critical
  elif [[ "$b" -ge 65 ]]; then echo critical
  elif [[ "$b" -ge 60 ]]; then echo normal
  else echo low
  fi
}

title_for() {
  local b="$1"
  if   [[ "$b" -ge 70 ]]; then echo "CPU critical - lower heat now"
  elif [[ "$b" -ge 65 ]]; then echo "CPU hot - cool it"
  elif [[ "$b" -ge 60 ]]; then echo "CPU warm - rising"
  else echo "CPU ok"
  fi
}

icon_for() {
  local b="$1"
  if   [[ "$b" -ge 60 ]]; then echo dialog-warning
  else echo utilities-system-monitor
  fi
}

should_notify() {
  [[ "${HEAT_FORCE:-0}" = "1" ]] && return 0
  local bucket="$1" now last_file="${HEAT_STATE_DIR}/last_bucket" cd_file="${HEAT_STATE_DIR}/cooldown_${bucket}"
  now=$(date +%s)
  local last=0
  [[ -f "$last_file" ]] && last=$(<"$last_file")
  if [[ "$bucket" -le "$last" ]]; then
    if [[ -f "$cd_file" ]]; then
      local mins=$(( (now-$(<"$cd_file"))/60 ))
      [[ "$mins" -ge "${HEAT_COOLDOWN_MIN:-10}" ]] && return 0 || return 1
    fi
    return 1
  fi
  echo "$bucket" >"$last_file"
  echo "$now" >"$cd_file"
  return 0
}

notify_once() {
  command -v notify-send >/dev/null 2>&1 || return 0
  local urg="$1" title="$2" body="$3" icon="$4"
  notify-send --urgency="$urg" --icon="$icon" --app-name="CPU Heat" "$title" "$body" || true
}

main() {
  local print_only=0
  [[ "${1:-}" == "--print" ]] && print_only=1

  local c
  if [[ -n "${HEAT_FAKE_C:-}" ]]; then
    c="$HEAT_FAKE_C"
  else
    c="$(detect_temp)" || {
      [[ "$print_only" -eq 1 ]] && { echo "N/A"; exit 1; }
      exit 0
    }
  fi

  if [[ "$print_only" -eq 1 ]]; then
    echo "$c"
    exit 0
  fi

  mkdir -p "${HEAT_STATE_DIR:-$HOME/.cache/heat-notify}"
  local b; b="$(bucket_for "$c")"
  [[ "$b" -eq 0 ]] && exit 0

  if should_notify "$b"; then
    notify_once "$(urgency_for "$b")" "$(title_for "$b")" "${c}°C (≥${b}°)" "$(icon_for "$b")"
  fi
}

# if invoked as cpu-temp, default to print mode
case "$(basename "$0")" in
  cpu-temp) main --print ;;
  *)        main "$@" ;;
esac
BASH
}

cpu_print_wrapper() { cat <<'BASH'
#!/usr/bin/env bash
# thin wrapper for Waybar: prints integer Celsius or N/A
exec "$HOME/.local/bin/heat-notify" --print
BASH
}

# ---------- systemd units ----------
service_unit() { cat <<EOF
[Unit]
Description=CPU heat notify check
# run only when a wayland socket exists
ConditionPathExistsGlob=%t/wayland-*

[Service]
Type=oneshot
Environment=PATH=%h/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=HEAT_THRESHOLDS="${HEAT_THRESHOLDS}"
Environment=HEAT_COOLDOWN_MIN="${HEAT_COOLDOWN_MIN}"
Environment=HEAT_STATE_DIR="${STATE_DIR}"
# optional override: Environment=HEAT_CPU_PATH=/sys/class/hwmon/.../temp1_input
ExecStart=/usr/bin/env bash -lc '%h/.local/bin/heat-notify || :'
EOF
}

timer_unit() { cat <<'EOF'
[Unit]
Description=CPU heat notify periodic timer

[Timer]
OnBootSec=30s
OnUnitActiveSec=20s
AccuracySec=5s
Persistent=true
Unit=heat-notify.service

[Install]
WantedBy=timers.target
EOF
}

# ---------- commands ----------
setup() {
  need_user_systemd
  write_file "$BIN_NOTIFY" "$(heat_notify_payload)"
  make_exec "$BIN_NOTIFY"
  write_file "$BIN_PRINT"  "$(cpu_print_wrapper)"
  make_exec "$BIN_PRINT"

  write_file "$SVC" "$(service_unit)"
  write_file "$TMR" "$(timer_unit)"

  rm -rf "$STATE_DIR"; mkdir -p "$STATE_DIR"

  systemctl --user daemon-reload
  systemctl --user enable --now heat-notify.timer
  ok "enabled heat-notify.timer"

  systemctl --user start heat-notify.service || true
  ok "kicked first check"

  print -P "%F{4}Waybar exec:%f  $BIN_PRINT"
  print -P "%F{4}Test:%f       $SELF test 60   |   $SELF test 70"
}

destroy() {
  need_user_systemd
  systemctl --user stop heat-notify.timer 2>/dev/null || true
  systemctl --user disable heat-notify.timer 2>/dev/null || true
  systemctl --user daemon-reload || true

  rm -f "$SVC" "$TMR" "$BIN_NOTIFY" "$BIN_PRINT"
  ok "removed units and binaries"

  rm -rf "$STATE_DIR"
  ok "cleared state"
}

status() {
  need_user_systemd
  systemctl --user status --no-pager heat-notify.timer  || true
  systemctl --user status --no-pager heat-notify.service || true
}

test_level() {
  local c="${1:-60}"
  HEAT_THRESHOLDS="$HEAT_THRESHOLDS" \
  HEAT_COOLDOWN_MIN=0 \
  HEAT_STATE_DIR="$STATE_DIR" \
  HEAT_FORCE=1 \
  HEAT_FAKE_C="$c" \
  "$BIN_NOTIFY"
  ok "simulated CPU ${c}°C"
}

test_sweep() {
  for c in $(seq 55 75); do
    HEAT_THRESHOLDS="$HEAT_THRESHOLDS" HEAT_COOLDOWN_MIN=0 HEAT_STATE_DIR="$STATE_DIR" HEAT_FORCE=1 HEAT_FAKE_C="$c" "$BIN_NOTIFY"
    sleep 0.06
  done
  ok "sweep done"
}

usage() {
  cat <<EOF
Usage:
  $SELF setup | destroy | status | test <C> | test-sweep

Waybar:
  "custom/cpu_temp": { "exec": "$BIN_PRINT", "interval": 2, "format": " {}°C" }

Env:
  HEAT_THRESHOLDS="${HEAT_THRESHOLDS}"
  HEAT_COOLDOWN_MIN=${HEAT_COOLDOWN_MIN}
  # optional: HEAT_CPU_PATH=/sys/class/hwmon/.../tempX_input
EOF
}

case "${1:-}" in
  setup) setup ;;
  destroy) destroy ;;
  status) status ;;
  test) shift; test_level "${1:-60}" ;;
  test-sweep) test_sweep ;;
  *) usage; exit 1 ;;
esac

