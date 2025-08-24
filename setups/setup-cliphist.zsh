#!/usr/bin/env zsh
# clip-cliphist.zsh  Hyprland + Wayland. No systemd.

emulate -L zsh
setopt err_return no_unset pipefail

: "${CLIP_CAP:=20}"
: "${BIN_DIR:=$HOME/.local/bin}"
: "${CACHE_DIR:=$HOME/.cache/cliphist}"
STORE="$BIN_DIR/cliphist-store-prune"
WATCH="$BIN_DIR/cliphist-watchers"
FZF_MENU="$BIN_DIR/clip-menu"     # TTY picker (for terminals)
WOFI_MENU="$BIN_DIR/clip-wofi"    # GUI picker (for Hypr binds)

blue(){ print -P "%F{4}[*]%f $*"; }
ok(){   print -P "%F{2}[ok]%f $*"; }
warn(){ print -P "%F{3}[warn]%f $*"; }
err(){  print -P "%F{1}[err]%f $*"; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }
need_user(){ [[ $EUID -ne 0 ]] || err "Run as your user, not root"; }
mkdirp(){ [[ -d "$1" ]] || mkdir -p "$1"; }
make_exec(){ chmod +x "$1" || err "chmod +x $1 failed"; }

assert_env(){
  have cliphist || err "cliphist missing. Install with Go: GO111MODULE=on go install github.com/sentriz/cliphist@latest"
  have wl-copy  || err "wl-clipboard missing"
  have wl-paste || err "wl-clipboard missing"
  have file     || err "file(1) missing"
  # Optional: fzf for terminal picker, wofi for GUI picker
  command -v fzf  >/dev/null || warn "fzf not found. Terminal picker will be skipped"
  command -v wofi >/dev/null || warn "wofi not found. GUI picker will be skipped"
}

write_store(){
  mkdirp "$BIN_DIR"
  cat > "$STORE" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"
cliphist store
cap="${CLIP_CAP:-20}"; [[ "$cap" =~ ^[0-9]+$ ]] || cap=20
ids="$(cliphist list | tail -n +$((cap+1)) | cut -f1 || true)"
[[ -n "${ids:-}" ]] && printf '%s\n' "$ids" | xargs -r -n1 cliphist delete
SH
  perl -0777 -pe "s/CLIP_CAP:-20/CLIP_CAP:-$CLIP_CAP/g" -i "$STORE" 2>/dev/null || true
  make_exec "$STORE"; ok "store+prune: $STORE"
}

write_watchers(){
  mkdirp "$BIN_DIR"
  cat > "$WATCH" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"
wl-paste --type text           --watch "$HOME/.local/bin/cliphist-store-prune" &
wl-paste --primary --type text --watch "$HOME/.local/bin/cliphist-store-prune" &
wl-paste --type image          --watch "$HOME/.local/bin/cliphist-store-prune" &
wait -n
SH
  make_exec "$WATCH"; ok "watchers: $WATCH"
}

