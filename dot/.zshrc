# PROMPT Load vcs_info for version control system information
autoload -Uz vcs_info

# AUTOCOMPLITION autoload
autoload -U compinit && compinit
# Autocomplition caseinsensitive
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# ZOXIDE must be place after compinit
eval "$(zoxide init --cmd cd zsh)"

#________________________________________________________________________
#ZSH History
setopt APPEND_HISTORY
setopt SHARE_HISTORY
HISTFILE=~/.history_zsh
HISTSIZE=6001
SAVEHIST=6000
setopt HIST_EXPIRE_DUPS_FIRST
setopt EXTENDED_HISTORY

#________________________________________________________________________
# autocompletion using arrow keys (based on history)
bindkey '\e[A' history-search-backward
bindkey '\e[B' history-search-forward

#________________________________________________________________________
# Define Prompt
# Define an array of symbols
#symbols=(➤ ➠ ✿ ⚡ ✪ Ȣ ⚤ ❖ Ϡ Ϩ ට      󰣇   󰿗 󱚝   🐱 )
#colors=("220" "161")

# Function to select a random symbol
#function select_random_symbol() {
#  RANDOM_SYMBOL=${symbols[RANDOM % ${#symbols[@]} + 1]}
#}

# Function to select a random color
#function select_random_color() {
#  RANDOM_COLOR=${colors[RANDOM % ${#colors[@]} + 1]}
#}

# Configure vcs_info for Git
#zstyle ':vcs_info:git:*' formats '%b'
#zstyle ':vcs_info:*' enable git

# Function to update vcs_info before each prompt
precmd() {
  vcs_info
#  select_random_symbol
#  select_random_color
}
#________________________________________________________________________
#Git prompt plugins MUST BE PLACED BEFORE setopt PROMPT_SUBST
source ~/.zsh/plugins/git/git-prompt.sh
# git prompt options
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWUPSTREAM="auto"
GIT_PS1_STATESEPARATOR=' '
GIT_PS1_HIDE_IF_PWD_IGNORED=true
GIT_PS1_COMPRESSSPARSESTATE=true

# Enable prompt substitution
setopt PROMPT_SUBST

NL=$'\n'

# Define the prompt
#PROMPT=' %F{yellow}%~%f %F{blue}${vcs_info_msg_0_}%f
# %F{$RANDOM_COLOR}${RANDOM_SYMBOL}%f '
#PS1='$NL%F{yellow} %3~%f% %F{118}$(__git_ps1 "  %s")%f$NL%B%(?.%F{220}.%F{161})%(!. ➠ . ✿ )%f%b '
PS1='$NL%F{yellow} %3~%f% %F{green}$(__git_ps1 "  %s")%f$NL%B%(?.%F{yellow}.%F{red})%(!. ➠ . 󰣇  )%f%b '
#________________________________________________________________________
# Get color support for 'less'
export LESS="--RAW-CONTROL-CHARS"

# Use colors for less, man, etc.
[[ -f ~/.LESS_TERMCAP ]] && . ~/.LESS_TERMCAP

export LESS_TERMCAP_mb=$'\e[1;31m'     # begin bold
export LESS_TERMCAP_md=$'\e[1;33m'     # begin blink
export LESS_TERMCAP_so=$'\e[01;44;37m' # begin reverse video
export LESS_TERMCAP_us=$'\e[01;37m'    # begin underline
export LESS_TERMCAP_me=$'\e[0m'        # reset bold/blink
export LESS_TERMCAP_se=$'\e[0m'        # reset reverse video
export LESS_TERMCAP_ue=$'\e[0m'        # reset underline
export GROFF_NO_SGR=1                  # for konsole and gnome-terminal

#________________________________________________________________________
# NeoVim Plugins Dependencies
export PATH="$PATH:/home/stars/.local/share/gem/ruby/3.0.0/bin"

PATH="/home/stars/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/home/stars/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/stars/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/stars/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/stars/perl5"; export PERL_MM_OPT;

#________________________________________________________________________
# Allias
alias rot13="tr 'A-Za-z' 'N-ZA-Mn-za-m'"
alias pac="sudo pacman -Syu --needed"
alias zsh.="nvim ~/.zshrc"
alias szsh="source ~/.zshrc"
alias land.="nvim ~/.config/hypr/hyprland.conf"
alias paper.="nvim ~/.config/hypr/hyprpaper.conf"
alias nvim.="nvim ~/.config/nvim/init.vim"
alias snvim="source ~/.config/nvim/init.vim"
alias critty.="nvim ~/.alacritty"
alias scritty="source ~/.alacritty"
alias kitty.="nvim ~/.config/kitty/kitty.conf"
alias skitty="source ~/.config/kitty/kitty.conf"
alias sys="sudo systemctl "
alias syss="sudo systemctl start "
alias syse="sudo systemctl enable "
alias ux="chmod u+x"
alias ip="ip -c "
alias ls="eza "
alias ll="eza -l "
alias lla="eza -la "
alias la="eza -la "
alias cat="bat --style=changes "
alias fm="yazi "

#________________________________________________________________________
# Other plugins MUST BE PLACED AT END OF THE FILE
#source /home/hiker/.zsh/plugins/syntaxDracula/zsh-syntax-highlighting/zsh-syntax-highlighting.sh
source /home/hiker/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /home/hiker/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

source /home/hiker/.config/broot/launcher/bash/br
