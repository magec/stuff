#!/usr/bin/perl

use strict;
use SNMP;
use Data::Dumper;

my $group = 'Appliances';
my $host  = 'localhost';
my $port = 161;
my $community = 'public';
my $oid = 'ifEntryInOctets.1';
my $text = 'Interface ';
my $iface = undef;

if ($0 =~ /^(?:|.*\/)snmp(?:|_G_(.*?))_H_([^_]+?)(?:|_C_(.*?))_O_([^_]+?)(?:|_T_(.*))$/) {
        $group          = $1 if defined $1;
        $host           = $2 if defined $2;
        $community      = $3 if defined $3;
        $oid            = $4 if defined $4;
        $text           = $5 if defined $5;
        if ($host =~ /^([^:]+):i(\d+)$/) {
                $host = $1;
                $port = $2;
        }
        if ($oid =~ /.+.(\d+)/) {
                $iface = $1;
        }
}

#Si el oid es una OID numerica sin el punto, lo anexamos.
$oid = ".$oid" if $oid =~ /^(?:\d+\.)+\w+$/;
$text =~ s/_+/ /g;

my %hash =(
        ifName                                          =>      '.1.3.6.1.2.1.1.1.0',
        ifEntryInOctets                         =>      ".1.3.6.1.2.1.2.2.1.10.$iface",
        ifEntryOutOctets                        =>      ".1.3.6.1.2.1.2.2.1.16.$iface",
        ifHCInOctets                            =>  ".1.3.6.1.2.1.31.1.1.1.6.$iface",
        ifHCOutOctets                           =>  ".1.3.6.1.2.1.31.1.1.1.10.$iface",
        AvgCpu5Sec                                      =>      '.1.3.6.1.4.1.89.35.1.112.0',
        AvgCpu60Sec                                     =>      '.1.3.6.1.4.1.89.35.1.113.0'
);

sub CreateSnmpSession() {
        my $session = new SNMP::Session(
                DestHost        => $host,
                Community       => $community,
                Port            => $port,
                Version         => '2c'
        );
        return $session ;
}

sub GetOne() {
        my $session = &CreateSnmpSession;
        my $result = $session->get(@_[0]);
        if ( $session->{ErrorNum} ) {
                return undef;
        } else {
                return $result;
        }
}

my $result = &GetOne($oid);
my $desc = &GetOne($hash{'ifName'});
$desc = $& if $desc =~ /[^\n]+/;

if ($ARGV[0] and lc($ARGV[0]) eq "config") {
print <<EOF;
host_name $group
graph_title $text $host
graph_args --base 1000
graph_vlabel ${oid}'s value per \${graph_period}
graph_category $host
graph_info This graph shows ${oid}'s value from "$host".
result.label Val
result.draw LINE1
result.type DERIVE
result.cdef recv,8,*
result.max 2000000000
result.min 0
EOF
}

if (defined $result) {
        print "result.value $result\n";
} else {
        print "result.value U\n";
}
