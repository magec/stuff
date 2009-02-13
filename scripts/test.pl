#!/usr/bin/perl -w
# http://search.cpan.org/src/HARDAKER/SNMP-5.0401/t/bulkwalk.t

#print "Content-Type: text/html\n\n";

use strict;
use SNMP;
use Data::Dumper; #Para depurar
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

my %oids =(
    ifNumber                        =>  '.1.3.6.1.2.1.2.1.0',
    vmMembershipEntry               =>  '.1.3.6.1.4.1.9.9.68.1.2.2.1.2',    #CISCO
    vtpVlanName                     =>  '.1.3.6.1.4.1.9.9.46.1.3.1.1.4.1',  #CISCO
    dot1dBasePortIfIndex            =>  '.1.3.6.1.2.1.17.1.4.1.2',          #ENT
    dot1qVlanStaticName             =>  '.1.3.6.1.2.1.17.7.1.4.3.1.1',      #ENT
    dot1qPvid                       =>  '.1.3.6.1.2.1.17.7.1.4.5.1.1',      #ENT
    ifIndex                         =>  '.1.3.6.1.2.1.2.2.1.1',
    ifName                          =>  '.1.3.6.1.2.1.31.1.1.1.1',
    ifAlias                         =>  '.1.3.6.1.2.1.31.1.1.1.18',
    ifDescr                         =>  '.1.3.6.1.2.1.2.2.1.2',
    ifSpeed                         =>  '.1.3.6.1.2.1.2.2.1.5',
    ifAdminStatus                   =>  '.1.3.6.1.2.1.2.2.1.7',
    ifOperStatus                    =>  '.1.3.6.1.2.1.2.2.1.8',
    ifInOctets                      =>  '.1.3.6.1.2.1.2.2.1.10',
    ifOutOctets                     =>  '.1.3.6.1.2.1.2.2.1.16',
    dot1qVlanStaticEgressPorts      =>  '.1.3.6.1.2.1.17.7.1.4.3.1.2',
    dot1qVlanForbiddenEgressPorts   =>  '.1.3.6.1.2.1.17.7.1.4.3.1.3',
    dot1qVlanStaticUntaggedPorts    =>  '.1.3.6.1.2.1.17.7.1.4.3.1.4',
    sysInfo                         =>  '.1.3.6.1.2.1.1'
);

my $table = '<TABLE style="font-size:9px; text-align: center; border-style:solid; border-width:1px;" border="0" cellspacing="3" SIZE=6>';
my %sinfo=();
my %vlans=();

sub SnmpSession() {
    my ($machine, $community) = @_;

    $machine   = 'localhost' unless $machine;
    $community = 'public'    unless $community;

    my $session = new SNMP::Session(
        DestHost    => $machine,
        Community   => $community,
        Version     => 2,
        RemotePort  => 161,
        UseNumeric  => 1,
    );
    return $session;
}

sub get() {
    my ($machine, $community, $oid) = @_;
    my $session = &SnmpSession($machine, $community);
    if ( $session->{ErrorNum} ) {
        print "<$@> Error ".$session->{ErrorNum}." \"".$session->{ErrorStr}."\n en ".$session->{ErrorInd}."\n";
    }
    return $session->get($oid);
}

sub bulk() {
    my ($machine, $community, @oids) = @_;
    my $session = &SnmpSession($machine, $community);
    my @VarBinds =();
    foreach (@oids) {
        push @VarBinds, new SNMP::Varbind([$_]);
    }
    my $VarList = new SNMP::VarList( @VarBinds );
    my $ifnum = &get($machine, $community,$oids{'ifNumber'});
    my @result = $session->bulkwalk( 0, $ifnum, $VarList );

    if ( $session->{ErrorNum} ) {
        print "<$@> Error ".$session->{ErrorNum}." \"".$session->{ErrorStr}."\n en ".$session->{ErrorInd}."\n";
    }

    return @result;
}


