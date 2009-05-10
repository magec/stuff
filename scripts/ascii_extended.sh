#!/bin/bash
i=0
while [ $i -lt 400 ]; do
    printf "%i : %b\n" "$i" "\0$i"
    let "i++"
done
