# ───────────────────────────────
# Core env
# ───────────────────────────────
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="bira"
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# ───────────────────────────────
# Path hygiene
# ───────────────────────────────
typeset -U PATH path
# user-first
path=(
  $HOME/.local/bin
  $HOME/bin
  $path
)
# common toolchains
path+=(
  $HOME/.nix-profile/bin
  $HOME/miniconda3/bin
  $HOME/.tfenv/bin
  $HOME/.cargo/bin
  $HOME/.local/share/pnpm
  $HOME/go/bin
  $HOME/.bun/bin
  $HOME/mathlab/MATLAB/R2024b/bin
  $HOME/.console-ninja/.bin
)

export PATH

# Make system themes/fonts visible to Nix apps
export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:$HOME/.nix-profile/share"
export NIXPKGS_ALLOW_UNFREE=1

# Modern Nix init (no nix-env)
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# ───────────────────────────────
# Editors
# ───────────────────────────────
export EDITOR="nvim"

# SSH ergonomics
if [[ -n "$SSH_CONNECTION" ]]; then
  export PINENTRY_USER_DATA='USE_CURSES=1'
fi

# GPG pinentry on current tty
export GPG_TTY="$(tty 2>/dev/null || echo /dev/pts/0)"

# ───────────────────────────────
# Oh My Zsh load
# ───────────────────────────────
source "$ZSH/oh-my-zsh.sh"

# ───────────────────────────────
# Completion
# ───────────────────────────────
autoload -Uz compinit
zmodload zsh/complist
# fast compdump in cache
compinit -d "$HOME/.cache/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' rehash true
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# include dotfiles in completion
_comp_options+=(globdots)

# ───────────────────────────────
# Shell options and prompt helpers
# ───────────────────────────────
setopt autocd
setopt interactivecomments
setopt magicequalsubst
setopt nonomatch
setopt notify
setopt numericglobsort
setopt promptsubst

WORDCHARS=${WORDCHARS//\/}   # treat slash as a word boundary
PROMPT_EOL_MARK=""           # hide %

# Dircolors (if present)
eval "$(dircolors ~/.dircolors 2>/dev/null || true)"

# ───────────────────────────────
# History
# ───────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000
SAVEHIST=2000
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify
alias history="history 0"

# `time` format
TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'

# ───────────────────────────────
# Tools that hook into the shell
# ───────────────────────────────
# zoxide + starship
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

# Conda
if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
  . "$HOME/miniconda3/etc/profile.d/conda.sh"
fi

# Node version manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"

# sbin too
export PATH=$PATH:/usr/sbin

# bun
export BUN_INSTALL="$HOME/.bun"

# ───────────────────────────────
# FZF defaults
# ───────────────────────────────
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_DEFAULT_OPTS=$'
  --height 40%
  --layout=reverse
  --preview-window=:wrap
  --preview "
    mime=$(file --mime-type -Lb {})
    if [[ $mime == text/* ]]; then
      bat --style=plain --color=always {}
    elif [[ $mime == image/* ]]; then
      viu -w 40 -h 20 {}
    elif [[ $mime == application/pdf ]]; then
      pdftotext {} - | head -50
    elif [[ $mime == audio/* ]]; then
      exiftool {}
    else
      echo {} is $mime
    fi
  "
'

# ───────────────────────────────
# Aliases
# ───────────────────────────────
alias c="clear"
alias ez="eza --long --header --inode --git"
alias sdn="shutdown -h now"
alias t="touch"
alias tt="tmux"
alias obs="obsidian"
alias p="python3 -m"
alias l="lsd -a"
alias purge="sudo apt purge --autoremove"
alias v="nvim"
alias reload=". ~/.zshrc"
alias y="rm -rf"
alias f="fzf"
alias b="cd .."
alias bb="cd ..."
alias bbb="cd ...."
alias bbbb="cd ....."
alias bbbbb="cd ......"
alias ka="killall"
alias bat="\bat --theme=GitHub"
alias sudo='sudo '
alias j="just"
alias x="chmod +x"
alias ddgo="librewolf https://duckduckgo.com"
alias e="$EDITOR"
alias lpg="loadpg"
alias tf="terraform"
alias a="apt-get"
alias i="sudo apt-get install"
alias g="git"
alias ts="pnpm ts-node"
alias gh="librewolf https://github.com/ashgw"
alias pubip='dig +short myip.opendns.com @resolver1.opendns.com'
alias localip='ipconfig getifaddr en1'
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
alias ports='lsof +c0 -iTCP -sTCP:LISTEN -n -P'
alias defaultip=\"ip route | grep default\"
alias cs="cursor"
alias lay='tree -a --gitignore -I ".git"'

# ───────────────────────────────
# Fun stubs
# ───────────────────────────────
get_some_bitches(){ echo 'coming soon, tap in G'; }
get_a_job_broke_aaah(){
  google-chrome "https://www.google.com/search?q=site%3A*.com+-site%3Aremoterocketship.com+-site%3Aweworkremotely.com+-site%3Ajobspresso.co+-site%3Ajustremote.co+-site%3Adynamitejobs.com+-site%3Aworkatastartup.com+-site%3Aangel.co+-site%3Ahimalayas.app+-site%3Aoutsourcely.com+-site%3Aeuropelanguagejobs.com+-site%3Ajobicy.com+-site%3Alanding.jobs+-site%3Aworkingnomads.co+inurl%3A(jobs+OR+careers)+(%22TypeScript%22+OR+%22Next.js%22+OR+%22Node.js%22+OR+%22Python%22+OR+%22Laravel%22)+(%22remote%22+OR+%22online%22)+(%22equity%22)+(%22United+States%22+OR+%22US-based%22)+after%3A2025-02-01"
}

# ───────────────────────────────
# Misc
# ───────────────────────────────
# command-not-found (Debian/Ubuntu)
[ -f /etc/zsh_command_not_found ] && . /etc/zsh_command_not_found

# functions pack
[ -f "$HOME/zshfuncs/entrypoint.zsh" ] && source "$HOME/zshfuncs/entrypoint.zsh"

