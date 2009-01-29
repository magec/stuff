alias ls='ls --color=auto'
alias vi='vim'
alias grep='egrep --color'
alias timor='ssh oprietop@192.168.139.14'
alias walk='snmpwalk -c uocpublic -v 1'
alias rdesktop='rdesktop -0 -z -g1022x766 -uAdministrador -kes -a16'
export PATH=$PATH:$HOME/scripts
export EDITOR=vim
#PS1='[\u@\h \W]\$ '
PS1='\[\e[0;37m\][\[\e[0;32m\]\u\[\e[0;33m\]@\[\e[0;31m\]\h\[\e[0;36m\]:\w\[\e[0;37m\]] \t\n\[\e[0;36m\]`echo $?`\[\e[0;39m\] \$\[\e[m\] '
