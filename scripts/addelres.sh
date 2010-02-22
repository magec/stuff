#/bin/bash
# Crea/elimina un recurso de cluster xen.
CFGFILE=$(readlink -f $1)
test -f $CFGFILE || { echo "+ $CFGFILE no existe"; exit 1; }
echo "+ Fichero de configuración: $CFGFILE"
NAME=$(sed -n "s:^name[ =]\+.\(.*\).$:\1:p" < $CFGFILE)
test -z $NAME &&{ echo "+ No hay entrada 'name' en $CFGFILE"; exit 1; }
echo "+ Nombre del domU: $NAME"
which xm-ha >/dev/null || { echo "+ 'xm-ha' no está en el path."; exit 1; }
STATE=$(xm-ha locate $NAME 2>&1 | egrep -o 'INVALID')
if [ "$STATE" == "INVALID" ] ; then
    cat > $NAME.xml <<-EOF
    <primitive id="$NAME" class="ocf" type="Xen" provider="heartbeat">
        <operations>
            <op name="monitor" interval="20s" timeout="60s" prereq="nothing" id="xen-op-01-$NAME"/>
        </operations>
        <instance_attributes id="$NAME-attr">
            <attributes>
                <nvpair id="$NAME-xen-01" name="xmfile" value="$CFGFILE"/>
                <nvpair id="$NAME-xen-02" name="allow_migrate" value="1"/>
            </attributes>
        </instance_attributes>
        <meta_attributes id="$NAME-meta-01">
            <attributes>
                <nvpair id="$NAME-meta-attr-01" name="target_role" value="stopped"/>
            </attributes>
        </meta_attributes>
    </primitive>
EOF
    echo "+ Creando recurso '$NAME'"
    cibadmin -o resources -C -x $NAME.xml && echo "+ OK" || echo "+ NOK!!"
else
    echo "+ Eliminado recurso '$NAME'"
    crm_resource -D -r $NAME -t primitive && echo "+ OK" || echo "+ NOK!!"
fi
rm $NAME.xml 2>/dev/null
