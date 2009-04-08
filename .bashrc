alias ls='ls --color=auto'
alias vi='vim'
alias grep='egrep --color'
alias timor='ssh oprietop@192.168.139.14'
alias walk='snmpwalk -c uocpublic -v 1'
alias rdesktop='rdesktop -0 -z -g1022x766 -uAdministrador -kes -a16'
alias millenium='nc -vvvzw1 84.88.0.230 80 443 2000 4600'
export PATH=$PATH:$HOME/scripts
export EDITOR=vim
export PS1='\[\033[0;33m\]┌┤\[\033[0m\033[1;33m\]\u\[\033[0;32m\]@\[\033[0;31m\]\h\[\033[0m\033[0;36m\]:\w\[\033[0m\033[0;33m\]│\[\033[0m\]\t\n\[\033[0;33m\]└→\[\033[0m\033[1;34m\]`echo $?`\[\033[0;33m\]┐\[\033[0m\]$ '
