#!/bin/bash
ok() { echo -ne "\e[32m#\n#\t$1\n#\e[m\n"; }
nk() { echo -ne "\e[31m#\n#\t$1\n#\e[m\n"; exit 1;}
PIN=
[ -c /dev/ttyUSB0 ] && [ -c /dev/ttyUSB2 ] || nk "No existe /dev/ttyUSB0 y/o /dev/ttyUSB2"
ok "Verificando binarios wvdial pppd y grep:"
which wvdial pppd grep || nk "Faltan binarios!"

[ ${#PIN} -ne 4 ] && {
    ok "Introducir PIN:"
    read -r PIN
}
[ ${#PIN} -ne 4 ] && nk "PIN tiene que tener 4 caracteres"

ok "Introduciendo PIN:"
cat <<-EOF > /tmp/wvdial.conf
[Dialer Defaults]
Modem = /dev/ttyUSB2
Baud  = 57600
Init1 = ATZ+CPIN=$PIN
Init2 = ATZ
Init3 = AT+CGDCONT=1,"IP","movistar.es","0.0.0.0",0,0;
EOF
wvdial -C /tmp/wvdial.conf

ok "Conexión PPP:"
cat <<-EOF > /tmp/wvdial.conf
[Dialer Defaults]
Modem         = /dev/ttyUSB0
Stupid Mode   = 1
#Auto DNS      = 0
Phone         = *99***1#
Username      = MOVISTAR
Password      = MOVISTAR
EOF
wvdial -C /tmp/wvdial.conf

ok "Out!"
[ -f /tmp/dial.conf ] && rm /tmp/dial.conf
