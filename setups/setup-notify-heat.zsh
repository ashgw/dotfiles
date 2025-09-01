
#!/usr/bin/env zsh
# setup-notify-heat.zsh v5 — thresholds: 55/60/65/70 (≤50 cool)

emulate -L zsh
setopt err_return pipefail no_unset

: "${HEAT_THRESHOLDS:=55 60 65 70}"
: "${HEAT_COOLDOWN_MIN:=10}"

BIN="$HOME/.local/bin/heat-notify"
STATE_DIR="$HOME/.cache/heat-notify"
UNIT_DIR="$HOME/.config/systemd/user"
SVC="$UNIT_DIR/heat-notify.service"
TMR="$UNIT_DIR/heat-notify.timer"
SELF="${(%):-%N}"

ok(){   print -P "%F{2}[ok]%f $*"; }
warn(){ print -P "%F{3}[warn]%f $*"; }
err(){  print -P "%F{1}[err]%f $*"; exit 1; }
need_user_systemd(){ systemctl --user show-environment >/dev/null 2>&1 || err "User systemd not active."; }

write_file(){ local t="$1" c="$2" d tmp; d="${t:h}"; [[ -n "$d" ]] && mkdir -p "$d"; tmp="$(mktemp)"; print -r -- "$c" > "$tmp"; if [[ -f "$t" ]] && cmp -s "$tmp" "$t"; then rm -f "$tmp"; ok "unchanged: $t"; else mv "$tmp" "$t"; ok "wrote: $t"; fi }
make_exec(){ chmod +x "$1"; ok "chmod +x $1"; }

# ------------ payload (bash) ------------
heat_script(){ cat <<'SH'
#!/usr/bin/env bash
# robust: no -e/-u; never nonzero-exit for systemd
set -o pipefail

IFS=' ' read -r -a THRESHOLDS <<< "${HEAT_THRESHOLDS:-55 60 65 70}"
COOLDOWN_MIN=${HEAT_COOLDOWN_MIN:-10}
STATE_DIR="${HEAT_STATE_DIR:-$HOME/.cache/heat-notify}"
CPU_HINT="${HEAT_CPU_PATH:-/sys/class/hwmon/hwmon5/temp1_input}"

mkdir -p "$STATE_DIR"
log(){ printf "[heat-notify] %s\n" "$*" >&2; }

read_temp_file(){
  local p="$1" v
  [[ -r "$p" ]] || return 1
  v=$(<"$p") || return 1
  [[ -n "$v" ]] || return 1
  if [[ "$v" -gt 200 ]]; then printf "%d" $((v/1000)); else printf "%d" "$v"; fi
}

detect_temp(){
  local t
  [[ -n "${HEAT_CPU_PATH:-}" ]] && t="$(read_temp_file "$HEAT_CPU_PATH")" && { echo "$t"; return 0; }
  t="$(read_temp_file "$CPU_HINT")" && { echo "$t"; return 0; }
  shopt -s nullglob
  local h l
  for h in /sys/class/hwmon/hwmon*; do
    for l in "$h"/temp*_label; do
      [[ -r "$l" ]] || continue
      case "$(tr '[:upper:]' '[:lower:]' <"$l")" in
        *tctl*|*tdie*|*package*|*cpu*)
          t="$(read_temp_file "${l/_label/_input}")" && { echo "$t"; return 0; }
          ;;
      esac
    done
    t="$(read_temp_file "$h/temp1_input")" && { echo "$t"; return 0; }
  done
  if command -v sensors >/dev/null 2>&1; then
    t="$(sensors 2>/dev/null | awk '/(Tctl|Tdie|Package id 0|CPU)/{match($0,/[0-9]+(\.[0-9])?/,m); if(m[0]!=""){printf "%.0f\n", m[0]; exit}}')" || true
    [[ -n "$t" ]] && { echo "$t"; return 0; }
  fi
  return 1
}

bucket_for(){ local c="$1" b=0; for t in "${THRESHOLDS[@]}"; do (( c>=t )) && b="$t"; done; echo "$b"; }
urgency_for(){ local b="$1"; if   (( b>=70 )); then echo critical; elif (( b>=65 )); then echo critical; elif (( b>=60 )); then echo normal; else echo low; fi; }
title_for(){   local b="$1"; if   (( b>=70 )); then echo "CPU 🔥🔥 SUPER CRITICAL"; elif (( b>=65 )); then echo "CPU 🔥 CRITICAL"; elif (( b>=60 )); then echo "CPU Warning"; else echo "CPU Warm"; fi; }
icon_for(){    local b="$1"; if   (( b>=70 )); then echo dialog-error; elif (( b>=65 )); then echo dialog-error; elif (( b>=60 )); then echo dialog-warning; else echo utilities-system-monitor; fi; }

