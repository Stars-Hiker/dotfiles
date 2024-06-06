#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Define an array of symbols
symbols=("✿")

# Define the color code for orange
ORANGE_COLOR="\[\033[38;5;208m\]"

# Function to select a random symbol
#select_random_symbol() {
#  RANDOM_SYMBOL=${symbols[$((RANDOM % ${#symbols[@]}))]}
#}

# Function to update vcs_info (dummy function in Bash)
vcs_info() {
  # Dummy function for compatibility with Zsh's vcs_info
  return
}

# Function to update vcs_info before each prompt
#PROMPT_COMMAND='select_random_symbol'

# Define the prompt with orange color
PS1="\[\033[0m\]\w ${vcs_info_msg_0_}
${ORANGE_COLOR}${symbols} \[\033[0m\] "


source /home/hiker/.config/broot/launcher/bash/br
