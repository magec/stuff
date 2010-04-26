#!/usr/bin/perl

use strict;
use warnings;
use SNMP;

unless ($#ARGV == 1 and $ARGV[0] =~ /^(\d{1,3}\.){3}\d{1,3}$/ and $ARGV[1] =~ /^\d+$/ ) {
    print "$0\t<ip/host> [0-14]\n\n";
    print "0\tMuestra el estado general de la enclosure mediante la oid 'systemHealthStat'\n";
    print "1-14\tMuestra el estado de la blade mediante la oid 'ledBladeHealthState'\n";
    exit 3;
}

my ($bld_health, $bld_id, $sys_health);

my %hash = ( 0  => [1, 'unknown']
           , 1  => [0, 'good']
           , 2  => [1, 'warning']
           , 3  => [2, 'critical']
           , 4  => [1, 'kernelMode']
           , 5  => [1, 'discovering']
           , 6  => [1, 'commError']
           , 7  => [1, 'noPower']
           , 8  => [1, 'flashing']
           , 9  => [1, 'initFailure']
           , 10 => [1, 'insufficientPower']
           , 11 => [1, 'powerDenied']
           );

my %hash2 = ( 0   => [2, 'critical']
            , 2   => [1, 'nonCritical']
            , 4   => [1, 'systemLevel']
            , 255 => [0, 'normal']
            );

my $session = new SNMP::Session( DestHost  => $ARGV[0]
                               , Community => 'public'
                               , Timeout   => 10000000
                               , Version   => 1
                               );

if ($ARGV[1] > 0) {
    $bld_health = $session->get(".1.3.6.1.4.1.2.3.51.2.2.8.2.1.1.5.$ARGV[1]");            #BLADE-MIB::ledBladeHealthState
    $bld_id = $session->get(".1.3.6.1.4.1.2.3.51.2.2.8.2.1.1.6.$ARGV[1]") || "(No Name)"; #BLADE-MIB::ledBladeId
} else {
    $sys_health = $session->get(".1.3.6.1.4.1.2.3.51.2.2.7.1.0");                         #BLADE-MIB::systemHealthStat
}

if (defined $bld_health and $#{$hash{$bld_health}} == 1) {
    print "($ARGV[1])$bld_id: ${$hash{$bld_health}}[1]\n";
    exit ${$hash{$bld_health}}[0];
} elsif (defined $sys_health and $#{$hash2{$sys_health}} == 1) {
    print "($ARGV[0])$sys_health: ${$hash2{$sys_health}}[1]\n";
    exit ${$hash2{$sys_health}}[0];
} else {
    print "Null/Bad response from $ARGV[0]\n";
    exit 3;
}
