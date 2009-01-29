#!/bin/bash
#set -x
NETS=`wget -q --user=ipadm --password=ipac01 -O - http://gestioip.uoc.es/index.cgi | sed -e 's/<[^>]*>/ /g' | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}.*'`

until [ -z "$1" ]
do
echo -e "\e[1;32m#\n#\t${1}\n#\e[0m"
	RES=`wget -q --user=ipadm --password=ipac01 --post-data "hostname=${1}&search_index=true" -O - http://gestioip.uoc.es/ip_search.cgi | sed -e 's/<[^>]*>/ /g' | egrep -i --color ${1} | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}.*'`
	if [ -z "$RES" ] ; then
		echo -e "\e[1;31m# No hay hosts.\e[0m"
	else
		echo -e "\e[1;32m# Hosts:\e[0m"
		echo "$RES" | egrep -i --color ${1}
        	echo -e "\e[1;32m# Redes:\e[0m"
	        echo "$NETS" | egrep --color `echo "$RES" | egrep -o '([0-9]{1,3}\.){3}' | xargs | sed -e 's/ /|/g' -e 's/\./\\./g'`
	fi
        shift
done
