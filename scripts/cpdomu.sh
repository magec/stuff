#!/bin/bash
#set -x
#set -e
#{{{ Muchos colores.
azul() { echo -ne "\e[34m$1\e[m"; }
amar() { echo -ne "\e[33m$1\e[m"; }
verd() { echo -ne "\e[32m$1\e[m"; }
rojo() { echo -ne "\e[31m$1\e[m"; }
blan() { echo -ne "\e[1m$1\e[m"; }
error(){ set +x; rojo "#\n#\tError "; echo "$1"; rojo "#\n"; exit 1; }
#}}}
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
    ssh -T 2>/dev/null root@$1 'which rsync dd mount umount rmdir mkswap dd' || error "Falta un binario en el equipo destino"
    RHOSTN=$(ssh -T 2>/dev/null root@$1 'uname -n || exit 1') || error "Al intentar conseguir el hostname remoto."
    blan "#\n#\tOK!\n#\n"
} #}}}
check() { #{{{ Chequeo local.
    for PROG in {ssh,ssh-agent,ssh-keygen,ssh-add,mount,rmdir,cat,egrep} ; do
        if [ ! -f `which $PROG` ]; then echo -n "$PROG "; error "No está en el PATH.\n"; exit 1; fi
    done
    if [ `file -b $1 2>/dev/null | egrep -q 'text' ; echo $?` != 0 ]; then
        echo -n "$1 "; rojo "No es un documento de texto.\n"
        echo "$0, copia domUs de xen. Uso: $0 <fichero de config> <máquina destino>"
        exit 1
    fi
    if [ `netcat -zw1 $2 22; echo $?` != 0 ]; then
        echo -n "$2 "; rojo "No es accesible por el puerto 22.\n"
        exit 1
    fi
    DOMU=$(egrep -i '^name *= *' $1 | cut -d '=' -f2 | sed -e s/[^0-z\.]//g)
    test -z $DOMU && error "El domu no tiene nombre." || echo "+ El nombre del domu es $DOMU"
    if [ -f `which xm` ]; then
        if [ `xm list | egrep -qi $DOMU ; echo $?` = 0 ] ; then error "'xm list' reporta que $DOMU está corriendo." ; fi
    fi
    if [ -f `which xm-ha` ]; then
        if [ `xm-ha list | egrep -qi $DOMU ; echo $?` = 0 ] ; then error "'xm-ha list' reporta que $DOMU está corriendo." ; fi
    fi
} #}}}
create_swap() { #{{{ Crear swap en el remoto.
    azul "#\n#\tCreando swap $FILE de $SIZE en $2\n#\n"
    DIR=$(echo $1 | egrep -o '^/.*/')
    ssh -T 2>/dev/null root@$2 <<EOF
which xm || { echo "+ No hay xm en el remoto"; exit 1;}
xm list $DOMU 2>/dev/null && { echo "+ $DOMU está corriendo en $2"; exit 1;} || echo "+ $DOMU no está corriendo según 'xm list'"
xm-ha locate $DOMU 2>/dev/null && { echo "+ $DOMU está corriendo en $2"; exit 1;} || echo "+ $DOMU no está corriendo según 'xm-ha locate'(o no existe xm-ha)"
mkdir -p $DIR && echo "+ Directorio $DIR existente o creado." || exit 1
test -f $1 && { echo "+ Cuidado, $1 YA existe en $DIR."; exit 2; }
dd if=/dev/null of=$1 bs=1 count=1 seek=$3 >/dev/null 2>&1 && echo "+ Swapfile $1 de tamaño $3 creado." || exit 1
mkswap $1 >/dev/null 2>&1 && echo "+ Swapfile formateado." || exit 1
EOF
    if [ "$?" == "2" ] ; then
        rojo "#\n#\tYa existe el fichero de swap en el remoto!\n#\n"
    elif test "$?" == "0" ; then
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
    if [ "$?" == "2" ] ; then
        rojo "#\n#\tYa existe el fichero de disco en el remoto!\n#\n"
        read -p "Pulse ENTER para hacer rsync entre discos origen/destino o CTRL+C para cancelar..."
    elif test "$?" == "0" ; then
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
    test "$?" == "0" && amar "#\n#\tOK!\n#\n" || error "Al crear/montar punto de montaje remoto."
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
do_stuff() { #{{{ Bucle principal.
    ARRAY=( $(egrep -io '/[0-z.\/-]+' $1) )
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
        elif [ `echo "$OUT" | egrep -qi 'ext[2-4]|reiser'; echo $?` = 0 ]; then
            echo "Nombre: $FILE"; echo -ne "Tamaño: $SIZE\nTipo: "; amar "\t$OUT\n\n"
            if [ ! -z $3 ] ; then
                create_disk $FILE $2 $(ls -l $FILE | awk '{print $5}') $(file -b $FILE | egrep -o 'ext[2-4]|reiser')
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
do_stuff $1 $2
ssh_init $2
do_stuff $1 $2 ASDF
blan "#\n#\tTodo OK!\n#\n" && exit 0
#vim: set foldmethod=indent tabstop=4 shiftwidth=4 nu:
