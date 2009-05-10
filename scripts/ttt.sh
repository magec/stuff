#!/bin/bash
TST="test.xm"
DST="new.xm"

SIZE=$(ls -l $TST | awk '{print $5}')
dd if=/dev/null of=$DST bs=1 count=1 seek=$SIZE
sfdisk -d $TST | sfdisk $DST

SFARRAY=( $(sfdisk -d $TST 2>&1 | sed -n "s:^.*$TST\([0-9]\) \: start= *\([0-9]\+\), size= *\([0-9]\+\), Id=\([823]\{2\}\).*$:\1;\2;\3;\4:p") )
KPARRAY=( $(kpartx -l $TST 2>&1 | sed -n "s:^\(.*\) \: 0 \([0-9]\+\) /dev/loop[0-9]\+ \([0-9]\+\)$:\1;\3;\2:p") )
kpartx -a $TST
#
#1;63;1959867;82
#2;1959930;14811930;83
#
#loop0p1;63;1959867
#loop0p2;1959930;14811930

COUNT=0

for SFLINE in ${SFARRAY[@]}; do

    SFLINE=( ${SFLINE//;/ } )

    KPLINE=( ${KPARRAY[$COUNT]//;/ } )

    DEVICE="/dev/mapper/${KPLINE[0]}"

    echo -e "Partición nº ${SFLINE[0]}\n\tcomienzo:\t${SFLINE[1]}\n\ttamaño:\t\t${SFLINE[2]}\n\ttipo:\t\t${SFLINE[3]}\n\tse montará en:\t$DEVICE"

    if [ -b $DEVICE ] ; then
        file -s $DEVICE
        echo "OK!"
    else
        echo "$DEVICE NO es un block device!"
    fi

    if [ ${SFLINE[3]} == 82 ] ; then
        echo "SWAP!"
        mkswap $DEVICE >/dev/null 2>&1 && echo "+ Swapfile formateado." || exit 1
    elif [ ${SFLINE[3]} == 83 ] ; then
        echo "LINUX!"
        TIPO=$(file -bs $DEVICE | egrep -o 'ext[2-4]|reiser')
        test $TIPO && mkfs.$TIPO -F $DEVICE >/dev/null 2>&1 && echo "+ Filesystem $4 creado." || exit 1
    else
        echo "(${SFLINE[3]}) no es una partición válida!"
    fi


    COUNT+=1
done



sleep 1
kpartx -d $TST


