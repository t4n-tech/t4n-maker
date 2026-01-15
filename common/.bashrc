#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Variabel
OS=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)

alias cat='bat --theme=base16'
alias ls='eza --icons=always --color=always'
alias la='eza --icons=always --color=always -a'
alias ll='eza --icons=always --color=always -la'
alias tree='exa --icons=always --tree'
alias grep='grep --color=auto'

# Prompt Line
#PS1='[\u@\h \W]\$ '
PS1='\n\[\033[\033[0;32m\]┌──>\[\e[0m\] [ \u @ \h ] <<|= User =|>> [ \d ] [ \W ] \n\[\033[\033[0;32m\]└[$OS]->>\[\e[0m\] '

