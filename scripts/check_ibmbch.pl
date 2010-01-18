#!/usr/bin/perl

use strict;
use warnings;
use SNMP;

exit 3 unless $#ARGV == 1 and $ARGV[0] =~ /^(\d{3}\.){3}\d{3}$/ and $ARGV[1] =~ /^\d+$/;

my $oid = ".1.3.6.1.4.1.2.3.51.2.2.8.2.1.1.5.$ARGV[1]";  #BLADE-MIB::ledBladeHealthState
my $oid2 = ".1.3.6.1.4.1.2.3.51.2.2.8.2.1.1.6.$ARGV[1]"; #BLADE-MIB::ledBladeId
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

my $session = new SNMP::Session( DestHost  => $ARGV[0]
                               , Community => 'public'
                               , Port      => 161
                               , Version   => 1
                               );

my $result = $session->get($oid)  || undef;
my $blname = $session->get($oid2) || "(No name)";

if (defined $result and $#{$hash{$result}} == 1) {
    print "($ARGV[1])$blname: ${$hash{$result}}[1]\n";
    exit ${$hash{$result}}[0];
} else {
    print "Null/Bad response from $oid on $ARGV[0]\n";
    exit 3;
}
