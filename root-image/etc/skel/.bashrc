#
# ~/.bashrc
#

# Print a password notice
echo -e "\r\n"
echo -e "#####################################################"
echo -e "#                                                   #"
echo -e "#               Welcome to BBQLinux!                #"
echo -e "#  Password for bbqlinux and root user is: bbqlinux #"
echo -e "#                                                   #"
echo -e "#####################################################"
echo -e "\r\n"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'

__git_ps1 () 
{
    local b="$(git symbolic-ref HEAD 2>/dev/null)";
    if [ -n "$b" ]; then
        printf " (%s)" "${b##refs/heads/}";
    fi
}

RED="\[\033[01;31m\]"
YELLOW="\[\033[01;33m\]"
GREEN="\[\033[01;32m\]"
BLUE="\[\033[01;34m\]"

export PS1="$GREEN\u@\h$BLUE \w$YELLOW\$(__git_ps1) $BLUE\$\[\033[00m\] "
