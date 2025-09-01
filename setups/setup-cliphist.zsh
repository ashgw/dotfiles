#!/usr/bin/env zsh
# setup-cliphist.zsh  Hyprland + Wayland. No systemd. Idempotent.

emulate -L zsh
setopt err_return no_unset pipefail

: "${CLIP_CAP:=20}"
: "${BIN_DIR:=$HOME/.local/bin}"
: "${STATE_DIR:=$HOME/.local/state/cliphist}"   # locks and pidfiles
: "${CACHE_DIR:=$HOME/.cache/cliphist}"         # cliphist uses this too

STORE="$BIN_DIR/cliphist-store-prune"
WATCH="$BIN_DIR/cliphist-watchers"
FZF_MENU="$BIN_DIR/clip-menu"
WOFI_MENU="$BIN_DIR/clip-wofi"
CACHE_TSV="$CACHE_DIR/top.tsv"
LOCKFILE="$STATE_DIR/lockfile"
WATCH_PIDFILE="$STATE_DIR/watchers.pid"

blue(){ print -P "%F{4}[*]%f $*"; }
ok(){   print -P "%F{2}[ok]%f $*"; }
warn(){ print -P "%F{3}[warn]%f $*"; }
err(){  print -P "%F{1}[err]%f $*"; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }
need_user(){ [[ $EUID -ne 0 ]] || err "Run as your user, not root"; }
mkdirp(){ [[ -d "$1" ]] || mkdir -p "$1"; }
make_exec(){ chmod +x "$1" || err "chmod +x $1 failed"; }

assert_env(){
  have cliphist || err "cliphist missing. Install with: GO111MODULE=on go install github.com/sentriz/cliphist@latest"
  have wl-copy  || err "wl-clipboard missing"
  have wl-paste || err "wl-clipboard missing"
  have file     || err "file(1) missing"
  command -v fzf  >/dev/null || warn "fzf not found. Terminal picker will be skipped"
  command -v wofi >/dev/null || warn "wofi not found. GUI picker will be skipped"
}

