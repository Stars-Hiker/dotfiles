# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          .zshrc — Stars-Hiker                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── Profiling (uncomment to debug slow startup) ───────────────────────────────
# zmodload zsh/zprof

# ── Instant prompt (keep at very top) ────────────────────────────────────────
# Nothing above this line should produce output or read from stdin

# ══════════════════════════════════════════════════════════════════════════════
#  ENVIRONMENT
# ══════════════════════════════════════════════════════════════════════════════

export HYPRSHOT_DIR="$HOME/ScreenShots/"
typeset -U path PATH   # auto-dedupe PATH (survives `exec zsh`)
export PATH="$HOME/.local/bin:$PATH"
export GROFF_NO_SGR=1

# Wayland
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

# Editor & pager
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="bat --paging=always"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"   # man pages with bat

# fzf — default options
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="
  --height=50% --layout=reverse --border=rounded
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# ══════════════════════════════════════════════════════════════════════════════
#  PERFORMANCE — lazy loading & compile cache
# ══════════════════════════════════════════════════════════════════════════════

# Compile .zshrc if newer than cached version (speeds up subsequent loads)
if [[ ! -f "${ZDOTDIR:-$HOME}/.zshrc.zwc" ]] || \
   [[ "${ZDOTDIR:-$HOME}/.zshrc" -nt "${ZDOTDIR:-$HOME}/.zshrc.zwc" ]]; then
  zcompile "${ZDOTDIR:-$HOME}/.zshrc" 2>/dev/null
fi

# ══════════════════════════════════════════════════════════════════════════════
#  HISTORY — smart & shared
# ══════════════════════════════════════════════════════════════════════════════

HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

setopt SHARE_HISTORY          # share across sessions instantly
setopt HIST_IGNORE_ALL_DUPS   # no duplicates
setopt HIST_IGNORE_SPACE      # lines starting with space are not saved
setopt HIST_REDUCE_BLANKS     # remove superfluous blanks
setopt HIST_VERIFY            # show expanded history before running
setopt EXTENDED_HISTORY       # save timestamp + duration
# (INC_APPEND_HISTORY omitted — SHARE_HISTORY already implies incremental append)

# ══════════════════════════════════════════════════════════════════════════════
#  COMPLETION — modern & fast
# ══════════════════════════════════════════════════════════════════════════════

# Cache completions for speed — only rebuild once a day
autoload -Uz compinit
_comp_cache="$HOME/.zcompdump"
if [[ -f "$_comp_cache" && $(find "$_comp_cache" -mtime +1 2>/dev/null) ]]; then
  compinit -C          # use cache, skip security check (fast)
elif [[ ! -f "$_comp_cache" ]]; then
  compinit             # first run: full init
else
  compinit -C
fi
unset _comp_cache

# Completion behavior
[[ -d ~/.zsh/cache ]] || mkdir -p ~/.zsh/cache              # ensure use-cache has a home
zstyle ':completion:*' menu no                              # fzf-tab takes over the menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"    # colorize menu
zstyle ':completion:*' group-name ''                        # group by category
zstyle ':completion:*:descriptions' format '[%d]'   # plain — fzf-tab shows %F codes literally
zstyle ':completion:*:warnings' format '%F{red}no matches%f'
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion::complete:*' gain-privileges 1          # sudo completions
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

# ══════════════════════════════════════════════════════════════════════════════
#  SHELL OPTIONS
# ══════════════════════════════════════════════════════════════════════════════

setopt AUTO_CD              # type a dir name to cd into it
setopt AUTO_PUSHD           # cd pushes to the directory stack
setopt PUSHD_IGNORE_DUPS    # no duplicate dirs in stack
# CORRECT disabled — it second-guesses valid commands; re-enable if you want it
setopt INTERACTIVE_COMMENTS # allow # comments in interactive shell
setopt GLOB_DOTS            # include hidden files in globs
setopt EXTENDED_GLOB        # extended globbing patterns
setopt NO_BEEP              # silence

# ══════════════════════════════════════════════════════════════════════════════
#  PROMPT — minimal custom (your style, enhanced)
# ══════════════════════════════════════════════════════════════════════════════

autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' actionformats '%F{yellow}%b|%a%f '  # shows rebase/merge state

