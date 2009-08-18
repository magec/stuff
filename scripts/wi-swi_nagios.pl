#!/usr/bin/perl -w

use strict;
use Net::Telnet;

my $telnet = new Net::Telnet ( Timeout  => 5
                             , Errmode  => 'die'
                             , Prompt   => '/RBT8200castelldefels[>#]/i'
                             );
$telnet->open('XXX.XXX.XXX.XXX');
$telnet->login('users', 'password');
$telnet->print('enable');
$telnet->waitfor('/Enter password:/i');
$telnet->cmd('enablepass');
$telnet->cmd('set length 0');
my @data = $telnet->cmd('show ap status all name');

print "Bad Data" and exit 2 if $#data < 7;  # El header ya ocupa 8 filas.

my @ApFail = ();
foreach (@data) {
    next if not $_ =~ /^\s{0,3}\d{1,4}/;
    my $ApName  = substr($_, 5,  16);
    my $Uptime  = substr($_, 72, 6);
    if ( not $ApName =~ /^<unknown>/ and $Uptime =~ /^\s+$/ ) {
        $ApName =~ s/\s+$//g;
        push (@ApFail, $ApName);
    }
}

if ($#ApFail == -1) {
    print "OK" and exit 0;
    } else {
    print "(".($#ApFail+1)." APs down) ".join ( ", ", @ApFail) and exit 1;
}