write_store(){
  mkdirp "$BIN_DIR" "$CACHE_DIR" "$STATE_DIR"
  cat > "$STORE" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"

CAP="${CLIP_CAP:-20}"
case "$CAP" in (*[!0-9]*|'') CAP=20;; esac

LOCKFILE="${STATE_DIR:-$HOME/.local/state/cliphist}/lockfile"
CACHE_TSV="${CACHE_DIR:-$HOME/.cache/cliphist}/top.tsv"

lock_and_run() {
  if command -v flock >/dev/null 2>&1; then
    exec 9>"$LOCKFILE"
    flock -w 2 9 || exit 0
    "$@"
  else
    LOCKDIR="${LOCKFILE}.d"
    if mkdir "$LOCKDIR" 2>/dev/null; then
      trap 'rmdir "$LOCKDIR" 2>/dev/null || true' EXIT
      "$@"
    else
      exit 0
    fi
  fi
}

store_input() {
  # If called without stdin, seed from current clipboards to avoid blocking
  if [ -t 0 ]; then
    { wl-paste --no-newline 2>/dev/null || true; } | cliphist store || true
    { wl-paste --type image 2>/dev/null || true; } | cliphist store || true
  else
    cat | cliphist store || true
  fi
}

materialize_cache() {
  tmp="$(mktemp -p "${CACHE_TSV%/*}" top.XXXXXX.tsv)"
  cliphist list | head -n "$CAP" > "$tmp" || true
  mv -f "$tmp" "$CACHE_TSV"
}

prune_db() {
  ids="$(cliphist list | tail -n +$((CAP+1)) | cut -f1 || true)"
  if [ -n "${ids:-}" ]; then
    printf '%s\n' "$ids" | xargs -r -n1 cliphist delete
  fi
}

do_store() {
  store_input
  prune_db
  materialize_cache
}

lock_and_run do_store
SH
  perl -0777 -pe "s|STATE_DIR:-\\$HOME/.local/state/cliphist|STATE_DIR:-$STATE_DIR|g" -i "$STORE" 2>/dev/null || true
  perl -0777 -pe "s|CACHE_DIR:-\\$HOME/.cache/cliphist|CACHE_DIR:-$CACHE_DIR|g" -i "$STORE" 2>/dev/null || true
  perl -0777 -pe "s/CLIP_CAP:-20/CLIP_CAP:-$CLIP_CAP/g" -i "$STORE" 2>/dev/null || true
  make_exec "$STORE"
  ok "store+prune+cache: $STORE"
}

write_watchers(){
  mkdirp "$BIN_DIR" "$STATE_DIR"
  cat > "$WATCH" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"

WATCH_PIDFILE="${STATE_DIR:-$HOME/.local/state/cliphist}/watchers.pid"
STORE="$HOME/.local/bin/cliphist-store-prune"

already_running() {
  if [ -f "$WATCH_PIDFILE" ]; then
    old="$(cat "$WATCH_PIDFILE" 2>/dev/null || true)"
    if [ -n "$old" ] && ps -p "$old" -o comm= 2>/dev/null | grep -q .; then
      exit 0
    fi
  fi
  if pgrep -fa 'wl-paste .* cliphist-store-prune' >/dev/null; then
    exit 0
  fi
}

spawn() {
  echo "$$" > "$WATCH_PIDFILE" || true
  wl-paste --type text           --watch "$STORE" &
  wl-paste --primary --type text --watch "$STORE" &
  wl-paste --type image          --watch "$STORE" &
  wait -n
}

already_running
spawn
SH
  perl -0777 -pe "s|STATE_DIR:-\\$HOME/.local/state/cliphist|STATE_DIR:-$STATE_DIR|g" -i "$WATCH" 2>/dev/null || true
  make_exec "$WATCH"
  ok "watchers: $WATCH"
}

write_fzf_menu(){
  command -v fzf >/dev/null || return 0
  cat > "$FZF_MENU" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"

need(){ command -v "$1" >/dev/null 2>&1 || { echo "$1 missing" >&2; exit 1; }; }
need cliphist; need fzf; need wl-copy; need file

CAP="${CLIP_CAP:-20}"
CACHE_TSV="${CACHE_DIR:-$HOME/.cache/cliphist}/top.tsv"
STORE="$HOME/.local/bin/cliphist-store-prune"

seed_cache() {
  if [ ! -s "$CACHE_TSV" ]; then
    "$STORE" || true
  fi
}
seed_cache

# keep DB tight
ids="$(cliphist list | tail -n +$((CAP+1)) | cut -f1 || true)"
[ -n "${ids:-}" ] && printf '%s\n' "$ids" | xargs -r -n1 cliphist delete || true

sel="$(
  cat "$CACHE_TSV" 2>/dev/null | head -n "$CAP" \
  | fzf --ansi --no-sort --tac --cycle \
        --prompt='clip> ' \
        --header='enter copy  ctrl-d delete  ctrl-o open  ctrl-y copy shown text' \
        --delimiter='\t' --with-nth=2.. \
        --bind 'enter:accept' \
        --bind 'ctrl-d:execute-silent(echo {1} | xargs -r -n1 cliphist delete)+'\
'reload(cat '"$CACHE_TSV"' | head -n '"$CAP"')' \
        --bind 'ctrl-o:execute-silent(echo {1} | xargs -I{} sh -c "cliphist decode {} > /tmp/clip_$PPID; nohup xdg-open /tmp/clip_$PPID >/dev/null 2>&1 &")' \
        --bind 'ctrl-y:execute-silent(sh -c '\''printf "%s" "{2..}" | sed "s/^\[[^]]*\]\s*//" | wl-copy'\'' )+abort'
) " || exit 0

id="$(printf '%s\n' "$sel" | cut -f1)"; [ -n "$id" ] || exit 0
tmp="$(mktemp -t cliphist_dec_XXXXXX)"
cliphist decode "$id" > "$tmp" || exit 0
mime="$(file -b --mime-type "$tmp")"
if [[ "$mime" == image/* ]]; then
  wl-copy --type image/png < "$tmp"; wl-copy --primary --type image/png < "$tmp"
else
  wl-copy < "$tmp"; wl-copy --primary < "$tmp"
fi
rm -f "$tmp"
SH
  perl -0777 -pe "s/CLIP_CAP:-20/CLIP_CAP:-$CLIP_CAP/g" -i "$FZF_MENU" 2>/dev/null || true
  make_exec "$FZF_MENU"
  ok "tty picker: $FZF_MENU"
}

write_wofi_menu(){
  command -v wofi >/dev/null || return 0
  cat > "$WOFI_MENU" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"

need(){ command -v "$1" >/dev/null 2>&1 || { echo "$1 missing" >&2; exit 1; }; }
need cliphist; need wofi; need wl-copy; need file

CAP="${CLIP_CAP:-20}"
CACHE_TSV="${CACHE_DIR:-$HOME/.cache/cliphist}/top.tsv"
STORE="$HOME/.local/bin/cliphist-store-prune"

seed_cache() {
  if [ ! -s "$CACHE_TSV" ]; then
    "$STORE" || true
  fi
}
seed_cache

ids="$(cliphist list | tail -n +$((CAP+1)) | cut -f1 || true)"
[ -n "${ids:-}" ] && printf '%s\n' "$ids" | xargs -r -n1 cliphist delete || true

sel="$(cat "$CACHE_TSV" 2>/dev/null | head -n "$CAP" | wofi --dmenu -i -p 'clip>' )" || exit 0
id="$(printf '%s\n' "$sel" | cut -f1)"; [ -n "$id" ] || exit 0
tmp="$(mktemp -t cliphist_dec_XXXXXX)"
cliphist decode "$id" > "$tmp" || exit 0
mime="$(file -b --mime-type "$tmp")"
if [[ "$mime" == image/* ]]; then
  wl-copy --type image/png < "$tmp"; wl-copy --primary --type image/png < "$tmp"
else
  wl-copy < "$tmp"; wl-copy --primary < "$tmp"
fi
rm -f "$tmp"
SH
  perl -0777 -pe "s/CLIP_CAP:-20/CLIP_CAP:-$CLIP_CAP/g" -i "$WOFI_MENU" 2>/dev/null || true
  make_exec "$WOFI_MENU"
  ok "wofi picker: $WOFI_MENU"
}

stop_dupes(){
  pkill -f 'wl-paste .* --watch cliphist store' 2>/dev/null || true
  pkill -f 'wl-paste .* cliphist-store-prune' 2>/dev/null || true
  if [[ -f "$WATCH_PIDFILE" ]]; then
    old="$(<"$WATCH_PIDFILE")"
    if [[ -n "$old" ]]; then
      kill "$old" 2>/dev/null || true
      rm -f "$WATCH_PIDFILE"
    fi
  fi
}

start_watchers_now(){
  if pgrep -fa 'cliphist-watchers' >/dev/null; then
    ok "watchers already running"
  else
    nohup "$WATCH" >/dev/null 2>&1 &
    ok "watchers started"
  fi
}

print_hypr_lines(){
  print -P "\n%F{6}Hyprland config to add%f"
  echo 'exec-once = $HOME/.local/bin/cliphist-watchers'
  echo 'bind = SUPER, X, exec, $HOME/.local/bin/clip-wofi'
}

setup(){
  need_user
  assert_env
  mkdirp "$STATE_DIR" "$CACHE_DIR"
  write_store
  write_watchers
  write_fzf_menu
  write_wofi_menu
  stop_dupes
  "$STORE" || true         # seed once, non blocking
  start_watchers_now
  print_hypr_lines
  ok "Setup done. Open with Super+V."
}

destroy(){
  need_user
  stop_dupes
  rm -f "$STORE" "$WATCH" "$FZF_MENU" "$WOFI_MENU"
  ok "removed helpers from $BIN_DIR"
  rm -rf "$STATE_DIR"
  ok "cleared $STATE_DIR"
  # keep ~/.cache/cliphist because cliphist owns it
}

usage(){
  cat <<EOF
Usage:
  $0 setup      install helpers, start watchers, print Hypr binds
  $0 destroy    stop watchers and remove helpers
Env:
  CLIP_CAP=$CLIP_CAP   BIN_DIR=$BIN_DIR
  CACHE_DIR=$CACHE_DIR STATE_DIR=$STATE_DIR
EOF
}

case "${1:-}" in
  setup) setup ;;
  destroy) destroy ;;
  *) usage; exit 1 ;;
esac

