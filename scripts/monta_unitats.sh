#!/bin/bash
#set -x

PATH=$PATH:/usr/sbin:/usr/bin:/sbin:/bin
USER="rmacian"
PASS="kadireta"
DEST="/media"
OPT="gid=disk,rw,iocharset=utf8"

#mount -t cifs //UOC-PRESSEC/INFTEC /media/G -o username=INTERNA/rmacian,password=kadireta,gid=disk

case "$1" in
	start)
		mount -t cifs //UOC-XIRIVIA/R_GLOBAL ${DEST}/R -o username=INTERNA/${USER},password=${PASS},${OPT}
		mount -t cifs //UOC-PRESSEC/INFTEC ${DEST}/G -o username=INTERNA/${USER},password=${PASS},${OPT}
		mount -t cifs //UOC-PRESSEC/KAOS ${DEST}/K -o username=INTERNA/${USER},password=${PASS},${OPT}
		mount -t cifs //UOC-LLENTIA/INFORMATICA ${DEST}/N -o username=INTERNA/${USER},password=${PASS},${OPT}
		mount -t cifs //UOC-XIRIVIA/GLOBAL ${DEST}/P -o username=INTERNA/${USER},password=${PASS},${OPT}
		mount -t cifs //uoc-celerra/SOFTPC ${DEST}/S -o username=INTERNA/${USER},password=${PASS},${OPT}
		mount -t cifs //INGLATERRA/APLICAHOME ${DEST}/H -o username=INTERNA/${USER},password=ibermat,${OPT}
	;;
	restart|reload|force-reload)
        echo "Error: argument '$1' not supported" >&2
        exit 3
	;;
	stop)
		umount ${DEST}/R
		umount ${DEST}/G
		umount ${DEST}/N
		umount ${DEST}/P
		umount ${DEST}/S
		umount ${DEST}/H 
	;;
	*)
		echo "Usage: $0 start|stop" >&2
		exit 3
	;;
esac
