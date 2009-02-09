#!/usr/bin/perl -wT
# http://search.cpan.org/src/HARDAKER/SNMP-5.0401/t/bulkwalk.t


print "Content-Type: text/html\n\n";

use strict;
use SNMP;
use Data::Dumper; #Para depurar
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

my %oids =(
    vmMembershipEntry           =>  '.1.3.6.1.4.1.9.9.68.1.2.2.1.2',    #CISCO
    vtpVlanName                 =>  '.1.3.6.1.4.1.9.9.46.1.3.1.1.4.1',  #CISCO
    dot1dBasePortIfIndex        =>  '.1.3.6.1.2.1.17.1.4.1.2',          #ENT
    dot1qVlanStaticName         =>  '.1.3.6.1.2.1.17.7.1.4.3.1.1',      #ENT
    dot1qPvid                   =>  '.1.3.6.1.2.1.17.7.1.4.5.1.1',      #ENT
    ifIndex                     =>  '.1.3.6.1.2.1.2.2.1.1',
    ifName                      =>  '.1.3.6.1.2.1.31.1.1.1.1',
    ifAlias                     =>  '.1.3.6.1.2.1.31.1.1.1.18',
    ifDescr                     =>  '.1.3.6.1.2.1.2.2.1.2',
    ifSpeed                     =>  '.1.3.6.1.2.1.2.2.1.5',
    ifAdminStatus               =>  '.1.3.6.1.2.1.2.2.1.7',
    ifOperStatus                =>  '.1.3.6.1.2.1.2.2.1.8',
    ifInOctets                  =>  '.1.3.6.1.2.1.2.2.1.10',
    ifOutOctets                 =>  '.1.3.6.1.2.1.2.2.1.16',
    dot1qVlanStaticUntaggedPort =>  '.1.3.6.1.2.1.17.7.1.4.3.1.4',
);

sub GetSnmp() {
    my ($machine, $community, @oids) = @_;

    $machine   = 'localhost' unless $machine;
    $community = 'public'    unless $community;

    my $session = new SNMP::Session(
        DestHost    => $machine,
        Community   => $community,
        Version     => 2,
        RemotePort  => 161,
        UseNumeric  => 1,
    );

    my @VarBinds =();
    foreach (@oids) {
        push @VarBinds, new SNMP::Varbind([$_]);
    }

    my $VarList = new SNMP::VarList( @VarBinds );
    my @result = $session->bulkwalk( 0, 75, $VarList );

    if ( $session->{ErrorNum} ) {
        print "Error ".$session->{ErrorNum}." \"".$session->{ErrorStr}."\n en ".$session->{ErrorInd}."\n";
    }

    my %vlans=();
    for my $x ($result[11]){
        for my $y (@$x){
            $vlans{@$y[1]} = @$y[2];
        }
    }

    my %ifaces = {};
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
            vlaname     => $vlans{$result[9][$_][2]}
        }; 
    }
    #print Dumper %ifaces;
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
my (@adminports,@operports)=();
my %FORM=&getValues;

sub tmp() {
	%hash = &GetSnmp ( $ARGV[0], 'uocpublic',
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
	#                            $oids{'dot1qVlanStaticUntaggedPorts'}
	);
	
	foreach my $key (keys %hash) {
	    push (@adminports, $hash{$key}{'name'}) if $hash{$key}{'admin'} eq "Off";
	    push (@operports, $hash{$key}{'name'}) if $hash{$key}{'oper'} eq "Off";
	}
	
	#print join (", ", &AgrArr(@adminports)); 
	#print "\n";
	#print join (", ", &AgrArr(@operports)); 
}


sub header() {
print <<EOF;
<HTML><BODY>
<B>Test:</B><BR/>
<FORM action="$ENV{'SCRIPT_NAME'}" method="POST">
    <table border="0">
        <tr><td align="right">Host:</td><td><input type="text" name="input" value=""/></td><td><input type="submit" value="Submit"/></td></tr>
    </TABLE>
</FORM>
EOF
}

sub ports() {
    print '<TABLE style="font-size:9px; text-align: center; border-style:solid; border-width:1px; white-space:nowrap" border="0" cellspacing="3" SIZE=6><TR bgcolor=#AAAAAA><TD>Index</TD><TD>Name</TD><TD>Alias</TD><TD>Speed</TD><TD>Admin</TD><TD>Oper<TD>In</TD><TD>Out</TD><TD>Pvid</TD><TD>Vlan Name</TD><TD>Description</TD></TR>';
    foreach my $key (sort { $a <=> $b } keys %hash) {
        next if not exists $hash{$key}{'index'} or $hash{$key}{'pvid'} < 1;
        my $bgc = '#DDDDDD'; 
        $bgc = '#B3D98C' if $hash{$key}{'oper'} eq "Off" ;
        $bgc = '#8CB3D9' if $hash{$key}{'admin'} eq "Off"; 
        $bgc = '#D9B38C' if $hash{$key}{'admin'} eq "Off" and $hash{$key}{'oper'} eq "Off";
    #    print "$hash{$key}{'index'}\t$hash{$key}{'name'}\t$hash{$key}{'alias'}\t$hash{$key}{'speed'}\t$hash{$key}{'admin'}\t$hash{$key}{'oper'}\t$hash{$key}{'in'}\t$hash{$key}{'out'}\t$hash{$key}{'pvid'}\t$hash{$key}{'vlanport'}\t$hash{$key}{'vlanname'}\n"; 
    print "\t<TR bgcolor=$bgc><TD bgcolor=#AAAAAA>$hash{$key}{'index'}</TD><TD>$hash{$key}{'name'}</TD><TD>$hash{$key}{'alias'}</TD><TD>$hash{$key}{'speed'}</TD><TD>$hash{$key}{'admin'}</TD><TD>$hash{$key}{'oper'}</TD><TD>$hash{$key}{'in'}</TD><TD>$hash{$key}{'out'}</TD><TD>$hash{$key}{'pvid'}</TD><TD>$hash{$key}{'vlaname'}</TD><TD>$hash{$key}{'descr'}</TD></TR>\n";
    }
    print "</TABLE>\n";
}    

sub end() {
#    foreach my $key (keys %ENV) {
#        print "$key -> $ENV{$key}<br>\n";
#    }
    print "</HTML></BODY>";
}

&header;
if ($FORM{'input'}) {
	$ARGV[0] = $FORM{'input'};
	&tmp;
    &ports;
}
&end;

exit 0;
