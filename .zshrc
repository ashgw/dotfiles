
# For all funcs have a look at github.com/ashgw/zshfuncs
#####
# nix-env -iA nixpkgs.glibcLocales
export LOCALE_ARCHIVE="$(nix-env --installed --no-name --out-path --query glibc-locales)/lib/locale/locale-archive"

export PATH=$HOME/bin:/usr/local/bin:$PATH
export ZSH="$HOME/.oh-my-zsh"

export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Nix initialization
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

ZSH_THEME="bira"
HIST_STAMPS="dd/mm/yyyy"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
export LANG=en_US.UTF-8

# editors for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='nvim'
 else
   export EDITOR='nvim' # also NeoVim
fi

# Disable GPG GUI prompts inside SSH.
if [[ -n "$SSH_CONNECTION" ]]; then
  export PINENTRY_USER_DATA='USE_CURSES=1'
fi

autoload -U colors && colors	# Load colors

# Basic auto/tab complete
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files.
get_some_bitches(){
	echo 'coming soon, tap in G'
}

get_a_job_broke_aaah(){
	google-chrome "https://www.google.com/search?q=site%3A*.com+-site%3Aremoterocketship.com+-site%3Aweworkremotely.com+-site%3Ajobspresso.co+-site%3Ajustremote.co+-site%3Adynamitejobs.com+-site%3Aworkatastartup.com+-site%3Aangel.co+-site%3Ahimalayas.app+-site%3Aoutsourcely.com+-site%3Aeuropelanguagejobs.com+-site%3Ajobicy.com+-site%3Alanding.jobs+-site%3Aworkingnomads.co+inurl%3A(jobs+OR+careers)+(%22TypeScript%22+OR+%22Next.js%22+OR+%22Node.js%22+OR+%22Python%22+OR+%22Laravel%22)+(%22remote%22+OR+%22online%22)+(%22equity%22)+(%22United+States%22+OR+%22US-based%22)+after%3A2025-02-01"

}

alias \
	c="clear" \
	ez="eza --long --header --inode --git" \
	sdn="shutdown -h now" \
	t="touch" \
	tt="tmux" \
	obs="obsidian" \
	p="python3 -m" \
	l="lsd -a" \
	v="nvim" \
	reload=". ~/.zshrc" \
	y="rm -rf"\
	f="fzf" \
	b="cd .."  \
	bb="cd ..."   \
	bbb="cd ...."   \
	bbbb="cd ....."  \
	bbbbb="cd ......" \
	ka="killall" \
  bat="\bat --theme=GitHub" \
  sudo='sudo ' \
  j="just"\
	x="chmod +x" \
	ddgo="librewolf https://duckduckgo.com" \
	e="$EDITOR" \
	lpg="loadpg" \
	tf="terraform" \
	a="apt-get" \
	i="sudo apt-get install" \
	g="git" \
	ts="pnpm ts-node" \
	gh="librewolf https://github.com/ashgw" \
	d_stopall="docker stop $(docker ps -a -q)" \
	d_restratall="docker restart $(docker ps -a -q)" \
	d_startall="docker start $(docker ps -a -q)" \
	d_rmall="docker rm $(docker ps -a -q)" \
	pubip='dig +short myip.opendns.com @resolver1.opendns.com' \
  	localip='ipconfig getifaddr en1' \
	ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'" \
	ports='lsof +c0 -iTCP -sTCP:LISTEN -n -P' \
	defaultip="ip route | grep default" \
	cs="cursor" \
	lay='tree -a --gitignore -I ".git"'

plugins=(
		zsh-syntax-highlighting
		git
		zsh-autosuggestions
	)

# Colors n all so run this: curl https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.ansi-dark --output ~/.dircolors
eval `dircolors ~/.dircolors`

setopt autocd              # change directory just by typing its name
setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt

WORDCHARS=${WORDCHARS//\/} # Don't consider certain characters part of the word

# hide EOL sign ('%')
PROMPT_EOL_MARK=""

# enable completion features
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' rehash true
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# History configurations
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
#setopt share_history         # share command history data

# force zsh to show the complete history
alias history="history 0"

# configure `time` format
TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'


force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# enable auto-suggestions based on the history
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    # change suggestion color
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999'
fi

# enable command-not-found if installed
if [ -f /etc/zsh_command_not_found ]; then
    . /etc/zsh_command_not_found
fi

eval "$(zoxide init bash)"
eval "$(starship init zsh)"
export PATH="$HOME/miniconda3/bin:$PATH"
. /home/ashgw/miniconda3/etc/profile.d/conda.sh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# go
export PATH=$PATH:/$HOME/go/bin
# Tfenv
export PATH="$HOME/.tfenv/bin:$PATH"
# Rust
export PATH="$HOME/.cargo/bin:$PATH"
# Poetry
export PATH="$HOME/.local/bin:$PATH"
# When GPG pwd verifcation screen doesn't show up on TTY
export GPG_TTY=/dev/pts/0
export PATH=$PATH:~/mathlab/MATLAB/R2024b/bin
PATH=~/.console-ninja/.bin:$PATH
# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


# make fzf better
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

# functions section (checkout my zshfuncs repo)
source ~/zshfuncs/entrypoint.zsh
