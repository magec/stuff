#!/bin/bash
USER="XXXXXXX"
PASS="XXXXXXX"
verd() { echo -ne "\e[1;32m$1\e[m"; }
rojo() { echo -ne "\e[1;31m$1\e[m"; }

until [ -z "$1" ] ; do
    verd "#\n#\t${1}\n#\n\n"
    RES=$(wget -q --user=$USER --password=$PASS --post-data "search_index=true&hostname=${1}" -O - http://gestioip.uoc.es/ip_searchip.cgi | sed -e 's/<[^>]*>/ /g' -e 's/ *$//g' | sed -n 's/^ \+\([0-9\.]\+\) \+\(.\+\).*/\1\t-> \2/p' | sort -V)
    if [ -z "$RES" ] ; then
        rojo "# No hay hosts.\n"
    else
        verd "# Hosts:\n"
        echo "$RES" | egrep -i --color ${1}
        verd "# Redes:\n"
        NETS=$(wget -q --user=$USER --password=$PASS -O - http://gestioip.uoc.es/index.cgi | sed -e 's/<[^>]*>/ /g' | sed -n 's/ \+\([0-9\.]\+\) \+\([0-9]\+\) \+\(.*\)/\1\t(\2) -> \3/p')
        echo "$NETS" | sort -V | egrep --color $(echo "$RES" | egrep -o '([0-9]{1,3}\.){3}' | xargs | sed -e 's/ /|/g' -e 's/\./\\./g')
    fi
    shift
done
