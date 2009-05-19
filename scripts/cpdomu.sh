#!/bin/bash
#set -x
#set -e
#{{{ Muchos colores.
lila() { echo -ne "\e[35m$1\e[m"; }
azul() { echo -ne "\e[34m$1\e[m"; }
amar() { echo -ne "\e[33m$1\e[m"; }
verd() { echo -ne "\e[32m$1\e[m"; }
rojo() { echo -ne "\e[31m$1\e[m"; }
blan() { echo -ne "\e[1m$1\e[m"; }
error(){ set +x; rojo "#\n#\tError "; echo "$1"; rojo "#\n"; exit 1; }
#}}}
io_nice() { #{{{ Inicializar SSH.
    which ionice > /dev/null 2>&1 && ionice -c2 -n7 -p$$ ; amar "Atención el Scheduler de IO para esta shell está en: "; blan "$(ionice -p$$)\n" || error "No existe o no se ejecutó 'ionice' correctemente"
#    which nice > /dev/null 2>&1 && renice +19 -u root ; amar "Atención el Scheduler para esta shell está en -19\n" || error "No existe o no se ejecutó 'nice' correctemente"
} #}}}
ssh_init() { #{{{ Inicializar SSH.
    blan "#\n#\tCreando claves RSA contra $1\n#\n"
    rm /tmp/id_rsa* || echo "+ No existen /tmp/id_rsa*, correcto."
    ssh-keygen -N '' -f /tmp/id_rsa -t rsa -q && echo "+ Claves RSA generadas." || error "Al crear claves"
    blan "#\n#\tLos ficheros anteriores se copiarán.\n#\tClave de root@$1 para continuar o CTRL+C para salir.\n#\n"
    cat /tmp/id_rsa.pub | ssh root@$1 'cat >> .ssh/authorized_keys' && echo "+ Clave pública copiada a $1" || error "al copiar clave pública en $1"
    eval `ssh-agent` >/dev/null 2>&1 && echo "+ ssh-agent lanzado." || error "Al lanzar ssh-agent"
    ssh-add /tmp/id_rsa >/dev/null 2>&1 && echo "+ Clave privada añadida a ssh-agent." || error "Al añadir nuestra clave privada al agente."
    blan "#\n#\tOK!\n#\n"
    blan "#\n#\tChequeo remoto de ficheros:\n#\n"
    ssh -T 2>/dev/null root@$1 'which rsync dd mount umount rmdir mkswap dd kpartx' || error "Falta un binario en el equipo destino"
    RHOSTN=$(ssh -T 2>/dev/null root@$1 'uname -n || exit 1') || error "Al intentar conseguir el hostname remoto."
    blan "#\n#\tOK!\n#\n"
} #}}}
check() { #{{{ Chequeo local.
    for PROG in {ssh,ssh-agent,ssh-keygen,ssh-add,mount,rmdir,cat,egrep,kpartx} ; do
        if [ ! -f `which $PROG` ]; then echo -n "$PROG "; error "No está en el PATH.\n"; exit 1; fi
    done
    if [ `file -b $1 2>/dev/null | egrep -q 'text' ; echo $?` != 0 ]; then
        echo -n "$1 "; rojo "No es un documento de texto.\n"
        echo "$0, copia domUs de xen. Uso: $0 <fichero de config> <máquina destino>"
        exit 1
    fi
    if [ `netcat -zw1 $2 22 2>/dev/null; echo $?` != 0 ]; then
        echo -n "$2 "; rojo "No es accesible por el puerto 22.\n"
        exit 1
    fi
    DOMU=$(egrep -i '^name *= *' $1 | cut -d '=' -f2 | sed -e s/[^0-z\.]//g)
    test -z "$DOMU" && error "El domu no tiene nombre." || echo "+ El nombre del domu es $DOMU"
   # if [ -f `which xm` ]; then
   #     if [ `xm list | egrep -qi $DOMU ; echo $?` = 0 ] ; then error "'xm list' reporta que $DOMU está corriendo." ; fi
   # fi
   # if [ -f `which xm-ha` ]; then
   #     if [ `xm-ha list | egrep -qi $DOMU ; echo $?` = 0 ] ; then error "'xm-ha list' reporta que $DOMU está corriendo." ; fi
   # fi
} #}}}
create_swap() { #{{{ Crear swap en el remoto.
    azul "#\n#\tCreando swap $FILE de $SIZE en $2\n#\n"
    DIR=$(echo $1 | egrep -o '^/.*/')
    ssh -T 2>/dev/null root@$2 <<EOF
which xm || { echo "+ No hay xm en el remoto"; exit 1;}
m list $DOMU 2>/dev/null && { echo "+ $DOMU está corriendo en $2"; exit 1;} || echo "+ $DOMU no está corriendo según 'xm list'"
xm-ha locate $DOMU 2>/dev/null && { echo "+ $DOMU está corriendo en $2" según 'xm-ha'.; exit 1;} || echo "+ $DOMU no está corriendo según 'xm-ha locate'(o no existe xm-ha)"
mkdir -p $DIR && echo "+ Directorio $DIR existente o creado." || exit 1
test -f $1 && { echo "+ Cuidado, $1 YA existe en $DIR."; exit 2; }
dd if=/dev/null of=$1 bs=1 count=1 seek=$3 >/dev/null 2>&1 && echo "+ Swapfile $1 de tamaño $3 creado." || exit 1
mkswap $1 >/dev/null 2>&1 && echo "+ Swapfile formateado." || exit 1
EOF
    STATE=$?
    if [ "$STATE" -eq 2 ] ; then
        rojo "#\n#\tYa existe un fichero de swap en el remoto, no se creará otro.\n#\n"
    elif [ "$STATE" -eq 0 ] ; then
        azul "#\n#\tOK!\n#\n"
    else
        error "Al crear el fichero de swap remoto."
    fi
} #}}}
create_disk() { #{{{ Crear filesystem en el remoto.
    amar "#\n#\tCreando imagen $1 en $2 con filesystem $4 y tamaño $3\n#\n"
    DIR=$(echo $1 | egrep -o '^/.*/')
    ssh -T 2>/dev/null root@$2 <<EOF
mkdir -p $DIR && echo "+ Directorio $DIR existente o creado." || exit 1
test -f $1 && { echo -e "+ Cuidado, $1 YA existe en $DIR." ; exit 2; }
dd if=/dev/null of=$1 bs=1 count=1 seek=$3 >/dev/null 2>&1 && echo "+ Imagen $1 de tamaño $3 creada." || exit 1
mkfs.$4 -F $1 >/dev/null 2>&1 && echo "+ Filesystem $4 creado." || exit 1
EOF
    STATE=$?
    if [ "$STATE" -eq 2 ] ; then
        rojo "#\n#\tYa existe el fichero de disco en el remoto.\n#\n"
        read -p "Pulse ENTER para hacer rsync entre discos origen/destino o CTRL+C para cancelar..."
    elif [ "$STATE" -eq 0 ] ; then
        amar "#\n#\tOK!\n#\n" || error "Al crear la imagen de disco remota."
    else
        error "Al crear el fichero de disco remoto."
    fi
    DISK=$(echo "$1" | egrep -o '[^/]+$')
    amar "#\n#\tCreando y montando imagen local en /mnt/_$DISK\n#\n"
    mkdir -p /mnt/_$DISK && echo "+ Punto de montaje /mnt/_$DISK creado." || exit 1
    mount -o loop,ro $1 /mnt/_$DISK && echo "+ Imagen $1 montada." || exit 1
    amar "#\n#\tOK!\n#\n"
    amar "#\n#\tCreando y montando imagen remota en /mnt/_$DISK\n#\n"
    ssh -T 2>/dev/null root@$2 <<EOF
mkdir -p /mnt/_$DISK && echo "+ Punto de montaje /mnt/_$DISK creado." || exit 1
mount -o loop $1 /mnt/_$DISK && echo "+ Imagen $1 montada." || exit 1
EOF
    test "$?" == "0" && amar "#\n#\tOK!\n#\n" || error "Al crear/montar punto de montaje remoto. Tal vez $USER no pueda montar filesystems."
    amar "#\n#\tHaciendo rsync del punto de montaje local al remoto.\n#\n"
    rsync -Raz /mnt/_$DISK/ root@$2:/ && echo "+ Rsync correcto." || exit 1
    amar "#\n#\tOK!\n#\n"
    amar "#\n#\tDesmontando y eliminando puntos de montaje\n#\n"
    umount /mnt/_$DISK && echo "+ Desmontando /mnt/_$DISK (local)." || exit 1
    rmdir /mnt/_$DISK && echo "+ Eliminando /mnt/_$DISK (local)." || exit 1
    ssh -T 2>/dev/null root@$2 <<EOF
umount /mnt/_$DISK && echo "+ Desmontando /mnt/_$DISK (remoto)." || exit 1
rmdir /mnt/_$DISK && echo "+ Eliminando /mnt/_$DISK (remoto)." || exit 1
EOF
    test "$?" == "0" && amar "#\n#\tOK!\n#\n" || error "Al desmontar/eliminar punto de montaje remoto."
} #}}}
create_disk_full() { #{{{ Crear disco entero en el remoto.

sfdisk -d $1 > $1.sfdisk
lila "#\n#\tTabla de particiones:\n#\n"
cat  $1.sfdisk
lila "#"
echo -e "\n+ Copiando tabla de particiones en $2"
rsync -Raz $1.sfdisk root@$2:/ && echo -e "+ $1.fdisk copiado en $2" || error "En la copia."

ssh -T 2>/dev/null root@$2 <<EOF
    test -f $1 && { echo "+ $1 ya existe en $2." ; exit 1; } || echo "+ $1 no existe en $2"
    dd if=/dev/null of=$1 bs=1 count=1 seek=$3 >/dev/null 2>&1 && echo "+ $1 creado" || { echo "+ No se pudo crear $1"; exit 1; }
    sfdisk -f $1 < $1.sfdisk >/dev/null 2>&1 && echo "+ tabla de particiones copiada" || { echo "+ Error al copiar la tabla de particiones en $1"; exit 1; }
EOF

# SFARRAY
#1;63;1959867;82
#2;1959930;14811930;83
SFARRAY=( $(sfdisk -d $1 2>&1 | sed -n "s:^.*$1\([0-9]\) \: start= *\([0-9]\+\), size= *\([0-9]\+\), Id=\([823]\{2\}\).*$:\1;\2;\3;\4:p") )
# KPARRAY
#loop0p1;63;1959867
#loop0p2;1959930;14811930
KPARRAY=( $(kpartx -l $1 2>&1 | sed -n "s:^\(.*\) \: 0 \([0-9]\+\) /dev/loop[0-9]\+ \([0-9]\+\)$:\1;\3;\2:p") )

# Porsia
quitar_mapeos $1 $2

kpartx -a $1
sleep 1
ssh -T 2>/dev/null root@$2 <<EOF
    kpartx -a $1
EOF

LOOPD=$(echo ${KPARRAY[0]} | egrep -o '^loop[0-9]+')
renice +19 -p `pidof $LOOPD`
test `ps xo ni,comm | egrep -q "19 $LOOPD"; echo $?` -eq 0 && echo "+ Renice +19 a $LOOPD OK" || error "al hacer renice a $LOOPD"

COUNT=0
for SFLINE in ${SFARRAY[@]}; do
    SFLINE=( ${SFLINE//;/ } )
    KPLINE=( ${KPARRAY[$COUNT]//;/ } )
    DEVICE="/dev/mapper/${KPLINE[0]}"

    lila "Partición nº\t"; echo -e "${SFLINE[0]}"
    lila "\tSector de Inicio:\t"; echo -e "${SFLINE[1]}"
    lila "\tNº de sectores:\t\t"; echo -e "${SFLINE[2]}"
    lila "\tTipo de partición:\t"; echo -e "${SFLINE[3]}"
    lila "\tMapping local:\t\t"; echo -e "$DEVICE"
    lila "\tFilesystem:\t\t"; echo -e "$(file -bs $DEVICE)"

    if [ ${SFLINE[3]} == 82 ] ; then
        ssh -T 2>/dev/null root@$2 <<EOF
RDEV="/dev/mapper/\$(kpartx -l $1 2>&1 | sed -n "s:^\(.*\) \: 0 ${SFLINE[2]} /dev/loop[0-9]\+ ${SFLINE[1]}$:\1:p")"
test -b \$RDEV && echo "+ OK, \$RDEV es un dispositivo de bloque." || echo "+ \$RDEV no existe o no es un dispositivo de bloque!"
if [ \$(file -bs \$RDEV | egrep -q ' swap |^data$' ; echo \$?) == "0" ] ; then
    echo "+ La partición \$RDEV es de tipo swap o data, se creará el swapfile igualmente."
    mkswap \$RDEV >/dev/null 2>&1 && echo "+ Swapfile formateado." || exit 1
else
    echo "+ \$RDEV no es una partición swap o vacía" && exit 1
fi
EOF
    elif [ ${SFLINE[3]} == 83 ] ; then
        TIPO=$(file -bs $DEVICE | egrep -io 'ext[2-4]|reiserfs|^data$')
        echo "+ El filesystem local $DEVICE de $1 es $TIPO"
        ssh -T 2>/dev/null root@$2 <<EOF
RDEV="/dev/mapper/\$(kpartx -l $1 2>&1 | sed -n "s:^\(.*\) \: 0 ${SFLINE[2]} /dev/loop[0-9]\+ ${SFLINE[1]}$:\1:p")"
test -b \$RDEV && echo "+ OK, \$RDEV es un dispositivo de bloque." || echo "+ \$RDEV no existe o no es un dispositivo de bloque!"
RTIPO=\$(file -bs \$RDEV | egrep -io 'ext[2-4]|reiserfs|^data$')
test \$RTIPO && echo "+ La partición remota \$RDEV de $1 es de tipo \$RTIPO"
if [ \$RTIPO == "data" ] ; then
    echo "+ Se va a formatear \$RDEV en $TIPO"
    if [ $TIPO == "ReiserFS" ] ; then
        mkreiserfs -fq \$RDEV >/dev/null 2>&1 && echo "+ Filesystem $TIPO creado en $1." || { echo "+ Error creando filesystem $TIPO en $1"; exit 1; }
    else
        mkfs.$TIPO -F \$RDEV >/dev/null 2>&1 && echo "+ Filesystem $TIPO creado en $1." || { echo "+ Error creando filesystem $TIPO en $1"; exit 1; }
    fi
else
    echo "+ \$RDEV ya tiene un filesystem \$RTIPO, no se formateará."
fi
    mkdir -p $1_dir
    mount \$RDEV $1_dir
EOF
        echo "+ Creando $1_dir"
        mkdir -p $1_dir || echo "+ Error al hacer rsync de a $2"
        echo "+ Montando $DEVICE en $1_dir"
        mount $DEVICE $1_dir || echo "+ Error al montar $DEVICE en $1_dir en local"
        echo "+ Rsync de $1_dir a $2"
        rsync -Raz $1_dir/ root@$2:/ && echo "+ Rsync correcto." || echo "+ Error al hacer rsync de a $2"
        echo "+ Desmontando $DEVICE en $1_dir"
        umount $1_dir || echo "+ Error al demontar $1_dir en local"
        echo "+ Eliminando directorio $DEVICE en $1_dir"
        rmdir $1_dir || echo "+ Error al borrar $1_dir"
        ssh -T 2>/dev/null root@$2 <<EOF
RDEV="/dev/mapper/\$(kpartx -l $1 2>&1 | sed -n "s:^\(.*\) \: 0 ${SFLINE[2]} /dev/loop[0-9]\+ ${SFLINE[1]}$:\1:p")"
echo "+ Desmontando \$RDEV en $1_dir en $2 (remoto)"
umount $1_dir || echo "+ Error al demontar $1_dir en (remoto)"
echo "+ Eliminando directorio \$RDEV en $1_dir en $2 (remoto)"
rmdir $1_dir || echo "+ Error al borrar $1_dir (remoto)"
EOF
    else
        echo "(${SFLINE[3]}) no es una partición válida!"
    fi
    let "COUNT += 1"
done

quitar_mapeos $1 $2

lila "#\n#\tOK!\n#\n"
} #}}}
quitar_mapeos() { #{{{ Quita los mapeos creados con kpartx.
    kpartx -d $1 >/dev/null 2>&1 && echo "+ Mapeos de $1 (local) eliminados." || error "al quitar mapeos de $1"
    ssh -T 2>/dev/null root@$2 <<EOF
kpartx -d $1 >/dev/null 2>&1 && echo "+ Mapeos de $1 (remoto) eliminados." || { echo "+ Error al quitar mapeos de $1"; exit 1;}
EOF
} #}}}
do_stuff() { #{{{ Bucle principal.
    ARRAY=( $(egrep -io '/[0-z.\/-\_]+' $1) )
    blan "#\n#\tFicheros en $1\n#\n\n"
    for FILE in ${ARRAY[@]}; do
        test -f $FILE || continue
        OUT=$(file -b $FILE)
        SIZE=$(ls -lh $FILE | awk '{print $5}')
        if [ `echo "$OUT" | egrep -qi 'swap' ; echo $?` = 0 ]; then
            echo "Nombre: $FILE"; echo -ne "Tamaño: $SIZE\nTipo: "; azul "\t$OUT\n\n"
            if [ ! -z $3 ] ; then
                create_swap $FILE $2 $(ls -l $FILE | awk '{print $5}')
            fi
        elif [ `echo "$OUT" | egrep -qi 'x86 boot sector'; echo $?` = 0 ]; then
            echo "Nombre: $FILE"; echo -ne "Tamaño: $SIZE\nTipo: "; lila "\t$OUT\n\n"
            if [ ! -z $3 ] ; then
                create_disk_full $FILE $2 $(ls -l $FILE | awk '{print $5}')
            fi
        elif [ `echo "$OUT" | egrep -qi 'ext[2-4]|reiserfs'; echo $?` = 0 ]; then
            echo "Nombre: $FILE"; echo -ne "Tamaño: $SIZE\nTipo: "; amar "\t$OUT\n\n"
            if [ ! -z $3 ] ; then
                create_disk $FILE $2 $(ls -l $FILE | awk '{print $5}') $(file -b $FILE | egrep -io 'ext[2-4]|reiserfs')
            fi
        elif [ `echo "$OUT" | egrep -qi 'image|zip' ; echo $?` = 0 ]; then
            echo "Nombre: $FILE"; echo -ne "Tamaño: $SIZE\nTipo: "; verd "\t$OUT\n\n"
            if [ ! -z $3 ] ; then
                verd "#\n#\tCopiando $FILE en $2\n#\n"
                rsync -Raz $FILE root@$2:/ && verd "#\n#\tOK!\n#\n\n" || error "En la copia."
            fi
        else
            echo "Nombre: $FILE"; echo -ne "Tamaño: $SIZE\nTipo: "; rojo "\t$OUT"; echo -e " (NO se copiará)\n"
        fi
    done
    if [ ! -z $3 ] ; then
        blan "#\n#\tCopiando fichero de configuración $1 a $2:/etc/xen/$RHOSTN\n#\n"
        ssh -T 2>/dev/null root@$2 'mkdir -p /etc/xen/$RHOSTN || exit 1' || error "Al crear /etc/xen/$RHOSTN en $2."
        rsync -az $1 root@$2:/etc/xen/$RHOSTN/ && echo "+ Fichero copiado." || error "En la copia."
    fi
} #}}}
check $1 $2
io_nice
do_stuff $1 $2
ssh_init $2
do_stuff $1 $2 ASDF
blan "#\n#\tTodo OK!\n#\n" && exit 0
#vim: set foldmethod=indent tabstop=4 shiftwidth=4 nu:
