alias ls='ls --color=auto'
alias vi='vim'
alias grep='egrep --color'
alias ssh='ssh -X -4'
alias timor='ssh oprietop@192.168.139.14'
alias wget='wget -U "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.10) Gecko/2009042810 GranParadiso/3.0.10" --execute robots=off'
alias walk='snmpwalk -c uocpublic -v 1'
alias pwgen='perl -le "print map { (a..z,A..Z,0..9)[rand 62] } 1..pop"'
alias dicks='perl -le "for (1..pop){print \"8\".\"=\"x((rand 10)+1).\"D\"}"'
alias rsync_size='rsync -aivh --size-only --progress'
export PATH=$PATH:$HOME/stuff/scripts:$HOME/scripts
export EDITOR=emacs
export BROWSER=chromium
export PS1='\[\033[0;33m\]┌┤\[\033[0m\033[1;33m\]\u\[\033[0;32m\]@\[\033[0;31m\]\h\[\033[0m\033[0;36m\]:\w\[\033[0m\033[0;33m\]│\[\033[0m\]\t\n\[\033[0;33m\]└\[\033[0m\033[1;34m\]`echo $?`\[\033[0;33m\]┐\[\033[0m\]$ '
which keychain >/dev/null 2>&1 && [ -f ~/.ssh/keys/id_rsa_ubuntest1 ] && eval $(keychain --eval --nogui -Q -q keys/id_rsa_ubuntest1)
