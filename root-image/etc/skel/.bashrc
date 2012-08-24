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
PS1='[\u@\h \W]\$ '
