#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Long qw(:config bundling);
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

local(*INPUT, $/);
open (INPUT, $ARGV[0]) or die RED "No puedo abrir $ARGV[0]: $!";
my $slurp=<INPUT>;
close INPUT;
my @files;
while ( $slurp=~/(?:tap:aio:|kernel|ramdisk).*?([\w\/\.\-]+)/gi ) {
    my $file=$1;
    my $out=`file -b $file`;
    if ( $out=~/(?:image|gzip)/i ) {
        print BLUE $out;
#        my @args = ("rsync", "-avz", $file, "root\@213.73.41.140:$file");
#        print GREEN "@args";
#        system(@args) == 0 or die RED "system @args failed: $?";
#            system("rsync -avz $file root\@172.26.0.232:$file");
#    system(q(rsync -avz $file root\@172.26.0.232:$file));
            &shell("\Qrsync -avz $file root@172.26.0.232:$file");
    } elsif ( $out=~/swap/i ) {
        print GREEN $out;
    } elsif ( $out=~/(?:ext[2-4]|reiser)/i ) {
        print YELLOW $out;
    } else {
        print RED $out;
    }
}

#ssh-keygen -N '' -f /tmp/id_rsa -t rsa -q
#cat /tmp/id_rsa.pub | ssh root@172.26.0.232 'cat >> .ssh/authorized_keys'
#eval `ssh-agent`
#ssh-add /tmp/id_rsa


sub shell() {

    system("@_") == 0 or die RED BOLD "system @_ failed: $?";

#    return system(quotemeta("@_"));
    
}
