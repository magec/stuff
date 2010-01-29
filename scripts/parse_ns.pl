#!/usr/bin/perl
use strict;
use Data::Dumper;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

$ARGV[0] = "fw3.config";
#die "Falta fichero o es binario." unless -T $ARGV[0];
local(*DB, $/);
open (DB, '<', $ARGV[0]) or die "No puedo abir $ARGV[0]";
my $slurp = <DB>;

sub td($$) {
    my $text = shift || "";
    my $args = shift || "";
    return "<TD $args>$text</TD>" if $text ne "" or return '<TD bgcolor=#EEEEEE style="color:grey;font-style:italic">Null</TD>';
}

my %address=();
while ( $slurp =~ /set address "([^"]+)" "([^"]+)" ((?:\d{1,3}\.){3}\d{1,3}) ((?:\d{3}\.){3}\d{3})(?:| "([^"]+)")\n/sg ) {
    $address{"$1~~$2"} = "$3/$4";
}

my %policy=();
while ( $slurp =~ /set policy id (\d+) from "(.+?)" to "(.+?)"  "(.+?)" "(.+?)" "(.+?)"(.+?)set policy id \d+(.+?)exit/sg ) {
    my $id = $1;
    my $rest = $8;
    $policy{$id} = { FROM => $2
                   , TO   => $3
                   , SRC  => [$4]
                   , DST  => [$5]
                   , SRV  => [$6]
                   , ARGS => $7
                   };

    push (@{$policy{$id}{SRC}}, $1) while $rest =~ /set src-address "(.+?)"/sg;
    push (@{$policy{$id}{DST}}, $1) while $rest =~ /set dst-address "(.+?)"/sg;
    push (@{$policy{$id}{SRV}}, $1) while $rest =~ /set service "(.+?)"/sg;
}

#print Dumper %policy;

my $table = '<TABLE style="text-align: center; border-style:solid; border-width:1px;" border="0" >';
    print "<B>Policies:</B><BR>\n";
    print "$table<TR bgcolor=#AAAAAA>"
        .&td('ID')
        .&td('From')
        .&td('To')
        .&td('Source')
        .&td('Destination')
        .&td('Service')
        .&td('Action')
        ."</TR>\n";
        foreach my $key (sort { $policy{$a}{FROM} cmp $policy{$b}{FROM} } keys %policy) {
#        foreach my $key (sort {$a <=> $b} %policy) {
#            next unless $policy{$key}{FROM} eq "laboratori" or $policy{$key}{TO} eq "laboratori";
            print "\t<TR bgcolor=#DDDDDD>"
                .&td($key, 'bgcolor=#AAAAAA')
                .&td($policy{$key}{FROM})
                .&td($policy{$key}{TO})
                .&td(join ('<BR>', map { '<a title="'.$address{"$policy{$key}{FROM}~~$_"}."\">$_</a>" } @{$policy{$key}{SRC}}))
                .&td(join ('<BR>', map { '<a title="'.$address{"$policy{$key}{TO}~~$_"}."\">$_</a>" } @{$policy{$key}{DST}}))
                .&td(join ('<BR>', @{$policy{$key}{SRV}}));
                if ( $policy{$key}{ARGS} =~ /permit/ ) {
                    print &td($policy{$key}{ARGS}, 'bgcolor=#B3D98C')
                } else {
                    print &td($policy{$key}{ARGS}, 'bgcolor=#D9B38C')
                }
                print "</TR>\n";
    }
    print "</TABLE>\n";

exit 0;

foreach (sort { $policy{$a}{FROM} cmp $policy{$b}{FROM} } keys %policy) {
    print "Policy $_: From \"$policy{$_}{FROM}\" to \"$policy{$_}{TO}\"";
    print BOLD RED "\t$policy{$_}{ARGS}";
    print YELLOW "\t@{$policy{$_}{SRC}}\n";
    print GREEN "\t@{$policy{$_}{DST}}\n";
    print BLUE "\t@{$policy{$_}{SRV}}\n";
}
