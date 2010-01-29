#!/usr/bin/perl
# chuinfo.pl AKA test.pl+SNMP::Info AKA "Switch CPU Toaster", Oscar Prieto.

use strict;
use warnings;
use SNMP::Info;
use Data::Dumper;

# No quiero escribir esto cada vez.
my $table = '<TABLE class="sortable"; style="text-align: center; border-style:solid; border-width:1px;" border="0" >';
my $infoTR="\t<TR bgcolor=#DDDDDD><TD bgcolor=#AAAAAA nowrap=\"nowrap\">";

# Quiero solo el nombre del script sin path.
$0 =~ s/.*\///g;

# Funciones.
sub footer() {  # HTML Footer (chapamos por las buenas)
    print "</BODY></HTML>\n";
    exit 0;
}

sub td($$) {# Paso de tratar las celdas a pelo.
    my $text = shift || "";
    my $args = shift || "";
    return "<TD $args>$text</TD>" if $text ne "" or return '<TD bgcolor=#EEEEEE style="color:grey;font-style:italic">Null</TD>';
}

sub tdn($$) {# Paso de tratar las celdas a pelo.
    my $text = shift || "";
    my $args = shift || "";
    return "<TD $args>$text</TD>" if $text !~ /^\-/ or return '<TD bgcolor=#D9B38">'.$text.'</TD>';
}
sub tde($$) {# Aquí devolvemos un color de alerta si el valor es verdadero (diferente de 0)
    my $text = shift || 0;
    my $args = shift || "";
    if (defined $text) {
        if ($text gt 0 or $text =~ /^-/) {
            return "<TD bgcolor=#D9B38><I>$text</I></TD>";
        } else {
            return "<TD $args>$text</TD>";
        }
    } else {
         return '<TD bgcolor=#EEEEEE style="color:grey;font-style:italic">Null</TD>';
    }
}
sub non_empty(%) { # Devuelve 0 (falso) si todos los valores del hash son ""
    return grep { $_ ne "" } values %{$_[0]};
}

sub convert_bytes ($$){ # Bytes a 'Human Readable'
    my $bytes = shift;
    my $dec = shift;
    foreach my $posfix (qw(bytes Kb Mb Gb Tb Pb Eb Zb Yb)) {
        return sprintf("\%.${dec}f \%s", $bytes, $posfix) if $bytes < 1024;
        $bytes /= 1024;
     }
}

sub timeticks2HR($) { # Centésimas de segundo a "Human Readable"
    my $seconds = ($_[0]/100);
    return sprintf ("%.1d Days, %.2d:%.2d:%.2d", $seconds/86400, $seconds/3600%24, $seconds/60%60, $seconds%60) if $seconds or return 0;
}

sub TrueSort(@) { # http://www.perlmonks.org/?node_id=483462
    my @list = @_;
    return @list[
        map { unpack "N", substr($_,-4) }
        sort
        map {
            my $key= $list[$_];
            $key =~ s[(\d+)][ pack "N", $1 ]ge;
            $key . pack "N", $_
        } 0..$#list
    ];
}

sub AgrArr(@) { #Agrupa los puertos de un array de un chui
    my @out=();
    my $cache=undef;
    my @array=&TrueSort(@_);
    for my $i (0..$#array) {
        next if $array[$i] eq $array[$i+1]; #Nos cargamos los duplicados
        my $next = $1.($2+1) if $array[$i] =~ /(.+?)(\d+)$/g;
        if ( $next ne $array[$i+1] ) {
            push (@out, $cache.$array[$i]) if $cache.$array[$i];
            undef($cache);
        } elsif ( ! defined($cache) ) {
            $cache = "$array[$i]~";
        }
    }
    return @out;
}

sub arr_resta(@@) {  # devuelve @first - @second
    my $first = shift;
    my $second = shift;
    my %hash;
    $hash{$_}=1 foreach @$second;
    return grep { not $hash{$_} } @$first;
}

#
#   Empezamos
#

