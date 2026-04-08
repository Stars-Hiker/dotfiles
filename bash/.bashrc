export HYPRSHOT_DIR="$HOME/ScreenShots/"

# ── Wayland environment ───────────────────────────────────────────────────────
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

export PATH="$HOME/.local/bin:$PATH"

# ── Aliases ───────────────────────────────────────────────────────────────────
alias ls="eza"
alias ll="eza -l --icons --git"
alias la="eza -la --icons --git"
alias lt="eza --tree --icons --level=2"

alias cat="bat --paging=never"
alias grep="grep --color=auto"
alias ip="ip -c"
alias ping="ping -c4"
alias ssh="kitty +kitten ssh"
alias fm="yazi"

alias pac="sudo pacman -S --needed"
alias pacu="sudo pacman -Syu --needed"
alias update="sudo pacman -Syu"

alias sbash="source ~/.bashrc"
alias nbash="nvim ~/.bashrc"
alias nhypr="nvim ~/.config/hypr/hyprland.conf"

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

alias syss="sudo systemctl start"
alias sysS="sudo systemctl stop"
alias syse="sudo systemctl enable"
alias sysd="sudo systemctl disable"
alias sysr="sudo systemctl restart"
alias syst="systemctl status"

# ── Git aliases ───────────────────────────────────────────────────────────────
alias giti="git init"
alias gita="git add"
alias gitcommit="git commit -m"
alias gitbranch="git branch -M main"
alias gitremote="git remote add origin git@github.com:Stars-Hiker/"
alias gitpush="git push -u origin main"

alias g="git"
alias gs="git status"
alias ga="git add"
alias gaa="git add ."
alias gc="git commit -m"
alias gca="git commit --amend -m"
alias gp="git push"
alias gpl="git pull"
alias gf="git fetch"

alias gb="git branch"
alias gba="git branch -a"
alias gco="git checkout"
alias gcob="git checkout -b"
alias gbd="git branch -d"
alias gbD="git branch -D"

alias gl="git log --oneline"
alias gla="git log --oneline --graph --all"
alias glp="git log --oneline -10"

alias gm="git merge"
alias gst="git stash"
alias gstp="git stash pop"

alias grst="git restore"
alias grsts="git restore --staged"

# ── Auto eza after cd ─────────────────────────────────────────────────────────
cd() { builtin cd "$@" && eza -la --icons --git; }

# ── Completion ────────────────────────────────────────────────────────────────
# Case-insensitive tab completion
bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"

# ── Prompt with git branch ────────────────────────────────────────────────────
_git_branch() {
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null) && echo "$branch "
}

# Colors: yellow path + green git branch (mirrors zshrc style)
PS1='\n\[\e[38;5;220m\]\w \[\e[32m\]$(_git_branch)\[\e[0m\]\n> '

# ── History ───────────────────────────────────────────────────────────────────
HISTFILE=~/.bash_history
HISTSIZE=10000
HISTFILESIZE=10000
# Ignore duplicates and lines starting with a space
HISTCONTROL=ignoreboth:erasedups
# Append to history file rather than overwriting
shopt -s histappend
# Save and reload history after each command (mirrors SHARE_HISTORY)
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# ── Key bindings (history search) ────────────────────────────────────────────
# Up/Down arrows search history based on what's already typed
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# ── Plugins (bash equivalents) ────────────────────────────────────────────────
# bash-autosuggestions is not native to bash; use bash-completion instead
if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# Optional: blesh (Bash Line Editor) provides syntax highlighting + autosuggestions
# Install via: https://github.com/akinomyoga/ble.sh
# Uncomment the lines below if you have blesh installed:
# [[ -f ~/.local/share/blesh/ble.sh ]] && source ~/.local/share/blesh/ble.sh
