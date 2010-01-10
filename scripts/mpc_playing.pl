#!/usr/bin/perl
use strict;
chomp (my $mpc = `which mpc`);
die $! unless -B $mpc; # -B fichero binario
my @out = `$mpc --format "Track %track%: %artist% - %title%, From The Album \'%album%\'"`;
if ($? == 0) {
    $mpc = "$out[1] $out[0]";
    $mpc =~ s/[#\n\r\s; ]+/ /g;
}
my $cmd = sprintf <<EOF;
screen -S mdc2 -p 0 -X stuff "say $mpc"
EOF
print "$mpc\n";
system('ssh oscar@172.26.0.252 -p 22222 -i ~/.ssh/zaibach_id_dsa '.quotemeta($cmd));