{   # Solo puede quedar uno. Solo funcionaremos si podemos tener acceso exclusivo a un fichero común.
    use Fcntl qw(LOCK_EX LOCK_NB);
    open HIGHLANDER, ">>/tmp/perl_$0_highlander" or die "Content-Type: text/html\n\nCannot open highlander: $!";
    {
        flock HIGHLANDER, LOCK_EX | LOCK_NB and last;
        print "Content-Type: text/html\n\nScript en uso!";
        exit 1;
    }
}

my %FORM=();
{   # Leemos POST
    read(STDIN, my $buffer, $ENV{'CONTENT_LENGTH'});
    my @pairs = split(/&/, $buffer);
    foreach my $pair (@pairs) {
        my ($name, $value) = split(/=/, $pair);
        $value =~ tr/+/ /;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $FORM{$name} = $value;
    }
}

{   # HTML Header
    my $date = scalar localtime();
    my $version = "v".int(rand(10))."\.".int(rand(1000))."b";
    print "Content-Type: text/html\n\n";
    print <<EOF;
<HTML>
    <HEAD>
        <META http-equiv="Content-Type" content="text/html; charset=utf-8">
        <TITLE>$0 // $date</TITLE>
        <script type="text/javascript" src="../sorttable.js"></script>
    </HEAD>
<BODY>
<B>ChuInfo $version</B><BR>
<FORM action="$ENV{'SCRIPT_NAME'}" method="POST">
    <TABLE border="0">
        <TR><TD align="right">Host:</TD><TD><INPUT type="text" name="input" value=""/></TD><TD><INPUT type="submit" value="Submit"/></TD></TR>
    </TABLE>
</FORM>
EOF
}

# Para poder usar el script sin cgi.
$FORM{'input'} = $ARGV[0] if not $FORM{'input'};

if ( $FORM{'input'} =~ /^[\w-]+(?:|(\.[\w-]+)+)$/ ) {
    print "<H2>$FORM{'input'}</H2>\n";
} elsif ($FORM{'input'}) { # Cagó la regexp
    print "<B>($FORM{'input'}) No es una entrada válida.</B>\n";
    &footer;
} else {    # 1era vez
    &footer;
}

# Creación del objeto SNMP::Info y conexión mediante SNMP::Session.
my $info = new SNMP::Info(
            AutoSpecify => 1,
            LoopDetect  => 1,
            Debug       => 0,
            BigInt      => 0,   # No se como tratar los obetos BigInt aún.
            BulkWalk    => 1,
            # The rest is passed to SNMP::Session
            DestHost    => $FORM{'input'}, # || '192.168.238.4', # 192.168.247.80
            Community   => 'public',
            Version     => 2,
            MibDirs     => [    '/usr/share/netdisco/mibs/rfc'
                           ,    '/usr/share/netdisco/mibs/net-snmp'
                           ,    '/usr/share/netdisco/mibs/cisco'
                           ,    '/usr/share/netdisco/mibs/enterasys'
                           ],
) or print "<H2>Can't connect to device.<H2>\n" and &footer;

my $err = $info->error();
print "<H2>SNMP Community or Version probably wrong connecting to device. $err</H2>\n" and &footer if defined $err;

