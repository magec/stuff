#!/bin/bash
CURRENT_DIR=`dirname $0`
for i in `ls -A $CURRENT_DIR/../dotfiles/`; do 
  [ -f ~/$i ] && echo "Ignoring $i" && continue
  ln -s $CURRENT_DIR/../dotfiles/$i ~/$i
done