sub parse() {
    my @result = @_;

    for my $x ($result[11]){
        for my $y (@$x){
            $vlans{@$y[1]} = {
                        name        => @$y[2],
                        pvid        => [],
                        egress      => [],
                        forbegress  => [],
                        untagged    => []
            };
        }
    }

   for my $x ($result[12]){
        for my $y (@$x){
            $sinfo{@$y[0]} = @$y[2];
        }
    }

    my %ifaces = ();
    for (0..$#{$result[$_]}) {
        $ifaces{$result[0][$_][2]} = {
            index       => $result[0][$_][2],
            name        => $result[1][$_][2],
            alias       => $result[2][$_][2],
            descr       => $result[3][$_][2],
            speed       => $result[4][$_][2]/1000000,
            admin       => &on_off($result[5][$_][2]),
            oper        => &on_off($result[6][$_][2]),
            in          => &convert_bytes($result[7][$_][2], 3),
            out         => &convert_bytes($result[8][$_][2], 3),
            pvid        => $result[9][$_][2],
            vlanport    => $result[10][$_][2],
            vlaname     => $vlans{$result[9][$_][2]}{'name'},
            egress      => [],
            untagged    => []
        };
    }


    for my $x ($result[9]){
        for my $y (@$x){
                push ( @{ $vlans{@$y[2]}{'pvid'} }, $ifaces{@$y[1]}{'name'} ) if @$y[1];
        }
    }

    for my $x ($result[13]){
        for my $y (@$x){
            my $pno = 0;
            foreach (split(//,unpack("B*", @$y[2]))) {
                $pno++; next unless $_ eq 1;
                push ( @{ $vlans{@$y[1]}{'egress'} }, $ifaces{$pno}{'name'} ) if $ifaces{$pno}{'name'};
                push ( @{ $ifaces{$pno}{'egress'} }, @$y[1] );
            }
        }
    }

    for my $x ($result[14]){
        for my $y (@$x){
            my $pno = 0;
            foreach (split(//,unpack("B*", @$y[2]))) {
                $pno++; next unless $_ eq 1;
                push ( @{ $vlans{@$y[1]}{'forbegress'} }, $ifaces{$pno}{'name'} ) if $ifaces{$pno}{'name'};
                push ( @{ $ifaces{$pno}{'forbegress'} }, @$y[1] );
            }
        }
    }

    for my $x ($result[15]){
        for my $y (@$x){
            my $pno = 0;
            foreach (split(//,unpack("B*", @$y[2]))) {
                $pno++; next unless $_ eq 1;
                push ( @{ $vlans{@$y[1]}{'untagged'} }, $ifaces{$pno}{'name'} ) if $ifaces{$pno}{'name'};
                push ( @{ $ifaces{$pno}{'untagged'} }, @$y[1] );
            }
        }
    }

    return %ifaces;
}

sub on_off {
    return "On" if  $_[0] == 1 or return "Off";
}

sub convert_bytes ($$){
     my ($bytes, $dec) = @_;
     foreach my $posfix (qw(bytes Kb Mb Gb Tb Pb Eb Zb Yb)) {
             return sprintf("\%.${dec}f \%s", $bytes, $posfix) if $bytes < 1024;
             $bytes = $bytes / 1024;
     }
}

sub TrueSort() { # http://www.perlmonks.org/?node_id=483462
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

sub RDigits() { #Devuelve los digitos a la derecha del string
    return $& if "$_[0]" =~ /\d+$/g;
}

sub AgrArr() { #Agrupa los puertos de un array de un chui
    my @out=();
    my $cache=undef;
    my @array=&TrueSort(@_);
    for my $i (0..$#array) {
        next if $array[$i] eq $array[$i+1]; #Nos cargamos los duplicados 
        if ( (&RDigits($array[$i])+1) != &RDigits($array[$i+1]) ) {
            push (@out, $cache.$array[$i]);
            undef($cache);
        } elsif ( ! defined($cache) ) {
            $cache = "$array[$i]-";
        }
    }
    return @out;
}

sub getValues {
    my %tmphash=();
    read(STDIN, my $buffer, $ENV{'CONTENT_LENGTH'});
    my @pairs = split(/&/, $buffer);
    foreach my $pair (@pairs) {
        my ($name, $value) = split(/=/, $pair);
        $value =~ tr/+/ /;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $tmphash{$name} = $value;
    }
    return %tmphash;
}

my %hash=();

sub enterasys() {
    %hash = &parse( &bulk ( $ARGV[0], 'uocpublic',
                                $oids{'ifIndex'},
                                $oids{'ifName'},
                                $oids{'ifAlias'},
                                $oids{'ifDescr'},
                                $oids{'ifSpeed'},
                                $oids{'ifAdminStatus'},
                                $oids{'ifOperStatus'},
                                $oids{'ifInOctets'},
                                $oids{'ifOutOctets'},
                                $oids{'dot1qPvid'},
                                $oids{'dot1dBasePortIfIndex'},
                                $oids{'dot1qVlanStaticName'},
                                $oids{'sysInfo'},
                                $oids{'dot1qVlanStaticEgressPorts'},
                                $oids{'dot1qVlanForbiddenEgressPorts'},
                                $oids{'dot1qVlanStaticUntaggedPorts'}
    )   );
}

sub cisco() {
    %hash = &parse( &bulk ( $ARGV[0], 'uocpublic',
                                $oids{'ifIndex'},
                                $oids{'ifName'},
                                $oids{'ifAlias'},
                                $oids{'ifDescr'},
                                $oids{'ifSpeed'},
                                $oids{'ifAdminStatus'},
                                $oids{'ifOperStatus'},
                                $oids{'ifInOctets'},
                                $oids{'ifOutOctets'},
                                $oids{'vmMembershipEntry'},
                                $oids{'dot1dBasePortIfIndex'},
                                $oids{'vtpVlanName'},
                                $oids{'sysInfo'},
                                $oids{'dot1qVlanStaticEgressPorts'},
                                $oids{'dot1qVlanForbiddenEgressPorts'},
                                $oids{'dot1qVlanStaticUntaggedPorts'}
    )   );
}
sub header() {
print "Content-Type: text/html\n\n";
print <<EOF;
<HTML>
    <HEAD>
        <META http-equiv="Content-Type" content="text/html; charset=utf-8">
        <TITLE>OAL!</TITLE>
    </HEAD>
<BODY>
<B>Test:</B><BR>
<FORM action="$ENV{'SCRIPT_NAME'}" method="POST">
    <TABLE border="0">
        <TR><TD align="right">Host:</TD><TD><INPUT type="text" name="input" value=""/></TD><TD><INPUT type="submit" value="Submit"/></TD></TR>
    </TABLE>
</FORM>
EOF
}

sub info() {
    print "<B>Info:</B><BR>\n";
    print "$table<TR bgcolor=#AAAAAA><TD>Index</TD><TD>Name</TD></TR>";
    foreach my $key (sort keys %sinfo) {
        print "\t<TR bgcolor=#DDDDDD><TD bgcolor=#AAAAAA>$key</TD>".&td($sinfo{$key})."</TR>\n";
    }
    print "</TABLE>\n";
}

sub dbg() {
   print "<pre>";
   print Dumper $_[0];
   print "</pre>";
}

sub totals() {
    my (@adminports,@operports)=();
    print "<B>Ports:</B><BR/>";
    print "$table<TR bgcolor=#AAAAAA>".&td('Range').&td('Ports').&td('Total')."</TR>";
    foreach my $key (keys %hash) {
        push (@adminports, $hash{$key}{'name'}) if $hash{$key}{'admin'} eq "Off";
        push (@operports, $hash{$key}{'name'}) if $hash{$key}{'oper'} eq "Off";
    }
    print "\t<TR bgcolor=#DDDDDD><TD bgcolor=#AAAAAA>Admin Off</TD>".&td(join (", ", &AgrArr(@adminports))).&td(($#adminports+1))."</TR>\n";
    print "\t<TR bgcolor=#DDDDDD><TD bgcolor=#AAAAAA>Oper Off</TD>".&td(join (", ", &AgrArr(@operports))).&td(($#operports+1))."</TR>\n";
    print "</TABLE>\n";
}

sub vlans() {
    print "<B>Vlans:</B><BR/>";
    print "$table<TR bgcolor=#AAAAAA><TD>Nombre</TD><TD>Pvid</TD><TD>Tipo</TD><TD>Puertos</TD><TD>Total</TD></TR>";
    foreach my $key (sort { $a <=> $b } keys %vlans) {
        next unless $key;
        print "\t<TR bgcolor=#DDDDDD><TD rowspan=\"4\" bgcolor=#AAAAAA>$vlans{$key}{'name'}</TD><TD rowspan=\"4\" >$key</TD><TD bgcolor=#BBBBBB>Pvid</TD>".&td(join (", ", &AgrArr( @{ $vlans{$key}{'pvid'}} ))).&td(($#{ $vlans{$key}{'pvid'}}+1))."</TR>\n";
        print "\t<TR bgcolor=#DDDDDD><TD bgcolor=#DDDDDD>Egress</TD>".&td(join (", ", &AgrArr( @{ $vlans{$key}{'egress'}} ))).&td(($#{ $vlans{$key}{'egress'}}+1))."</TR>\n";
        print "\t<TR bgcolor=#DDDDDD><TD bgcolor=#BBBBBB>Forbidden Egress</TD>".&td(join (", ", &AgrArr( @{ $vlans{$key}{'forbegress'}} ))).&td(($#{ $vlans{$key}{'forbegress'}}+1))."</TR>\n";
        print "\t<TR bgcolor=#DDDDDD><TD bgcolor=#DDDDDD>Untagged</TD>".&td(join (", ", &AgrArr( @{ $vlans{$key}{'untagged'}} ))).&td(($#{ $vlans{$key}{'untagged'}}+1))."</TR>\n";
    }
    print "</TABLE>\n";
}

sub ports() {
    print '<B>Ports:</B><BR/>';
    print "$table<TR bgcolor=#AAAAAA><TD>Index</TD><TD>Name</TD><TD>Alias</TD><TD>Speed</TD><TD>Admin</TD><TD>Oper</TD><TD>In</TD><TD>Out</TD><TD>Pvid</TD><TD>Egress</TD><TD>Untagged</TD><TD>Vlan Name</TD><TD>Description</TD></TR>";
    foreach my $key (sort { $a <=> $b } keys %hash) {
        next if not $hash{$key}{'index'} or $hash{$key}{'pvid'} < 1;
        my $bgc = '#DDDDDD';
        $bgc = '#B3D98C' if $hash{$key}{'oper'} eq "Off";
        $bgc = '#8CB3D9' if $hash{$key}{'admin'} eq "Off";
        $bgc = '#D9B38C' if $hash{$key}{'admin'} eq "Off" and $hash{$key}{'oper'} eq "Off";
    print "\t<TR bgcolor=$bgc><TD bgcolor=#AAAAAA>$hash{$key}{'index'}</TD>".&td($hash{$key}{'name'}).&td($hash{$key}{'alias'}).&td($hash{$key}{'speed'}).&td($hash{$key}{'admin'}).&td($hash{$key}{'oper'}).&td($hash{$key}{'in'}).&td($hash{$key}{'out'}).&td($hash{$key}{'pvid'}).&td(@{$hash{$key}{'egress'}}).&td(@{$hash{$key}{'untagged'}}).&td($hash{$key}{'vlaname'}).&td($hash{$key}{'descr'})."</TR>\n";
    }
    print "</TABLE>\n";
}

sub td() {
    return "<TD>@_</TD>" if $_[0] or return "<TD bgcolor=#B9B974><I>Vacío</I></TD>";
}


sub end() {
#    foreach my $key (keys %ENV) {
#        print "$key -> $ENV{$key}<br>\n";
#    }
    print "</BODY></HTML>";
}


my %FORM=&getValues;
&header;
if ($FORM{'input'}) {
    $ARGV[0] = $FORM{'input'};
    my $sysObjectID = &get($FORM{'input'},'uocpublic','.1.3.6.1.2.1.1.2.0');
    if ($sysObjectID =~ /\.1\.3\.6\.1\.4\.1\.5624/) {
        &enterasys;
    } elsif ($sysObjectID =~ /\.1\.3\.6\.1\.4\.1\.9/) {
        &cisco;
    } else {
        print "<B>($FORM{'input'}) '$sysObjectID' No está soportado.</B>";
        die;
    }
    &info;
    &totals;
    &vlans;
    &ports;
}
&end;

exit 0;