# Si no hubo errores, Interrogamos $info y rellenamos nuestros hashes.
# Find out the Duplex status for the ports
my $interfaces = $info->interfaces();
my $i_duplex   = $info->i_duplex();
my $i_duplex_admin  = $info->i_duplex_admin();
# Iface Info
my $i_index = $info->i_index();
my $i_description = $info->i_description();
my $i_type = $info->i_type();
my $i_mtu = $info->i_mtu();
my $i_speed = $info->i_speed();
my $i_mac = $info->i_mac();
my $i_up = $info->i_up();
my $i_up_admin = $info->i_up_admin();
my $i_lastchange = $info->i_lastchange();
my $i_alias = $info->i_alias();
# Iface Stats
my $i_octet_in64 = $info->i_octet_in64();
my $i_octet_out64 = $info->i_octet_out64();
my $i_errors_in = $info->i_errors_in();
my $i_errors_out = $info->i_errors_out();
my $i_pkts_bcast_in64 = $info->i_pkts_bcast_in64();
my $i_pkts_bcast_out64 = $info->i_pkts_bcast_out64();
my $i_discards_in = $info->i_discards_in();
my $i_discards_out = $info->i_discards_out();
my $i_bad_proto_in = $info->i_bad_proto_in();
my $i_qlen_out = $info->i_qlen_out();
# Get CDP Neighbor info
my $c_if       = $info->c_if();
my $c_ip       = $info->c_ip();
my $c_port     = $info->c_port();
#Vlan
my $i_vlan = $info->i_vlan();
my $i_vlan_membership = $info->i_vlan_membership();
my $qb_v_fbdn_egress = $info->qb_v_fbdn_egress();
my $qb_v_untagged = $info->qb_v_untagged();
my $v_name = $info->v_name();
# A esto se le va la olla con algunos cisco y da llaves del tipo "1.100"
foreach (keys %$v_name) {
    next if /^\d+$/; # Si la vlan es todo digitos, OK
    /\d+$/;
    $v_name->{$&} = $v_name->{$_};
    delete $v_name->{$_};
}

#print Dumper $v_name;

#&footer;

my $vtp_trunk_dyn = $info->vtp_trunk_dyn();
my $vtp_trunk_dyn_stat = $info->vtp_trunk_dyn_stat();
#   Fin del martilleo.

{   #Info
    print "<B>Info:</B><BR>\n";
    print "$table<TR bgcolor=#AAAAAA><TD>Index</TD><TD>Name</TD></TR>\n";
    print "${infoTR}Name</TD>".&td($info->name())."</TR>\n";
    print "${infoTR}Location</TD>".&td($info->location())."</TR>\n";
    print "${infoTR}Contact</TD>".&td($info->contact())."</TR>\n";
    print "${infoTR}Class</TD>".&td($info->class())."</TR>\n";
    print "${infoTR}Model</TD>".&td($info->model())."</TR>\n";
    print "${infoTR}OS Version</TD>".&td($info->os_ver())."</TR>\n";
    print "${infoTR}Serial Number</TD>".&td($info->serial())."</TR>\n";
    print "${infoTR}Base MAC</TD>".&td($info->mac())."</TR>\n";
    print "${infoTR}Uptime</TD>".&td(&timeticks2HR($info->uptime()))."</TR>\n";
    print "${infoTR}Layers</TD>".&td($info->layers())."</TR>\n";
    print "${infoTR}Ports</TD>".&td($info->ports())."</TR>\n";
    print "${infoTR}Ip Forwarding".&td($info->ipforwarding())."</TR>\n";
    print "${infoTR}CDP".&td($info->hasCDP())."</TR>\n";
    print "${infoTR}Bulkwalk</TD>".&td($info->bulkwalk())."</TR>\n";
    print "</TABLE>\n";
}

# !!!!!!!
#my @keys = grep { $i_up->{$_} ne "up" } keys %{$i_up};
#return sort map { $interfaces->{$_} } @keys or 0;
#
#my %tmphash= ();
#my @keys = grep { $i_up->{$_} ne "up" } keys %{$i_up};
#@tmphash{@keys} = @$i_up{@keys};
#
#while ((my $k, my $v) = each %tmphash) {
#    print "$k = >$v\n" ;
#}

{   # IP Address Table
    my $index = $info->ip_index();
    my $tble = $info->ip_table();
    my $netmask = $info->ip_netmask();
    my $broadcast = $info->ip_broadcast();

    print "<B>Policies:</B><BR>\n";
    print "$table<TR bgcolor=#AAAAAA>"
        .&td('Index')
        .&td('Port')
        .&td('Table')
        .&td('Netmask')
        .&td('Broadcast')
        ."</TR>\n";
    foreach my $key (sort { $index->{$a} cmp $index->{$b} } keys %$index){
        print "\t<TR bgcolor=#DDDDDD>"
            .&td($index->{$key}, 'bgcolor=#AAAAAA')
            .&td($interfaces->{$index->{$key}})
            .&td($tble->{$key})
            .&td($netmask->{$key})
            .&td($broadcast->{$key})
            ."</TR>\n";
    }
    print "</TABLE>\n";
}