write_fzf_menu(){
  command -v fzf >/dev/null || return 0
  cat > "$FZF_MENU" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"
need(){ command -v "$1" >/dev/null 2>&1 || { echo "$1 missing" >&2; exit 1; }; }
need cliphist; need fzf; need wl-copy; need file
cap="${CLIP_CAP:-20}"; [[ "$cap" =~ ^[0-9]+$ ]] || cap=20
ids="$(cliphist list | tail -n +$((cap+1)) | cut -f1 || true)"
[[ -n "${ids:-}" ]] && printf '%s\n' "$ids" | xargs -r -n1 cliphist delete
sel="$(
  cliphist list | head -n "$cap" \
  | fzf --ansi --no-sort --tac --cycle \
        --prompt='clip> ' \
        --header='enter=copy  ctrl-d=delete  ctrl-o=open  ctrl-y=copy shown text' \
        --delimiter='\t' --with-nth=2.. \
        --bind 'enter:accept' \
        --bind 'ctrl-d:execute-silent(echo {1} | xargs -r -n1 cliphist delete)+reload(cliphist list | head -n '"$cap"')' \
        --bind 'ctrl-o:execute-silent(echo {1} | xargs -I{} sh -c "cliphist decode {} > /tmp/clip_$PPID; nohup xdg-open /tmp/clip_$PPID >/dev/null 2>&1 &")' \
        --bind 'ctrl-y:execute-silent(sh -c '\''printf "%s" "{2..}" | sed "s/^\[[^]]*\]\s*//" | wl-copy'\'' )+abort'
)" || exit 0
id="$(printf '%s\n' "$sel" | cut -f1)"; [[ -n "$id" ]] || exit 0
tmp="$(mktemp -t cliphist_dec_XXXXXX)"
cliphist decode "$id" > "$tmp"
mime="$(file -b --mime-type "$tmp")"
if [[ "$mime" == image/* ]]; then
  wl-copy --type image/png < "$tmp"; wl-copy --primary --type image/png < "$tmp"
else
  wl-copy < "$tmp"; wl-copy --primary < "$tmp"
fi
rm -f "$tmp"
SH
  perl -0777 -pe "s/CLIP_CAP:-20/CLIP_CAP:-$CLIP_CAP/g" -i "$FZF_MENU" 2>/dev/null || true
  make_exec "$FZF_MENU"; ok "tty picker: $FZF_MENU"
}

write_wofi_menu(){
  command -v wofi >/dev/null || return 0
  cat > "$WOFI_MENU" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"
need(){ command -v "$1" >/dev/null 2>&1 || { echo "$1 missing" >&2; exit 1; }; }
need cliphist; need wofi; need wl-copy; need file
cap="${CLIP_CAP:-20}"; [[ "$cap" =~ ^[0-9]+$ ]] || cap=20
ids="$(cliphist list | tail -n +$((cap+1)) | cut -f1 || true)"
[[ -n "${ids:-}" ]] && printf '%s\n' "$ids" | xargs -r -n1 cliphist delete
# Build a human list but keep ID at field 1. Wofi will display everything.
sel="$(cliphist list | head -n "$cap" | wofi --dmenu -i -p 'clip>' )" || exit 0
id="$(printf '%s\n' "$sel" | cut -f1)"; [[ -n "$id" ]] || exit 0
tmp="$(mktemp -t cliphist_dec_XXXXXX)"
cliphist decode "$id" > "$tmp"
mime="$(file -b --mime-type "$tmp")"
if [[ "$mime" == image/* ]]; then
  wl-copy --type image/png < "$tmp"; wl-copy --primary --type image/png < "$tmp"
else
  wl-copy < "$tmp"; wl-copy --primary < "$tmp"
fi
rm -f "$tmp"
SH
  perl -0777 -pe "s/CLIP_CAP:-20/CLIP_CAP:-$CLIP_CAP/g" -i "$WOFI_MENU" 2>/dev/null || true
  make_exec "$WOFI_MENU"; ok "wofi picker: $WOFI_MENU"
}

start_watchers_now(){
  # kill any duplicate ad-hoc watchers you had in cfg
  pkill -f 'wl-paste -p -t text --watch cliphist store' 2>/dev/null || true
  pkill -f 'wl-paste -p -t image --watch cliphist store' 2>/dev/null || true
  if pgrep -fa 'wl-paste.*cliphist-store-prune' >/dev/null; then
    ok "watchers already running"
  else
    nohup "$WATCH" >/dev/null 2>&1 &
    ok "watchers started"
  fi
}

print_hypr_lines(){
  print -P "\n%F{6}Hyprland lines to add%f"
  echo 'exec-once = $HOME/.local/bin/cliphist-watchers'
  echo 'bind = ALT, X, exec, $HOME/.local/bin/clip-wofi'
  echo 'bind = SUPER, V, exec, kitty -e $HOME/.local/bin/clip-menu   # optional: TTY picker in a terminal'
}

setup(){
  need_user
  assert_env
  write_store
  write_watchers
  write_fzf_menu
  write_wofi_menu
  mkdirp "$CACHE_DIR"
  start_watchers_now
  print_hypr_lines
  ok "Setup done"
}

destroy(){
  need_user
  pkill -f 'wl-paste.*cliphist-store-prune' 2>/dev/null || true
  pkill -f "$WATCH" 2>/dev/null || true
  rm -f "$STORE" "$WATCH" "$FZF_MENU" "$WOFI_MENU"
  ok "removed helpers from $BIN_DIR"
  rm -rf "$CACHE_DIR"
  ok "cleared $CACHE_DIR"
  if [[ -d "$HOME/.cache/cliphist" ]]; then
    rm -rf "$HOME/.cache/cliphist"
    ok "wiped cliphist DB at ~/.cache/cliphist"
  fi
  blue "Remove any old duplicate exec-once watchers from your Hypr cfg"
}

usage(){
  cat <<EOF
Usage:
  $0 setup      install helpers, start watchers, print Hypr binds
  $0 destroy    stop watchers, remove helpers, wipe cliphist cache
Env:
  CLIP_CAP=$CLIP_CAP
EOF
}

case "${1:-}" in
  setup) setup ;;
  destroy) destroy ;;
  *) usage; exit 1 ;;
esac