# Show untracked / staged indicators
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '%F{green}●%f'
zstyle ':vcs_info:git:*' unstagedstr '%F{red}●%f'
zstyle ':vcs_info:git:*' formats '%F{green}%b%f %c%u%m'   # %m = ahead/behind + stash (below)

# Append untracked-file dot, ↑ahead / ↓behind vs upstream, and ⚑ stash via hooks
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked git-aheadbehind git-stash

+vi-git-untracked() {
  # vcs_info's %c/%u cover staged + modified-tracked, but NOT new untracked files
  [[ -n $(git ls-files --others --exclude-standard 2>/dev/null) ]] && \
    hook_com[unstaged]+="%F{244}●%f"   # dim dot = untracked present
  return 0
}

+vi-git-aheadbehind() {
  local ab; ab=$(git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null) || return 0
  local behind=${ab%%[[:space:]]*} ahead=${ab##*[[:space:]]}
  (( ahead ))  && hook_com[misc]+=" %F{cyan}↑${ahead}%f"
  (( behind )) && hook_com[misc]+=" %F{red}↓${behind}%f"
  return 0   # never abort the hook chain (vcs_info stops on non-zero)
}
+vi-git-stash() {
  local n; n=$(git rev-list --walk-reflogs --count refs/stash 2>/dev/null)
  (( n )) && hook_com[misc]+=" %F{magenta}⚑${n}%f"
  return 0
}

precmd() { vcs_info }
setopt PROMPT_SUBST

# Prompt: yellow path + git branch + staged/unstaged dots
PROMPT='
%F{220}%~%f ${vcs_info_msg_0_}
%F{244}❯%f '

# Right prompt: last exit code (shown only on error) + background jobs
RPROMPT='%(?..%F{red}✘ %?%f)%(1j. %F{cyan}⚙ %j%f.)'

# ══════════════════════════════════════════════════════════════════════════════
#  KEY BINDINGS
# ══════════════════════════════════════════════════════════════════════════════

bindkey -e   # emacs key bindings (Ctrl-A/E, Ctrl-R, etc.)

# History substring search (widgets are defined when the plugin loads below;
# these bindings resolve once that happens in the same startup)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P'   history-substring-search-up
bindkey '^N'   history-substring-search-down

# Better word navigation
bindkey '^[[1;5C' forward-word   # Ctrl+Right
bindkey '^[[1;5D' backward-word  # Ctrl+Left

# Edit current command in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# ══════════════════════════════════════════════════════════════════════════════
#  ALIASES — navigation
# ══════════════════════════════════════════════════════════════════════════════

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# ── Listing ───────────────────────────────────────────────────────────────────
alias ls="eza --icons --group-directories-first"
alias ll="eza -l --icons --git --group-directories-first"
alias la="eza -la --icons --git --group-directories-first"
alias lt="eza --tree --icons --level=2 --git --group-directories-first"
alias ltt="eza --tree --icons --level=3 --git --group-directories-first"

# ── Modern replacements ───────────────────────────────────────────────────────
alias cat="bat --paging=never"
alias grep="grep --color=auto"
alias diff="diff --color=auto"
alias ip="ip -c"
alias ping="ping -c4"
alias ssh="kitty + kitten ssh"
alias fm=y                                    # y() wrapper (see FUNCTIONS): cd's on quit
alias du="dust"        # dust (modern du) — install: sudo pacman -S dust
alias df="duf"         # duf  (modern df) — install: sudo pacman -S duf
alias top="btop"       # btop (modern top) — install: sudo pacman -S btop

# ── Config shortcuts ──────────────────────────────────────────────────────────
alias szsh="exec zsh"                         # reload zsh (faster than source)
alias nzsh="nvim ~/.zshrc"
alias nhypr="nvim ~/.config/hypr/hyprland.conf"

# ── Pacman ────────────────────────────────────────────────────────────────────
alias pac="sudo pacman -S --needed"
alias pacu="sudo pacman -Syu --needed"
alias update="sudo pacman -Syu"
alias pacr="sudo pacman -Rns"                 # remove + orphan deps
alias pacs="pacman -Ss"                       # search
alias paci="pacman -Qi"                       # package info
alias paclo="pacman -Qdt"                     # list orphans
# paclean is a function (see FUNCTIONS) — an alias would freeze the orphan
# list at shell-startup time instead of evaluating it when you run it.

# ── Dotfiles / system snapshot ──────────────────────────────────────────────────
alias dotsync="$HOME/.dotfiles/bin/sync.sh"          # refresh pkg lists, commit & push dotfiles
alias pkgsnap="$HOME/.dotfiles/bin/pkg-snapshot.sh"  # regenerate package lists only
alias dots="cd $HOME/.dotfiles && git status -sb"    # jump to dotfiles + show status

# ── Systemctl ─────────────────────────────────────────────────────────────────
alias syss="sudo systemctl start"
alias sysS="sudo systemctl stop"
alias syse="sudo systemctl enable"
alias sysd="sudo systemctl disable"
alias sysr="sudo systemctl restart"
alias syst="systemctl status"
alias sysdr="sudo systemctl daemon-reload"

# ── Safety nets ───────────────────────────────────────────────────────────────
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias mkdir="mkdir -pv"

# ── Global aliases (expand anywhere on the line) ──────────────────────────────
alias -g NUL='>/dev/null 2>&1'   # e.g. `cmd NUL`
alias -g G='| grep -i'           # e.g. `ls G foo`
alias -g L='| less'

# ══════════════════════════════════════════════════════════════════════════════
#  GIT ALIASES
# ══════════════════════════════════════════════════════════════════════════════

alias giti="git init"
alias gita="git add"
alias gitcommit="git commit -m"
alias gitbranch="git branch -M main"
alias gitremote="git remote add origin git@github.com:Stars-Hiker/"
alias gitpush="git push -u origin main"

alias g="git"
alias gs="git status -sb"          # compact status
alias ga="git add"
alias gaa="git add ."
alias gap="git add -p"             # interactive patch staging
alias gc="git commit -m"
alias gca="git commit --amend -m"
alias gcane="git commit --amend --no-edit"
alias gp="git push"
alias gpf="git push --force-with-lease"  # safe force push
alias gpl="git pull --rebase"      # rebase instead of merge on pull
alias gf="git fetch --prune"       # prune stale remote refs

alias gb="git branch"
alias gba="git branch -a"
alias gco="git checkout"
alias gcob="git checkout -b"
alias gbd="git branch -d"
alias gbD="git branch -D"
alias gsw="git switch"             # modern checkout
alias gswc="git switch -c"

alias gl="git log --oneline"
alias gla="git log --oneline --graph --all --decorate"
alias glp="git log --oneline -10"
alias gld="git log --oneline --graph --all --decorate --color"

alias gm="git merge"
alias gst="git stash"
alias gstp="git stash pop"
alias gstl="git stash list"

alias grst="git restore"
alias grsts="git restore --staged"
alias grh="git reset --hard"
alias grs="git reset --soft"

alias gd="git diff"
alias gds="git diff --staged"

# ══════════════════════════════════════════════════════════════════════════════
#  FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

# Auto eza after cd
cd() { builtin cd "$@" && eza -ll --icons --git --group-directories-first; }

# mkcd — make dir and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# yazi wrapper — cd into wherever you browsed when you quit (uses the eza-listing cd above)
y() {
  local tmp cwd; tmp=$(mktemp -t yazi-cwd.XXXXXX)
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && cd -- "$cwd"
  rm -f -- "$tmp"
}

# paclean — remove orphaned packages (evaluated at call time, not at startup)
paclean() {
  local orphans=$(pacman -Qtdq)
  [[ -z "$orphans" ]] && { echo "no orphans to remove"; return 0; }
  sudo pacman -Rns $orphans
}

# Note: Ctrl-R is handled by fzf's key-bindings.zsh (sourced below). A custom
# fzf-history widget here would be clobbered by that source, so it's omitted.

# fzf cd — fuzzy jump to any subdirectory
fcd() {
  local dir
  dir=$(fd --type d --hidden --follow --exclude .git | fzf --prompt="cd ❯ ") && cd "$dir"
}

# fzf open file in nvim
fv() {
  local file
  file=$(fd --type f --hidden --follow --exclude .git | fzf --prompt="nvim ❯ " --preview 'bat --color=always {}') && nvim "$file"
}

# Extract anything
extract() {
  case "$1" in
    *.tar.bz2)  tar xjf "$1"     ;;
    *.tar.gz)   tar xzf "$1"     ;;
    *.tar.xz)   tar xJf "$1"     ;;
    *.tar.zst)  tar --zstd -xf "$1" ;;
    *.bz2)      bunzip2 "$1"     ;;
    *.gz)       gunzip "$1"      ;;
    *.zip)      unzip "$1"       ;;
    *.7z)       7z x "$1"        ;;
    *.rar)      unrar x "$1"     ;;
    *.xz)       unxz "$1"        ;;
    *)          echo "'$1': unknown archive format" ;;
  esac
}