#IP Routing Table
if ( &non_empty($info->ipr_if()) ) {
    my $ipr_route = $info->ipr_route();
    my $ipr_if = $info->ipr_if();
    my $ipr_1 = $info->ipr_1();
    my $ipr_2 = $info->ipr_2();
    my $ipr_3 = $info->ipr_3();
    my $ipr_4 = $info->ipr_4();
    my $ipr_5 = $info->ipr_5();
    my $ipr_dest = $info->ipr_dest();
    my $ipr_type = $info->ipr_type();
    my $ipr_proto = $info->ipr_proto();
    my $ipr_age = $info->ipr_age();
    my $ipr_mask = $info->ipr_mask();

    print "<B>Routing Table:</B><BR>\n";
    print "$table<TR bgcolor=#AAAAAA>"
        .&td('Index')
        .&td('Route')
        .&td('Mask')
        .&td('Dest')
        .&td('1')
        .&td('2')
        .&td('3')
        .&td('4')
        .&td('5')
        .&td('Type')
        .&td('Proto');
    print &td('Age') if &non_empty($ipr_age);
    print "</TR>\n";
    foreach my $key (sort keys %$ipr_route){
        print "\t<TR bgcolor=#DDDDDD>"
            .&td($ipr_if->{$key}, 'bgcolor=#AAAAAA')
            .&td($ipr_route->{$key})
            .&td($ipr_mask->{$key})
            .&td($ipr_dest->{$key})
            .&td($ipr_1->{$key})
            .&td($ipr_2->{$key})
            .&td($ipr_3->{$key})
            .&td($ipr_4->{$key})
            .&td($ipr_5->{$key})
            .&td($ipr_type->{$key})
            .&td($ipr_proto->{$key});
        print &td($ipr_age->{$key}) if &non_empty($ipr_age);
        print "</TR>\n";
    }
    print "</TABLE>\n";
}

sub hashmatch(%$) { # devuelve el puerto asociado a claves de $hash cuyo valor coinciden con $reg
    my $hash = shift;
    my $reg = shift;
    my @tmplist = grep { $hash->{$_} =~ $reg and $i_type->{$_} eq "ethernetCsmacd" } keys %$hash;
    my @result = ();
    @result = map { $interfaces->{$_} } @tmplist or ();
    return @result;
}