should_notify(){
  [[ "${HEAT_FORCE:-0}" = "1" ]] && return 0
  local bucket="$1" now last_file="$STATE_DIR/last_bucket" cd_file="$STATE_DIR/cooldown_$bucket"
  now=$(date +%s)
  local last=0; [[ -f "$last_file" ]] && last=$(<"$last_file")
  if (( bucket <= last )); then
    if [[ -f "$cd_file" ]]; then
      local tsd=$(( (now-$(<"$cd_file"))/60 ))
      (( tsd >= COOLDOWN_MIN )) && return 0 || return 1
    fi
    return 1
  fi
  echo "$bucket" > "$last_file"; echo "$now" > "$cd_file"; return 0
}

send_note(){
  local urg="$1" title="$2" body="$3" icon="$4"
  command -v notify-send >/dev/null 2>&1 || { log "notify-send missing"; return 0; }
  notify-send --urgency="$urg" --icon="$icon" --app-name="CPU Heat" "$title" "$body" || true
}

main(){
  local c
  if [[ -n "${HEAT_FAKE_C:-}" ]]; then c="$HEAT_FAKE_C"
  else
    if ! c="$(detect_temp)"; then log "no temperature source"; exit 0; fi
  fi

  local b; b="$(bucket_for "$c")"
  (( b == 0 )) && exit 0      # ≤ first bucket → cool

  if should_notify "$b"; then
    send_note "$(urgency_for "$b")" "$(title_for "$b")" "${c}°C (≥${b}°)" "$(icon_for "$b")"
  fi
  exit 0
}
main "$@"
SH
}

# ------------ units ------------
service_unit(){ cat <<EOF
[Unit]
Description=CPU heat notify check
ConditionPathExistsGlob=%t/wayland-*

[Service]
Type=oneshot
# Make PATH sane in user units; include ~/.local/bin for notify-send on some distros
Environment=PATH=%h/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=HEAT_THRESHOLDS="${HEAT_THRESHOLDS}"
Environment=HEAT_COOLDOWN_MIN="${HEAT_COOLDOWN_MIN}"
Environment=HEAT_STATE_DIR="${STATE_DIR}"
Environment=HEAT_CPU_PATH="/sys/class/hwmon/hwmon5/temp1_input"
# Force success even if script returns nonzero for any reason
ExecStart=/usr/bin/env bash -lc '%h/.local/bin/heat-notify || :'
EOF
}

timer_unit(){ cat <<'EOF'
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

setup(){
  need_user_systemd
  write_file "$BIN" "$(heat_script)"; make_exec "$BIN"
  write_file "$SVC" "$(service_unit)"
  write_file "$TMR" "$(timer_unit)"
  rm -rf "$STATE_DIR"; mkdir -p "$STATE_DIR"
  systemctl --user daemon-reload
  systemctl --user enable --now heat-notify.timer
  ok "enabled timer heat-notify.timer"
  systemctl --user start heat-notify.service || true
  ok "kicked first check"
  print -P "%F{4}Test:%f  $SELF test 60   |  $SELF test 70"
}

destroy(){
  need_user_systemd
  systemctl --user stop heat-notify.timer 2>/dev/null || true
  systemctl --user disable heat-notify.timer 2>/dev/null || true
  systemctl --user daemon-reload || true
  rm -f "$SVC" "$TMR" "$BIN"
  ok "removed units and binary"
  rm -rf "$STATE_DIR"; ok "cleared state"
}

status(){ need_user_systemd; systemctl --user status --no-pager heat-notify.timer || true; systemctl --user status --no-pager heat-notify.service || true; }

test_level(){
  local c="${1:-60}"
  HEAT_THRESHOLDS="$HEAT_THRESHOLDS" HEAT_COOLDOWN_MIN=0 HEAT_STATE_DIR="$STATE_DIR" HEAT_FORCE=1 HEAT_FAKE_C="$c" "$BIN"
  ok "simulated CPU ${c}°C"
}

test_sweep(){
  for c in $(seq 50 75); do
    HEAT_THRESHOLDS="$HEAT_THRESHOLDS" HEAT_COOLDOWN_MIN=0 HEAT_STATE_DIR="$STATE_DIR" HEAT_FORCE=1 HEAT_FAKE_C="$c" "$BIN"
    sleep 0.06
  done
  ok "sweep done"
}

usage(){
  cat <<EOF
Usage:
  $SELF setup|destroy|status|test <C>|test-sweep
Env:
  HEAT_THRESHOLDS="${HEAT_THRESHOLDS}"
  HEAT_COOLDOWN_MIN=${HEAT_COOLDOWN_MIN}
  HEAT_CPU_PATH=/sys/class/hwmon/hwmon5/temp1_input
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