# Quick note to ~/notes/
note() {
  local notes_dir="$HOME/notes"
  mkdir -p "$notes_dir"
  if [[ -z "$1" ]]; then
    nvim "$notes_dir/$(date +%Y-%m-%d).md"
  else
    echo "$*" >> "$notes_dir/$(date +%Y-%m-%d).md"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  ZOXIDE — smarter cd
# ══════════════════════════════════════════════════════════════════════════════

# Overrides the `cd` function above with zoxide's smarter version
# `z foo` jumps to most frecent match, `zi` opens fzf picker
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd z)"
fi

# ══════════════════════════════════════════════════════════════════════════════
#  FZF — shell integration
# ══════════════════════════════════════════════════════════════════════════════

# Ctrl+T: paste file path | Alt+C: cd into dir | Ctrl+R: history (overridden above)
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
fi
if [[ -f /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
fi

# ══════════════════════════════════════════════════════════════════════════════
#  PLUGINS — loaded last for speed
# ══════════════════════════════════════════════════════════════════════════════

_load() { [[ -f "$1" ]] && source "$1"; }

# fzf-tab must load AFTER compinit + completion zstyles (above) and BEFORE the
# widget-wrapping plugins below. Syntax-highlighting stays near-last; history-
# substring-search after it.
_load "${HOME}/AUR/fzf-tab/fzf-tab.plugin.zsh"
_load "${HOME}/AUR/zsh-autosuggestions/zsh-autosuggestions.zsh"
_load "${HOME}/AUR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
_load "${HOME}/AUR/zsh-history-substring-search/zsh-history-substring-search.zsh"

# fzf-tab — fzf-powered completion menu with previews (inherits FZF_DEFAULT_OPTS theme)
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  'bat --color=always $realpath 2>/dev/null || eza -1 --color=always --icons $realpath'

# Autosuggestions tuning
ZSH_AUTOSUGGEST_STRATEGY=(history completion)  # try history first, then completion
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20             # don't suggest for very long lines
ZSH_AUTOSUGGEST_USE_ASYNC=1                    # async = no typing lag
bindkey '^ ' autosuggest-accept                # Ctrl+Space to accept suggestion
bindkey '^]' autosuggest-clear

# Syntax highlighting — fine-tune colors
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[function]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[path]='fg=blue'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'

# ── End profiling (uncomment if zmodload above is uncommented) ────────────────
# zprof
# ══════════════════════════════════════════════════════════════════════════════
#  COMPLETIONS & TOOL INTEGRATIONS
# ══════════════════════════════════════════════════════════════════════════════
# NOTE: the duplicate Wayland/aliases/history/keybindings/plugins block that used
# to live here (appended by postInstall) was removed — it re-sourced every plugin
# a second time and reset HISTSIZE 50000 → 10000. All of that is configured above.

# OpenClaw completion
_load "/home/nimrod/.openclaw/completions/openclaw.zsh"

# ── NVM (lazy-loaded) ─────────────────────────────────────────────────────────
# Sourcing nvm.sh eagerly cost ~510ms at startup (its auto-use runs `nvm use`
# on every shell). These shims load nvm only on first use of node/npm/npx/nvm.
export NVM_DIR="$HOME/.nvm"
_load_nvm() {
  unset -f nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm()  { _load_nvm; nvm "$@"; }
node() { _load_nvm; node "$@"; }
npm()  { _load_nvm; npm "$@"; }
npx()  { _load_nvm; npx "$@"; }