{   #Totals
    my @ether      = &hashmatch($i_type,             ".*");
    my @adminon    = &hashmatch($i_up_admin,         "up");
    my @adminoff   = &arr_resta(\@ether,             \@adminon);
    my @operon     = &hashmatch($i_up,               "up");
    my @operoff    = &arr_resta(\@ether,             \@operon);
    my @gbports    = &hashmatch($i_speed,            "1.0 G");
    @gbports       = &arr_resta(\@gbports,           \@operoff);
    my @fastports  = &hashmatch($i_speed,            "100 M");
    @fastports     = &arr_resta(\@fastports,         \@operoff);
    my @ethports   = &hashmatch($i_speed,            "10 M");
    @ethports      = &arr_resta(\@ethports,          \@operoff);
    my @halfdup    = &hashmatch($i_duplex,           "half");
    @halfdup       = &arr_resta(\@halfdup,           \@operoff);
    my @trunkports = &hashmatch($vtp_trunk_dyn_stat, '^trunking$' );
    print '<B>Totals:</B><BR/>';
    print "$table<TR bgcolor=#AAAAAA>".&td('Range').&td('Ports').&td('Total')."</TR>";
    print "${infoTR}Admin On</TD>"    .&td(join (", ", &AgrArr(@adminon)))   .&td(($#adminon+1))."</TR>\n";
    print "${infoTR}Admin Off</TD>"   .&td(join (", ", &AgrArr(@adminoff)))  .&td(($#adminoff+1))."</TR>\n";
    print "${infoTR}Oper On</TD>"     .&td(join (", ", &AgrArr(@operon)))    .&td(($#operon+1))."</TR>\n";
    print "${infoTR}Oper Off</TD>"    .&td(join (", ", &AgrArr(@operoff)))   .&td(($#operoff+1))."</TR>\n";
    print "${infoTR}Gb Link</TD>"     .&td(join (", ", &AgrArr(@gbports)))   .&td(($#gbports+1))."</TR>\n";
    print "${infoTR}Fast Link</TD>"   .&td(join (", ", &AgrArr(@fastports))) .&td(($#fastports+1))."</TR>\n";
    print "${infoTR}Ether Link</TD>"  .&td(join (", ", &AgrArr(@ethports)))  .&tde(($#ethports+1))."</TR>\n";
    print "${infoTR}Half Duplex</TD>" .&td(join (", ", &AgrArr(@halfdup)))   .&tde(($#halfdup+1))."</TR>\n";
    print "${infoTR}Trunking</TD>"    .&td(join (", ", &AgrArr(@trunkports))).&td(($#trunkports+1))."</TR>\n" if @trunkports;
    print "</TABLE>\n";
}

#my @keys = grep { $i_up->{$_} ne "up" } keys %{$i_up};
#return sort map { $interfaces->{$_} } @keys or 0;

{   # Vlans
    print "<B>Vlans:</B><BR/>\n";
    print "$table<TR bgcolor=#AAAAAA><TD>Nombre</TD><TD>Pvid</TD><TD>Tipo</TD><TD>Puertos</TD><TD>Total</TD></TR>\n";
    foreach my $pvid ( sort {$a <=> $b} keys %$v_name) {
        my @pvid        = ();
        my @pegress     = ();
        my @pforbegress = ();
        my @puntagged   = ();
        foreach my $port (keys %$interfaces) {
            next unless $i_type->{$port} eq "ethernetCsmacd"; #Solo tendremos en cuenta puertos "usables"
            push (@pvid,        $interfaces->{$port}) if $i_vlan->{$port} eq $pvid;
            push (@pegress,     $interfaces->{$port}) if grep { $_ eq $pvid } @{$i_vlan_membership->{$port}};
            push (@pforbegress, $interfaces->{$port}) if @{$qb_v_fbdn_egress->{$pvid}}[($port-1)];
            push (@puntagged,   $interfaces->{$port}) if @{$qb_v_untagged->{$pvid}}[($port-1)];
        }
        print "\t<TR bgcolor=#DDDDDD><TD rowspan=\"4\" bgcolor=#AAAAAA>$v_name->{$pvid}</TD><TD rowspan=\"4\" >$pvid</TD><TD bgcolor=#BBBBBB>Pvid</TD>".&td(join (", ", &AgrArr(@pvid)))  .&td(($#pvid+1))."</TR>\n";
        print "\t<TR bgcolor=#DDDDDD><TD bgcolor=#DDDDDD>Egress</TD>".&td(join (", ", &AgrArr(@pegress)))  .&td(($#pegress+1))."</TR>\n";
        print "\t<TR bgcolor=#DDDDDD><TD bgcolor=#BBBBBB>Forbidden</TD>".&td(join (", ", &AgrArr(@pforbegress)))  .&tde(($#pforbegress+1))."</TR>\n";
        print "\t<TR bgcolor=#DDDDDD><TD bgcolor=#DDDDDD>Untagged</TD>".&td(join (", ", &AgrArr(@puntagged)))  .&td(($#puntagged+1))."</TR>\n";
    }
    print "</TABLE>\n";
}

{   # Ports
    print "<B>Ports:</B><BR>\n";
    print "$table<TR bgcolor=#AAAAAA>"
        .&td('Index')
        .&td('Name');
    print &td('Alias') if &non_empty($i_alias);
    print &td('Oper')
        .&td('Admin')
        .&td('Duplex')
        .&td('Speed')
        .&td('PVID Name')
        .&td('PVID')
        .&td('Egress');
        if ($info->vtp_version()) {
            print &td('VTP Trunk State/Neg.');
        } else {
            print &td('Untagged');
        }
    print &td('Last Change')
        .&td('Octets In')
        .&td('Octets Out')
        .&td('Bcast In')
        .&td('Bcast Out')
        .&td('Errors In')
        .&td('Errors Out')
        .&td('Discards In')
        .&td('Discards Out')
        .&td('Bad Proto In');
    print &td('Qlen_out') if &non_empty($i_qlen_out);
    print &td('Mtu')
        .&td('Mac')
        .&td('Type')
        .&td('Description');
    print &td('CDP') if &non_empty($c_ip);
    print "</TR>";

    foreach my $iid (sort { $a <=> $b } keys %$interfaces){
        my $TRArgs = 'bgcolor=#DDDDDD';
        my $itime = ($info->uptime() - $i_lastchange->{$iid});
        $TRArgs = 'bgcolor=#B3D98C' if $i_up->{$iid} ne "up";
        if ($itime > 0) {
            $TRArgs = 'bgcolor=#BBCBDB' if $itime/100 < 86400;
            $TRArgs = 'bgcolor=#8CB3D9' if $itime/100 < 900;
        }
        $TRArgs = 'bgcolor=#D1D175 style="font-style:italic"' if $i_type->{$iid} ne "ethernetCsmacd";
        $TRArgs = 'bgcolor=#8CB3D9' if $i_up_admin->{$iid} eq "down";
        $TRArgs = 'bgcolor=#EEEEEE style="color:gray; font-style:italic"' if $i_up_admin->{$iid} eq "down" and $i_up->{$iid} eq "down";

        my $egress = join('<BR>', &TrueSort(@{$i_vlan_membership->{$iid}})) if $i_vlan_membership->{$iid};

        my @untagged = ();
        foreach (keys %$v_name) {
            next unless @{$qb_v_untagged->{$_}}[($iid-1)];
            push (@untagged, $_) if @{$qb_v_untagged->{$_}}[($iid-1)];
        }
        my $untag = join('<BR>', &TrueSort(@untagged));

        print "\t<TR $TRArgs><TD bgcolor=#AAAAAA>$i_index->{$iid}</TD>"
            .&td($interfaces->{$iid});
        print &td($i_alias->{$iid}) if &non_empty($i_alias);
        print &td($i_up->{$iid})
            .&td($i_up_admin->{$iid})
            .&td($i_duplex->{$iid}.' / '.$i_duplex_admin->{$iid})
            .&td($i_speed->{$iid})
            .&td($v_name->{$i_vlan->{$iid}})
            .&td($i_vlan->{$iid})
            .&td($egress);
            if ($info->vtp_version()) {
                print &td($vtp_trunk_dyn_stat->{$iid}.' / '.$vtp_trunk_dyn->{$iid});
            } else {
                 print &td($untag);
            }
        print &tdn(&timeticks2HR($itime))
            .&td(&convert_bytes($i_octet_in64->{$iid}, 1))
            .&td(&convert_bytes($i_octet_out64->{$iid}, 1))
            .&td($i_pkts_bcast_in64->{$iid})
            .&td($i_pkts_bcast_out64->{$iid})
            .&tde($i_errors_in->{$iid})
            .&tde($i_errors_out->{$iid})
            .&tde($i_discards_in->{$iid})
            .&tde($i_discards_out->{$iid})
            .&tde($i_bad_proto_in->{$iid});
        print &tde($i_qlen_out->{$iid}) if &non_empty($i_qlen_out);
        print &td($i_mtu->{$iid})
            .&td($i_mac->{$iid})
            .&td($i_type->{$iid})
            .&td($i_description->{$iid}, 'nowrap=\"nowrap\"');
    # The CDP Table has table entries different than the interface tables.
    # So we use c_if to get the map from cdp table to interface table.
        print "</TR>\n" and next unless &non_empty($c_ip);
        my %c_map = reverse %$c_if;
        my $c_key = $c_map{$iid};
        my $portcdp = "$c_ip->{$c_key} ($c_port->{$c_key})" if defined $c_ip->{$c_key};
        print &td($portcdp, 'nowrap="nowrap"');
        print "</TR>\n";
    }
    print "</TABLE>\n";
}

&footer;
