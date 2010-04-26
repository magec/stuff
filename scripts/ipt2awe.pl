#!/usr/bin/perl
# Esto parsea logs de iptables y se los enchufa a awesome-client.

use strict;

{   # Solo puede quedar uno.
    $0 =~ s/.*\///g;
    use Fcntl qw(LOCK_EX LOCK_NB);
    open HIGHLANDER, ">>/tmp/perl_$0_highlander" or die "Cannot open /tmp/perl_$0_highlander: $!";
    {
        flock HIGHLANDER, LOCK_EX | LOCK_NB and last;
        print "Script en uso!\n";
        exit 1;
    }
}

fork and exit;

my $log = "/var/log/iptables.log";
-f $log or die "Can't find $log\n";
my $inotail = `which inotail` || die "Can't find inotail\n";
chomp $inotail;
my $awe = `which awesome-client` || die "Can't find awesome-client\n";
chomp $awe;

open (INPUT, "$inotail -n0 -f $log |") or die "Input pipe phail: $!\n";
while (<INPUT>){
    my %hash = ();
    $hash{$1} = $2 while /([^ ]+)=([^ ]+)/g;
    if ( $hash{MAC} =~ /^((?:\w{2}:){5}\w{2}):((?:\w{2}:){5}\w{2})/ ) {
        open OUTPUT, "| $awe" or die "Output pipe phail: $!\n+";
        printf OUTPUT ("naughty.notify({text = '<span color=\"red\"><b>%-4.4s</b></span> %15.15s <span color=\"yellow\"><b>%-5.5s</b></span> %17.17s <span color=\"green\"><b>-></b></span> %15.15s <span color=\"yellow\"><b>%-5.5s</b></span> %17.17s', timeout = 10, fg = \"white\", bg =\"black\"})\n", $hash{PROTO}, $hash{SRC}, $hash{SPT}, $2, $hash{DST}, $hash{DPT}, $1);
        close OUTPUT;
    }
}
close INPUT;
